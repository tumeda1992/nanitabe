# Tasklist: Terraform の適用を GitHub Actions へ移す

設計参照: `./design.md`

前提:

- agent は手元で prod / review の Terraform を apply できない（auto mode の分類器が拒否する）。手元の apply が要る段階（Phase 2）は、agent が plan file を作り、要約と利用者が `!` で実行するコマンドを示して止まる。
- AWS への変更、GitHub の設定変更、secrets の登録、`main` への merge は、それぞれ独立した phase で行い、phase の最後で止まって結果を確認する。
- plan / apply の全文、secrets の値、domain 名、account ID、zone ID を、chat、log、commit、PR に出さない。

## Phase 1: 定義と workflow を用意する（AWS と GitHub の設定は変えない）

### DoD（完了条件）

- `infrastructure/terraform/modules/github_oidc/` と `envs/prod` からの呼び出しがあり、scratchpad に複製した repository で `terraform validate` が通る。
- workflow 4 本と composite action があり、YAML として読める。
- 両 root の `.terraform.lock.hcl` が `linux_amd64` と `darwin_arm64` の hash を持ち、追跡対象になっている。repository 直下に `.terraform-version` がある。
- secrets 登録用の script が scratchpad にあり、値を出力しない。
- AWS の resource、GitHub の設定、remote は変わっていない。

### Tasks

- [x] `infrastructure/terraform/modules/github_oidc/main.tf` を作る
- [x] `infrastructure/terraform/envs/prod/main.tf` から `module "github_oidc"` を呼ぶ
- [x] composite action `.github/actions/terraform-run/action.yml` を作る
- [x] workflow 4 本を作る
- [x] `.terraform-version` を置き、lock file を追跡対象にする
- [x] scratchpad で `terraform fmt -check`（新規 file）と `terraform validate`（両 root）を通す
- [x] workflow と composite action を YAML として parse できることを確かめる
- [x] secrets 登録用の script を scratchpad に作る
- [x] secrets 登録 script から、Terraform に通さなくなった値（`DB_*`、`RAILS_MASTER_KEY`、`ROUTE53_HOSTZONE_ID`、`AWS_ACCOUNT_ID`、`AWS_CODE_CONNECTION_ID_TO_GITHUB`、`AMPLIFY_GITHUB_ACCESS_TOKEN`）を外す（discussion 論点13・14）
- [x] review の SSM parameter を Terraform の管理から外す（design「review の SSM parameter」、discussion 論点13）
  - [x] `backend/terraform/modules/ssm/` を削除し、ssm module を呼んでいる root に `removed` block（`from = module.ssm`、`lifecycle { destroy = false }`）を置く
  - [x] ECS module へ渡していた parameter の ARN を、名前から組み立てて渡す（task definition の `valueFrom` と `ssm:GetParameters` の対象の値が変わらないこと）
  - [x] review root と backend の review env から `db_*`、`rails_master_key` の variable を外す
  - [x] `scripts/review_backend/put_ssm_parameters.sh` を作る（`.env` から 6 つを読み、`aws ssm put-parameter --type SecureString --overwrite`。値を出力しない。AWS CLI の設定の認証情報を使う）
- [x] AWS から引ける識別子を data source に置き換える（discussion 論点14）
  - [x] `route53_zone_id` を `data "aws_route53_zone"`（`route53_name` から）に置き換える
  - [x] `aws_account_id` を `data "aws_caller_identity"` に置き換える
  - [x] `aws_code_connection_id_to_github` を `data "aws_codestarconnections_connection"`（connection の名前は AWS CLI の `aws codeconnections list-connections` で確認して module に書く）に置き換える
  - [x] review root と backend の review env から 3 つの variable を外す
