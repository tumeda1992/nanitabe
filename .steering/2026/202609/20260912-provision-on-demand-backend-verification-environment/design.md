# Design: backend の動作確認環境を ECS 上へオンデマンドで立てる

## 元の依頼内容

> バックエンドの動作確認環境を立てたい。ECSで立てて、立てたい時だけ立てて、停止も指示して停止するか、自動で起動から30分で停止するみたいな感じ。 `~/src/github.com/<参照元 owner>/<参照元 repository>/.steering/2026/202609/20260910-provision-amplify-verification-environment` でやったものでブランチ運用とか参考にして。ただ、`<参照元 repository>` はprivateリポジトリだから、design.mdに転記するときも出典元のリポジトリ名はマスク化すること

参照元 steering は private repository にあるため、本文中では `<参照元 repository>` と表記し、実 repository 名を記載しない。参照するのは運用の型（常設 branch への force push による載せ替え、後始末を運用へ含めない規約、閉じる操作の定義）であり、その repository 固有の resource 名や URL ではない。

---

## TL;DR

現在、backend を動かして確認できるのは開発者の PC 上の `docker compose` だけで、スマホ実機など PC 以外の端末からその backend へ到達できない。ECS 上に backend API 単体の動作確認環境を置き、必要なときだけ起動して、明示停止と起動から 30 分の自動停止のどちらでも落ちる状態を作る。DB は既存の DB サーバへ接続し、環境内に持たない。frontend とは繋がず、確認手段は `POST /graphql` を直接叩くことに限る。

「立てたい時だけ立てる」という要求の実質は、停止中に課金が積み上がらないことである。これを構成の制約として扱い、存在するだけで課金される時間課金の resource（ALB、RDS、NAT Gateway、Elastic IP）を持たない。停止中に残る課金は image と log の保存料、および止め忘れを検知する alarm だけで、合計は月 $0.22 程度になる。この制約が公開方式を規定し、HTTPS 終端を ALB ではなく API Gateway に置く形を導く。

---

## 完成後の姿

### workflow

**ownerと責務:**

| owner | 判断・更新するもの | 行わないこと | single source of truth |
| --- | --- | --- | --- |
| 動作確認したい開発者 | `review` branch へ何を載せるか、いつ起動・停止するか、確認が済んだか | AWS resource の定義変更 | git remote の `review` の HEAD |
| 起動 script（`scripts/review_backend/start.sh`） | `desired_count` を 1 へ、integration URI を実 IP へ、停止 schedule の作成。schedule の作成に失敗した場合は両方を停止側へ戻す | 何を載せるかの判断、image の作成 | ECS service の `desired_count` と API Gateway の integration URI |
| 停止 script（`scripts/review_backend/stop.sh`） | 上記 2 つを停止側へ戻す、停止 schedule の削除 | 同上 | 同上 |
| EventBridge Scheduler | 起動から 30 分後に、停止 script と同じ 2 つの操作を行う | 何を載せるかの判断 | schedule の実行時刻 |
| CodePipeline / CodeBuild | `review` branch の HEAD から image を作り ECR へ push する | 起動中かどうかの状態 | ECR の image |
| Terraform | 常設 resource の定義。`desired_count` は 0 を定義の正とする | 実行時の `desired_count` と integration URI の増減 | `infrastructure/terraform/envs/review` を root とする定義 |

`desired_count` は Terraform と script の両方が書き込む値だが、正本が二重になるわけではない。Terraform の定義は「停止状態が正」を表し、script が行う 1 への変更は一時的な逸脱として扱う。`terraform apply` は常に停止側へ倒れる。

integration URI も両方が書き込むが、扱いを逆にする。Terraform 側で `lifecycle { ignore_changes = [integration_uri] }` を設定し、`terraform apply` が実行時の値を上書きしないようにする。`desired_count` と扱いが分かれるのは、両者が表すものが違うためである。`desired_count` は「起動しているべきか」という意図であり、apply が停止側へ倒れることに意味がある。integration URI は「今どの task を指しているか」という実体との対応であり、apply が実体と食い違う値を書き込むと、service は動いているのに到達できないという中途半端な状態が生まれる。

**状態と遷移:**

```text
  停止状態（desired_count=0、integration URI = 到達しない値）
     |
     |  確認対象を main へ rebase し、review branch へ force push（開発者）
     v
  image build（CodePipeline → CodeBuild）
     |
     |  build 成功、ECR へ push
     v
  起動可能状態
     |
     |  起動 script を実行（開発者）
     v
  desired_count=1、task 起動中
     |
     |  task が RUNNING になり public IP が確定
     v
  integration URI を実 IP へ更新 + 30 分後の停止 schedule を 2 つ作成
     |
     v
  到達可能（https://review-backend-nanitabe.kibotsu.com が応答）
     |
     +----- 動作を確認（開発者） ----->  確認完了
     |
     +----- 停止 script を実行（開発者） --------+
     |                                           |
     +----- 起動から 30 分経過（Scheduler） -----+
                                                 |
                                                 v
              desired_count=0 + integration URI を到達しない値へ戻す
                                                 |
                                                 v
                                            停止状態
```

常設の resource（ECS cluster、service 定義、task definition、ACM 証明書、API Gateway、custom domain、Route53 の A レコード、ECR、CodePipeline / CodeBuild）はこの遷移で変化しない。起動・停止で変わるのは `desired_count` と integration URI の 2 つだけである。

**必須順序とhandoff:**

