# infrastructure

AWS 上のインフラを Terraform で定義する場所。

## 構成

```text
infrastructure/terraform/
├── values/values.tf        # appname = "nanitabe"
├── modules/github_oidc/    # GitHub Actions が assume する AWS role（README あり）
└── envs/
    ├── prod/               # 本番。state key = prod/terraform.tfstate
    ├── review/             # 動作確認環境。state key = review/terraform.tfstate
    └── verify-infra/       # module がローカル実行で動くかを確かめる spike 用（README 参照）
```

`envs/*` が root module であり、各アプリケーションの `terraform/envs/*` を module として呼ぶ。

| env | 呼ぶ module | 中身 |
| --- | --- | --- |
| `prod` | `state_in_s3`、`frontend/terraform/envs/prod`、`github_oidc` | Terraform state 用の S3 と DynamoDB、frontend の Amplify app（branch と custom domain を含む）、GitHub Actions 用の role |
| `review` | `backend/terraform/envs/review` | backend の動作確認環境。ECR、ECS、API Gateway、CI/CD |

state を分けているため、`review` への適用が `prod` の resource を対象にしない。逆も同じ。
`verify-infra` の spike は local state を使い、prod と review の state には触れない。

## 適用のしかた

`prod` と `review` の plan と apply は GitHub Actions だけが行う。手元から実行しない。

```text
PR を出す  → plan workflow が動き、要約が PR コメントに出る
merge する → apply workflow が動き、続けて plan して差分が空であることを確かめる
```

| workflow | 起動 | 行うこと |
| --- | --- | --- |
| `terraform-plan-prod.yml`、`terraform-plan-review.yml` | `main` への PR（同じ repository の branch から。対象 root の file を変えたときだけ）、手動 | plan role で plan。全文を S3 へ保存し、要約を PR コメントへ出す |
| `terraform-apply-prod.yml` | `main` への push、手動 | Environment `prod` の apply role で apply。続けて plan し、差分が空であることを確かめる |
| `terraform-apply-review.yml` | `main` への push、任意の branch からの手動 | Environment `review` の apply role で apply。手動起動のときは、plan に destroy が 1 件でもあれば apply せず失敗する |

- 4 本が共有する手順は `.github/actions/terraform-run/` にある。各 workflow は root、role、`TF_VAR_*` の対応だけを持つ。
- `TF_VAR_*` の元の値は GitHub の repository secrets にある。secret 名は旧 `.env` の key 名に揃えている。apply role の ARN だけは Environment secrets（`prod`、`review`）にある。
- Terraform に通す値は、resource の定義に Terraform 自身が必要とし、AWS から引けない値だけにする。AWS から引ける識別子（zone の ID、account ID、CodeConnections の connection）は data source で引く。認証情報と鍵は通さない（Amplify の GitHub token、review の DB 接続情報と `RAILS_MASTER_KEY`）。

### 出力の読み方

repository は public で、Actions の log と PR コメントは誰でも読める。plan / apply の全文には domain 名、account ID、zone ID が含まれるため、log にも PR コメントにも出さない。

- PR コメントと log に出るのは、resource の種別ごとの create / update / delete / replace / forget の件数と、destroy の件数だけである。destroy が 0 でなければ merge の前に全文を読む。
- 全文は state 用 bucket の `plans/<root>/<run id>.txt`（plan）と `applies/<root>/<run id>.txt`（apply）へ保存される。要約に key が書かれている。非公開で暗号化済みである。

```sh
aws s3 ls                                                        # state 用 bucket の名前を確かめる
aws s3 cp "s3://<state 用 bucket>/plans/review/<run id>.txt" - | less
```

認証情報は AWS CLI の設定（`~/.aws/`）から得る。

- Terraform のエラーメッセージに値が混ざる可能性は残る。失敗した run は log を確認し、値が出ていれば当該 run の log を削除する。

### review の apply を試す

review の定義を試すために `main` へ merge する必要は無い。作業 branch から `terraform-apply-review.yml` を手動起動する（`gh workflow run terraform-apply-review.yml --ref <branch>`）。destroy を含む plan では apply せず失敗する。`terraform-apply-prod.yml` を作業 branch から起動しても、Environment `prod` の deployment branch が `main` だけのため動かない。

