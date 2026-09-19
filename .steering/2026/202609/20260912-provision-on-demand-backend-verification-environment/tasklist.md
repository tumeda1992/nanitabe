## Phase 1: `review` branch への push で ECS 用 image が ECR にできる

> ⚠️ この phase は AWS resource の作成と GitHub への push を含む。どちらもこの作業を破棄しても残る。

### DoD（完了条件）

- `review` branch へ push すると CodePipeline が起動し、ECR repository `nanitabe-back/rails-on-ecs/review` に image が push される。

### Tasks

- [x] `backend/buildOnEcs/Dockerfile` と `backend/buildOnEcs/entrypoint.sh` を新規作成する
- [x] `backend/terraform/values/values.tf` を新規作成する
- [x] `backend/terraform/modules/ecr/` を新規作成する
- [x] `backend/terraform/modules/cicd/` を新規作成する
- [x] `backend/terraform/envs/review/main.tf` を新規作成する（この phase では ecr と cicd だけを呼ぶ）
- [x] `infrastructure/terraform/envs/review/` を新規作成する
- [x] `terraform init` と `terraform plan` を実行し、差分を確認する
- [x] `terraform apply` を実行する
  > 結果: 10 added, 0 changed, 0 destroyed。作成resource: ECR `nanitabe-back/rails-on-ecs/review` + lifecycle policy、CodeBuild `nanitabe-back_build_review`、CodePipeline `nanitabe-back_codepipeline_review`、および付随するIAM role/policy。
  > apply実行方法をpermission classifierのblockを受けて `infrastructure/terraform/envs/review/apply_terraform.sh` へplan保存とdestroy判定を埋め込む形へ変更（論点1、implementation_review.md参照）。`terraform state list` で10resourceの存在を確認済み。
- [x] Phase 1 の成果物を commit する
  > 5 commit に分割: (1) design/運用document4件+task-design-discussion.md+implementation_review.md、(2) backend/buildOnEcs/、(3) Phase1のTerraform一式+.gitignoreのtfplan、(4) .claude/settings.jsonのpermission追加、(5) tumeda-dev-plugin-context.mdの公開範囲追記。すべてlocal commitのみ、originへは未push。
- [x] `review` branch を作成して初回 push する
  > `git push -f origin feature-278:review` 実行。GitHub側実体 `tumeda1992/nanitabe` へ `review` branch を new branch として作成済み。
- [x] build が通り ECR に image ができることを確認する
  > `aws codepipeline get-pipeline-state --name nanitabe-back_codepipeline_review` で Source/Build ともに `Succeeded` を確認。`aws ecr list-images --repository-name nanitabe-back/rails-on-ecs/review` で `imageTag: latest` の image 1件を確認。
- [x] ここで作業を停止し、結果をユーザーに確認する。次 phase へは進まない
  > `infrastructure/README.md` の state key（`review/terraform.tfstate`）と apply script（plan保存→destroy判定→apply）の記述を実際の構成と照合し、ずれなし。

### 各task詳細

#### `backend/buildOnEcs/Dockerfile` と `backend/buildOnEcs/entrypoint.sh` を新規作成する

既存の `backend/Dockerfile` は変更しない。`frontend/buildOnLambda/Dockerfile` が通常の Dockerfile と別に存在するのと同じ形にする。

Dockerfile は `ruby:3.3.8` をベースにし、`Gemfile` と `Gemfile.lock` を COPY して `bundle install` を実行し、その後 application code を COPY する。開発用 Dockerfile と違い、code を image に含める。

entrypoint.sh は次の内容にする。

```sh
#!/bin/bash
set -e

bundle exec rails db:migrate

exec bundle exec puma -b "tcp://0.0.0.0:${PORT}"
```

`set -e` は migration 失敗時に puma を起動させないために要る。`exec` は ECS の SIGTERM を puma へ届けるために要る。`-b` に `0.0.0.0` を直接渡すと `Invalid URI` で異常終了するため、`tcp://` を含む URI 形式にする（`design.md` の付録に実測を記載）。

開発用 `entrypoint.sh` が行う `bundle install`、test 用 DB の migrate、`tail -f log/development.log` は入れない。

#### `backend/terraform/values/values.tf` を新規作成する

`frontend/terraform/values/values.tf` と同じ形で `appname` を output する。値は `nanitabe-back`。

#### `backend/terraform/modules/ecr/` を新規作成する

`frontend/terraform/modules/ecr/main.tf` を参照する。repository 名は `nanitabe-back/rails-on-ecs/${var.stage}` とし、`stage` は呼び出し側から受け取る。

lifecycle policy を設定し、最新 1 世代を残して古い image を削除する。停止中の保存料を抑えるため。

#### `backend/terraform/modules/cicd/` を新規作成する

