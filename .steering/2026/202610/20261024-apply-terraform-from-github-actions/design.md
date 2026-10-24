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

TBD: 終了時に成立する状態を、後続の論点の決定後に追記する。

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

TBD: workflow の構成、OIDC と role、secrets、state の lock、spike の持ち方、branch protection、移行の手順。

### runtime・設定・環境構築

TBD

---

## 要件（Requirements）

### MUST（必達）

- TBD

### SHOULD（できれば）

- TBD

### MAY（あれば嬉しい）

- TBD

### 非目標

- 親 phase の scope外のすべて。

### 受け入れ基準

- TBD

---

## リスクと対策

| リスク | 対策 |
| --- | --- |
| TBD | TBD |

---

## テスト方針

- TBD

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

なし

### task-design内の対象成果物反映待ち

なし

### execution plan対象

なし

### 分類保留（設計中のみ）

| 変更候補 | 保留理由 | 分類を確定するdecision |
| --- | --- | --- |
| workflow、OIDC、role、secrets、README の更新 | 目的と実行場所の原則が未合意 | Actions へ移す目的と、Terraform を実行してよい場所の原則 |