### 初回の bootstrap

GitHub Actions が AWS に接続するための role（`modules/github_oidc/`）だけは、role が無いと Actions が動かないため、手元から一度だけ apply した。以後は Actions が適用し、この role 自身の変更も PR から行う。

### spike（verify-infra）

手元で Terraform を実行してよいのは、module がローカル実行で動くかを確かめる spike だけである。方針は [`envs/verify-infra/README.md`](./terraform/envs/verify-infra/README.md) にある。prod と review の apply を手元から行わない決まりは、構成ではなく規範が担保する。

### `main` の保護

branch protection で PR を経ない push を禁止している。required check は置かない（paths で絞った workflow を required にすると、Terraform に触れない PR が merge できなくなるため）。

## review 環境に固有の注意

### review の変更は PR の要約で destroy を確かめてから merge する

`main` への merge での review の apply は、destroy の有無を自動では止めない（手動起動の apply だけが止める）。PR の要約の先頭にある destroy の件数を見て、0 でなければ全文を読んでから merge する。destroy を一律に止めるのは、destroy が「失敗しても再実行で回復できる」前提を崩すためである（理由は [`review_environment.md`](../backend/docs/ai_guideline/development_standard/review_environment.md)）。

### review の SSM parameter は Terraform の管理外

`/nanitabe-back/review/` の `DB_NAME`、`DB_HOST`、`DB_PORT`、`DB_USER`、`DB_PASS`、`RAILS_MASTER_KEY` は Terraform の管理外で、AWS 上に残っている。値を GitHub secrets と Terraform の state の両方に残さないためである。task definition の `valueFrom` と task execution role の `ssm:GetParameters` は、名前から組み立てた ARN で参照する。値を変えるときは `scripts/review_backend/put_ssm_parameters.sh`（`.env` から読む）を実行する。代償として parameter の存在が IaC に現れず、script と task definition が同じ名前を使うことで対応を保つ。

### `terraform apply` は起動中の review 環境を落とす

`review` 環境の ECS service は、Terraform の定義上 `desired_count = 0` を持つ。
`lifecycle { ignore_changes = [desired_count] }` は付けていない。

そのため、環境が起動している最中に `terraform apply` を実行すると、`desired_count` が 0 へ戻され、環境が停止する。

これは意図した挙動である。「停止している状態が正しい」を定義が表し、起動は一時的な逸脱として扱う。
定義と実態がずれたまま放置されるより、apply が常に停止側へ倒れるほうが、止め忘れによる課金を生まない。

環境を使っている最中に構成を変えたい場合は、先に停止してから apply する。

### 実行時の状態は Terraform が持たない

起動・停止のたびに変わる値は Terraform の管理外にある。

| 値 | 誰が変えるか |
| --- | --- |
| ECS service の `desired_count` | `scripts/review_backend/start.sh` が 1 へ、`stop.sh` と EventBridge Scheduler が 0 へ |
| API Gateway の integration URI | 同上。起動時に task の public IP を指し、停止時に到達しない値へ戻る |

integration URI については、Terraform 側で `lifecycle { ignore_changes = [integration_uri] }` を設定している。
`desired_count` と扱いが逆なのは、両者が表すものが違うためである。

- `desired_count` は「起動しているべきか」という**意図**。apply が停止側へ倒れることに意味がある。
- integration URI は「今どの task を指しているか」という**実体との対応**。
  apply が実体と食い違う値を書き込むと、service は動いているのに到達できないという中途半端な状態が生まれる。

### 停止中にかかる費用

停止中も課金される resource を、次の 3 つに限っている。合計で月 $0.3 程度。

- ECR の image 保存。lifecycle policy で最新 1 世代だけを残している。
- CloudWatch Logs の保存。取り込み側の課金は起動中にしか発生しない。
- CloudWatch alarm 1 つ。止め忘れの検知に使う。

存在するだけで時間課金が発生する resource（ALB、RDS、NAT Gateway、Elastic IP）と Secrets Manager、
Container Insights は構成に含めていない。
構成を変えるときは、この前提を崩さないか確認する。