`frontend/terraform/modules/cicd/` と同じく `codebuild` と `codepipeline` の 2 階層にする。

CodeBuild は `type = "ARM_CONTAINER"` にする。task definition の architecture を `ARM64` にするため、build 環境も合わせる。buildspec は `backend/buildOnEcs/Dockerfile` を使って image を build し、ECR へ push する内容にする。frontend の buildspec にある Lambda 更新と CloudFront invalidation に当たる処理は入れない。

CodePipeline は `pipeline_type = "V2"` を指定する。V1 は active pipeline に月 $1 の固定課金があり、`design.md` の要件に抵触するため。Source は既存 prod と同じ `CodeStarSourceConnection` を使い、`FullRepositoryId` は `tumeda1992/nanitabe`、`BranchName` は `review` とする。

CodeBuild role と CodePipeline role の権限は `design.md` の IAM role 表に従う。

#### `backend/terraform/envs/review/main.tf` を新規作成する

`frontend/terraform/envs/prod/main.tf` と同じ形で、`stage` を local に `review` として持ち、各 module へ配る。この phase では `ecr` と `cicd` だけを呼ぶ。`ecs` と `apigateway` は Phase 2 で追加する。

#### `infrastructure/terraform/envs/review/` を新規作成する

`main.tf`、`init_terraform.sh`、`apply_terraform.sh` を置く。既存の `infrastructure/terraform/envs/prod/` と同型にする。

`init_terraform.sh` の `TF_ENV` は `review` にする。state key が `review/terraform.tfstate` になる。

`apply_terraform.sh` は既存 prod と同じく `.env` から `TF_VAR_*` を export する。この phase で必要なのは `bucket_name`、`dynamodb_table_name`、`aws_account_id`、`codebuild_artifact_s3_bucket`、`aws_code_connection_id_to_github`。

`main.tf` は `backend/terraform/envs/review` を module として呼ぶ。

#### `terraform init` と `terraform plan` を実行し、差分を確認する

`infrastructure/terraform/envs/review/` で実行する。差分が review state 内の resource の追加だけであり、destroy が 0 件であることを確認する。条件を満たさない差分が 1 件でもあれば apply せず停止して報告する。

#### `terraform apply` を実行する

plan で確認した差分だけが適用されることを確認したうえで実行する。

#### Phase 1 の成果物を commit する

`review` branch へ push する内容を確定させるため、この時点で commit する。意味単位で分ける。

1. 運用 document 4 件（`infrastructure/README.md`、`backend/docs/ai_guideline/development_standard/review_environment.md`、`AGENTS.md`、`backend/docs/ai_guideline/development_standard/README.md`）。task-design 内で作成済みであり、実装より前に確定した合意なので先頭へ置く。
2. ECS 用の image 定義（`backend/buildOnEcs/`）。
3. Phase 1 の Terraform（`backend/terraform/` の values・ecr・cicd・envs/review、`infrastructure/terraform/envs/review/`）と `.gitignore` の `**/tfplan*` 追加。

`.steering/` 配下の `design.md`、`task-design-discussion.md`、`implementation_review.md` は 1 と同じ commit か、その前の commit へ入れる。合意が実装より後に記録された履歴にしないため。

`.claude/settings.json` の permission 追加と `.agents/skills/tumeda-dev-plugin-context.md` の公開範囲追記は、実装とは別の意味単位なので分けて commit する。

この commit は local に留まる。`feature-278` を `origin` へ push するのは動作確認が完了した後である。

#### `review` branch を作成して初回 push する

`git push -f origin feature-278:review` を実行する。

この push は動作確認の手段であり、成果物を `main` へ届ける操作ではない。`review` branch は使い捨てで、次に確認する人の force push で上書きされる。`design.md` の「実行者の線引き」でも review branch への force push を閉じる操作としている。

#### build が通り ECR に image ができることを確認する

CodePipeline の実行状態を確認し、Build stage が成功することを見る。失敗した場合は CodeBuild の log から原因を特定して修正し、再度 push する。

成功後、`aws ecr list-images --repository-name nanitabe-back/rails-on-ecs/review` で image が存在することを確認する。

test は作成しない。Terraform 定義と buildspec に対する自動 test を持つ仕組みが repository に無いため。`terraform plan` の差分確認と、実際に image ができることの実測をもって代える。

#### ここで作業を停止し、結果をユーザーに確認する。次 phase へは進まない

AWS 上に ECR repository、CodeBuild project、CodePipeline が作られたこと、GitHub に `review` branch ができたことをユーザーへ報告する。どちらもこの作業を破棄しても残るため、実際に作られたことをユーザーが確認してから次へ進む。

