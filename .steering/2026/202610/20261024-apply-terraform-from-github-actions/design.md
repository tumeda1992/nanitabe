# Design: Terraform の適用を GitHub Actions へ移す

## 元の依頼内容

~/src/github.com/tumeda1992/x_favorites でamplifyで本番環境をAWSに構築できるようになったから、真似したい

（親 roadmap の phase `terraform-on-github-actions` として起動した。）

## 上位roadmap制約（子phaseの場合のみ）

- 親roadmap: `.steering/2026/202610/20261024-host-production-on-aws-amplify/roadmap.md`
- 親phase identity: `terraform-on-github-actions`
- 親phaseの目的: `infrastructure/terraform/envs/prod` と `envs/review` の適用を GitHub Actions へ移し、Terraform の変更が PR で plan され、`main` への merge で apply される状態にする。
- 親phaseのscope: 二つの root の plan・apply workflow、OIDC の identity provider と plan 用・apply 用の AWS role、host の `.env` から GitHub secrets へ移す値の移動、state の lock の扱い、`infrastructure/README.md`「構成上の前提」の GitHub と AWS の関係の書き換えと適用手順の更新、branch protection の扱い、module をローカル実行で Terraform が動くか確かめる用途を新しい構成でどう持つか（「値を必要とする Terraform は Actions だけで実行する」方針と両立させる）。
- 親phaseのscope外: Amplify app の構成と frontend の配信、frontend の常設 review branch、backend の本番 deploy。
- 親phaseのDoD: `envs/prod` と `envs/review` の変更を含む PR で `terraform plan` の結果が PR に出る。`main` への merge で `terraform apply` が実行され、適用後の `terraform plan` が `No changes` になる。値を必要とする `terraform plan` / `apply` を実行する場所が GitHub Actions だけになっている。`infrastructure/README.md` が新しい適用経路と前提を説明している。本番 frontend と backend の review 環境が、移行前と同じく利用できる。
- 依存phaseの確定結果:
  - `envs/prod` の resource は `state_in_s3`（S3 と DynamoDB）と `frontend` module の Amplify（app、branch `main`、domain association）だけになった。variable は `bucket_name`、`dynamodb_table_name`、`backend_origin`、`route53_name`、`amplify_github_access_token`。
  - `envs/prod/apply_terraform.sh` が読む `.env` の key は `TERRAFROM_STATE_S3_BUCKET`、`TERRAFROM_STATE_DYNAMODB_TABLE`、`NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`、`ROUTE53_HOSTZONE_NAME`、`AMPLIFY_GITHUB_ACCESS_TOKEN`。AWS の認証情報も同じ `.env` から読む。
  - 実施中の逸脱（子 steering `20261024-migrate-frontend-hosting-to-amplify/implementation_review.md`）: Claude Code の auto mode の分類器が agent による本番 Terraform の apply を拒否し、allow rule でも解けなかった。各 apply は利用者が `!` で実行した（論点3）。
  - 旧構成の `verify-infra` 環境を撤去した。新しい構成には、module をローカル実行で確かめる手段がまだ無い（論点8）。

---

## TL;DR

`infrastructure/terraform/envs/prod` と `envs/review` の適用を手元から GitHub Actions へ移し、PR で plan の差分を読み `main` への merge で apply される形にする。誰が apply するかを毎回判断せず、適用の履歴を PR と workflow に残し、apply が利用者と agent の往復にならないようにするためである。prod と review の state へ書き込むのは Actions だけとし、手元では module をローカル実行で確かめる spike だけを別の state で行う。

終了時には、`envs/prod` と `envs/review` の Terraform の変更は PR で plan され、要約が PR コメントに、全文が非公開の S3 に残る。`main` への merge で apply され、適用後の plan が `No changes` であることを workflow が確かめる。手元の Terraform の script と、`.env` の Terraform 専用の値と AWS の認証情報は無くなり、手元で apply するのは verify-infra だけになる。

---

## 完成後の姿

### workflow

#### Terraform を実行してよい場所

