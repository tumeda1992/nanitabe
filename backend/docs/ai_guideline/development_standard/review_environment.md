# review 環境（backend の動作確認環境）

`main` へ入れる前の backend を、開発者の PC 以外の端末から叩いて確認するための環境。

## 何ができて、何ができないか

できること。

- ECS 上で production 設定の Rails を起動し、
  `https://review-backend-nanitabe.<hosted zone>/graphql` へ `POST` を叩ける。
  `<hosted zone>` は `.env` の `ROUTE53_HOSTZONE_NAME` が指す domain。terraform 側も同じ変数から組み立てる。
- スマホ実機など、ローカルの `docker compose` へ到達できない端末から確認できる。これがこの環境を作った理由である。

できないこと。

- frontend とは繋がない。画面から操作する確認はできない。
- `admin/` 配下の管理画面は開けない。image で `assets:precompile` を行っていないため。
- `/graphiql` は開けない。`RAILS_ENV=production` では mount されない。

## 開発 DB を共有している

この環境は、ローカルの `docker compose` が使っているのと同じ DB・同じ database へ接続する。専用の DB を持たない。

そのため次の 2 つが起きる。どちらも承知のうえで、実データのまま確認できることを取っている。

- 起動時に `rails db:migrate` が走る。`review` へ載せたコードに未適用の migration が含まれていれば、開発 DB のスキーマがその時点で変わる。
- この環境からの mutation は開発 DB のデータを変える。ローカルでの確認結果に影響する。

## 使い方

### 1. 確認対象を `review` branch へ載せる

```sh
git switch <確認対象の branch>
git rebase main
git push -f origin <確認対象の branch>:review
```

`main` へ rebase してから載せる。`main` の変更と組み合わせた挙動を確認するため。

### 2. build の成否を確認する

push を契機に CodePipeline が起動し、CodeBuild が image を作って ECR へ push する。

build が失敗すると ECR には前回の image が残る。**成否を確認せずに起動すると、確認したい内容ではなく前回の内容が動く。**

```sh
aws codepipeline list-pipeline-executions --pipeline-name nanitabe-back_codepipeline_review
```

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

出力された URL へ `POST /graphql` する。認証は通常どおり devise + JWT で、開発 DB の既存アカウントがそのまま使える。

### 5. 停止する

```sh
./scripts/review_backend/stop.sh
```

停止操作をしなくても、起動から 30 分で自動的に止まる。

### 停止中に URL を叩くとどうなるか

HTTP 500 が返る。**これは壊れているのではなく、停止中の正常な状態である。**

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
- review state に対する `terraform plan`
- 差分が review state 内の resource の追加・変更だけで、destroy を含まない `terraform apply`

### 閉じる範囲でも緩めないこと

- `terraform apply` の前に必ず `terraform plan` を実行し、差分が上の条件を満たすことを確認する。
  満たさない差分が 1 件でもあれば apply せず停止して報告する。
  この確認は `infrastructure/terraform/envs/review/apply_terraform.sh` が行う。
  同 script は plan を保存し、destroy を含む変更が 1 件でもあれば apply せず異常終了する。
  `terraform apply` を直接実行せず、この script を使う。
- secret を log、成果物、chat へ出さない。
- `main` への merge と PR 操作は緩和の対象外とする。

### 閉じているように見えて該当しないもの

- `review` へ載せたコードに含まれる migration。起動時に開発 DB のスキーマを変えるため閉じない。
- prod state に対する apply。review 環境のための変更であっても閉じない。
- SSM parameter の値の変更。値の出所が `.env` であり、開発環境と共有しているため閉じない。

閉じるかどうかは**対象の resource と state で決まる**。`review` という名前が付いているかでは決まらない。

## 誤適用

- `review` を「`main` と同じものが載っている場所」として開くこと。何が載っているかは保証しない。
- frontend と繋いだ end-to-end の確認に使おうとすること。この環境は backend API 単体までを対象にしている。
- `admin/` 配下の管理画面を開こうとすること。image で `assets:precompile` を行っていないため開けない。

## インフラ側の制約

`terraform apply` を実行すると、起動中の review 環境が停止する。
ECS service の `desired_count = 0` が Terraform 定義の正であるため。
詳細と理由は [`infrastructure/README.md`](../../../../infrastructure/README.md) にある。