あわせて、`infrastructure/README.md` に書いた state key と apply script の記述が、実際に作った構成と合っているかを照合する。ずれていた場合はその場で document を書き換えず、`design.md` へ戻す。

---

## Phase 2: ECS service と API Gateway を立て、起動 script で到達できるようにする

> ⚠️ この phase は AWS resource の作成と、起動時の `rails db:migrate` による開発 DB への migration 適用を含む。どちらもこの作業を破棄しても残る。

### DoD（完了条件）

- 起動 script を実行すると `https://review-backend-nanitabe.kibotsu.com/graphql` へ `POST` して応答が返る。
- task の public IP へ直接 `POST` すると 403 が返る。
- 停止 script を実行すると `https://review-backend-nanitabe.kibotsu.com/graphql` が応答しなくなる。

### Tasks

- [x] `backend/terraform/modules/ecs/` を新規作成する
- [x] `backend/terraform/modules/apigateway/` を新規作成する
- [x] SSM Parameter Store の parameter を Terraform 定義へ追加する
- [x] CloudWatch alarm と SNS topic を Terraform 定義へ追加する
- [x] `backend/terraform/envs/review/main.tf` へ `ecs` と `apigateway` の呼び出しを追加する
  > `scheduler_role` module（EventBridge Schedulerが起動script経由でECS/API Gatewayを操作するためのrole）も同時に追加した。design.md「EventBridge Schedulerが AWS API を直接呼ぶためのroleはTerraformで作る」に対応。
- [x] `terraform plan` を実行し、差分を確認する
  > dry run（`TF_VAR_review_backend_alarm_email`に暫定値を渡し確認のみ、applyせず破棄）: **31 to add, 0 to change, 0 to destroy**。追加はecs/apigateway/ssm/alarm/scheduler_role配下のみで、Phase1のECR・CodeBuild・CodePipelineにchangeなし。
- [x] `terraform apply` を実行する
  > `infrastructure/terraform/envs/review/apply_terraform.sh` で実行。1回目、`aws_security_group.task`の`description`に日本語（非ASCII）が含まれ`InvalidParameterValue`で失敗（AWS SGのdescriptionはASCIIのみ）。`backend/terraform/modules/ecs/main.tf`のdescriptionを英語へ修正し、コメントとして元の説明はソース上に残した。2回目のapplyで残り4resource（security group、ECS service、scheduler_roleのpolicy、alarm）を含め全46resourceが作成完了（`terraform state list`で確認）。destroyは0件のまま。
- [x] SNS topic の email 購読を確認する
  > `aws sns list-subscriptions-by-topic`で確認。当初`SubscriptionArn: "PendingConfirmation"`だったためユーザーへ確認を依頼して停止。ユーザーが確認メールのlinkを開いた後、`SubscriptionArn: "arn:aws:sns:ap-northeast-1:241875560804:nanitabe-back_review_alarm:f2c74ef5-fb42-40ed-b1e0-d9e9c1f1f946"`（`PendingConfirmation`ではない）を独立に確認済み。
- [x] `scripts/review_backend/start.sh` と `scripts/review_backend/stop.sh` を新規作成する
  > jqでEventBridge Schedulerのtarget JSONを組み立て、`REVIEW_BACKEND_AUTO_STOP_MINUTES`（既定30）で自動停止時刻を上書き可能にした。schedule作成失敗時はdesired_countとintegration URIを停止側へ戻すrollback関数を実装。
- [x] 起動 script を実行し、URL が応答することを確認する
  > `start.sh`実行 → `https://review-backend-nanitabe.kibotsu.com/graphql`へ`{"query":"{ __typename }"}`をPOSTし、`AUTHENTICATION_ERROR`のJSON（HTTP 200）を確認。GraphQL層まで到達。
  > CloudWatch Logsで`[entrypoint] rails db:migrate を開始します`/`が完了しました`を確認（`backend/buildOnEcs/entrypoint.sh`にログ出力を追加して可視化。migrationが無い場合`rails db:migrate`が無出力になるため、rebuildして再検証した）。
- [x] public IP への直接アクセスが 403 になることを確認する
  > taskのENIから public IP を取得し`http://<public IP>:18101/graphql`へPOST。HTTP 403を確認。
- [x] 停止 script を実行し、URL が応答しなくなることを確認する
  > `stop.sh`実行後、`desired_count=0`・`running_count=0`・schedule 0件を確認。URLへPOSTすると`{"message":"Internal Server Error"}`（HTTP 500、integration URIが到達しないIPを指しAPI Gateway側でエラーになる）で、正常応答は得られない。
- [x] Phase 2 の成果物を commit する
  > 2 commit に分割: (1) ecs/apigateway/ssm/alarm/scheduler_role の Terraform 一式 + envs/review への呼び出し追加、(2) start.sh/stop.sh。加えて検証中に見つけた entrypoint.sh のmigrationログ不足を別途1 commitで修正済み（image定義の延長）。すべてlocal commitのみ、originへは未push。