| 実行するもの | 場所 | 使う state |
| --- | --- | --- |
| `envs/prod`、`envs/review` の `plan` / `apply` | GitHub Actions だけ | S3 の `prod/`、`review/` key |
| module がローカル実行で動くかの spike | 手元 | local state。stage 名を prod / review と重ねない |
| `fmt`、`validate` | 手元でも Actions でも | なし |

- 手元から prod / review の state を扱う入口（各 root の `init_terraform.sh` / `apply_terraform.sh`）は取り除く。
- 手元の AWS 認証情報と値は spike のために残る。「手元で prod / review を apply しない」は構成ではなく規範で担保する。参考元 x_favorites は terraform だけが使う値の一部を手元へ置かないことで、手元で plan / apply を実行できないことを構成として担保したが、nanitabe では spike 用途を残すためこの形を採らない。

#### plan / apply の出力の公開範囲

repository は public であり、Actions の log と PR コメントは誰でも読める。plan / apply の全文には hosted zone の domain 名、ARN 内の AWS account ID、Route53 の zone ID が含まれる。

- plan / apply の全文は Actions の log に出さず、state 用の S3 bucket（非公開、暗号化済み）へ保存する。
- PR コメントと log に出すのは、resource の種別ごとの add / change / destroy の件数と destroy の有無だけとする。
- 全文は利用者か agent が `aws s3 cp` で取り寄せて読む。
- エラー時の Terraform のメッセージに値が混ざる可能性は残る。

#### workflow の構成

| file | 起動条件 | 行うこと |
| --- | --- | --- |
| `.github/workflows/terraform-plan-prod.yml` | `main` への PR（同じ repository の branch からだけ）、手動起動。paths: `infrastructure/terraform/envs/prod/**`、`infrastructure/terraform/modules/**`、`frontend/terraform/**`、`.terraform-version`、自身、`.github/actions/terraform-run/**` | plan role で `terraform plan -out`。全文を S3 へ保存し、要約を PR コメントへ出す（同じ PR では既存コメントを更新） |
| `.github/workflows/terraform-apply-prod.yml` | `main` への push、手動起動。paths は上と同じ | apply role で `terraform apply`。続けて plan し、差分が空であることを確かめる。全文は S3、log には結果の要約だけ |
| `.github/workflows/terraform-plan-review.yml` | 同上。paths: `infrastructure/terraform/envs/review/**`、`backend/terraform/**`、`.terraform-version`、自身、`.github/actions/terraform-run/**` | 同上 |
| `.github/workflows/terraform-apply-review.yml` | `main` への push（paths は上と同じ）と、**任意の branch からの手動起動** | apply role（review）で apply。手動起動のときは plan を保存し、destroy（replace を含む）が 1 件でもあれば apply せず job を失敗させる。それ以外は prod の apply と同じ |

- 4 file に共通する手順（checkout、`setup-terraform`、OIDC での role の assume、`init`、出力の S3 保存と要約）は `.github/actions/` の composite action に置く。各 workflow file は root、role、`TF_VAR_*` の対応だけを持つ。
- 要約は、resource の種別ごとの add / change / destroy の件数と、destroy の有無を先頭に示す。resource のアドレスと値は出さない。
- 全文の保存先は state 用 bucket の `plans/<root>/<run id>.txt`（plan）と `applies/<root>/<run id>.txt`（apply）。要約には保存先の key を書く。
- plan と apply を同じ file に入れないのは、`AdministratorAccess` を持つ apply role を条件分岐で切り替えると、書き誤りで PR から apply role を assume する経路ができるためである。prod と review を同じ file に入れないのは、`paths` が workflow file 単位でしか書けず、一つの file で root を選ぶには第三者の action か自作の判定 script が apply の経路に入るためである。
- review root の `apply_terraform.sh` が持っていた destroy の拒否判定は、review の手動起動の apply へ移す。`main` への merge での apply では、PR の要約の先頭に destroy の有無を示し、人が読んで merge する。判定は resource の種類を区別せず一律に止める。destroy が「失敗しても再実行で回復できる」前提を崩すため（理由は `review_environment.md` に記載）。
- apply の job は GitHub の Environment（`prod`、`review`）を指定する。`prod` の deployment branch は `main` だけ、`review` は制限しない。review の変更を merge すると起動中の review 環境は `desired_count = 0` に戻って停止する。これは現行の手元 apply と同じ挙動である。

