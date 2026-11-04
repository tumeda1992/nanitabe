# review 環境（動作確認環境）

`main` へ入れる前の変更を、開発者の PC 以外の端末から、画面の操作と API の呼び出しで確認するための環境。frontend（Amplify）と backend（ECS）から成り、同じ git の `review` branch を両方が監視する。

## 何ができて、何ができないか

できること。

- ECS 上で production 設定の Rails を起動し、
  `https://review-backend-nanitabe.<hosted zone>/graphql` へ `POST` を叩ける。
  `<hosted zone>` は `.env` の `ROUTE53_HOSTZONE_NAME` が指す domain。terraform 側も同じ変数から組み立てる。
- frontend の画面 `https://review-nanitabe.<hosted zone>` を PC 以外の端末で開き、ログイン、カレンダーの表示、献立の登録などを画面から操作できる。frontend は backend の review 環境を向き、本番の backend は向かない。
- スマホ実機など、ローカルの `docker compose` へ到達できない端末から確認できる。これがこの環境を作った理由である。

できないこと。

- backend が停止している間の API 呼び出しと、データを変える画面操作。frontend の画面は常に開けるが、API が応答しない（後述）。
- 本番の backend を向いた確認。
- `admin/` 配下の管理画面は開けない。image で `assets:precompile` を行っていないため。
- `/graphiql` は開けない。`RAILS_ENV=production` では mount されない。

## 開発 DB を共有している

この環境（frontend 経由の操作を含む）は、ローカルの `docker compose` が使っているのと同じ DB・同じ database へ接続する。専用の DB を持たない。

そのため次の 2 つが起きる。どちらも承知のうえで、実データのまま確認できることを取っている。

- 起動時に `rails db:migrate` が走る。`review` へ載せたコードに未適用の migration が含まれていれば、開発 DB のスキーマがその時点で変わる。
- この環境からの mutation は、画面からの操作を含めて開発 DB のデータを変える。ローカルでの確認結果に影響する。本番のデータは変わらない。

## 使い方

### 1. 確認対象を `review` branch へ載せる

```sh
git switch <確認対象の branch>
git rebase main
git push -f origin <確認対象の branch>:review
```

`main` へ rebase してから載せる。`main` の変更と組み合わせた挙動を確認するため。

frontend と backend は同じ `review` branch を監視するため、片方だけ古いまま確かめる事故は起きない。frontend だけの変更を載せても、backend は `main` の上に frontend の変更が乗った commit を build するため、挙動は `main` と同じになる。

### 2. build の成否を確認する

push を契機に、backend は CodePipeline が起動し、CodeBuild が image を作って ECR へ push する。frontend は Amplify の review app が build して配信する。

backend の build が失敗すると ECR には前回の image が残る。**成否を確認せずに起動すると、確認したい内容ではなく前回の内容が動く。** frontend も同様に、失敗すると前回の build が配信され続ける。

```sh
# backend
aws codepipeline list-pipeline-executions --pipeline-name nanitabe-back_codepipeline_review
# frontend（app id は aws amplify list-apps で nanitabe-front-review の id を引く）
aws amplify list-jobs --app-id <review app id> --branch-name review
```

frontend の job が起動しなかったときは `aws amplify start-job --app-id <review app id> --branch-name review --job-type RELEASE` で起動する。

### 3. 起動する

```sh
./scripts/review_backend/start.sh
```

script が行うこと。

1. ECS service の `desired_count` を 1 にする
2. task が RUNNING になるまで待ち、public IP を取得する
3. API Gateway の integration URI をその IP へ向ける
4. 30 分後の自動停止を EventBridge Scheduler へ登録する
5. 到達 URL と自動停止の予定時刻を出力する

自動停止までの時間は `REVIEW_BACKEND_AUTO_STOP_MINUTES` で上書きできる。既定は 30。

schedule の登録に失敗した場合、script は起動を取り消して終了する。自動停止の保証がないまま起動したままにしないため。

### 4. 確認する

画面から確かめるときは、`https://review-nanitabe.<hosted zone>` を PC 以外の端末で開く。認証は通常どおりで、開発 DB の既存アカウントがそのまま使える。frontend は常に配信していて、起動・停止の操作を持たない。

API だけを確かめるときは、出力された URL へ `POST /graphql` する。認証は devise + JWT。

### 5. 停止する

```sh
./scripts/review_backend/stop.sh
```

停止操作をしなくても、起動から 30 分で自動的に止まる。

### 停止中に URL を叩くとどうなるか

frontend の画面は開けるが、API が応答しないため、ログインやデータの取得・登録はできない。これも壊れているのではない。backend を `start.sh` で起動してから確かめる。

backend の URL を直接叩くと HTTP 500 が返る。**これは壊れているのではなく、停止中の正常な状態である。**

