# 内部検討記録: 論点6 — Amplify 移行の Terraform 構成

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点6

## 開始context

論点3〜5で決めた手順を、Terraform の定義としてどこにどう書くか。

- 決める範囲: Amplify module の配置、手順 (2) で custom domain を旧 CloudFront から外す方法、custom domain の関連付けの形、Amplify が GitHub へ接続する token の受け渡し、手順 (5) で消す定義と variable。
- 既決条件: 論点1〜5。`infrastructure/terraform/envs/prod` が root で、`frontend/terraform/envs/prod` を module として呼ぶ二層構成（`infrastructure/README.md`）。
- 残る不足: 旧 CloudFront module の custom domain の持ち方、同じ hosted zone を別の Amplify app が使っている場合の制約。

<a id="iteration-0"></a>

## イテレーション0: 定義の配置と変え方

<a id="iteration-0-record-1"></a>

### 調査: 旧構成の定義と、domain の関連付けの制約

#### 見つかった事実

- `frontend/terraform/modules/cloudfront/main.tf` は custom domain を必須の variable として受け、distribution の `aliases`、`viewer_certificate.acm_certificate_arn`（`module "cert"`、us-east-1）、`module "dns"`（A / AAAA alias record）で使う。custom domain を外す切替口は無い。
- prod root（`infrastructure/terraform/envs/prod/main.tf`）の variable のうち、`aws_account_id`、`aws_access_key`、`aws_secret_access_key`、`codebuild_artifact_s3_bucket`、`aws_code_connection_id_to_github`、`branch` は旧構成の ECR・Lambda・CI/CD だけが使う。`route53_zone_id` は旧構成の証明書と record だけが使う。us-east-1 の provider は CloudFront 用証明書だけが使う。
- tracked な定義は `frontend/terraform/modules/` 配下の apigateway、cicd、cloudfront（cert、dns を含む）、ecr、lambda、s3/for_assets と、それぞれの `test/`、`frontend/terraform/envs/prod/main.tf`、`frontend/terraform/values/values.tf`（`appname = "nanitabe-front"`）、`frontend/terraform/envs/review/.gitkeep`。
- x_favorites の Amplify module は、親 domain を `domain_name` に渡し、branch ごとの `prefix` を `sub_domain` に並べる。証明書は `*.<親 domain>` のワイルドカード形式になる。x_favorites の app は nanitabe と同じ AWS account・同じ hosted zone を使っている（x_favorites の `20260906-deploy-amplify-with-terraform/design.md`）。
- 同じ root domain を別の Amplify app へ関連付けると「already associated with another Amplify app」で拒否される事例がある一方、API（CLI）から root domain と別の prefix を指定すれば複数 app で共有できたという報告もある（AWS re:Post の質問 QU6qqfnHGLSMS19OnpEw1Gyw、QU-lRKkSuHQUmIW6b49fXRDA）。公式文書での明記は確認できていない。

#### 言える範囲

手順 (2) のために旧 CloudFront module へ custom domain の有無を切り替える口を足す必要がある。親 domain を共有する関連付けが通るかは未実測で、手順 (3) の apply で確かめるしかない。

<a id="iteration-0-record-2"></a>

### 判断: 構成

- 推奨: discussion の提案0のとおり。
- 親 domain の共有が拒否された場合の扱い: 手順 (3) で止まり、(2) を戻す apply で旧構成へ戻して design へ戻る。代わりに `domain_name` を `nanitabe.<hosted zone>` 自体にすると、後から足す review branch が `review.nanitabe.<hosted zone>` になり、「hosted zone のレコードはフラットな 1 ラベルにする」前提を崩すため、その場で決めない。