- [x] `aws_amplify_app` に `lifecycle { ignore_changes = [access_token] }` を付け、`amplify_github_access_token` の variable を既定値 `null` の optional にする（prod root、frontend の prod env、`modules/amplify`）。`modules/amplify/README.md` に token の更新手順（`aws amplify update-app --access-token`）を書く
- [x] 上の変更後、scratchpad で両 root の `terraform validate` と plan を作り（読み取りだけで apply しない）、prod は差分 0、review は SSM parameter 6 つの state からの削除だけであることを確認する
- [x] `.env` から `NEXT_PUBLIC_ASSET_ORIGIN` を消す手順を、利用者向けに用意する（値を出さない `sed` の 1 行）

> 実施メモ: scratchpad の複製で両 root の `terraform validate` が通り、read-only の plan を作った。prod は `No changes`、review は `aws_ssm_parameter` 6 つの state からの削除（forget）だけで、追加・変更・destroy は 0。`aws_codestarconnections_connection` の data source は 1 度 DNS 解決の一過性エラーで失敗したが、同じ endpoint が解決できることを確認して再実行し通った（provider 6.70.0 に `aws_codeconnections_connection` の data source は無い）。ecs module の region は `ap-northeast-1` を直接書いた（`aws_region.name` が deprecated のため）。

### 各task詳細

#### `infrastructure/terraform/modules/github_oidc/main.tf`

design の「OIDC と role」の表のとおり。

- variable: `repository`（`tumeda1992/nanitabe`）、`name_prefix`（`nanitabe`）、`state_bucket_name`、`lock_table_name`
- `data "tls_certificate"` と `aws_iam_openid_connect_provider`（x_favorites の `terraform/modules/github_oidc/main.tf` と同じ取り方）
- plan role `${name_prefix}-terraform-plan`: 信頼条件 `token.actions.githubusercontent.com:aud = sts.amazonaws.com`、`sub` が `repo:<repository>:pull_request` または `repo:<repository>:ref:refs/heads/*`（手動起動の plan 用）。権限は `ReadOnlyAccess` の attach と、state 用 bucket の `s3:GetObject`・`s3:PutObject`・`s3:ListBucket`、lock 用 table の `dynamodb:GetItem`・`PutItem`・`DeleteItem`
- apply role `${name_prefix}-terraform-apply-prod`: `sub` が `repo:<repository>:environment:prod`。`AdministratorAccess` を attach
- apply role `${name_prefix}-terraform-apply-review`: `sub` が `repo:<repository>:environment:review`。`AdministratorAccess` を attach
- output: 3 つの role の ARN
- `envs/prod/main.tf` は既存の `bucket_name`・`dynamodb_table_name` を渡す。`required_providers` に `hashicorp/tls` を加える

#### composite action `.github/actions/terraform-run/action.yml`

input: `working-directory`、`role-to-assume`、`state-key`（`prod/terraform.tfstate` 等）、`mode`（`plan` / `apply` / `apply-guarded`）、`root-name`（`prod` / `review`）、`state-bucket`、`lock-table`。

手順:

1. `hashicorp/setup-terraform`（version は `.terraform-version`、`terraform_wrapper: false`）
2. `aws-actions/configure-aws-credentials`（`role-to-assume`、region `ap-northeast-1`）
3. `terraform init -lockfile=readonly -input=false` に既存の `init_terraform.sh` と同じ `-backend-config`（bucket、key、region、`dynamodb_table`、`encrypt=true`）
4. mode ごとに実行し、Terraform の標準出力と標準エラーはすべて file へ redirect する
   - `plan`: `terraform plan -input=false -no-color -out=tfplan > out.txt 2>&1`
   - `apply`: `terraform apply -input=false -no-color -auto-approve > out.txt 2>&1`、続けて `terraform plan -no-color -out=post.tfplan >> out.txt 2>&1`
   - `apply-guarded`: plan を保存し、`terraform show -json tfplan` の `resource_changes` に `delete` を含むものが 1 件でもあれば apply せず失敗。無ければ `terraform apply tfplan`、続けて post-apply plan
