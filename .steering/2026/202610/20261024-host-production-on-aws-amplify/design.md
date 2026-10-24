# Design: 本番環境を AWS Amplify で構築する

## 元の依頼内容

~/src/github.com/tumeda1992/x_favorites でamplifyで本番環境をAWSに構築できるようになったから、真似したい

---

## TL;DR

学習を兼ねて自前で組んだ frontend の配信基盤（Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild）は、Amplify Hosting が managed に提供しているものと同じだった。この自前構成を Amplify Hosting へ移して保守対象を減らし、今後の動作確認環境を自前構成の複製ではなく branch の追加で作れる土台にする。現行の CodeBuild は build 中の apt で特定の version を取得できず本番 build が失敗しており、本番 deploy が止まっているため移行を急ぐ。作業は二段に分ける。先に「Amplify 移行」で本番配信を Amplify へ移して旧構成を撤去し、本番 build の停止を解消する。続く「Terraform の Actions 移行」で、Terraform の適用を手元から GitHub Actions へ移す。

終了時には、`main` への push で Amplify が frontend を build・配信し、custom domain で応答する。旧構成の AWS resource と定義は残らない。Terraform の変更は PR で plan され、`main` への merge で apply される。

この design が詳細まで確定させるのは「Amplify 移行」までである。「Terraform の Actions 移行」は目的、scope、完了条件までを確定し、詳細は「Amplify 移行」の結果を入力にして、その段階の設計で決める（[段階の分け方](#段階の分け方)）。

---

## 完成後の姿

### workflow

#### 段階の分け方

```text
phase「Amplify 移行」                     phase「Terraform の Actions 移行」
  本番配信を Amplify へ移し、        →        Amplify 移行後の root の適用を
  旧構成を撤去する                            GitHub Actions へ移す
  （この design で詳細まで確定）              （この design では目的・scope・完了条件まで）
```

| phase | この design で確定する範囲 | 完了時点で成立すること |
| --- | --- | --- |
| Amplify 移行 | 下記「移行の手順」と「runtime・設定・環境構築」のすべて | 本番 frontend が Amplify で配信され、`main` への push で deploy される。旧構成の resource と定義が無い。Terraform は現行どおり手元 apply で運用できる |
| Terraform の Actions 移行 | 目的、scope、scope外、完了条件 | `infrastructure/terraform/envs/prod` と `envs/review` の変更が PR で plan され、`main` への merge で apply される。値を必要とする `terraform plan` / `apply` は GitHub Actions だけで実行される |

「Terraform の Actions 移行」の次の事項は、その段階の設計で決める。apply role に要る権限と GitHub secrets へ移す値は、「Amplify 移行」の後に root に残る resource と variable の実物で決まるためである。

- 二つの root（`envs/prod`、`envs/review`）それぞれの workflow と、`envs/review` の destroy 拒否判定・agent の実行権限の扱い
- OIDC の identity provider、plan 用・apply 用 role と、その権限の範囲（IAM role を作る権限を含むか）
- host の `.env` から GitHub secrets へ移す値（`envs/review` の DB 接続情報と `RAILS_MASTER_KEY` を含む）
- state の lock（現行の DynamoDB を続けるか）
- `infrastructure/README.md` の「GitHub 側に AWS の credentials も OIDC の信頼設定も置かない」前提の書き換え
- branch protection の扱い

段階を分けるのは、Actions 移行の設計完了まで Amplify 移行の実行（本番 build 停止の解消）を待たせず、かつ Actions 移行をこのテーマの完了条件に残すためである。別の steering に分けると、Actions 移行を行う義務がこのテーマから消える。順序を Amplify 移行から始めるのは、Actions 移行を先に行うと、旧構成のための長期 IAM access key を GitHub secrets へ置き、撤去予定の service への権限を apply role へ付けることになるためである。

#### 移行の手順

Amplify 移行は、現行の手元 apply（`infrastructure/terraform/envs/prod` の `apply_terraform.sh`）で次の順に行う。

```text
(1) Amplify app を custom domain なしで作る
      → Amplify の default domain で機能を確認する
(2) 旧 CloudFront から custom domain を外す apply
      （distribution の alias、us-east-1 の ACM 証明書、Route53 の A / AAAA record）
      旧 distribution と Lambda は残す
(3) Amplify へ custom domain を関連付ける apply → 証明書の検証完了を待つ
(4) custom domain で機能を確認する
(5) 旧構成の残り（CloudFront、API Gateway、Lambda、S3、ECR、CodePipeline、CodeBuild）を撤去する apply
```

(1) は、Amplify が監視する branch を次のように移しながら進める。

```text
(1-a) Amplify app を branch_names = ["feature-258"] で作る
        → feature-258 の default domain で build と機能を確認する
        （amplify.yml の試行錯誤はこの branch で行う）
(1-b) 確認済みの amplify.yml と frontend/next.config.js の変更だけを、
        main から切った feature-258-amplify-build-config から main へ PR で入れる
        （Closes を付けない途中 merge。本文に「issue #258 の完了を意味しない」と書く）
(1-c) branch_names = ["feature-258", "main"] にして apply
        → main の default domain で build と機能を確認する
(1-d) branch_names = ["main"] にして apply し、feature-258 を外す
```

- (3) で custom domain を関連付ける先は `main` である。
- 作業 branch から始めるのは、Amplify は監視 branch に `amplify.yml` が無いと build できず、試行錯誤のたびに `main` へ merge しないためである。
- 「追加してから外す」順にするのは、`branch_name` の差し替えが Amplify branch resource の再作成になり、`main` を確認する前に `feature-258` の環境が消えるためである。
- (1-b) は plugin の `development_flow/branch_pr_issue.md` の経路 2 にあたる。branch 名は context が宣言する `feature-<issue番号>` から issue 番号を一意に引ける形を保ったまま、本線と区別する。`main` の Amplify build を (1-a) と同じ構成にするため、`frontend/next.config.js` の変更も含める。
- (1-b) の merge で旧 CodePipeline と `backend-deploy.yml` が一度起動する。旧 CodePipeline の build は apt の取得で失敗中のため Lambda を更新しない。backend は差分が無いため挙動を変えない。

- (2) から (3) の証明書検証完了までは本番 URL が応答しない。利用しない時間帯に行う。利用者がほぼ本人だけ（`frontend/README.md`「想定ユーザ」）であるため、停止時間を避ける仕組みは作らない。
- (3) または (4) で失敗したら、(2) を戻す apply（旧 distribution へ alias、証明書、record を戻す）で旧構成へ戻す。(5) を行うまでこの rollback の手段を残す。
- 外してから付ける順序にするのは、CloudFront の alternate domain name が distribution 間で重複できず、Amplify Hosting も内部で CloudFront を使うためである。重複が実際に拒否されるかは (3) の apply で実測する。
- (1) の確認を default domain で行えるのは、backend の CORS が `origins "*"`（`backend/config/application.rb`）で frontend の origin を限定せず、認証 token を frontend 側の cookie で持つためである。

#### Amplify 移行後の deploy

| owner | 判断・更新するもの | 行わないこと |
| --- | --- | --- |
| 開発者 | `main` への PR の merge | Amplify の build を手で起動しない |
| Amplify | `main` への push を契機に `amplify.yml` で build し、成功した build を配信する。失敗した build は配信しない | Amplify app の設定（環境変数、branch、domain）を変えない |
| Terraform（「Amplify 移行」完了時点では手元 apply、「Terraform の Actions 移行」完了後は GitHub Actions） | Amplify app の設定、branch、custom domain | build と配信を行わない |

- build が失敗した場合、Amplify は前回成功した build の配信を続ける。原因を直して `main` へ push し直す。
- アプリケーションの rollback は、Amplify の過去の成功 build へ再 deploy して行う。

### runtime・設定・環境構築

**実行条件と設定:**

| identifier / dependency | 値または解決元 | default | 影響する挙動 |
| --- | --- | --- | --- |
| `amplify.yml`（repository 直下） | `applications[0].appRoot: frontend`。`preBuild` で `nvm install 24` と `node -v`、`yarn install --frozen-lockfile`。`build` で `yarn build`。artifacts の `baseDirectory: .next`。cache は `.next/cache` と `node_modules` | なし | Amplify が push を契機に `frontend/` を build する。Tailwind の `build:css` は `yarn build` が随伴する |
| Amplify app の `platform` | `WEB_COMPUTE` | なし | Next.js の server 側描画を Amplify の managed SSR で実行する |
| `AMPLIFY_MONOREPO_APP_ROOT` | Amplify app の環境変数。値は `frontend` | なし | monorepo の app root を Amplify に伝える。`amplify.yml` の `appRoot` と一致させる |
| `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` | Amplify app の環境変数。値は host の `.env` の同名の値を `apply_terraform.sh` が `TF_VAR_backend_origin` として渡す | なし | build 時に bundle へ埋め込まれ、`generateApiOrigin.ts` が本番の backend の origin として返す |
| `NEXT_PUBLIC_ENVIRONMENT` | 設定しない | 未設定 | 未設定なら `generateApiOrigin.ts` が本番の分岐へ入る |
| `frontend/next.config.js` | `assetPrefix` と `compress: false` を削除する | Next.js の既定 | static asset を Amplify が同じ origin から配信する。圧縮は Next.js の既定に戻る |
| access gate | 置かない | なし | 本番 URL へ誰でも到達でき、application のログインが認証を担う |

**環境別の完成状態:**

| environment | 配置・起動条件 | 観測可能な結果 |
| --- | --- | --- |
| local | 変更なし。`docker compose` の `frontend` container | 現行どおり |
| CI | 変更なし。`ci-frontend-build-verification.yml` | 現行どおり |
| production | Amplify app が監視 branch への push で build・配信する | custom domain で frontend が応答し、本番 backend を呼ぶ |

**不足・不整合時:**

- Amplify の build image で Node 24 を使えない: 移行手順 (1) の build log で検知し、(1) で止まって design へ戻る。
- `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` が未設定: build は成功するが、画面から backend を呼べない。移行手順 (1) の機能確認で検知する。

**残すもの:**

- `/system/warmup` の route。Lambda の cold start 対策として作られたが、route 自体は Lambda に依存しない。repository 内に呼び出し元は無い。

**設計意図:**

- x_favorites との差は monorepo、yarn、Node version の三点である。build の条件は PR ごとに通っている `ci-frontend-build-verification.yml` に合わせる。
- `NEXT_PUBLIC_` の値は build 時に埋め込まれるため、Amplify の環境変数が build container にしか届かないという x_favorites の制約は当たらない。`.env.production` への書き出しは行わない。
- x_favorites は application に認証が無いため Basic authentication を置いた。nanitabe は application のログイン（`frontend/src/app/login`、backend の devise）があるため置かない。

**Terraform の配置:**

```text
infrastructure/terraform/envs/prod/main.tf      root。variable の追加・削除だけを行う
frontend/terraform/
├── envs/prod/main.tf                           module "amplify" を呼ぶ。手順 (5) で旧 module の呼び出しを消す
├── modules/
│   ├── amplify/main.tf                         新設
│   └── apigateway/ cicd/ cloudfront/ ecr/      手順 (5) で test/ ごと削除
│       lambda/ s3/
└── values/values.tf                            変えない（appname = "nanitabe-front"）
frontend/buildOnLambda/                         手順 (5) で削除
```

`modules/amplify` は x_favorites の module から Basic authentication を除いた形とする。

| resource | 設定 |
| --- | --- |
| `aws_amplify_app` | name `${appname}-${stage}`（`nanitabe-front-prod`）、repository `https://github.com/tumeda1992/nanitabe`、`access_token = var.github_access_token`、`platform = "WEB_COMPUTE"`、`environment_variables` は上表の `AMPLIFY_MONOREPO_APP_ROOT` と `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`。`build_spec` は書かない（書くと repository の `amplify.yml` より優先されるため） |
| `aws_amplify_branch` | `for_each = toset(var.branch_names)`、`enable_auto_build = true` |
| `aws_amplify_domain_association` | `custom_domain` が null の間は作らない。`domain_name = var.route53_name`（hosted zone の親 domain）、`sub_domain` は `{ branch_name = "main", prefix = "nanitabe" }` の一組、`wait_for_verification = false` |

移行手順の各段階での入力値:

| 段階 | `branch_names` | `custom_domain` | `modules/cloudfront` の `enable_custom_domain` |
| --- | --- | --- | --- |
| (1-a) | `["feature-258"]` | null | true |
| (1-c) | `["feature-258", "main"]` | null | true |
| (1-d) | `["main"]` | null | true |
| (2) | `["main"]` | null | false |
| (3) 以降 | `["main"]` | `var.route53_name` | false（(5) で module ごと削除） |

**手順 (2) の切替口:** `modules/cloudfront` に bool の variable `enable_custom_domain` を足す。false のとき、distribution の `aliases` を空にし、`viewer_certificate` を CloudFront の既定証明書（`cloudfront_default_certificate = true`）にし、`module "cert"` と `module "dns"` を作らない。rollback は true へ戻す apply で行う。この module は (5) で消えるため、足すのは切替に必要な分だけである。

**variable:**

| variable | 供給元 | 扱い |
| --- | --- | --- |
| `amplify_github_access_token`（sensitive、新設） | host の `.env` の `AMPLIFY_GITHUB_ACCESS_TOKEN` を `apply_terraform.sh` が export | Amplify が GitHub repository へ接続する。`tumeda1992/nanitabe` だけを対象にした fine-grained personal access token（Contents: read、Metadata: read、Webhooks: read and write） |
| `backend_origin`、`route53_name` | 現行どおり | 残す |
| `aws_account_id`、`aws_access_key`、`aws_secret_access_key`、`codebuild_artifact_s3_bucket`、`aws_code_connection_id_to_github`、`branch`、`route53_zone_id` と us-east-1 の provider | 現行どおり | 旧構成だけが使う。(5) で prod root と `frontend/terraform/envs/prod` から消し、`apply_terraform.sh` の対応する export も消す |

**設計意図:**

- custom domain を親 domain と branch ごとの prefix で関連付けるのは、後から review branch を足すときに prefix を一組増やすだけで、`review-nanitabe.<hosted zone>` のようなフラットな 1 ラベルの名前を作れるためである（`infrastructure/README.md`「構成上の前提」の host 名）。
- 同じ account の別の Amplify app が同じ親 domain をすでに関連付けている。共有が通るかは公式文書で確認できておらず、手順 (3) の apply で実測する。拒否された場合は (2) を戻す apply で旧構成へ戻し、design へ戻る。`domain_name` を `nanitabe.<hosted zone>` 自体にする代替は、review branch がフラットな 1 ラベルの前提を崩すため、その場では採らない。

**「Amplify 移行」で更新する docs:**

| 対象 | 更新後に書かれていること |
| --- | --- |
| `infrastructure/README.md` の構成表 | `prod` env の中身を「Terraform state 用の S3 と DynamoDB、frontend の Amplify app」にする |
| `infrastructure/README.md`「構成上の前提」の GitHub と AWS の関係 | frontend の deploy は Amplify が personal access token で GitHub を見る形であることを書き足す。OIDC と credentials の前提の書き換えは「Terraform の Actions 移行」で行う |
| `frontend/README.md`「インフラ」 | 本番は Amplify Hosting（`WEB_COMPUTE`）で配信し、build 設定は repository 直下の `amplify.yml`、定義は `frontend/terraform/modules/amplify/` にあること |
| `frontend/terraform/modules/amplify/README.md`（新設） | この module が持つもの・持たないもの（build 設定は `amplify.yml`、Route53 の record は Amplify が作る）、`build_spec` を書かない理由、branch を「追加してから外す」順序と git branch を先に作る必要、custom domain を親 domain と prefix で持つ理由、`NEXT_PUBLIC_` 以外の値を実行時に渡す場合は build 時に `.env.production` へ書き出す必要があること |
| `frontend/docs/ai_guideline/development_standard/docker.local.md` | 「CI と Lambda イメージビルドでは」を「CI と Amplify の build では」にする |
| `frontend/entrypoint.sh` のコメント | 「Lambdaに載せるイメージのビルド」を「Amplify の build」にする |

---

## 要件（Requirements）

### MUST（必達）

- frontend の本番配信を Amplify Hosting へ移す。
- 移行後に旧構成（Lambda、API Gateway、CloudFront、static asset 用 S3、ECR、CodePipeline、CodeBuild と、それを定義する `frontend/terraform/` 配下・`frontend/buildOnLambda/`）を撤去する。
- Terraform の適用を GitHub Actions へ移す。Amplify 移行（旧構成の撤去まで）を現行の手元 apply で先に終えてから行う。旧構成のための長期 IAM access key と撤去予定 service への権限を、GitHub secrets と apply role へ持ち込まないため。
- Amplify 構成は branch を list で持ち、custom domain を branch ごとの sub domain の集合で持つ。後から review branch を足す作業を list への追加で済ませるため。
- 作業を phase「Amplify 移行」→ phase「Terraform の Actions 移行」の順に分け、「Amplify 移行」の完了時点で本番が正常に利用できる状態にする。
- 旧構成の撤去までは、旧 CloudFront へ custom domain を戻す rollback の手段を残す。

### SHOULD（できれば）

なし

### MAY（あれば嬉しい）

なし

### 非目標

- frontend の常設 review branch は作らない。frontend の review がどの backend を指すかという、本番移行と無関係な設計判断を持ち込むため。本番移行の後に別 branch で行う。
- backend の本番 deploy は変えない。Amplify Hosting は Rails の server を動かす service ではなく、backend の本番 deploy はこの repository の Terraform の管理外である。
- custom domain の切替中の停止時間を避ける仕組みは作らない。利用者がほぼ本人だけで、利用しない時間帯に切り替えれば影響が無いため。
- local の開発環境と CI は変えない。

### 受け入れ基準

phase「Amplify 移行」:

- custom domain（`https://nanitabe.<hosted zone>`）を開くと、Amplify が配信した frontend が応答し、証明書が有効である。
- その画面でログインし、カレンダー画面で献立が表示される（本番 backend の GraphQL を呼べている）。
- static asset（`/_next/static/...`）が custom domain と同じ origin から配信されている。
- `main` へ frontend の変更を push すると、Amplify の build が起動し、成功後に custom domain の内容が入れ替わる。
- AWS 上に旧構成の resource（Lambda、API Gateway、CloudFront distribution、static asset 用 S3、ECR、CodePipeline、CodeBuild、us-east-1 の証明書、旧 A / AAAA record）が残っていない。
- `infrastructure/terraform/envs/prod` で `terraform plan` が `No changes` になる。
- 「Amplify 移行で更新する docs」の表の内容が各 file に反映されている。

phase「Terraform の Actions 移行」:

- 完了条件は「段階の分け方」の表のとおり。受け入れ基準の詳細はその段階の設計で決める。

---

## リスクと対策

| リスク | 対策 |
| --- | --- |
| 同じ account の別の Amplify app が同じ親 domain を関連付け済みで、domain の関連付けが拒否される | 手順 (3) の apply で実測する。拒否されたら手順 (2) を戻す apply で旧構成へ戻し、design へ戻る |
| Amplify の build image で Node 24 を使えない | 手順 (1-a) の build log で確認する。使えなければ (1-a) で止まって design へ戻る。旧構成には触れていないため本番への影響は無い |
| 旧 distribution が custom domain を外しても Amplify 側の検証が進まず、停止が長引く | (3) の後、Amplify の domain association の status と Route53 の検証 record を確認する。利用しない時間帯に始め、戻すと決めたら (2) を戻す apply を行う |
| 旧構成の撤去後に不具合が見つかる | 撤去は (4) の確認後に行う。撤去後のアプリケーションの不具合は Amplify の過去の成功 build へ再 deploy して戻す |
| GitHub personal access token の失効で Amplify が repository を見られなくなる | token の期限と必要な権限を `frontend/terraform/modules/amplify/README.md` に書く。失効時は token を更新して apply する |

---

## テスト方針

- application code の変更は `frontend/next.config.js` の設定削除だけで、振る舞いを変える分岐を足さない。既存の `yarn test`、`yarn lint`、`ci-frontend-build-verification.yml` が通ることを確認する。
- Terraform の変更は、各 apply の前に `terraform plan` の差分が移行手順の段階どおりであること（意図しない destroy が無いこと）を確認する。
- 本番の動作は、移行手順 (1-a)、(1-c)、(4) で受け入れ基準の画面操作（ログイン、カレンダー画面の表示、static asset の配信元）を確認する。(1-a)・(1-c) は Amplify の default domain、(4) は custom domain で行う。

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

| 対象 | 掲載理由 | 参照するdesign section |
| --- | --- | --- |
| `amplify.yml`、`frontend/next.config.js`、`frontend/terraform/modules/amplify/`、`frontend/terraform/envs/prod/main.tf`、`frontend/terraform/modules/cloudfront/`、`infrastructure/terraform/envs/prod/`、旧構成の定義の削除、AWS への apply | 本番 infrastructure の runtime behavior を変え、順序依存する複数段階の apply と中間確認、rollback 境界を持つ | [移行の手順](#移行の手順)、[runtime・設定・環境構築](#runtime設定環境構築) |
| 「Amplify 移行で更新する docs」の各 file | 上記の実装と同じ phase で事実が確定する。`frontend/entrypoint.sh` は本番成果物の一部 | [runtime・設定・環境構築](#runtime設定環境構築) |
| Terraform の適用を GitHub Actions へ移す変更一式 | 本番 infrastructure の適用経路を変え、OIDC の初回構築など順序依存の段階を持つ | [段階の分け方](#段階の分け方) |