#### 適用の実行者

| 操作 | 誰が行うか |
| --- | --- |
| Terraform の定義の変更、PR の作成 | agent |
| PR の plan の要約と全文を読み、merge する | 利用者（agent は全文を `aws s3 cp` で取り寄せて要約を補える） |
| apply（prod） | `main` への merge を契機に Actions |
| apply（review） | `main` への merge を契機に Actions。agent は作業 branch から手動起動して試せる（destroy を含む plan では止まる） |
| verify-infra の apply と destroy | 手元（`infrastructure/terraform/envs/verify-infra/README.md`） |

`backend/docs/ai_guideline/development_standard/review_environment.md`「review 環境に閉じる操作」が agent に事前確認なしで許していた「review state に対する `terraform plan`」と「destroy を含まない `terraform apply`」は、「作業 branch から review の apply workflow を手動起動すること」へ置き換わる。agent が事前確認なしで行ってよいことは変わらない。review の定義を試すために先に `main` へ merge する必要は無い。

#### 移行の手順

```text
(1) infrastructure/terraform/modules/github_oidc/ を追加し、envs/prod から呼ぶ
    → 利用者の手元 apply で OIDC と role を作る（手元からの最後の prod apply）
(2) 利用者が GitHub の Environments（prod、review）を作り、script で repository secrets と、Environment secrets（apply role の ARN）を登録する
(3) workflow 4 本、composite action、lock file、.terraform-version を feature-258 に追加する
    → feature-258 の PR で plan workflow が動き、要約コメントと S3 の全文を確認する
(4) 派生 branch からの途中 merge（Closes なし）で main へ入れる
    → apply workflow が No changes で通ることを確認する
(5) 手元の init_terraform.sh / apply_terraform.sh（prod と review）を削除し、.claude/settings.json の review apply の allow を外す
    GitHub の repository secrets から DB_*、RAILS_MASTER_KEY、ROUTE53_HOSTZONE_ID、AWS_ACCOUNT_ID、AWS_CODE_CONNECTION_ID_TO_GITHUB、AMPLIFY_GITHUB_ACCESS_TOKEN、CI_JENKINS_* を削除する（利用者）
    .env から Terraform 専用の 8 key と AWS の access key を消す（利用者）
    infrastructure/README.md と review_environment.md を新しい経路へ書き換える
(6) branch protection を設定する（利用者）
(7) feature-258 の PR に Closes #258 を付けて merge する（roadmap の完了）
```

- (1) を手元で行うのは、role が無いと Actions が AWS に接続できないためである。agent は手元の apply を実行できないため、(1) の apply は利用者が `!` で行う。
- (4) は plugin の `development_flow/branch_pr_issue.md` の経路 2 で、派生 branch から出す。本線 `feature-258` は (7) まで使う。(4) で差分が出れば、(1) の定義か secrets の値の誤りである。
- branch protection は PR の merge を妨げないため、どの段階で設定してもよい。直接 push が拒否されることを、新しい経路が動いた後に確かめるため最後に置く。

### runtime・設定・環境構築

**OIDC と role:**

| resource | 設定 |
| --- | --- |
| OIDC identity provider | `token.actions.githubusercontent.com`、audience `sts.amazonaws.com`。account に一つしか作れず、同じ account の別 repository（x_favorites）の Terraform が所有している。nanitabe は作らず、URL で引く data source で参照する |
| plan role | 信頼条件 `repo:tumeda1992/nanitabe:pull_request` と手動起動。権限は `ReadOnlyAccess`、state 用 S3 bucket の読み書き（`plans/`・`applies/` の保存を含む）、lock 用 DynamoDB の読み書き |
| apply role（prod） | 信頼条件 `repo:tumeda1992/nanitabe:environment:prod` だけ。権限は `AdministratorAccess` |
| apply role（review） | 信頼条件 `repo:tumeda1992/nanitabe:environment:review` だけ。権限は `AdministratorAccess` |