5. `out.txt` を `s3://<state-bucket>/plans/<root-name>/<run id>.txt`（plan）または `applies/<root-name>/<run id>.txt`（apply 系）へ `aws s3 cp` する
6. 要約を作る: `terraform show -json` の `resource_changes` を `jq` で resource の type ごとに create / update / delete / replace を数え、destroy（delete と replace）の総数を先頭に置く。resource のアドレス、名前、値は出さない。要約と S3 の key を `$GITHUB_STEP_SUMMARY` に書き、output として返す
7. apply 系は post-apply plan の変更数が 0 でなければ失敗する
8. Terraform のコマンドが失敗した場合も、`out.txt` の S3 への保存と、「失敗した」という一行だけの要約は行う。`out.txt` を log へ出さない

#### workflow 4 本

design の「workflow の構成」の表のとおり。

- 共通: `paths` には design の表の paths に加えて `.github/actions/terraform-run/**` を含める（共通手順の変更でも plan と apply が動くようにするため）。`permissions: { contents: read, id-token: write, pull-requests: write }`（plan のみ `pull-requests: write`）、`concurrency` を root ごとに 1 つにし、実行中の apply を取り消さない（`cancel-in-progress: false`）
- `terraform-plan-*.yml`: `pull_request`（`branches: [main]`、paths）と `workflow_dispatch`。job の条件 `github.event.pull_request.head.repo.full_name == github.repository`（fork を除く）。plan role を使う。要約を PR コメントに出し、同じ PR では既存コメントを更新する（`<!-- terraform-plan-<root> -->` の marker で探す。`gh api` を使い、第三者の action を使わない）
- `terraform-apply-prod.yml`: `push`（`branches: [main]`、paths）と `workflow_dispatch`。`environment: prod`。mode `apply`
- `terraform-apply-review.yml`: `push`（`branches: [main]`、paths）と `workflow_dispatch`。`environment: review`。push のときは mode `apply`、手動起動のときは mode `apply-guarded`
- `TF_VAR_*` は design の secrets の表のとおりに渡す（repository secrets と Environment secrets）
- 使う action は `actions/checkout`、`hashicorp/setup-terraform`、`aws-actions/configure-aws-credentials` だけ。いずれも commit SHA で固定する

#### lock file と `.terraform-version`

- `.gitignore` から `**/.terraform.lock.hcl` を外す
- `.terraform-version` には、手元の `terraform version` と同じ版を書く
- scratchpad に repository を複製し、`envs/prod` と `envs/review` で `terraform init -backend=false` の後に `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64` を実行し、生成された lock file を repository へ戻す。手元の `envs/*/.terraform` は触らない

#### secrets 登録用の script

`scratchpad/register_github_secrets.sh`。`.env` を読み、`gh secret set` で登録する。

- repository secrets: `TERRAFROM_STATE_S3_BUCKET`、`TERRAFROM_STATE_DYNAMODB_TABLE`、`ROUTE53_HOSTZONE_NAME`、`AWS_TERRAFORM_PLAN_ROLE_ARN`
- `prod` Environment secrets: `AWS_TERRAFORM_APPLY_ROLE_ARN`（prod）、`NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`、`AMPLIFY_GITHUB_ACCESS_TOKEN`
- `review` Environment secrets: `AWS_TERRAFORM_APPLY_ROLE_ARN`（review）、`AWS_ACCOUNT_ID`、`CODEBUILD_ARTICACT_S3_BUCKET`、`AWS_CODE_CONNECTION_ID_TO_GITHUB`、`ROUTE53_HOSTZONE_ID`、`DB_NAME`、`DB_HOST`、`DB_PORT`、`DB_USER`、`DB_PASS`、`RAILS_MASTER_KEY`、`REVIEW_BACKEND_ALARM_EMAIL`
- role の ARN は Phase 2 の apply 後に `aws iam get-role` で取得する
- 値は標準入力から渡し（`gh secret set NAME --body -` ではなく `printf '%s' "$V" | gh secret set NAME`）、echo しない。最後に `gh secret list` と `gh secret list --env <env>` の名前だけを表示する

