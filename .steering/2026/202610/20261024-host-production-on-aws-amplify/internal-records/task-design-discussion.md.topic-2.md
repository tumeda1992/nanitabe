# 内部検討記録: 論点2 — Amplify 移行と Terraform の Actions 移行の順序

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点2

## 開始context

論点1で、今回の範囲は「frontend の本番配信を Amplify Hosting へ移し旧構成を撤去する」と「Terraform の適用を GitHub Actions へ移す」の二つに決まった。

- 決める範囲: 二つをどちらから行うか。先に行う側が、後に行う側の実行経路（手元 apply か PR 経由の apply か）と、GitHub へ移す値と権限の範囲を規定する。
- 既決条件: 論点1の決定。現行の Terraform は `infrastructure/terraform/envs/prod` と `envs/review` の二つの root を持ち、どちらも host 上の `.env` を読む script で手元から適用する。
- 残る不足: 二つの順序が他の設計にどう効くかの比較。

<a id="iteration-0"></a>

## イテレーション0: どちらを先に行うか

<a id="iteration-0-record-1"></a>

### 調査: 順序によって GitHub へ移す値と apply role の権限がどう変わるか

#### 問いと探索範囲

- 問い: Actions 移行を先に行うと、何を GitHub secrets と apply role へ持たせる必要が生じるか。
- source: `infrastructure/terraform/envs/prod/main.tf`、`apply_terraform.sh`、`frontend/terraform/modules/cicd/codebuild/main.tf`、x_favorites の `terraform/modules/github_oidc/main.tf`。

#### 見つかった事実

- prod root の variable は、旧構成のために `aws_access_key`、`aws_secret_access_key`、`codebuild_artifact_s3_bucket`、`aws_code_connection_id_to_github`、`backend_origin` 等を受け取る。`aws_access_key` と `aws_secret_access_key` は CodeBuild の環境変数へ平文で渡され、定義側に `# TODO: secret化する` とある（`frontend/terraform/modules/cicd/codebuild/main.tf`）。
- x_favorites の apply role は、操作する service（Amplify、state の S3、OIDC 用の IAM）へ action を列挙した policy を持つ。nanitabe で先に Actions へ移すと、apply role は現行の prod root が操作する Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild、ACM、Route53 への権限を持つ必要がある。
- x_favorites は Amplify を手元 apply で成立させた後に Actions へ移した（`.steering/2026/202609/` の順序）。

#### 言える範囲

Actions を先に行うと、撤去予定の構成のために長期の IAM access key を GitHub secrets へ置き、撤去予定の service への権限を apply role へ付けることになる。どちらも Amplify 移行の後には不要になる。

<a id="iteration-0-record-2"></a>

### 判断: 順序

- 評価軸: GitHub へ置く secret と権限を最小にする。本番移行の作業中に、適用経路の変更という別の不確実性を重ねない。
- 推奨: Amplify 移行（旧構成の撤去まで）を先に、現行の手元 apply で行う。その後に Actions へ移す。Actions へ移す時点の variable と権限は、Amplify 構成と state 用 resource の分だけになる。
- 代償: Amplify 移行の間だけ、Amplify が GitHub へ接続するための値を host 上の `.env` へ置く。Actions 移行時に GitHub secrets へ移す。