- 定義は `infrastructure/terraform/modules/github_oidc/` に置き、`envs/prod` から呼ぶ。plan role は prod と review で共有し、apply role は環境ごとに分ける。review だけ任意の branch から apply できるようにするためで、branch の制限は Environment の deployment branch の設定が持つ。
- apply role の権限を列挙しないのは、review root が IAM role を作るため列挙が実質的な制限にならず、resource を足すたびの更新が保守対象を増やすためである。review の role を名前で絞らないのは、Route53 の zone を prod と共有しており、絞っても prod の record を書ける余地が残るためである。`main` への直接 push を防ぐのは branch protection が担う。

**GitHub secrets:** prod と review の値は repository secrets に置き、Environment secrets には apply role の ARN だけを置く。plan の job は Environment を指定できない（指定すると OIDC の `sub` が `environment:*` になり plan role の信頼条件と合わない）ため、plan が必要とする値は repository secrets でなければ読めない。plan は作業 branch で動き prod の値を必要とするため、作業 branch の job から prod の値を読めなくする分離はどの構成でも成立しない。

| 区分 | secret | workflow での渡し先 |
| --- | --- | --- |
| 共通（repository） | `AWS_TERRAFORM_PLAN_ROLE_ARN` | `aws-actions/configure-aws-credentials` |
| prod / review（Environment） | `AWS_TERRAFORM_APPLY_ROLE_ARN`（Environment ごとに別の値） | `aws-actions/configure-aws-credentials` |
| 共通（repository） | `TERRAFROM_STATE_S3_BUCKET`、`TERRAFROM_STATE_DYNAMODB_TABLE` | `terraform init` の `-backend-config`、`TF_VAR_bucket_name`、`TF_VAR_dynamodb_table_name` |
| 共通（repository） | `ROUTE53_HOSTZONE_NAME` | `TF_VAR_route53_name`（zone の ID もこの名前から data source で引く） |
| prod（repository） | `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` | `TF_VAR_backend_origin` |
| review（repository） | `CODEBUILD_ARTICACT_S3_BUCKET`、`REVIEW_BACKEND_ALARM_EMAIL` | review root の同名の `TF_VAR_*` |

- secret 名は `.env` の key 名に揃える。AWS の access key は置かない。
- Terraform に通す値は、resource の定義に Terraform 自身が必要とし、AWS から引けない値だけにする。AWS から引ける識別子は data source で引き、認証情報や鍵は Terraform に通さない。
  - `ROUTE53_HOSTZONE_ID` は `data "aws_route53_zone"`（`ROUTE53_HOSTZONE_NAME` から）、`AWS_ACCOUNT_ID` は `data "aws_caller_identity"`、`AWS_CODE_CONNECTION_ID_TO_GITHUB` は `data "aws_codestarconnections_connection"`（connection の名前から）で引く。
  - `AMPLIFY_GITHUB_ACCESS_TOKEN` は `aws_amplify_app` に `lifecycle { ignore_changes = [access_token] }` を付け、variable を既定値 `null` の optional にする。token の更新は手元で `aws amplify update-app --access-token` を行う。app を作り直すときだけ値を個別に渡す。作成時の値は state に残っており、この phase では消さない。
  - DB の接続情報と `RAILS_MASTER_KEY` は GitHub にも Terraform にも置かない（下の「review の SSM parameter」）。
  - Jenkins から n8n への移行で参照されなくなった `CI_JENKINS_*` の repository secrets も、移行手順 (5) で一緒に削除する。
- 登録は `.env` を読んで `gh secret set` する script を scratchpad に用意し、利用者が `!` で実行する。値は chat と log に出さない。

**review の SSM parameter:**

