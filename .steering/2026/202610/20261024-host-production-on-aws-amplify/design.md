# Design: 本番環境を AWS Amplify で構築する

## 元の依頼内容

~/src/github.com/tumeda1992/x_favorites でamplifyで本番環境をAWSに構築できるようになったから、真似したい

---

## TL;DR

学習を兼ねて自前で組んだ frontend の配信基盤（Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild）は、Amplify Hosting が managed に提供しているものと同じだった。この自前構成を Amplify Hosting へ移して保守対象を減らし、今後の動作確認環境を自前構成の複製ではなく branch の追加で作れる土台にする。あわせて Terraform の適用を手元から GitHub Actions へ移す。

TBD: 終了時に成立する状態（配信、deploy、Terraform の適用経路）を、後続の論点の決定後に一文で書く。

---

## 完成後の姿

### workflow

TBD: 上位の WHY と scope の合意後に、変更後の deploy 経路（誰が何を契機に build・配信するか）と、Terraform の適用経路の owner を描く。

### runtime・設定・環境構築

TBD: scope 合意後に、Amplify の platform、build 設定、frontend が build 時・実行時に必要とする値の供給元、custom domain、旧構成（Lambda / API Gateway / CloudFront / CodePipeline）の扱いを描く。

---

## 要件（Requirements）

### MUST（必達）

- frontend の本番配信を Amplify Hosting へ移す。
- 移行後に旧構成（Lambda、API Gateway、CloudFront、static asset 用 S3、ECR、CodePipeline、CodeBuild と、それを定義する `frontend/terraform/` 配下・`frontend/buildOnLambda/`）を撤去する。
- Terraform の適用を GitHub Actions へ移す。
- Amplify 構成は branch を list で持ち、custom domain を branch ごとの sub domain の集合で持つ。後から review branch を足す作業を list への追加で済ませるため。
- TBD: 後続の論点で追加する。

### SHOULD（できれば）

- TBD

### MAY（あれば嬉しい）

- TBD

### 非目標

- frontend の常設 review branch は作らない。frontend の review がどの backend を指すかという、本番移行と無関係な設計判断を持ち込むため。本番移行の後に別 branch で行う。
- backend の本番 deploy は変えない。Amplify Hosting は Rails の server を動かす service ではなく、backend の本番 deploy はこの repository の Terraform の管理外である。
- TBD: 後続の論点で追加する。

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

- frontend の本番配信: Next.js を container image にして Lambda（`aws-lambda-adapter`）で動かし、API Gateway を origin とする CloudFront から配信している。`_next/static` と `public` は image build 中に S3 へ同期し、CloudFront の別 origin から配信する。確認元: `frontend/README.md`、`frontend/buildOnLambda/Dockerfile`、`frontend/terraform/envs/prod/main.tf`。
- frontend の本番 deploy: CodePipeline が `CodeStarSourceConnection` で GitHub の branch を監視し、CodeBuild（ARM）が image を build して ECR へ push、Lambda の image を更新し、CloudFront を invalidate する。確認元: `frontend/terraform/modules/cicd/`、`frontend/terraform/modules/cicd/codebuild/buildspec.yml`。
- frontend が backend を指す値: `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` を image build 時に build arg として渡し、`frontend/src/lib/generateApiOrigin.ts` が development 以外でこの値を返す。asset の配信元は `NEXT_PUBLIC_ASSET_ORIGIN` を `next.config.js` の `assetPrefix` に使う。
- frontend の custom domain: `frontend/terraform/envs/prod/main.tf` が `nanitabe.${var.route53_name}` を CloudFront へ割り当てる。domain 名は `.env` の `ROUTE53_HOSTZONE_NAME` から渡す。
- backend の本番 deploy: `.github/workflows/backend-deploy.yml` が `main` への merge 時に外部 webhook を呼ぶ。この repository の Terraform の管理外である。
- Terraform の構成: `infrastructure/terraform/envs/prod` が root で、`state_in_s3`（S3 と DynamoDB）と `frontend/terraform/envs/prod` を module として呼ぶ。`init_terraform.sh` / `apply_terraform.sh` が host 上の `.env` を読み `TF_VAR_*` へ export して手元から適用する。確認元: `infrastructure/README.md`。
- 構成上の前提: GitHub 側に AWS の credentials も OIDC の信頼設定も置かず、deploy は AWS 側が GitHub を見る形にする。`.github/workflows/` は test と lint だけを行う。container の build と実行は ARM に統一する。hosted zone のレコードはフラットな 1 ラベルにする。確認元: `infrastructure/README.md`「構成上の前提」。
- 参考元 x_favorites の構成: `aws_amplify_app`（`platform = "WEB_COMPUTE"`、GitHub personal access token で接続、app レベルの Basic authentication）、`aws_amplify_branch`（`main` と常設の `review`）、`aws_amplify_domain_association`。build 設定は repository 直下の `amplify.yml`。Amplify の環境変数は build container にしか渡らないため、`amplify.yml` の build phase で明示列挙した変数を `.env.production` へ書き出して SSR runtime へ届ける。Terraform は GitHub Actions が OIDC で AWS role を assume し、PR で plan、`main` への merge で apply する。state は S3 の native lockfile で排他する。確認元: x_favorites の `terraform/README.md`、`terraform/modules/amplify/README.md`、`amplify.yml`。

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
| Amplify の Terraform 定義、`amplify.yml`、旧構成の撤去 | 実行順序と適用経路が未決 | Amplify 移行と Actions 移行の順序 |
| GitHub Actions の workflow と OIDC 定義 | 実行順序と適用対象の env が未決 | Amplify 移行と Actions 移行の順序 |
| `infrastructure/README.md`、`frontend/README.md` 等の docs 更新 | 内容が後続 decision に依存する | 後続の各論点 |