resource を構成へ含めるかを金額で判断する基準は [`cost_judgment.md`](./cost_judgment.md) にある。
課金モデルの見分け方、損益分岐の出し方、サービス別の要点を扱う。

## 構成上の前提

新しい resource を足すときに、既に成立している前提。崩す場合は影響を確認する。

- **network**: VPC は default の 1 つだけで、subnet は 3 つとも public。
  private subnet と NAT Gateway を持たない。private subnet に置く前提の構成は、NAT Gateway の新設を伴う。
- **GitHub と AWS の関係**: GitHub Actions が OIDC で AWS の role を assume して Terraform を適用する。
  OIDC identity provider は同じ account の別 repository（x_favorites）の Terraform が所有し、この repository は参照するだけである（[`modules/github_oidc/README.md`](./terraform/modules/github_oidc/README.md)）。
  plan role は PR と任意の branch から、apply role は Environment（`prod`、`review`）からだけ assume できる。
  AWS の access key は GitHub にも `.env` にも置かない。
  repository は public のため、plan / apply の出力の全文は log に出さず非公開の S3 へ保存する（「適用のしかた」）。
  backend の deploy は AWS 側（CodePipeline / CodeBuild）が `CodeStarSourceConnection` で GitHub を見る形にする。
  frontend の deploy は Amplify が GitHub の personal access token で repository を見て、`main` への push で build する。
  token は Terraform に通さず、手元で更新する（[`frontend/terraform/modules/amplify/README.md`](../frontend/terraform/modules/amplify/README.md)）。
  `.github/workflows/` は test と lint のほか、Terraform の plan と apply を行う。
- **CPU architecture**: container の build と実行を ARM で統一する。
  CodeBuild は `ARM_CONTAINER`、Fargate は `ARM64`。
- **課金**: resource を足すかどうかを金額で判断するときは [`cost_judgment.md`](./cost_judgment.md) を見る。
  時間課金と保存・件数課金を分けて考え、防ぐ対象の損失と固定費を並べて比べる。
- **環境の分け方**: 本番と動作確認環境（review）は、同じ module を `stage` 違いで呼び、resource を環境ごとに別の実体として持つ。
  本番の resource の中に review 用の変種（Amplify の branch、Lambda の alias、API Gateway の stage 等）を作って共用しない。
  変種の仕組みは resource の種類ごとに違い、無いものもあるため、共用すると review の定義が本番と review の root にまたがる。
  どうしても共用しなければならない制約があるものだけを例外として共用し、その制約を記録する。
  判断の問い: 「これを review 用に別の実体として作れない制約は何か。それを書けるか」
- **ログの lifecycle**: application が出すログ（Next.js の SSR、Rails の request log など）は、
  それを実行する AWS resource より長く残る前提で置く。application のログを入れる log group は、
  実行基盤の resource と同じ destroy の単位に入れない。resource 固有のログ（API Gateway の
  access log など、その resource の振る舞いだけを記録するもの）は、resource と同じ lifecycle でよい。
  判断の問い: 「この resource を作り直した後や撤去した後にも、このログを見返したいか」
- **host 名**: hosted zone へ置くレコードはフラットな 1 ラベルにする。sub-sub ドメインを掘らない。
  domain 名は `.env` の `ROUTE53_HOSTZONE_NAME` から渡し、terraform の定義にも document にも直接書かない。
- **API Gateway v2 の管理 API 権限**: EventBridge Scheduler 等の AWS SDK 統合から apigatewayv2 の操作
  （`UpdateIntegration` 等）を呼ぶ場合、IAM policy は HTTP verb ベースの action（`apigateway:PATCH` 等）で与える。
  `apigatewayv2:UpdateIntegration` のような friendly な action 名は評価されず、`AccessDenied` になる。
- **EC2 系 resource の `description` は ASCII のみ**: `aws_security_group` 等の `description` 属性へ
  日本語を書くと `InvalidParameterValue` で失敗する。設計意図は属性値ではなく HCL コメント（`#`）へ書く。

## 環境の使い方

review 環境へ何を載せ、どう起動して確認するかは、
[`review_environment.md`](../backend/docs/ai_guideline/development_standard/review_environment.md) にある。