- `/nanitabe-back/review/` の `DB_NAME`、`DB_HOST`、`DB_PORT`、`DB_USER`、`DB_PASS`、`RAILS_MASTER_KEY` は Terraform の管理から外す。`backend/terraform/modules/ssm/` を削除し、`removed` block（`lifecycle { destroy = false }`）で state から外す。AWS 上の parameter は消さない。
- ECS の task definition の `valueFrom` と task execution role の `ssm:GetParameters` は、parameter の ARN を名前から組み立てて参照する。
- 値は `scripts/review_backend/put_ssm_parameters.sh`（新設）が `.env` から読み、`aws ssm put-parameter --type SecureString --overwrite` で書く。AWS CLI の設定の認証情報を使う。値を変えたときに実行する。
- 値を Terraform に通さないのは、通すと GitHub secrets と Terraform の state（`aws_ssm_parameter` は value を state に持つ）の両方に値が残るためである。値だけ `ignore_changes` にしても、refresh で AWS の値が state へ読み込まれる。代償として parameter の存在が IaC に現れず、script と task definition が同じ名前を使うことで対応を保つ。

**state、lock、再現性:**

- state の lock は DynamoDB のまま使う。
- 両 root の `.terraform.lock.hcl` を追跡対象にし（`.gitignore` の `**/.terraform.lock.hcl` を外す）、`linux_amd64` と `darwin_arm64` の hash を持たせる。Actions の `terraform init` は `-lockfile=readonly`。
- repository 直下に `.terraform-version` を置く。

**`main` の保護:** branch protection で PR を経ない push を禁止する。required check は設定しない（paths で絞った workflow を required にすると、Terraform に触れない PR が merge できなくなるため）。

**手元の `.env` と AWS 認証情報:**

| key | 扱い |
| --- | --- |
| `RAILS_MASTER_KEY`、`DB_*`、`FRONTEND_PROD_HOST`、`BACKEND_PROD_HOST`、`NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`、`ROUTE53_HOSTZONE_NAME`、`AWS_DEFAULT_REGION` | 残す |
| `AMPLIFY_GITHUB_ACCESS_TOKEN`、`AWS_ACCOUNT_ID`、`ROUTE53_HOSTZONE_ID`、`CODEBUILD_ARTICACT_S3_BUCKET`、`AWS_CODE_CONNECTION_ID_TO_GITHUB`、`REVIEW_BACKEND_ALARM_EMAIL`、`TERRAFROM_STATE_S3_BUCKET`、`TERRAFROM_STATE_DYNAMODB_TABLE` | 移行手順 (5) で消す。値は AWS、GitHub、利用者自身から再取得できる |
| `AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY` | 移行手順 (5) で消す。手元で AWS を操作するもの（review の start / stop script、verify-infra、その場の AWS CLI）は AWS CLI 自身の設定（`~/.aws/config`・`~/.aws/credentials`、必要なら `AWS_PROFILE`）から認証情報を得る |
| `NEXT_PUBLIC_ASSET_ORIGIN` | 今回消す（どこからも参照されない） |

- 認証情報の置き場所を AWS CLI の設定に一本化するのは、置き場所が複数あるとどれが使われるかが export の有無で変わり、`docker-compose.yml` の `env_file` を通じて app container にも入るためである。IAM user の access key は無効化しない。
- review 環境の起動・停止（`scripts/review_backend/start.sh`・`stop.sh`）は Terraform ではなく AWS CLI の script であり、手元に残る。`ROUTE53_HOSTZONE_NAME` のため `.env` を export し続ける。

**verify-infra:** 方針は `infrastructure/terraform/envs/verify-infra/README.md` が持つ（task-design 内で作成済み）。spike 用の root は必要になったときに作り、`modules/amplify/test/` は今回作らない。

**更新する docs:**