API Gateway と証明書と DNS レコードは常設なので、URL 自体は生きている。停止すると転送先が到達しない address へ戻るため、API Gateway が backend へ届かず 500 になる。

停止中に前の起動の IP を指したままにしない設計にしているのは、その IP が AWS から別の利用者へ再割当されるためである。指したままだと、URL を叩いた request が無関係の第三者のホストへ届く。

## 規約

### `review` に何が載っているかは保証しない

`review` branch は共有の置き場であり、誰の何が載っているかを保証しない。**確認する人は、開く前に必ず自分の確認対象を force push する。**

### 確認が終わっても後始末をしない

`review` branch を元に戻す、といった後始末を運用に含めない。次に確認する人の force push で上書きされる。

後始末を運用へ入れると、それが守られなかったときに「前の人の後始末漏れ」という状態が生まれる。上書きを前提にすれば、その状態自体が存在しない。

### 止め忘れると通知が届く

自動停止が働かず task が動き続けた場合、45 分で CloudWatch alarm から通知が届く。

**alarm は task を止めない。** 通知を受け取った人が `stop.sh` を実行する。

## review 環境に閉じる操作

AI agent へ作業を依頼するときの線引き。

review 環境に閉じる操作を、次のいずれにも影響が及ばない操作と定義する。

- 本番 backend とその host
- 開発 DB のスキーマとデータ
- prod の Terraform state と、そこにある resource
- `/etc/opt/app_setting_files/nanitabe/.env` の内容と SSM parameter の値

該当するのは次であり、操作ごとの事前確認なしに実行してよい。失敗しても `stop.sh` と再実行で回復でき、影響が review 環境の外へ出ないため。

- `review` branch への force push
- `start.sh` と `stop.sh` の実行
- 作業 branch から review の apply workflow（`terraform-apply-review.yml`）を手動起動すること（`gh workflow run terraform-apply-review.yml --ref <branch>`）。plan に destroy が 1 件でもあれば workflow が apply せず失敗する

### 閉じる範囲でも緩めないこと

- review の apply は手元から行わず、apply workflow の手動起動で行う。
  手動起動の apply は plan を保存し、destroy を含む変更が 1 件でもあれば apply せず失敗する（replace を含む）。
  満たさない差分で workflow が失敗したら、再実行せず停止して報告する。
  plan / apply の全文は S3 にあり、Actions の log には出ない（`infrastructure/README.md`「適用のしかた」）。
- destroy を含む差分を閉じる操作から外すのは、destroy が「失敗しても再実行で回復できる」という前提を崩すためである。
  add と change は apply し直せば戻るが、destroy で消したものは apply し直しても戻らないことがある。
  - ECR の repository: 中の image も消える。CodePipeline で build し直すまで起動できない。
  - CloudWatch の log group: application のログが消える（`infrastructure/README.md`「構成上の前提」のログの lifecycle）。
  - ACM 証明書と Route53 の record: 作り直すと証明書の検証を待つ間、review の URL が使えない。
  - IAM、security group、API Gateway などの設定だけを持つ resource は、apply し直せば同じものが戻る。
  変更できない属性の変更による作り直し（replace）も削除を含むため、同じく止まる。
  判定は resource の種類を区別せず一律に止める。種類の一覧を持つと resource を足すたびに見直しが要り、
  止まったときは plan を読んで判断すればよく、往復が増えるのはまれだからである。
- secret を log、成果物、chat へ出さない。
- `main` への merge と PR 操作は緩和の対象外とする。

### 閉じているように見えて該当しないもの

- `review` へ載せたコードに含まれる migration。起動時に開発 DB のスキーマを変えるため閉じない。
- prod state に対する apply。review 環境のための変更であっても閉じない。
- SSM parameter の値の変更。値の出所が `.env` であり、開発環境と共有しているため閉じない。値を変える経路は `scripts/review_backend/put_ssm_parameters.sh`（`.env` から読み、AWS CLI の設定の認証情報で書く）で、これらの parameter は Terraform の管理外である。

閉じるかどうかは**対象の resource と state で決まる**。`review` という名前が付いているかでは決まらない。

## 誤適用

- `review` を「`main` と同じものが載っている場所」として開くこと。何が載っているかは保証しない。
- backend を起動せずに frontend の画面を開いて、壊れていると判断すること。
- 画面の操作が本番のデータに入ると考えること。向き先は backend の review 環境で、データは開発 DB である。
- `admin/` 配下の管理画面を開こうとすること。image で `assets:precompile` を行っていないため開けない。

## インフラ側の制約

review の apply（`main` への merge、または手動起動）が走ると、起動中の review 環境が停止する。
ECS service の `desired_count = 0` が Terraform 定義の正であるため。
詳細と理由は [`infrastructure/README.md`](../../../../infrastructure/README.md) にある。