- [x] ここで作業を停止し、結果をユーザーに確認する。次 phase へは進まない
  > `review_environment.md` の手順（起動scriptの5ステップ、REVIEW_BACKEND_AUTO_STOP_MINUTES、確認方法、停止）を実際のscript引数・出力と照合し、ずれなし。

### 各task詳細

#### `backend/terraform/modules/ecs/` を新規作成する

ECS cluster `nanitabe-back-review`、task definition、service を定義する。

- cluster は Fargate だけを使う。Container Insights は有効にしない（`design.md` の要件）。
- task definition は `runtime_platform` に `ARM64` を指定し、`cpu = 256`、`memory = 512` とする。
- 環境変数は `RAILS_ENV=production`、`RAILS_LOG_TO_STDOUT=1`、`PORT=18101`、`BACKEND_PROD_HOST=review-backend-nanitabe.kibotsu.com` を `environment` に平文で置く。
- `DB_NAME` / `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASS` / `RAILS_MASTER_KEY` は `secrets` で SSM parameter の ARN を参照する。
- log driver は `awslogs` とし、log group を Terraform で作る。`retention_in_days` は設定しない（無期限保持）。
- service は `desired_count = 0` とする。`lifecycle { ignore_changes = [desired_count] }` は付けない。`terraform apply` が停止側へ倒れる挙動を意図しているため。
- network configuration は default VPC の public subnet 3 つを指定し、`assign_public_ip = true` とする。
- security group は task の `18101/tcp` を `0.0.0.0/0` から許可する。API Gateway の送信元 IP が固定されないため絞れない。IP 直アクセスは Rails の `config.hosts` が弾く。
- deployment circuit breaker は設けない。起動失敗は 30 分の自動停止で止まるため。

task execution role には ECR pull、CloudWatch Logs 書き込み、`ssm:GetParameters`、`kms:Decrypt` を与える。task role は付与しない。

#### `backend/terraform/modules/apigateway/` を新規作成する

`frontend/terraform/modules/apigateway/main.tf` を参照する。違いは integration type と custom domain の有無。

- `aws_apigatewayv2_api` を `protocol_type = "HTTP"` で作る。
- route は `ANY /{proxy+}` とする。path をそのまま転送するため。
- `aws_apigatewayv2_integration` は `integration_type = "HTTP_PROXY"`、`integration_uri` の初期値を `http://192.0.2.1:18101/{proxy}` とする。起動 script がこの URI を書き換える。
- `request_parameters` に `"overwrite:header.Host" = "review-backend-nanitabe.kibotsu.com"` を設定する。これにより API Gateway 経由の request だけが Rails の `config.hosts` を通る。
- `aws_acm_certificate` を `ap-northeast-1` で発行し、DNS 検証する。検証用の CNAME レコードを Route53 へ作る。
- `aws_apigatewayv2_domain_name` と `aws_apigatewayv2_api_mapping` で `review-backend-nanitabe.kibotsu.com` を割り当てる。
- Route53 の A レコード（alias）を、API Gateway の regional domain name と hosted zone id を指す形で作る。hosted zone は既存の `kibotsu.com`。
- stage は `$default` で `auto_deploy = true`。access log を CloudWatch Logs へ出し、log group の `retention_in_days` は設定しない。

`integration_uri` は起動・停止 script が実行時に書き換えるため、Terraform 側で `lifecycle { ignore_changes = [integration_uri] }` を設定する。これがないと `terraform apply` のたびに起動中の環境の転送先が停止側の値へ戻る。`desired_count` と扱いが違うのは、`desired_count` は apply が停止側へ倒れることを意図しているのに対し、`integration_uri` は task の実体と対応する値であり、apply が実体と食い違う値を書き込むと「service は動いているが到達できない」という中途半端な状態になるため。

#### SSM Parameter Store の parameter を Terraform 定義へ追加する

`DB_NAME` / `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASS` / `RAILS_MASTER_KEY` を `aws_ssm_parameter` の `type = "SecureString"` で作る。値は `apply_terraform.sh` が `.env` から `TF_VAR_*` 経由で渡す。

`infrastructure/terraform/envs/review/apply_terraform.sh` へ、これらの export を追加する。secret の値を log や成果物へ出さない。

#### CloudWatch alarm と SNS topic を Terraform 定義へ追加する

`design.md` の「log と監視」の表に従う。