| 対象 | 更新後に書かれていること |
| --- | --- |
| `infrastructure/README.md` | 構成表に verify-infra を加える。「適用のしかた」を、PR の plan と merge の apply、出力の要約と S3 の全文、手動起動、初回の bootstrap（OIDC と role だけは手元 apply）に書き換える。「review 環境に固有の注意」から `apply_terraform.sh` の destroy 判定の記述を、PR の要約で destroy を確かめる記述へ置き換える。「構成上の前提」の GitHub と AWS の関係を、OIDC で role を assume して Actions が適用する形と、public repository のため出力の全文を公開しないことへ書き換える |
| `backend/docs/ai_guideline/development_standard/review_environment.md`（SSM） | 「閉じているように見えて該当しないもの」の SSM parameter の項に、値を変える経路が `put_ssm_parameters.sh` であることを書き足す |
| `backend/docs/ai_guideline/development_standard/review_environment.md` | 「review 環境に閉じる操作」の review state への手元の `terraform plan` / `apply` を、作業 branch からの review の apply workflow の手動起動へ置き換える（destroy を外す理由は task-design 内で追記済み） |
| `.claude/settings.json` | `Bash(bash infrastructure/terraform/envs/review/apply_terraform.sh)` の allow を外す |

---

## 要件（Requirements）

### MUST（必達）

- 親 phase の DoD のすべて。
- plan / apply の全文を Actions の log と PR コメントに出さない。
- prod の apply role は `main` からしか assume できない。review の apply role は review の Environment からしか assume できない。
- repository の file と `.env` に AWS の認証情報を持たない。
- DB の接続情報と `RAILS_MASTER_KEY` を GitHub secrets と Terraform の state に持たない。AWS から引ける識別子と `AMPLIFY_GITHUB_ACCESS_TOKEN` を GitHub secrets に持たない。

### SHOULD（できれば）

なし

### MAY（あれば嬉しい）

なし

### 非目標

- 親 phase の scope外のすべて。
- review 環境の起動・停止の Actions 化。
- IAM user の access key の無効化。
- 既存の Terraform file の fmt。

### 受け入れ基準

- `frontend/terraform/` を変える PR で `terraform-plan-prod.yml` が動き、PR コメントに要約（種別ごとの件数と destroy の有無）が出て、全文が S3 の `plans/prod/` にある。`backend/terraform/` を変える PR では review の plan が同じく動く。Terraform に触れない PR ではどちらも動かない。
- PR コメントと workflow の log に、domain 名、account ID、zone ID が出ていない。
- `main` への merge で apply workflow が動き、適用後の plan が `No changes` で job が成功する。
- 作業 branch から review の apply workflow を手動起動でき、destroy を含む plan では apply せず失敗する。作業 branch から prod の apply role は assume できない。
- repository に `init_terraform.sh` / `apply_terraform.sh` が無く、`.env` に Terraform 専用の 8 key と AWS の access key が無い。review の `start.sh` / `stop.sh` が AWS CLI の設定の認証情報で動く。
- GitHub secrets に `DB_*` と `RAILS_MASTER_KEY` が無く、review root の state に SSM parameter が無い。review 環境を起動すると、task が SSM から値を読んで起動し `/graphql` が応答する。
- `main` への直接 push が拒否される。
- 本番の custom domain と review 環境（起動して `/graphql` を叩く）が移行前と同じく使える。
- `infrastructure/README.md` と `review_environment.md` の手順だけを読んで、Terraform の変更を PR から適用できる。

---

## リスクと対策

| リスク | 対策 |
| --- | --- |
| plan の要約処理の誤りで全文が log に出る | composite action の要約は `terraform show -json` から件数だけを数え、Terraform の標準出力は file へ redirect する。最初の PR で log と コメントを目視で確かめる |
| Terraform のエラーメッセージに値が混ざって log に出る | 受け入れる（「plan / apply の出力の公開範囲」）。エラー時は log を確認し、出ていれば当該 run の log を削除する |
| apply role の信頼条件の誤りで PR や作業 branch から prod を apply できる | 信頼条件の `sub` を `environment:prod` に固定し、`prod` Environment の deployment branch を `main` に制限する。(3) の PR と作業 branch から prod の apply role を assume できないことを確かめる |
| 途中 merge (4) で apply が想定外の差分を適用する | (3) の PR の plan で差分が無いことを確認してから merge する |
| review の Terraform の変更の merge が起動中の review 環境を止める | 現行と同じ挙動。README の注意に残す |