#### Phase 1 実施メモ（design との差分）

- plan workflow は Environment を指定できない（指定すると OIDC の `sub` が `environment:*` になり、plan role の信頼条件と合わない）。そのため plan に要る TF_VAR の元の値は Environment secrets では plan から読めない。secrets 登録 script は、prod と review の TF_VAR の元の値を repository secrets に登録し、apply role の ARN（`AWS_TERRAFORM_APPLY_ROLE_ARN`）だけを Environment secrets に登録する。secret 名は prod と review で重ならない。design の「review の job には prod の値が渡らない」は成り立たなくなる（repository の workflow を書ける者は全 secrets を読める）。
- apply 系は、plan を保存してから `terraform apply tfplan` する（要約を適用内容から作るため）。`apply-guarded` との違いは destroy の判定だけ。
- S3 key は `<run id>.txt`、再実行（attempt 2 以降）は `<run id>-<attempt>.txt`。
- `.env` から `NEXT_PUBLIC_ASSET_ORIGIN` を消す 1 行: `sed -i '' '/^NEXT_PUBLIC_ASSET_ORIGIN=/d' /etc/opt/app_setting_files/nanitabe/.env`

## Phase 2: OIDC と role を作る（手元からの最後の prod apply）

### DoD（完了条件）

- AWS に OIDC identity provider と role 3 つがあり、`envs/prod` の `terraform plan` が `No changes` になる。

### Tasks

- [x] `envs/prod` の plan を作る（`terraform plan -out=<scratchpad>/oidc.tfplan`）
  - [x] plan の追加が OIDC provider、role 3 つ、policy と attachment だけで、変更・削除が無いことを確認する
- [x] 利用者に apply を依頼する。要約と、`cd <envs/prod> && export $(grep -v '^#' <.env> | xargs) && terraform apply <plan file>` の形のコマンドを示して止まる
- [x] apply 後、`terraform plan` が `No changes` であることを確認する
- [x] ここで作業を停止し、結果を利用者に確認する。次 phase へは進まない

> 実施メモ: 初回の apply は、OIDC provider が同じ account の x_favorites の Terraform に所有されており `EntityAlreadyExists` で失敗した（何も作られていない）。provider を作らず `data "aws_iam_openid_connect_provider"` で参照する形に変え（implementation_review.md 論点1）、`Apply complete! Resources: 7 added, 0 changed, 0 destroyed.`（role 3、role policy 1、attachment 3）。適用後の `terraform plan` は `No changes`。

## Phase 3: GitHub の Environments と secrets を用意する

### DoD（完了条件）

- GitHub に Environment `prod`（deployment branch は `main` だけ）と `review`（制限なし）がある。
- design の表の secrets が、名前で `gh secret list`（repository と各 Environment）に出る。

### Tasks

- [x] Environment を作るコマンド（`gh api -X PUT repos/tumeda1992/nanitabe/environments/prod` に `deployment_branch_policy`、`review` は制限なし）を用意し、利用者に実行を依頼して止まる
- [x] secrets 登録 script の実行を利用者に依頼して止まる（`! bash <scratchpad>/register_github_secrets.sh`）
- [x] 名前の一覧を確認する（値は見ない）
- [x] ここで作業を停止し、結果を利用者に確認する。次 phase へは進まない

## Phase 4: PR で plan workflow を確かめる

### DoD（完了条件）

- `feature-258` の PR で `terraform-plan-prod.yml` と `terraform-plan-review.yml` が成功し、PR コメントに要約（種別ごとの件数と destroy の有無。どちらも変更 0）が出る。
- S3 の `plans/prod/` と `plans/review/` に全文がある。
- PR コメントと workflow の log に、domain 名、account ID、zone ID が出ていない。

### Tasks