1. 開発者が確認対象の branch を `main` へ rebase する。`main` の変更と組み合わせた挙動を確認対象へ含めるため。
2. 開発者が `git push -f origin <確認対象>:review` を実行する。`review` branch に何が載っているかは保証されないため、開く前に必ず自分の確認対象を載せる。
3. push を契機に CodePipeline が起動し、CodeBuild が image を作って ECR へ push する。開発者は build の成否を確認してから次へ進む。
4. 開発者が起動 script を実行する。script は `desired_count` を 1 にし、task が RUNNING になるまで待ち、ENI から public IP を取得し、integration URI を更新し、停止 schedule を 2 つ作り、到達 URL と自動停止の予定時刻を出力する。schedule の作成に失敗した場合は、`desired_count` と integration URI を停止側へ戻してエラー終了する。自動停止の保証がない状態で起動したままにしない。
5. 開発者が PC 以外の端末から `https://review-backend-nanitabe.kibotsu.com/graphql` を叩いて確認する。
6. 確認が終わったら停止 script を実行する。実行しなくても起動から 30 分で Scheduler が同じ状態へ戻す。
7. 確認後の後始末（`review` branch を戻す等）は行わない。次に確認する人の force push で上書きされる。

**失敗・取消・再開:**

- build が失敗した場合: ECR には前回の image が残る。build の成否を確認せずに起動すると、確認したい内容ではなく前回の内容が動く。起動前に build の成否を確認する。
- task の起動に失敗した場合（image pull 失敗、migration 失敗、DB 接続失敗）: service は task を再作成し続ける。同じ失敗が最大 30 分ぶん CloudWatch Logs へ積み上がる。原因を確認したら停止 script を実行し、直してから起動し直す。circuit breaker は設けない（起動失敗が無限には続かないため）。
- migration が途中まで適用されて失敗した場合: 開発 DB のスキーマが中間状態になる。開発 DB を共有する構成であるため、この影響はローカル開発にも及ぶ。復旧は通常の migration 運用と同じ手順で行う。
- 停止 schedule の作成に失敗した場合: 起動 script が `desired_count` と integration URI を停止側へ戻してエラー終了する。起動していない状態へ戻るため、原因を直してから起動し直す。
- 停止処理の片方だけが成功した場合: `desired_count` を 0 にする操作と integration URI を戻す操作はどちらも冪等であるため、停止 script をもう一度実行すれば揃う。
- 起動から 45 分が経過しても task が動き続けていた場合: 自動停止が働かなかったことを意味する。alarm から通知が届くので、受け取った人が停止 script を実行する。alarm 自体は task を止めない。
- 確認対象を取り違えて push した場合: 正しい確認対象を同じ手順で force push し直す。`review` branch に後始末の操作がないため、上書きが唯一の訂正手段になる。

---

### runtime・設定・環境構築

**実行条件と設定:**