- `aws_sns_topic` を作り、topic policy で `cloudwatch.amazonaws.com` からの `sns:Publish` を許可する。
- `aws_sns_topic_subscription` で email を購読する。宛先は `TF_VAR_` 経由で渡す。
- `aws_cloudwatch_metric_alarm` を `AWS/ECS` の `CPUUtilization`、`statistic = "SampleCount"`、`period = 300`、`evaluation_periods = 9`、`treat_missing_data = "notBreaching"` で作る。閾値は data point の存在を判定する形にする。

#### `terraform plan` を実行し、差分を確認する

差分が review state 内の resource の追加だけであり、destroy が 0 件であることを確認する。Phase 1 で作った ECR と CodePipeline に change が出ないことも確認する。

#### `terraform apply` を実行する

ACM 証明書の DNS 検証に時間がかかるため、apply が完了するまで待つ。

#### SNS topic の email 購読を確認する

購読確認メールが届くので、link を開いて購読を確定する。これは Terraform の適用だけでは完了しない手作業である。確定しないと alarm が発報しても通知が届かない。

`aws sns list-subscriptions-by-topic` で `SubscriptionArn` が `PendingConfirmation` でないことを確認する。

#### `scripts/review_backend/start.sh` と `scripts/review_backend/stop.sh` を新規作成する

`start.sh` は次の順で行う。

1. 現在の `desired_count` を確認する。既に 1 なら、その task がいつから起動しているかを表示して終了する。
2. `aws ecs update-service --desired-count 1` を実行する。
3. `aws ecs wait services-stable` または task が RUNNING になるまで待つ。
4. `aws ecs list-tasks` と `describe-tasks` で task を特定し、ENI の id を取得する。
5. `aws ec2 describe-network-interfaces` で public IP を取得する。
6. `aws apigatewayv2 update-integration` で `integration_uri` を `http://<public IP>:18101/{proxy}` へ更新する。
7. EventBridge Scheduler へ 30 分後の one-time schedule を 2 つ作る。同名の schedule が既にあれば削除してから作る。`ActionAfterCompletion` は `DELETE` とする。
   - 1 つ目の target は `aws-sdk:ecs:updateService` で `desiredCount` を 0 にする。
   - 2 つ目の target は `aws-sdk:apigatewayv2:updateIntegration` で URI を `http://192.0.2.1:18101/{proxy}` へ戻す。
8. schedule の作成に失敗した場合は、`desired_count` を 0 へ戻し、`integration_uri` も停止側へ戻したうえでエラー終了する。自動停止の保証がない状態で起動したままにしない。
9. 到達 URL と自動停止の予定時刻を出力する。

`stop.sh` は `desired_count` を 0 にし、`integration_uri` を停止側の値へ戻し、schedule 2 つを削除する。どの操作も冪等にする。

EventBridge Scheduler が AWS API を直接呼ぶための role は Terraform で作り、`ecs:UpdateService` と `apigatewayv2:UpdateIntegration` を与える。

#### 起動 script を実行し、URL が応答することを確認する

`scripts/review_backend/start.sh` を実行し、出力された URL へ `POST /graphql` する。`{"query":"{ __typename }"}` を送り、認証エラーの JSON が返ることを確認する。認証エラーが返れば GraphQL 層まで到達している。

CloudWatch Logs で、起動時に `rails db:migrate` が実行されたことを確認する。

#### public IP への直接アクセスが 403 になることを確認する

起動中の task の public IP を取得し、`http://<public IP>:18101/graphql` へ直接 `POST` する。Rails の `config.hosts` により 403 が返ることを確認する。

#### 停止 script を実行し、URL が応答しなくなることを確認する

`scripts/review_backend/stop.sh` を実行し、`desired_count` が 0 になり、`integration_uri` が停止側の値へ戻り、schedule が削除されたことを確認する。その後 URL へ `POST` して応答しないことを確認する。

test は作成しない。Terraform 定義と shell script に対する自動 test を持つ仕組みが repository に無いため。上記の実測をもって代える。

#### Phase 2 の成果物を commit する

意味単位で 2 つに分ける。

1. Phase 2 の Terraform（`backend/terraform/modules/ecs/`、`modules/apigateway/`、SSM parameter、alarm、SNS、`envs/review/main.tf` への呼び出し追加）
2. 起動・停止 script（`scripts/review_backend/`）

この commit も local に留まる。

#### ここで作業を停止し、結果をユーザーに確認する。次 phase へは進まない

AWS 上に ECS cluster、service、API Gateway、ACM 証明書、Route53 レコード、SSM parameter、SNS topic、CloudWatch alarm が作られたこと、および起動時に開発 DB へ migration が適用されたことをユーザーへ報告する。いずれもこの作業を破棄しても残る。

あわせて、`review_environment.md` に書いた手順が実際の script の引数や出力と合っているかを照合する。ずれていた場合はその場で document を書き換えず、`design.md` へ戻す。

---

## Phase 3: 自動停止が発火して環境が落ちる

### DoD（完了条件）