---

## テスト方針

- Terraform の定義（`github_oidc` module）は `terraform validate` を通し、(1) の手元 apply の plan を確認する。
- workflow は、(3) の PR で plan の要約・S3 の全文・log に値が出ないことを、(4) の途中 merge で apply と post-apply plan の `No changes` を実測する。
- review の `start.sh` / `stop.sh` を `.env` の AWS key を消した状態で実行し、起動と停止ができることを確かめる。

---

## （付録）前提とする既存仕様

- Terraform の root: `infrastructure/terraform/envs/prod`（state key `prod/terraform.tfstate`）と `envs/review`（state key `review/terraform.tfstate`）。state は S3、lock は DynamoDB。各 root の `init_terraform.sh` / `apply_terraform.sh` が host の `.env` を読み、`TF_VAR_*` を export して手元から適用する。確認元: `infrastructure/README.md`。
- `envs/review/apply_terraform.sh` は plan を file へ保存し、destroy を含む変更が 1 件でもあれば apply せず異常終了する。review 環境では agent が permission を持ってこの script を実行する前提で、差分確認を人の目視に委ねず script 自身が行う。`.claude/settings.json` に `Bash(bash infrastructure/terraform/envs/review/apply_terraform.sh)` の allow がある。確認元: `infrastructure/README.md`、`backend/docs/ai_guideline/development_standard/review_environment.md`。
- review 環境の ECS service は Terraform 定義上 `desired_count = 0` を持ち、起動中に apply すると停止する。確認元: `infrastructure/README.md`。
- `envs/review` の variable には DB の接続情報（`db_name`、`db_host`、`db_port`、`db_user`、`db_pass`）、`rails_master_key`、`review_backend_alarm_email` などの sensitive な値を含む。
- 構成上の前提: GitHub 側に AWS の credentials も OIDC の信頼設定も置かない。deploy は AWS 側が GitHub を見る形にし、`.github/workflows/` は test と lint だけを行う。確認元: `infrastructure/README.md`「構成上の前提」。
- 参考元 x_favorites の Actions 化: `terraform-plan.yml`（PR で plan、差分を PR コメントへ出し、destroy を先頭に明示）と `terraform-apply.yml`（`main` への push で apply し、続けて plan の差分が空であることを確認）の二つの workflow を持ち、plan 用と apply 用の role を OIDC で assume する。`TF_VAR_*` は GitHub の repository secrets から渡す。terraform だけが使う値の一部を手元へ置かないことで、手元で plan / apply を実行できないことを構成として担保する。state の lock は S3 の native lockfile。確認元: x_favorites の `terraform/README.md`、`.github/workflows/terraform-*.yml`。

---

## （付録）変更の実行区分

### task-design内で対象成果物へ適用済み

| 対象 | 反映内容 | validation結果 | 参照するdesign section |
| --- | --- | --- | --- |
| `infrastructure/terraform/envs/verify-infra/README.md` | verify-infra の用途、使う場面と使わない場面、使い方を新設 | 利用者が置き場所を指定し内容を確認中 | [runtime・設定・環境構築](#runtime設定環境構築) |
| `backend/docs/ai_guideline/development_standard/review_environment.md` | 「閉じる範囲でも緩めないこと」に、destroy を閉じる操作から外す理由と、判定を一律にする理由を追記 | 現行の `apply_terraform.sh` の判定と矛盾しないことを目視で確認 | [workflow の構成](#workflow-の構成) |

### task-design内の対象成果物反映待ち

なし

### execution plan対象

| 対象 | 掲載理由 | 参照するdesign section |
| --- | --- | --- |
| `github_oidc` module、workflow 4 本、composite action、lock file、`.terraform-version`、script の削除、`.env` と settings の整理、docs、branch protection | 本番 infrastructure の適用経路を変え、手元 apply・secrets 登録・途中 merge・保護設定と順序依存の段階を持つ | [移行の手順](#移行の手順)、[runtime・設定・環境構築](#runtime設定環境構築) |