- [ ] Phase 1 の変更を意味単位で commit し、`feature-258` を push する
- [ ] `feature-258` から `main` への PR を作る（`Closes #258` は付けない。Phase 8 で付ける）
- [ ] plan workflow の成功と PR コメントを確認する
- [ ] S3 の全文を `aws s3 cp` で取得し、差分が prod は 0、review は SSM parameter 6 つの state からの削除（`removed`、destroy ではない）だけであることを確認する
- [ ] log と PR コメントを、hosted zone 名、account ID、zone ID の文字列で検索し、出ていないことを確認する（検索語は `.env` から読み、chat に出さない）
- [ ] 失敗した場合は、原因を特定してから直す。値が log に出た場合は当該 run の log を削除し、利用者へ報告して止まる
- [ ] ここで作業を停止し、結果を利用者に確認する。次 phase へは進まない

## Phase 5: 途中 merge で apply workflow を確かめる

### DoD（完了条件）

- `main` への merge で `terraform-apply-prod.yml` と `terraform-apply-review.yml` が成功し、apply の変更 0、post-apply plan の変更 0 になる。
- 作業 branch から review の apply workflow を手動起動でき、変更 0 で成功する。
- 作業 branch から prod の apply workflow を手動起動すると、Environment `prod` の deployment branch の制限で job が動かない。

### Tasks

- [ ] `main` から `feature-258-terraform-on-github-actions` を切り、`feature-258` の Phase 1 の変更を取り込んで PR を作る（`Closes` なし。本文に「issue #258 の完了を意味しない」と書く。plugin の `development_flow/branch_pr_issue.md` の経路 2）
- [ ] 利用者に merge を依頼して止まる
- [ ] merge 後、両 apply workflow の成功と要約を確認する。S3 の `applies/` の全文で、prod は差分 0、review は SSM parameter の state からの削除だけで、post-apply plan が両方 0 であることを確認する。AWS 上に SSM parameter が残っていることを `aws ssm get-parameters-by-path --path /nanitabe-back/review/`（名前だけ）で確認する
- [ ] `main` を `feature-258` へ取り込む
- [ ] `gh workflow run terraform-apply-review.yml --ref feature-258` を実行し、成功を確認する
- [ ] `gh workflow run terraform-apply-prod.yml --ref feature-258` を実行し、job が Environment の制限で動かないことを確認する
- [ ] ここで作業を停止し、結果を利用者に確認する。次 phase へは進まない

## Phase 6: 手元の入口と値を片付け、docs を新しい経路へ書き換える

### DoD（完了条件）

- repository に `infrastructure/terraform/envs/{prod,review}/{init,apply}_terraform.sh` が無い。`.claude/settings.json` に review の apply script の allow が無い。
- `.env` に Terraform 専用の 8 key、`AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY`、`NEXT_PUBLIC_ASSET_ORIGIN` が無い。
- `.env` の AWS key を消した状態で、`scripts/review_backend/start.sh` と `stop.sh` が AWS CLI の設定の認証情報で動く。
- `infrastructure/README.md` と `review_environment.md` が新しい経路を説明している。

### Tasks

- [ ] 4 本の script を削除する
- [ ] `.claude/settings.json` から `Bash(bash infrastructure/terraform/envs/review/apply_terraform.sh)` を外す
- [ ] GitHub の repository secrets から `DB_NAME`、`DB_HOST`、`DB_PORT`、`DB_USER`、`DB_PASS`、`RAILS_MASTER_KEY`、`ROUTE53_HOSTZONE_ID`、`AWS_ACCOUNT_ID`、`AWS_CODE_CONNECTION_ID_TO_GITHUB`、`AMPLIFY_GITHUB_ACCESS_TOKEN`、`CI_JENKINS_URL`、`CI_JENKINS_NANITABE_BUILD_JOB_URL`、`CI_JENKINS_NANITABE_BUILD_TOKEN` を消すコマンド（`gh secret delete`）を示し、利用者に実行を依頼する
- [ ] `.env` から消す key の一覧を示し、利用者に削除を依頼して止まる（値を出さない `sed -i` のコマンドを添える）
- [ ] `start.sh` を実行して review 環境を起動し、`/graphql` へ `POST` して応答を確認してから `stop.sh` で停止する
- [ ] docs を書き換える（design の「更新する docs」の表）
  - [ ] `infrastructure/README.md`
  - [ ] `backend/docs/ai_guideline/development_standard/review_environment.md`（SSM parameter の値を変える経路が `put_ssm_parameters.sh` であることも書き足す）
  - [ ] emit 前に document-review を通す