- `REVIEW_BACKEND_AUTO_STOP_MINUTES=1` で起動すると、schedule の発火によって `desired_count` が 0 になり、integration URI が停止側の値へ戻り、URL が応答しなくなる。
- 既定値で起動したとき、作られる schedule の実行予定時刻が起動時刻の 30 分後になっている。

### Tasks

- [x] `REVIEW_BACKEND_AUTO_STOP_MINUTES=1` で起動し、発火を確認する
  > 1回目の実行で発火はしたが、`desired_count`は0に戻った一方でintegration URIが起動時のIPを指したまま残るバグを発見した。CloudTrailで`apigateway:PATCH`への`AccessDenied`を確認し、`backend/terraform/modules/scheduler_role/main.tf`のIAM policyが誤っていたと判明（`apigatewayv2:UpdateIntegration`という action名は実際には評価されず、API Gateway v2管理APIはHTTP verb単位の`apigateway:PATCH`/`apigateway:GET`で認可される）。修正し`apply_terraform.sh`で再apply（0 added, 1 changed, 0 destroyed）後に再実行し、`desired_count=0`・integration URIが`http://192.0.2.1:18101/{proxy}`・URLがHTTP 500になることを確認した。
- [x] schedule が実行後に削除されていることを確認する
  > `aws scheduler list-schedules`で`nanitabe-back_review_auto_stop_service`/`_integration`とも消滅、残るのは無関係の既存`database-backup-to-s3`のみ。`ActionAfterCompletion=DELETE`が機能した。
- [x] 既定値で起動し、schedule の予定時刻が 30 分後であることを確認する
  > `aws scheduler get-schedule`で`CreationDate`と`ScheduleExpression`の差が約30分（01:42:23 UTC作成 → 02:12:21 UTC発火）であることを確認。発火は待たず、確認後に`stop.sh`で停止（`desiredCount=0`・`runningCount=0`まで確認）。

### 各task詳細

#### `REVIEW_BACKEND_AUTO_STOP_MINUTES=1` で起動し、発火を確認する

```sh
REVIEW_BACKEND_AUTO_STOP_MINUTES=1 ./scripts/review_backend/start.sh
```

1 分後に次を確認する。

- `aws ecs describe-services` で `desiredCount` が 0 になっている
- `aws apigatewayv2 get-integration` で `integration_uri` が `http://192.0.2.1:18101/{proxy}` へ戻っている
- URL へ `POST` しても応答しない

検証したいのは schedule が発火して 2 つの target が実行されることであり、この動作は待ち時間の長さに依存しない。30 分待つ必要はない。

#### schedule が実行後に削除されていることを確認する

`aws scheduler list-schedules` で、作られた 2 つの schedule が残っていないことを確認する。`ActionAfterCompletion` が `DELETE` として働いたことの確認になる。

#### 既定値で起動し、schedule の予定時刻が 30 分後であることを確認する

環境変数を渡さずに起動 script を実行し、`aws scheduler get-schedule` で `ScheduleExpression` の時刻が起動時刻の 30 分後になっていることを確認する。

発火まで待たない。発火の動作は前の task で確認済みであり、ここで確認するのは起動 script が 30 分という既定値から正しく時刻を計算しているかである。

確認後に停止 script を実行し、環境を停止させる。

## Phase 4: 自動停止が働かなかった場合に通知が届く

### DoD（完了条件）

- alarm の `evaluation_periods` を一時的に 1 へ下げた状態で、停止 schedule を作らずに task を動かすと、alarm が `ALARM` になり email が届く。
- 定義値に戻した状態で、`evaluation_periods` が 9、`period` が 300 秒であることを確認できる。

### Tasks

- [x] alarm の `evaluation_periods` を一時的に 1 へ変えて apply する
  > `apply_terraform.sh`で適用（0 added, 1 changed, 0 destroyed）。
- [x] 停止 schedule を作らずに service を起動し、alarm の発報と通知を確認する
  > `aws ecs update-service --desired-count 1`で起動（start.shは使わず、scheduleを作らない）。約1分でalarmがOK→ALARMへ遷移（`aws cloudwatch describe-alarm-history`で`Successfully executed action arn:aws:sns:...:nanitabe-back_review_alarm`を確認）。SNSの`NumberOfNotificationsDelivered`メトリクスで配信1件を確認（購読済みemailへの配信）。alarm発報後もserviceは`desiredCount=1`・`runningCount=1`のまま動き続けることを確認（alarmはtaskを止めない）。
- [x] 手動で停止する
  > `stop.sh`実行。この起動ではscheduleを作っていないため「対象が無い状態でのschedule削除」を通過（エラーなし=冪等性の確認）。`desiredCount=0`・`runningCount=0`を確認。