| identifier / dependency | 値または解決元 | default | 影響する挙動 |
| --- | --- | --- | --- |
| `RAILS_ENV` | 確認環境の task definition。値は `production` | なし | `config/environments/production.rb` が適用される。`/graphiql` は mount されず、`POST /graphql` だけが入口になる |
| `DB_NAME` / `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASS` | SSM Parameter Store の SecureString。値は開発環境と同じ（既存 DB サーバの同じ database）。`apply_terraform.sh` が `.env` から `TF_VAR_*` 経由で渡し、Terraform が parameter を作る | なし | 未設定なら起動時に DB 接続失敗。開発環境と同一 database のため、この環境の migration と mutation が開発 DB へ直接届く |
| `RAILS_MASTER_KEY` | 同上（SSM Parameter Store の SecureString） | なし | credentials 復号。未設定なら production boot が失敗する |
| `BACKEND_PROD_HOST` | `review-backend-nanitabe.kibotsu.com` | 空文字 | `config.hosts` 許可 host。API Gateway が Host ヘッダをこの値へ上書きするため、経由した request だけが通る。public IP を直接叩いた request は Host が IP になり `Blocked hosts` で弾かれる |
| `FRONTEND_PROD_HOST` | 設定しない。frontend を繋がないため（[非目標](#非目標)） | 空文字 | 未設定でも `config.hosts` へ空文字が足されるだけで、到達可否は `BACKEND_PROD_HOST` が決める |
| `RAILS_LOG_TO_STDOUT` | 確認環境の task definition。値は `1` | 未設定 | 未設定だと log が file 出力のみになり CloudWatch Logs へ出ない |
| `PORT` | task definition。値は `18101` | `3000` | puma の listen port。API Gateway の integration URI がこの port を指す。外部からは見えない |
| CPU architecture | task definition の `runtime_platform`。値は `ARM64` | `X86_64` | X86_64 より約 20% 安い。開発機も aarch64 のため native 拡張を持つ gem の挙動が揃う |
| 起動から自動停止までの時間 | 起動 script の環境変数 `REVIEW_BACKEND_AUTO_STOP_MINUTES`。起動 script はこの値から schedule の実行時刻を計算する | `30` | 自動停止の発火時刻。検証時に短い値を渡すことで、待たずに発火と停止処理を確認できる |
| `desired_count` | Terraform の定義は 0。実行時は起動 script が 1、停止 script と Scheduler が 0 にする | `0` | 0 なら task が存在せず、Fargate の時間課金が発生しない。`terraform apply` は常に 0 へ戻す |
| integration URI | 起動 script が `http://<task の public IP>:18101/{proxy}` を書き、停止時は `http://192.0.2.1:18101/{proxy}` へ戻す | 到達しない値 | API Gateway が転送する先。停止中に実 IP を指したままにしない |
| CodePipeline 名 | `${appname}_codepipeline_${stage}` を展開した `nanitabe-back_codepipeline_review`。既存 frontend の `frontend/terraform/modules/cicd/codepipeline/main.tf` と同じ命名規則 | なし | 運用 document が build の成否確認 command へこの名前を書くため、実装が別名を付けると手順が通らない |
| ECS cluster 名 / service 名 | cluster は `nanitabe-back-review`。service は `${appname}_service_${stage}` を展開した `nanitabe-back_service_review` | なし | 起動・停止 script と停止 schedule がこの名前で対象を指す |

**環境別の完成状態:**

| environment | 配置・起動条件 | 観測可能な結果 |
| --- | --- | --- |
| development（既存） | `docker compose up`、`backend/entrypoint.sh` | `localhost:18101` で Rails が応答し `/graphiql` が開ける |
| production（既存） | `ap-northeast-1` の EC2 上で git pull 起点の deploy（[前提とする既存仕様](#付録前提とする既存仕様)） | 本番 backend host が応答する |
| 動作確認（新規） | ECS 上。起動操作があるときだけ稼働する。DB は持たず既存 DB サーバへ接続する | 開発者の PC 以外の端末から `https://review-backend-nanitabe.kibotsu.com/graphql` が応答する。停止中は同じ URL が API Gateway 経由で到達不能になる |

**IAM role:**

| role | 付与する権限 | 必要な理由 |
| --- | --- | --- |
| task execution role | ECR からの image pull、CloudWatch Logs への書き込み、`ssm:GetParameters`、`kms:Decrypt` | image を取得し、log を出し、SecureString の parameter を復号して task へ渡すため |
| task role | なし（付与しない） | backend の application は AWS API を呼ばない。DB は EC2 上の MySQL へ通常の接続で到達する |
| EventBridge Scheduler role | `ecs:UpdateService`、`apigatewayv2:UpdateIntegration` | 自動停止の 2 つの schedule が AWS API を直接呼ぶため |
| CodeBuild role | ECR への push、CloudWatch Logs への書き込み、artifact 用 S3 bucket への読み書き | image を作って push し、build log を残すため |
| CodePipeline role | CodeBuild の起動、artifact 用 S3 bucket への読み書き、CodeStarConnection の使用 | Source から Build へ artifact を渡すため |
| SNS topic policy | CloudWatch（`cloudwatch.amazonaws.com`）からの `sns:Publish` | alarm が topic へ通知を送るため。role ではなく topic 側の resource policy として与える |

**log と監視:**

task の log は CloudWatch Logs へ出す。`RAILS_LOG_TO_STDOUT=1` を設定し、task definition の `awslogs` driver で log group へ送る。log group は Terraform が作る。`frontend/terraform/modules/apigateway/main.tf` が `/aws/http-api/<api name>` の log group を持つのと同じ形で、API Gateway 側の access log も残す。

いずれの log group も `retention_in_days` を設定せず無期限で保持する。CloudWatch Logs の課金は取り込み（$0.76 / GB）が主で、これは起動中にしか発生しない。停止中の課金は保存分（$0.03 / GB / 月）だけであり、月 10 回起動のペースで 1 年蓄積しても月 $0.02 程度にとどまる。

止め忘れの検知に CloudWatch alarm を 1 つ置く。起動している task の数を直接表す標準 metric が存在しないため、`AWS/ECS` の `CPUUtilization` の data point の有無で判定する。

| 項目 | 値 |
| --- | --- |
| statistic | `SampleCount` |
| period | 300 秒 |
| evaluation periods | 9（合計 45 分） |
| 条件 | 9 期間すべてで data point が存在する |
| `treat_missing_data` | `notBreaching`（task が無い＝正常） |
| action | SNS topic へ通知し、topic から email へ配信する |

Container Insights は有効にしない。`RunningTaskCount` が得られる代わりに、従来版は metric あたり月 $0.30、service あたり 10 から 20 個の metric が出るため月 $3 から $6 になり、止め忘れ時の損失と競う水準になる。標準 metric で同じ判定ができるため導入しない。

alarm は通知するだけで task を止めない。45 分後に強制停止する保険の schedule も置かない。保険で止まると「30 分の自動停止が働いたのか、45 分の保険で止まったのか」が利用者から区別できず、30 分の設定が守られているかを検証できなくなる。

**停止中に発生する課金:**

| 対象 | 月額 |
| --- | --- |
| ECR の image 保存（lifecycle policy で最新 1 世代を残す） | $0.1 |
| CloudWatch Logs の保存（無期限保持、1 年蓄積時点） | $0.02 |
| CloudWatch alarm 1 つ | $0.10 |
| 合計 | $0.22 |

**不足・不整合時:**

- SSM parameter が存在しない、または task execution role に復号権限がない場合: task が起動前に失敗する。`secrets` の解決は container の起動より前に行われるため、application のエラーではなく ECS の task 起動失敗として現れる。
- `BACKEND_PROD_HOST` が設定されていない場合: `config.hosts` に host 名が入らず、API Gateway 経由の request も `Blocked hosts` で 403 になる。到達できなくなるだけで、誤って公開される方向へは倒れない。
- DB へ到達できない場合: 起動処理の `rails db:migrate` が失敗し、`set -e` により puma を起動せず task が異常終了する。壊れた状態で到達可能にはならない。
- ECR に image が無い、または pull できない場合: task が起動しない。service が再作成を繰り返し、最大 30 分後に自動停止で止まる。
- SNS topic の email 購読が確認されていない場合: alarm は発報するが通知が届かない。購読確認は確認メールへの応答が要る手作業であり、Terraform の適用だけでは完了しない。止め忘れに気づけなくなるため、構築時に購読状態を確認する。

**file配置と既存pattern:**

```text
infrastructure/terraform/envs/
├── prod/          # 既存。state key = prod/terraform.tfstate
└── review/        # 新設。state key = review/terraform.tfstate
    ├── main.tf    # backend/terraform/envs/review を module として呼ぶ
    ├── init_terraform.sh
    └── apply_terraform.sh

backend/terraform/          # 新設
├── values/values.tf        # appname = "nanitabe-back"
├── modules/
│   ├── ecr/
│   ├── ecs/                # cluster、task definition、service（desired_count = 0）
│   ├── apigateway/         # HTTP API、custom domain、ACM 証明書、Route53
│   └── cicd/               # CodePipeline + CodeBuild
└── envs/review/main.tf     # stage = "review" を local で持ち、各 module へ配る

scripts/review_backend/     # 新設
├── start.sh
└── stop.sh
```

- prod と review を別 state にする。`terraform apply` が停止側へ倒れる挙動（`desired_count = 0` が定義の正）を、prod 側の作業へ波及させないため。
- root を `infrastructure/terraform/envs/*` に置き、各アプリの `terraform/envs/*` を module として呼ぶ既存構造を維持する。`frontend/terraform/envs/review/`（現在 `.gitkeep` だけの空 directory）を将来同じ root から呼べる。
- ECS cluster は `nanitabe-back-review` を新設する。既存の `sample_todo_list_cluster` は別プロジェクトのものであり流用しない。Fargate だけを使う cluster に固定費は発生しない。
- 参照する既存 pattern: `frontend/terraform/envs/prod/main.tf`（`stage` を local で持ち、module へ配る）
- `backend/buildOnEcs/Dockerfile`（新規）: ECS 用の image を作る。application code を COPY し、`bundle install` を build 時に済ませる。既存の `backend/Dockerfile` は開発用（volume mount 前提）のまま変更しない。
- `backend/buildOnEcs/entrypoint.sh`（新規）: `set -e` のもとで `rails db:migrate` を実行し、`exec bundle exec puma -b "tcp://0.0.0.0:${PORT}"` で puma をプロセス 1 に置き換える。
- 参照する既存 pattern: `frontend/buildOnLambda/Dockerfile`。通常の `Dockerfile` と別に、deploy 先向けの Dockerfile を持つ形。
- 参照する既存 pattern: `frontend/terraform/modules/cicd/`（`codebuild` と `codepipeline` の 2 階層）。CodePipeline の Source に `CodeStarSourceConnection`、Build に CodeBuild を置く。
- 参照する既存 pattern: `frontend/terraform/modules/apigateway/main.tf`。`aws_apigatewayv2_api` を HTTP protocol で作り、`$default` route と `auto_deploy` の stage、CloudWatch log group を持つ。今回は integration type が `AWS_PROXY`（Lambda）ではなく `HTTP_PROXY`（task の public IP）になり、custom domain と ACM 証明書が加わる。

---

### documentationによって成立する知識体系

**形式知化する対象:**

- 暗黙知・散在知識・pain: この環境の存在と使い方が、この steering の議論ログにしか無い。次に「スマホから backend を叩いて確認したい」と思った開発者が、どの branch へ何を push し、どの script を叩き、どの URL を開けばよいかを再探索することになる。
- 再利用可能な原則へ引き上げるもの: `review` branch に何が載っているかは保証せず、確認する人が開く前に自分の確認対象を force push するという規約。後始末の操作を運用へ含めないことで、規約が守られなかった場合により悪い状態を作らない。

**読者と成立させる判断:**

| 読者 | 利用場面 | codeや過去会話を再調査せず可能になる判断・action | 入口 |
| --- | --- | --- | --- |
| 動作確認したい開発者 | PC 以外の端末から backend を叩きたい | どの branch へ何を push し、どの script を叩き、どの URL を開くか | `backend/docs/ai_guideline/development_standard/review_environment.md` |
| AI agent へ作業を依頼する人 | agent にどこまで自走させるか判断する場面 | どの操作なら事前確認なしに実行してよく、どこから停止するか | 同上 |
| Terraform を適用する人 | review 環境の構成変更、prod 側の適用 | state が分かれていること、`terraform apply` が起動中の review 環境を落とすこと | `infrastructure/README.md` |

**知識構造:**

```text
AGENTS.md（既存へ追記）
└── infrastructure/ の行を足し、infrastructure/README.md を入口にする

infrastructure/README.md（新規）
├── terraform/envs/prod と terraform/envs/review が別 state であること（state key と内訳）
├── init_terraform.sh と apply_terraform.sh の使い方（既存 prod の script と同型）
├── desired_count = 0 が定義の正であり、terraform apply は起動中の review 環境を落とす
└── 実行時の desired_count と integration URI は Terraform が管理せず、script と Scheduler が持つ

backend/docs/ai_guideline/development_standard/review_environment.md（新規）
├── review 環境とは何か（backend API 単体、PC 以外の端末から叩く、frontend は繋がない）
├── 使い方（main へ rebase → review へ force push → build 確認 → 起動 script → URL → 停止 script）
├── 規約（何が載っているかは保証しない。開く前に自分で載せる。後始末はしない）
├── 開発 DB を共有していること（migration と mutation が開発 DB へ届く）
├── 止め忘れると 45 分で通知が届くこと（alarm は止めないので、受け取ったら停止 script を実行する）
├── review 環境に閉じる操作の定義と、閉じる範囲で緩める扱い・緩めない扱い
└── 誤適用（frontend と繋ぐ用途に使う、admin/ 配下の画面を開こうとする）
```

**規範の根拠と適用境界:**

- 根拠となるpain: 確認手段が各自の `docker compose` だけであり、そこへは PC 以外の端末から到達できない。
- MUST: `review` へ載せる前に確認対象 branch を `main` へ rebase する。URL を開く前に自分の確認対象を force push する。build の成否を確認してから起動する。
- SHOULD: 確認が終わったら停止 script を実行する。実行しなくても 30 分で止まる。
- 適用対象: `main` へ入れる前に、PC 以外の端末から backend API を確認する場面。
- 例外・非目標: PR ごとに環境を立てる運用は対象外。`review` は固定 1 本の常設 branch である。frontend と繋いだ確認も対象外。
- 誤適用: `review` を「`main` と同じものが載っている場所」として開くこと。何が載っているかは保証しない。
- 誤適用: `admin/` 配下の管理画面を開こうとすること。`assets:precompile` を行っていないため開けない。

**実行者の線引き:**

review 環境に閉じる操作を、本番 backend とその host、開発 DB のスキーマとデータ、prod の Terraform state とその resource、`.env` と SSM parameter の値のいずれにも影響が及ばない操作と定義する。

該当するのは、`review` branch への force push、起動 script の実行、停止 script の実行、review state に対する `terraform plan`、および差分が review state 内の resource の追加・変更だけで destroy を含まない `terraform apply` である。これらは操作ごとの事前確認なしに実行してよい。

閉じる範囲でも緩めない扱いを三つ置く。`terraform apply` の前に必ず `terraform plan` を実行し、差分が条件を満たさなければ apply せず停止して報告する。secret を log、成果物、chat へ出さない。`main` への merge と PR 操作は緩和の対象外とする。

差分の確認は人の目視に委ねず、`infrastructure/terraform/envs/review/apply_terraform.sh` が行う。この script は plan を file へ保存し、`terraform show -json` で destroy を含む変更が 1 件でもあれば apply せず異常終了する。harness の permission を script 単位で与えても契約が飛ばされないようにするためである。`terraform apply` を直接許可する permission は設けない。

閉じる操作に見えて該当しないものが三つある。`review` へ載せたコードに含まれる migration は開発 DB のスキーマを変えるため閉じない。prod state に対する apply は、review 環境のための変更であっても閉じない。SSM parameter の値の変更は、値の出所が `.env` であり開発環境と共有されているため閉じない。

閉じるかどうかは対象 resource と state で決まり、`review` という名前が付いているかでは決まらない。

**公開 repository であることの制約:**

この repository は GitHub 上で public である。`.steering/` 配下も tracked であり公開される。

repository へ commit する document には、次を書かない。

- 実際の domain 名。`frontend/terraform/envs/prod/main.tf` が `custom_domain = "nanitabe.${var.route53_name}"` と変数化しているのと同じ扱いにし、document では `review-backend-nanitabe.<hosted zone>` と表記して `.env` の `ROUTE53_HOSTZONE_NAME` を参照する形にする。
- 本番 backend と DB が動いている場所（どの AWS service か、開発環境と共有しているか）。この環境が開発 DB を共有していることは `review_environment.md` に書くが、その DB がどこにあるかは書かない。

`.steering/` 配下の design、tasklist、discussion は作業記録として現状の表記を維持する。議論の原文を書き換えないため。公開 document を書くときだけこの制約を当てる。

**snapshotと維持規律:**

| 正しいsnapshot | single source of truth | 更新owner | 更新trigger | 腐敗signal |
| --- | --- | --- | --- | --- |
| review 環境の使い方、規約、実行者の線引き | `backend/docs/ai_guideline/development_standard/review_environment.md` | 運用方法または線引きを変える人 | 載せ方、起動・停止手順、緩和範囲のいずれかが変わったとき | script の引数や出力と手順の記述がずれる |
| state の分かれ方と apply の挙動 | `infrastructure/README.md` | Terraform の構成を変える人 | env の増減、state key の変更、`desired_count` の扱いの変更 | `review_environment.md` の帰結の記述と食い違う |

`terraform apply` が起動中の環境を落とすという条件の本文は `infrastructure/README.md` だけが持ち、`review_environment.md` は利用者から見た帰結を書いて参照する。同じ条件を二箇所へ書くと、片方だけが更新されたときに矛盾する。

---

## 要件（Requirements）

### MUST（必達）

- backend API 単体が ECS 上で起動し、開発者の PC 以外の端末から `POST /graphql` へ到達できる。
- 明示的な停止操作で停止する。
- 起動から 30 分で自動停止する。
- 停止中に発生する課金を、image と log の保存料、および止め忘れを検知する alarm に限り、合計で月 $1 を超えない。時間課金の compute / network resource（ALB、RDS、NAT Gateway、Elastic IP）と Secrets Manager、および Container Insights を構成へ含めない。
- DB は環境内に持たず、既存の DB サーバへ接続する。接続先は開発環境と同じ database とする。
- 自動停止が働かずに task が動き続けた場合に通知が届く。通知までの時間は既定で 45 分とする。

### SHOULD（できれば）

- AWS 上の frontend と繋ぐ構成（非目標に記載）へ後から拡張するときに、今回作ったものを作り直さずに済む。

### MAY（あれば嬉しい）

- 停止し忘れた状態で起動 script を実行したとき、いつから起動しているかが分かる。

### 非目標

- AWS 上の frontend と繋いだ end-to-end の確認。今回は backend API 単体までとする。
- 本番 backend を ECS へ移行すること。今回の環境はその前段になり得るが、移行自体は扱わない。
- 動作確認環境の内部に DB を持つこと。
- 上記の将来構想のために、今回の要求を満たすのに不要な構成を先回りで作ること。

### 受け入れ基準

- 起動操作の後、開発者の PC 以外の端末から `POST /graphql` を叩いて期待する response が返る。
- 明示的な停止操作の後、同じ endpoint へ到達できなくなる。
- 停止操作をしなくても、schedule の発火によって同じ endpoint へ到達できなくなり、`desired_count` が 0 になる。発火までの時間が既定で 30 分であることは、作られた schedule の実行予定時刻で確認する。
- 停止状態で発生する課金が、image と log の保存料および alarm に限られる。`terraform plan` と `terraform state list` の出力に ALB / RDS / NAT Gateway / Elastic IP / Secrets Manager が現れないことで確認する。Cost Explorer は反映が翌日以降になり完了判定に使えないため用いない。
- 自動停止が働かずに task が動き続けた場合に、alarm から通知が届く。通知までの時間が 45 分であることは alarm の定義値で確認する。
- 記載された運用 document の手順だけを入力として、起動から確認、停止までの一連の操作が通る。

---

## リスクと対策

| リスク | 対策 |
| --- | --- |
| 停止し忘れて課金が続く | 起動から 30 分の自動停止。自動停止が働かなかった場合は、45 分で CloudWatch alarm が通知する。通知を受けた人が停止 script を実行する |
| 自動停止の schedule 自体が作られない | 起動 script が schedule の作成結果を確認し、失敗したら `desired_count` を 0 へ戻し integration URI も戻してエラー終了する。自動停止の保証がない状態で起動したままにしない |
| public IP を知られ、API Gateway を経由せず直接叩かれる | integration で Host ヘッダを host 名へ上書きし、`config.hosts` にその host 名だけを許可する。IP 直アクセスは `Blocked hosts` で弾かれる |
| 停止処理が失敗し、integration URI が解放済みの IP を指し続ける | 停止処理で URI を到達しない値へ戻すことを、task 停止と同じ処理単位に含める。どちらの操作も冪等であるため、停止 script を再実行すれば揃う |
| 動作確認環境の migration と mutation が開発 DB へ届く | 実データで確認できる価値と引き換えに受け入れる。`main` へ入る直前のコードだけを載せる運用でリスクを抑える |
| API Gateway から task への転送が VPC 外を通る | ALB でないと消せず、ALB は停止中も課金される。動作確認環境として受け入れる |
| URL を知る第三者が GraphQL endpoint へ到達できる | 認証は devise + devise-jwt のみとし、追加の保護は設けない。本番 backend も同じ endpoint を公開しており、review 環境だけを保護する理由がない。受け入れるのは、`main` へ未マージのコードが動くため未検証の脆弱性が一時的に露出しうることで、窓は最大 30 分である |

---

## テスト方針

| 検証すること | 手段 |
| --- | --- |
| 構成に時間課金の resource が無い | `terraform plan` の出力に ALB / RDS / NAT Gateway / Elastic IP / Secrets Manager が現れないことを確認する |
| 起動 script で到達できるようになる | 起動 script を実行し、`https://review-backend-nanitabe.kibotsu.com/graphql` へ `POST` して応答を得る |
| PC 以外の端末から到達できる | スマホから同じ URL を叩く。これが今回の主目的であり、代替手段で確認したことにしない |
| IP 直アクセスが弾かれる | task の public IP へ直接 `POST` し、403 が返ることを確認する |
| 停止 script で到達できなくなる | 停止 script を実行し、同じ URL が応答しなくなることを確認する |
| 自動停止の発火と停止処理 | `REVIEW_BACKEND_AUTO_STOP_MINUTES=1` で起動し、schedule の発火によって `desired_count` が 0 になり integration URI が停止側へ戻ることを確認する |
| 自動停止までの時間が 30 分である | `REVIEW_BACKEND_AUTO_STOP_MINUTES` を既定のまま起動し、作られた schedule の実行予定時刻が起動時刻の 30 分後であることを確認する。発火を待つ必要はない |
| migration が流れる | 起動時の log に migration の実行が現れることを CloudWatch Logs で確認する |
| 止め忘れ時に通知が届く | alarm の `evaluation_periods` を一時的に 1 へ変えて apply し、停止 schedule を作らずに `desired_count` を 1 にして、alarm が `ALARM` になり email が届くことを確認する。確認後に定義値へ戻して apply する |
| 通知までの時間が 45 分である | `evaluation_periods` が 9、`period` が 300 秒であることを Terraform の定義と `describe-alarms` の出力で確認する。発報を待つ必要はない |

30 分の自動停止は待ち時間が発生するが、要件の中心であるため 1 回は実測する。schedule の実行時刻を短く設定して代用すると、実際に使う 30 分の設定を検証しないまま完成にすることになる。

---

## （付録）前提とする既存仕様

- **backend の本番 deploy**: `.github/workflows/backend-deploy.yml`。`main` への PR merge 時に n8n の webhook を叩くだけで、CI から直接 deploy する経路は存在しない。コメントに「ciサーバに設定をめちゃめちゃ書き込ませたくないから、git pull だけやらせる」とあり、実体は server 上での git pull 運用である。
- **本番 backend と開発 DB の実体**: どちらも `ap-northeast-1` の同一 EC2 上にある。`BACKEND_PROD_HOST` と `DB_HOST` が同じ host へ解決されることを確認した。`DB_PORT` は 33307 で、開発マシンからこの port へ TCP 接続できる。つまり本番 backend は AWS 上で動いており、Terraform の管理下にないだけである。ローカルの `docker compose` の backend も、この EC2 上の MySQL へ接続している（`docker-compose.yml` に DB service は無く、`env_file` で接続情報を渡している）。
- **backend の AWS 資産のうち Terraform 管理下にあるもの**: 存在しない。`infrastructure/terraform/envs/prod/main.tf` が呼ぶ module は `state_in_s3` と `frontend` だけ。repository 全体で `ECS` / `Fargate` への言及は 0 件（`*.md` / `*.tf` / `*.yml` を対象に確認）。上記 EC2 は Terraform の管理外で稼働している。
- **AWS account の既存構成**（`ap-northeast-1`、AWS CLI で実測）:
  - VPC は default の `vpc-d69c93b1`（`172.31.0.0/16`）only。subnet は 3 つ（`ap-northeast-1a` / `1c` / `1d`）で、いずれも `MapPublicIpOnLaunch=true` の public subnet。private subnet と NAT Gateway は存在しない。
  - EC2 は `various_function_machine`（`t2.small`、`ap-northeast-1a`）が 1 台稼働。これが本番 backend と MySQL を兼ねる。
  - security group `mysql` は `33307/tcp` の inbound を `0.0.0.0/0` へ開放している。したがって接続元 IP が起動ごとに変わっても DB へ到達できる。同一 VPC 内から `DB_HOST` の public DNS 名を解決した場合は private IP が返るため、経路は VPC 内に閉じる。
  - ECS cluster は `sample_todo_list_cluster` が別プロジェクト用に存在する。nanitabe 用の cluster は無い。
  - ECR repository は `nanitabe-front/next-js-on-lambda/{prod,verify-infra}` があり、backend 用は無い。
  - Route53 hosted zone は `kibotsu.com` のみ。frontend の custom domain `nanitabe.kibotsu.com` がこの zone に属する。
- **frontend の AWS 構成**: `frontend/terraform/envs/prod/main.tf`。`ecr` → `lambda`（container image）→ `api_gateway` → `cloudfront`（custom domain `nanitabe.${route53_name}`）、assets 用 `s3`、`cicd`（CodePipeline / CodeBuild、`branch` 変数で対象 branch を指定）。`stage = "prod"` を local で持ち各 module へ渡す。
- **Terraform の構成**: `infrastructure/terraform/envs/prod/main.tf` が root。`terraform` backend は S3 + DynamoDB lock で、`init_terraform.sh` が `-backend-config` で bucket / key（`prod/terraform.tfstate`）を渡す。`apply_terraform.sh` は `/etc/opt/app_setting_files/nanitabe/.env` を読んで `TF_VAR_*` へ export してから `terraform apply` する。secret は repository に無い。
- **`frontend/terraform/envs/review/`**: `.gitkeep` だけの空 directory が存在する。review 環境の器が意図として置かれている。
- **backend の DB**: `backend/config/database.yml`。development / production とも `mysql2` で、接続先は `DB_NAME` / `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASS` の環境変数。test だけ sqlite3。
- **backend の起動**: `backend/entrypoint.sh` は開発用。`bundle install` → `rails s -p 18101` → `rails db:migrate RAILS_ENV=test` → `tail -f log/development.log` で常駐する。`puma.rb` の port は `ENV["PORT"]`（default 3000）だが、entrypoint は `-p 18101` で上書きする。container を ECS で動かす場合、この entrypoint をそのまま使うと開発用の挙動（`bundle install`、test DB migrate、tail 常駐）が混ざる。
- **backend の Dockerfile**: `ruby:3.3.8` ベース、`bundle install` のみ。application code は COPY せず、`docker-compose.yml` の volume mount 前提。ECS では image に code が含まれている必要があるため、この Dockerfile はそのままでは使えない。
- **backend の公開 endpoint**: `POST /graphql` のみ（`/graphiql` は development 限定、`admin/` 配下に管理画面の resources がある）。
- **CORS と host 制限**: `backend/config/application.rb`。CORS は `origins "*"` で全許可。一方 `config.hosts` は `FRONTEND_PROD_HOST`、`nanitabe_back`、`BACKEND_PROD_HOST` を許可 host へ追加する。確認環境の host 名をここへ通さないと `Blocked hosts` になる。
- **認証**: `devise` + `devise-jwt` + `graphql_devise`。動作確認には user レコードが要る。
- **seed**: `backend/db/seeds.rb` は `DishEffortLevel` のマスタ 14 件のみ。user や献立データは作らない。
- **schema**: `backend/db/schema.rb` に 14 テーブル。
- **branch / PR 運用**: `feature-<issue番号>` branch から `main` へ PR（`.agents/skills/tumeda-dev-plugin-context.md`）。現在の作業 branch は `feature-278`。
- **開発規約**: Rails の command は container 内で実行する（`backend/docs/ai_guideline/development_standard/docker.md`）。test は container 内の RSpec、test-first（同 `testing.md`）。
- **参照元 steering の branch 運用**（`<参照元 repository>`、private のため要点のみ）:
  - 検証用に別 app を作らず、正本の app に常設の確認用 branch を一本足す。build 設定と環境変数が本番と乖離しないことを構造で担保する。
  - 確認対象 branch を `main` へ rebase してから `git push -f origin <確認対象>:<確認用 branch>` で載せる。確認用 branch に何が載っているかは保証せず、確認する人が開く前に必ず自分の確認対象を force push する。
  - 確認完了後の後始末（branch を戻す等）を運用へ含めない。規約が守られなかったときに、より悪い状態を作らないため。
  - 「確認環境に閉じる操作」を、本番の deploy・本番 URL・共有 resource・既存 state のいずれにも影響しない操作として定義し、閉じる範囲では AI agent が都度確認なしで実行してよいとした。閉じるかどうかは対象 resource が本番と共有かで決まり、名前が確認用かでは決まらない。
  - `terraform apply` の前に必ず `plan` を実行し、差分が定義した条件を満たさなければ停止する扱いは、閉じる範囲でも緩めない。

---

## （付録）変更の実行区分

### task-design内で対象成果物へ適用済み

| 対象 | 反映内容 | validation結果 | 参照するdesign section |
| --- | --- | --- | --- |
| `infrastructure/README.md` | 新規作成。state の分かれ方、apply script の使い方、`desired_count = 0` が定義の正であること、実行時の値を Terraform が管理しないことを記載 | `document-review` を pass。`review_environment.md` への相対 link が解決することを確認 | [documentationによって成立する知識体系](#documentationによって成立する知識体系) |
| `backend/docs/ai_guideline/development_standard/review_environment.md` | 新規作成。review 環境の位置づけ、使い方、規約、開発 DB の共有、止め忘れ時の通知、閉じる操作の定義、誤適用を記載 | `document-review` を pass。`infrastructure/README.md` への相対 link が解決することを確認 | [documentationによって成立する知識体系](#documentationによって成立する知識体系) |
| `AGENTS.md` | `infrastructure/` の行を追記し、`infrastructure/README.md` を入口にする | 既存の `backend/` `frontend/` と同じ形式であることを確認 | [documentationによって成立する知識体系](#documentationによって成立する知識体系) |
| `backend/docs/ai_guideline/development_standard/README.md` | `review_environment.md` の行を追記する | 既存 4 行と同じ `@file` 形式であることを確認 | [documentationによって成立する知識体系](#documentationによって成立する知識体系) |

これらを execution plan 対象へ載せないのは、本番 application coding でも段階実行を要する作業でもなく、合意済みの design から一意に書けるためである。適用後に記述と実態が一致するかを照合する作業だけは、実態が適用の結果で決まるため execution plan 対象に残す。

### task-design内の対象成果物反映待ち

なし

### execution plan対象

| 対象 | 掲載理由 | 参照するdesign section |
| --- | --- | --- |
| `backend/buildOnEcs/Dockerfile`、`backend/buildOnEcs/entrypoint.sh` | 本番成果物として利用者へ届く container image を定義する。ECS 上の runtime behavior を決める | [runtime・設定・環境構築](#runtime設定環境構築) |
| `backend/terraform/values/`、`backend/terraform/modules/{ecr,ecs,apigateway,cicd}/`、`backend/terraform/envs/review/` | infrastructure component の新規構築 | [runtime・設定・環境構築](#runtime設定環境構築) |
| `infrastructure/terraform/envs/review/`（`main.tf`、`init_terraform.sh`、`apply_terraform.sh`） | 同上。review 用 state の root を新設する | [runtime・設定・環境構築](#runtime設定環境構築) |
| `scripts/review_backend/start.sh`、`scripts/review_backend/stop.sh` | 環境の起動・停止という runtime behavior を担う。schedule 作成の失敗時に停止側へ戻す分岐を含む | [workflow](#workflow) |
| `review` branch の作成と初回 push | 外部（GitHub）へ影響する操作であり、CodePipeline の起動を伴う | [workflow](#workflow) |
| `terraform init` と `terraform plan` / `terraform apply` | AWS 上の resource を実際に作る。plan の差分確認を中間 checkpoint として挟む | [runtime・設定・環境構築](#runtime設定環境構築) |
| SNS topic の email 購読確認 | 購読確認メールの承認は Terraform の外で行う手作業であり、alarm が通知に到達するために必要 | [runtime・設定・環境構築](#runtime設定環境構築) |
| 適用後の動作確認（起動、スマホからの到達、IP 直アクセスの遮断、停止、30 分の自動停止） | 適用の後にしか実行できない。30 分の待ち時間を含む | [テスト方針](#テスト方針) |
| 止め忘れ検知の実測（alarm の `evaluation_periods` を一時的に短くし、停止 schedule を作らずに動かして通知が届くことを確認する） | 適用の後にしか実行できない。自動停止が働かない状況を意図的に作るため、通常の起動 script を使わない独立した手順になる | [テスト方針](#テスト方針) |
| 運用 document の記述と実態の照合 | 記述が実際の script の引数・出力・構成と一致するかは、適用の後にしか確認できない | [documentationによって成立する知識体系](#documentationによって成立する知識体系) |