- [ ] 変更を commit し、`feature-258` へ push する（PR の plan workflow が差分 0 で通ることを確認する）
- [ ] ここで作業を停止し、結果を利用者に確認する。次 phase へは進まない

## Phase 7: `main` を保護する

### DoD（完了条件）

- `main` の branch protection が、PR を経ない push を禁止している（`gh api repos/tumeda1992/nanitabe/branches/main/protection` で確認する）。

### Tasks

- [ ] 設定コマンド（`gh api -X PUT .../branches/main/protection`。PR 必須、required check なし）を用意し、利用者に実行を依頼して止まる
- [ ] 設定を読み取りで確認する。`main` への実際の push で試さない
- [ ] ここで作業を停止し、結果を利用者に確認する。次 phase へは進まない

## Phase 8: 品質check

### DoD（完了条件）

- 新規の Terraform file の `terraform fmt -check` と、両 root の `terraform validate` が通る。
- frontend と backend の全 test と lint が green（Terraform 以外の変更が無いことの確認）。

### Tasks

- [ ] `terraform fmt -check`（新規 file）と `terraform validate`（scratchpad、両 root）
- [ ] `docker compose exec backend bundle exec rspec`、`docker compose exec frontend yarn test`
- [ ] `docker compose exec backend bundle exec rubocop`、`docker compose exec frontend yarn lint`

## Documentation reviewと実装後振り返り

- [ ] code readingまたは実装で永続化候補を得た場合、その場でdoc-enricherを提案modeで適用する
  - [ ] 提案がある場合だけユーザー承認後に既存READMEまたは既存docsへ反映する
- [ ] 実装、review、validationからfeedbackまたは実装とのずれが生じた場合、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用する
  - [ ] 原文、関連する実装・design・plan、原因、採用方針、決定を渡し、修正済みでも記録を省略しない
  - [ ] 「共有されていなかった知識の前提は何か」「codeを読めば分かるか、設計意図か、process不足か」「どこに書けば次回この議論が不要になるか」を確認し、合意後だけ反映する
  - [ ] designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す。review後に実装を自動再開しない

---

## 動作確認

### DoD

Tasks に挙げた確認をユーザーが行い、期待どおりであることを確認した。

### Tasks

- [ ] ユーザーに動作確認を依頼する（Phase 4 の PR の要約コメントを読み、S3 の全文の取り寄せ方が README のとおりに使えること。本番の custom domain が今までどおり使えること）
- [ ] feedbackがあれば、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用し、decisionをcallerへ返す
  - [ ] feedbackがなければ`[x] ~~feedback収集~~（feedbackなし）`の形式で完了扱いにする

---

## 完了後のaction

> ⚠️ 動作確認phaseが完了するまでcommit、push、PRを促したり実行したりしない。急かすことも禁止する。Phase 4〜6 の commit・push・PR は、各 phase の検証に必要なため例外とする。

- [ ] 残りの変更を phase 単位かつ意味単位で commit し、`feature-258` を push する
- [ ] Phase 4 で作った PR の本文に `Closes #258` を加え、変更内容と確認結果を書く（issue #258 の完了の merge。plugin の `development_flow/branch_pr_issue.md` の経路 1）
- [ ] merge は利用者が行う

---

## 参照

- 設計の正本: 同じdirectoryの `./design.md`
- 完了条件、取消完了、subtask分割、checkbox更新timingの規則の正本: `tasklist-executor/SKILL.md`
- tasklistへ載せるtaskの範囲の正本: `task-design/tasklist-design.md`