- [x] `evaluation_periods` を 9 へ戻して apply し、定義値を確認する
  > `apply_terraform.sh`で適用（0 added, 1 changed, 0 destroyed）。`aws cloudwatch describe-alarms`で`EvaluationPeriods=9`・`Period=300`を確認。

### 各task詳細

#### alarm の `evaluation_periods` を一時的に 1 へ変えて apply する

Terraform 定義の `evaluation_periods` を 1 へ変更して apply する。5 分で発報する状態になる。

検証したいのは「data point が存在し続けたら `ALARM` になり、SNS 経由で email が届く」という経路であり、この経路は評価期間の長さに依存しない。45 分待つ代わりに期間を縮めて同じ経路を通す。

#### 停止 schedule を作らずに service を起動し、alarm の発報と通知を確認する

起動 script は必ず schedule を作るため、この検証では使わない。

```sh
aws ecs update-service --cluster nanitabe-back-review --service nanitabe-back_service_review --desired-count 1
```

この操作は自動停止の保証がない状態を意図的に作る。開始時刻を記録し、検証が終わったら必ず手動で停止する。

5 分から 10 分後に `aws cloudwatch describe-alarms` で state が `ALARM` になっていることと、購読している email へ通知が届いていることを確認する。

alarm は task を止めない。通知が届いた後も service は動き続けることを確認する。

#### 手動で停止する

`./scripts/review_backend/stop.sh` を実行する。`desired_count` が 0 になり、`integration_uri` が停止側の値へ戻ったことを確認する。

この phase の起動では schedule を作っていないため、stop script の schedule 削除は対象が無い状態で実行される。冪等であることの確認にもなる。

#### `evaluation_periods` を 9 へ戻して apply し、定義値を確認する

Terraform 定義を元に戻して apply する。`aws cloudwatch describe-alarms` で `EvaluationPeriods` が 9、`Period` が 300 であることを確認する。

この 2 つの値が、通知までの時間が 45 分であることを担保する。発報を待って実測しない。

## Phase 5: 品質checkと修正

### DoD（完了条件）

- 全testがgreen
- repository全体のlint・static analysisにerrorがない
- `review_environment.md` と `infrastructure/README.md` の記述が、実際の script の引数・出力・構成と一致している

### Tasks

- [x] 全test実行
  - [x] `docker compose exec backend bundle exec rspec` を実行する
  - [x] すべてgreenであることを確認する
    > 710 examples, 0 failures。

- [x] repository全体のlintを実行する
  - [x] `docker compose exec backend bundle exec rubocop` を実行する
  - [x] errorがあれば修正して再実行する
  - [x] error zeroを確認する
    > 433 files inspected, no offenses detected。

- [x] document と実態の照合（document 本体は task-design 内で作成済み。ここでは実態との一致だけを見る）
  - [x] `review_environment.md` の手順どおりに、起動から停止までを一度通す
    > `start.sh`実行 → 出力形式（URL・自動停止予定時刻）が「使い方」節の記述と一致。`POST /graphql`が`AUTHENTICATION_ERROR`（HTTP 200、devise+jwt保護と整合）→ `stop.sh`実行 → 「停止中にURLを叩くとどうなるか」節どおりHTTP 500を確認。
  - [x] 記述と実際の script の引数・出力が食い違う箇所がないか確認する
    > 食い違いなし。参考: `start.sh`実行直後の初回requestで一度だけHTTP 503（API Gateway側の反映が数秒遅れたと見られる）が出たが、documentはinstant availabilityを主張していないため記述との食い違いではない。数秒後のretryで200になることを確認済み。
  - [x] `infrastructure/README.md` の state key と apply script の記述が実際の構成と一致するか確認する
    > state key（`review/terraform.tfstate`）、apply_terraform.shのplan保存+destroy判定、`desired_count=0`が定義の正、`lifecycle.ignore_changes=[integration_uri]`、network/CPU architecture/host名の前提、すべて実装と一致。
  - [x] 食い違いが記述のミスなら document を直す。設計方針の変更にあたるなら document を書き換えず `design.md` へ戻す
    > 食い違いが見つからなかったため対象なし。

UI 変更が無いため screenshot 確認は行わない。

## Documentation reviewと実装後振り返り

- [x] code readingまたは実装で永続化候補を得た場合、その場でdoc-enricherを提案modeで適用する
  - [x] 提案がある場合だけユーザー承認後に既存READMEまたは既存docsへ反映する
    > `infrastructure/README.md`の「構成上の前提」へ2件追記（API Gateway v2管理APIのIAM権限、EC2系resourceのdescriptionはASCIIのみ）。`rails db:migrate`の無音挙動はcode(entrypoint.sh)に既に自己文書化されているためDROP。
  - [x] 提案・承認判断を別taskへ先送りしない
- [x] 実装、review、validationからfeedbackまたは実装とのずれが生じた場合、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用する
  - [x] `discussion_directory=<working_dir>`と`discussion_file_name=implementation_review.md`を渡す
  - [x] 原文、関連する実装・design・plan、原因、採用方針、決定を渡し、修正済みでも記録を省略しない
  - [x] 「共有されていなかった知識の前提は何か」を確認する
  - [x] 「codeを読めば分かるか、設計意図か、process不足か」を確認する
  - [x] 「どこに書けば次回この議論が不要になるか」を確認し、合意後だけ反映する
  - [x] decisionをcallerへ返し、designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す
  - [x] review後に実装を自動再開しない
    > 本tasklist実行を通じて発生した6件のずれ（review branchのforce push規約、apply script契約のscript化、公開範囲の遡及漏れ、停止中挙動の記述誤り、scheduler IAM action名の誤り、DB schema drift）は、直接受領したworkflow owner（coordinator）が都度`implementation_review.md`へ記録済み（論点1〜6）。論点6（schema drift）は今回のsteeringに起因しない既存問題のため保留とし、再開条件を動作確認完了後としている。

---

## 動作確認

### DoD

ユーザーが実際にスマホ実機から `https://review-backend-nanitabe.kibotsu.com/graphql` を叩き、意図どおりであることを確認した。

### Tasks

- [x] ユーザーに動作確認を依頼する
  - [x] 起動 script を実行し、URL をユーザーへ伝える
    > `./scripts/review_backend/start.sh`実行。URL: `https://review-backend-nanitabe.kibotsu.com/graphql`。自動停止予定: 2026-09-19T02:40:41 UTC。`POST /graphql`でHTTP 200（AUTHENTICATION_ERROR）を確認し、到達可能であることを確認済み。
  - [x] ユーザーがスマホ実機から叩けることを確認する。これが今回の主目的であり、PC からの確認で代替しない
    - スマホ実機の browser から `https://review-backend-nanitabe.<hosted zone>` を開き、Rails の 404 ページが返った。DNS 解決、TLS ハンドシェイク（ACM 証明書を端末の OS が検証）、API Gateway の受理、task への転送、Rails の処理までが通っている。`config.hosts` を通過していることも意味する（Host ヘッダ上書きが効いていなければ 403 になる）
    - 確認時の接続は Wi-Fi であり、モバイル回線での実測は取っていない。今回の構成は接続元 IP を絞っていないため結果は変わらない
  - [x] 確認後に停止 script を実行する
    - `desired_count` と `running_count` がともに 0、schedule 2 件とも削除済みであることを確認した
- [x] ~~feedback収集~~（動作確認からのfeedbackなし。実装中に判明した事項は論点1〜6として記録済み）
  - [x] designまたはplan構造が変わる変更（論点1、4、5）は design へ反映済み。論点2と論点6は再開条件付きの保留

---

## 完了後のaction

> ⚠️ 動作確認phaseが完了するまで、`feature-278` の `origin` への push と PR 作成を行わない。促すことも急かすことも禁止する。
>
> `review` branch への force push は対象外である。あれは動作確認の手段そのものであり、成果物を `main` へ届ける操作ではない。
> 各 phase 内の local commit も対象外である。commit を実装の進行に合わせて刻むのは、どの変更がどの合意に基づくかを後から辿れるようにするためであり、最後に一括する形はその性質を失わせる。

- [ ] 残りの成果物を commit する
  - 各 phase の成果物は、その phase 内の commit task で確定済みである
  - ここで commit するのは、実装が終わってから確定した次の 2 つ
    - `tasklist.md` の checkbox
    - `implementation_review.md`
  - MUST: 上記 2 つを、対応する実装 commit より後に置く
  - ユーザーが一部だけ承認した場合は承認範囲だけをcommitし、残りは待つ

- [ ] current branchをpushしてPRを作成する
  - [ ] commit taskの結果としてlocal commitが実際に一件以上あることを確認する。一件もなければpush・PRを実行しない
  - [ ] current branch が `feature-278` であり、公開可能なnon-default branchであることを確認する
  - [ ] `git push -u origin feature-278` を実行する
  - [ ] pluginのskills directory配下にある `scripts/github/create_or_get_pr.sh` を実行する
    - pathの起点はpluginのskills directoryである。利用先repositoryからの相対pathではない
    - branch 名から issue 番号を導き、PR body へ `Closes #278` が入る

---

## 参照

- 設計の正本: 同じdirectoryの `./design.md`
- 完了条件、取消完了、subtask分割、checkbox更新timingの規則の正本: `tasklist-executor/SKILL.md`
- tasklistへ載せるtaskの範囲の正本: `task-design/tasklist-design.md`
