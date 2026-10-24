# Tasklist: frontend の本番配信を Amplify へ移す

設計参照: `./design.md`（完成後の姿の正本は `../20261024-host-production-on-aws-amplify/design.md`）

以下で「親 design」は `../20261024-host-production-on-aws-amplify/design.md` を指す。
apply は常に `infrastructure/terraform/envs/prod` で `./init_terraform.sh` → `./apply_terraform.sh` の順に実行し、`terraform apply` が表示する plan を確認してから承認する。
plan に、その phase で想定した resource 以外の変更（特に destroy）が含まれていたら承認せず停止し、利用者へ報告する。

## Phase 1: Amplify 移行の定義を用意する（AWS と remote は変えない）

### DoD（完了条件）

- `feature-258` の working copy に、親 design の (1-a) を apply できる定義が揃い、`terraform validate` が通る。
- `frontend/` で `yarn test`、`yarn lint` が通り、`docker compose restart frontend` 後の `entrypoint.sh` による `NODE_ENV=production yarn build` が成功する（`next.config.js` の変更後も build が成立する）。
- `frontend/terraform/modules/amplify/README.md` が親 design の docs 表のとおりに書かれている。
- AWS 上の resource と remote の branch はまだ変わっていない。

### Tasks

- [x] `amplify.yml` を repository 直下に作る
- [x] `frontend/next.config.js` から `assetPrefix` と `compress: false` を削除する
  - [x] `yarn test`、`yarn lint` を container 内で実行し green を確認する。build は `docker compose restart frontend` で確認する（`docker compose exec frontend yarn build` は使わない）
    > 結果: `yarn test` 192 件 green、`yarn lint` error 0。build は steering 側が 20:29:40 に `docker compose restart frontend` で確認済み（`✓ Compiled successfully in 5.9s`、`✓ Generating static pages (19/19)`、`✓ Ready in 1927ms`、container Up）。以前の useContext エラーは NODE_ENV=development で build したことが原因。
- [x] `frontend/terraform/modules/amplify/main.tf` を作る
- [x] `frontend/terraform/modules/cloudfront/` に `enable_custom_domain` を足す
- [x] `frontend/terraform/envs/prod/main.tf` から `module "amplify"` を呼び、入力値を (1-a) の値にする
- [x] prod root と `apply_terraform.sh` に `amplify_github_access_token` を足す
- [x] `terraform fmt` と `terraform validate` を通す
  > 結果: scratchpad に複製して `init -backend=false` の後 `terraform validate` が Success（provider 宣言の warning は既存どおり）。`fmt` は新規 module のみ適用（既存 file は元から fmt 非準拠で、一括適用は無関係な差分を生むため対象外）。
- [x] `frontend/terraform/modules/amplify/README.md` を作る
  > document-review: 濃さ・記法・指示対象・機密性（domain、account ID、本番 backend の所在なし）を確認済み。
- [x] code reading で永続化候補を得た場合、その場で doc-enricher を提案 mode で適用する
  > 結果: 候補は amplify module README に反映済みの内容のみ。追加提案なし（cloudfront の count 化と moved block は main.tf のコメントに記載）。

### 各task詳細

#### `amplify.yml` を repository 直下に作る

親 design の「実行条件と設定」の `amplify.yml` 行のとおり。

```yaml
version: 1
applications:
  - appRoot: frontend
    frontend:
      phases:
        preBuild:
          commands:
            - nvm install 24
            - node -v
            - yarn install --frozen-lockfile
        build:
          commands:
            - yarn build
      artifacts:
        baseDirectory: .next
        files:
          - '**/*'
      cache:
        paths:
          - .next/cache/**/*
          - node_modules/**/*
```

#### `frontend/next.config.js` から `assetPrefix` と `compress: false` を削除する

`baseConfig` から `compress: false` の行（コメント含む）と、`assetPrefix` の行およびその上の旧 CloudFront URL のコメント 2 行を削除する。`isProd` は production 用の `turbopack` 設定で引き続き使うため残す。振る舞いを変える分岐を足さないため、test の追加はしない（理由: 設定値の削除で、test から観測できる挙動が無い）。`assetPrefix` は production build でだけ効く設定で local の開発画面の見た目を変えないため、visual-inspector による screenshot 確認は行わず、本番の見た目は Phase 2・4・6 の利用者確認で見る。確認は `docker compose exec frontend yarn test`、`docker compose exec frontend yarn lint` と、build の確認。

build は `docker compose exec frontend yarn build` で実行しない。`frontend/docs/ai_guideline/development_standard/docker.local.md` が、起動済み watcher がある container で Tailwind をコンパイルする操作を禁止している（MUST）。代わりに `docker compose restart frontend` を実行する。`entrypoint.sh` の development 分岐は watcher を起動する前に `NODE_ENV=production yarn build` を実行し、失敗すると `set -e` で container が停止する。`docker compose logs frontend` で build の成否（`next build` の完了表示、またはエラー原文）を確認し、続けて `docker compose ps` で container が起動していることを確認する。build が失敗した場合は再実行せず、エラー原文を添えて停止・報告する。restart 前後に `docker stats --no-stream` で frontend のメモリを確認し、80% を超えていたら作業を続けず報告する。

#### `frontend/terraform/modules/amplify/main.tf` を作る

x_favorites の `terraform/modules/amplify/main.tf` を基に、親 design の「Terraform の配置」の表のとおりにする。

- variable: `appname`、`stage`、`repository_url`、`github_access_token`（sensitive）、`branch_names`（list(string)）、`backend_origin`、`custom_domain`（default null）、`custom_domain_sub_domains`（list(object({branch_name, prefix}))、default []）
- `aws_amplify_app`: `name = "${var.appname}-${var.stage}"`、`repository = var.repository_url`、`access_token = var.github_access_token`、`platform = "WEB_COMPUTE"`、`environment_variables = { AMPLIFY_MONOREPO_APP_ROOT = "frontend", NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN = var.backend_origin }`。`build_spec`、`enable_basic_auth` は書かない。
- `aws_amplify_branch`: `for_each = toset(var.branch_names)`、`enable_auto_build = true`。
- `aws_amplify_domain_association`: `count = var.custom_domain == null ? 0 : 1`、`domain_name = var.custom_domain`、`wait_for_verification = false`、`dynamic "sub_domain"` で `custom_domain_sub_domains` を展開し、`branch_name` は `aws_amplify_branch.this[...]` を参照する。
- output: `app_id`、`default_domain`、`branch_urls`、`custom_domain_certificate_verification_dns_record`、`custom_domain_sub_domains`。
- `required_providers` は既存 module と同じ `hashicorp/aws` の制約に合わせる。

#### `frontend/terraform/modules/cloudfront/` に `enable_custom_domain` を足す

親 design の「手順 (2) の切替口」のとおり。

- `variable "enable_custom_domain" { type = bool, default = true }`
- `aliases = var.enable_custom_domain ? [var.custom_domain] : []`
- `viewer_certificate`: true のとき現行の `acm_certificate_arn` / `sni-only` / `TLSv1.2_2019`、false のとき `cloudfront_default_certificate = true`。dynamic block ではなく三項演算子で各属性を切り替える（`acm_certificate_arn = var.enable_custom_domain ? module.cert[0].certificate_arn : null` 等）。
- `module "cert"` と `module "dns"` に `count = var.enable_custom_domain ? 1 : 0` を付ける。既存 state のアドレスが `module.cert` から `module.cert[0]` へ変わるため、`moved` block（`from = module.cert`、`to = module.cert[0]`、dns も同様）を置き、(1-a) の plan で cert と dns の destroy / create が出ないようにする。
- `frontend/terraform/envs/prod/main.tf` の `module "cloudfront"` に `enable_custom_domain = true` を渡す。

#### `frontend/terraform/envs/prod/main.tf` から `module "amplify"` を呼ぶ

- variable `amplify_github_access_token`（sensitive）を足す。
- `module "amplify"`: `source = "../../modules/amplify"`、`appname = module.values.appname`（`frontend/terraform/envs/prod/main.tf` に `module "values" { source = "../../values" }` を足して参照する）、`stage = local.stage`、`repository_url = "https://github.com/tumeda1992/nanitabe"`、`github_access_token = var.amplify_github_access_token`、`backend_origin = var.backend_origin`、`branch_names = ["feature-258"]`、`custom_domain = null`、`custom_domain_sub_domains = [{ branch_name = "main", prefix = "nanitabe" }]`。
- 旧 module の呼び出しは変えない。

#### prod root と `apply_terraform.sh` に `amplify_github_access_token` を足す

- `infrastructure/terraform/envs/prod/main.tf`: `variable "amplify_github_access_token" { type = string, sensitive = true }` を足し、`module "frontend"` へ渡す。行末コメントは既存の書式（`# export TF_VAR_...=${...}`）に合わせる。
- `infrastructure/terraform/envs/prod/apply_terraform.sh`: `export TF_VAR_amplify_github_access_token=${AMPLIFY_GITHUB_ACCESS_TOKEN}` を足す。

#### `terraform fmt` と `terraform validate` を通す

`terraform fmt` は新規作成した file だけに適用する（既存 file は元から fmt に適合しておらず、一括適用すると無関係な差分が出るため。`implementation_review.md` 論点2）。`terraform validate` は repository の terraform 一式を scratchpad へ複製し、`init -backend=false` の後に実行する。本物の `envs/prod` の `.terraform` を書き換えず、backend へ接続しないため、この phase で AWS の状態は変わらない。

#### `frontend/terraform/modules/amplify/README.md` を作る

親 design の「Amplify 移行で更新する docs」の `modules/amplify/README.md` 行の内容を、doc-enricher の README テンプレ（概要と非責務、クイックマップ、不変条件、変更ガイド、参照）で書く。domain 名、account ID、本番 backend の所在は書かない。emit 前に document-review を通す。

## Phase 2: Amplify app を作り、`feature-258` の default domain で確認する（親 design (1-a)）

### DoD（完了条件）

- `https://feature-258.<Amplify の default domain>` を開くと nanitabe のログイン画面が表示される。
- その画面でログインすると、カレンダー画面で献立が表示される。
- Amplify の build log の `node -v` が `v24` 系を示している。
- 旧構成（custom domain の本番 URL）は従来どおり応答している。

### Tasks

- [x] 利用者に GitHub の fine-grained personal access token の発行と、host の `.env` への `AMPLIFY_GITHUB_ACCESS_TOKEN` の追加を依頼し、完了の返答を受ける
  > 利用者が用意済み（steering 側で `.env` の存在と nanitabe 限定のアクセスを確認済み）。値は表示していない。
- [x] Phase 1 の変更を commit し、利用者の確認を得て `feature-258` を push する
- [x] (1-a) の apply を行う
  > plan 作成済み（apply 未承認）: `Plan: 2 to add, 0 to change, 0 to destroy.`。追加は `aws_amplify_app.this` と `aws_amplify_branch.this["feature-258"]` のみ。cert・dns 計 5 resource は `has moved` 表示、cloudfront distribution に差分なし。plan file は session scratchpad の `amplify-1a.tfplan`。
  > apply は利用者が自分の操作で実行（agent の apply は権限分類器が拒否）。結果: `Apply complete! Resources: 2 added, 0 changed, 0 destroyed.`（app id `d20nu0a9ujey4d`、branch `feature-258`）。
  - [x] plan の追加が `aws_amplify_app`、`aws_amplify_branch`（`feature-258`）だけで、cert・dns が `moved` として表示され destroy が無いことを確認してから承認する
- [x] Amplify の build 完了を待ち、build log の `node -v` を確認する
  > 結果: job 1（`start-job` で起動）の BUILD / DEPLOY / VERIFY が SUCCEED。build log: `nvm install 24` 後に `Now using node v24.22.1`、`node -v` を実行、`next build` は 19/19 page 生成。
- [x] default domain でログインとカレンダー画面の表示を確認する
  > 結果: 利用者が `https://feature-258.d20nu0a9ujey4d.amplifyapp.com` でログインできたことを確認（backend への疎通も成立）。
- [x] ここで作業を停止し、(1-a) の結果を利用者に確認する。次 phase へは進まない
  > 利用者が確認済み。Phase 3 へ進む。

### 各task詳細

#### 利用者への token 発行依頼

token の条件: 対象 repository は `tumeda1992/nanitabe` だけ、権限は Contents: read、Metadata: read、Webhooks: read and write。値は chat に貼らず `.env` にだけ置くよう依頼する。

#### Phase 1 の変更を commit し `feature-258` を push する

Amplify は remote の `amplify.yml` を build するため、(1-a) の前に push が必要である（design の「親 design から一意に導ける実行上の事項」）。commit は `amplify.yml` と `next.config.js`、Terraform 定義、README の意味単位で分ける。push の前に利用者へ push する commit を示して確認を得る。

#### build の確認

`aws amplify list-jobs --app-id <app_id> --branch-name feature-258` で job の status を確認する。`node -v` が `v24` でなかった、または `nvm install 24` が失敗した場合は、親 design の「不足・不整合時」に従い停止して親 task-design へ戻る。build が他の理由で失敗した場合は `amplify.yml` を `feature-258` 上で直して push し直す。直し方が親 design の設定表から外れる場合は停止して親 task-design へ戻る。

#### default domain での確認

URL は `aws amplify list-apps` で `nanitabe-front-prod` の `appId` と `defaultDomain` を得て、`https://feature-258.<defaultDomain>` とする。root module から module output を出す変更は行わない。ログインとカレンダー表示は利用者に依頼し、結果を受け取る。

## Phase 3: `amplify.yml` と `next.config.js` の変更を `main` へ入れる（親 design (1-b)）

### DoD（完了条件）

- `main` に `amplify.yml` と `frontend/next.config.js` の変更が入っている。
- その PR は `Closes` を持たず、本文に「issue #258 の完了を意味しない」と書かれている。

### Tasks

- [x] `main` から `feature-258-amplify-build-config` を切り、`feature-258` の `amplify.yml` と `frontend/next.config.js` だけを取り込んで commit する
- [x] 利用者の確認を得て push し、PR を作る
  > 利用者から tasklist 記載の操作は確認不要との指示あり。PR: https://github.com/tumeda1992/nanitabe/pull/286（base main、本文に Closes なし）。
  - [x] `create_or_get_pr.sh` に `--title` と `--body` を渡し、`Closes` を含めない
- [x] 利用者に PR の merge を依頼し、merge の返答を受ける
  > 利用者が PR #286 を merge。
- [x] ここで作業を停止し、merge の結果を利用者に確認する。次 phase へは進まない

### 各task詳細

#### PR の title と body

- title: `Amplify の build 設定を main へ入れる（#258 の途中 merge）`
- body: この PR は issue #258 の完了を意味しないこと、Amplify app が `main` を build できるようにするための途中 merge であること、参照として `#258` を書く。
- merge で旧 CodePipeline と `backend-deploy.yml` が一度起動する。旧 CodePipeline の build は失敗中で Lambda を更新せず、backend は差分が無いため挙動を変えないことを body に書く。

## Phase 4: `main` を監視対象へ加え、`main` の default domain で確認する（親 design (1-c)）

### DoD（完了条件）

- `https://main.<Amplify の default domain>` でログインでき、カレンダー画面で献立が表示される。
- `main` の build は Phase 3 の merge commit を build している。

### Tasks

- [x] `feature-258` を `origin/main` へ追従させる（`git merge origin/main`）
- [x] `frontend/terraform/envs/prod/main.tf` の `branch_names` を `["feature-258", "main"]` にして apply する
  > 利用者が apply を実行: `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`（`aws_amplify_branch.this["main"]`）。
  > plan 作成済み（apply は利用者が実行）: `Plan: 1 to add, 0 to change, 0 to destroy.`、追加は `aws_amplify_branch.this["main"]` のみ。`branch_names` の変更は commit・push 済み。
  - [x] plan の変更が `aws_amplify_branch`（`main`）の追加だけであることを確認してから承認する
- [x] `main` の build を確認する
  > `list-jobs` が空だったため `start-job --job-type RELEASE` で起動（job 1）。BUILD/DEPLOY/VERIFY が SUCCEED。log は `main` を clone し、`amplify.yml` 由来の `nvm install 24`（`node -v` = v24.22.1）が走った。`amplify.yml` は PR #286 の merge commit にのみ存在するため、merge commit 以降を build している（job の commitId は `HEAD` 表示、origin/main の先頭は 52e79c5）。
  - [x] branch resource の作成は push event ではないため build が自動で起動しない場合がある。`list-jobs` に job が無ければ `aws amplify start-job --job-type RELEASE` で起動する
- [x] `main` の default domain でログインとカレンダー画面の表示を利用者に確認してもらう
  > 結果: 利用者が `https://main.d20nu0a9ujey4d.amplifyapp.com` でログインできたことを確認。
- [x] ここで作業を停止し、(1-c) の結果を利用者に確認する。次 phase へは進まない
  > 利用者が確認済み。Phase 5 へ進む。

## Phase 5: `feature-258` を監視対象から外す（親 design (1-d)）

### DoD（完了条件）

- Amplify app の branch が `main` だけになり、`main` の default domain が引き続き応答する。

### Tasks

- [x] `branch_names` を `["main"]` にして apply する
  > plan 作成済み（apply は利用者が実行）: `Plan: 0 to add, 0 to change, 1 to destroy.`、destroy は `aws_amplify_branch.this["feature-258"]` のみ。`branch_names` の変更は commit・push 済み。
  - [x] plan の変更が `aws_amplify_branch`（`feature-258`）の destroy だけであることを確認してから承認する
    > 利用者が apply を実行: `Apply complete! Resources: 0 added, 0 changed, 1 destroyed.`
- [x] `main` の default domain が応答することを確認する
  > 結果: `aws amplify list-branches` は `["main"]` のみ。`https://main.d20nu0a9ujey4d.amplifyapp.com/` は HTTP 308（アプリ内 redirect）で応答。
- [x] ここで作業を停止し、(1-d) の結果を利用者に確認する。次 phase へは進まない
  > 利用者が apply 成功を報告済み。

## Phase 6: custom domain を Amplify へ切り替える（親 design (2)〜(4)）

### DoD（完了条件）

- custom domain（`https://nanitabe.<hosted zone>`）を開くと Amplify の `main` が応答し、証明書が有効である。
- その画面でログインし、カレンダー画面で献立が表示される。
- `/_next/static/...` が custom domain と同じ origin から配信されている。

### Tasks

- [x] 利用者と切替の開始時刻を合わせる（利用しない時間帯）
  > 利用者が自分の判断で (2) の apply を開始した。
- [x] (2) `module "cloudfront"` の `enable_custom_domain` を false にして apply する
  > (2) の最終結果: 証明書の削除失敗は (3) の apply で解消（下記）。
  > (2) の apply は部分的に失敗: ACM 証明書（us-east-1、`module.cert[0].aws_acm_certificate.cert`）の削除が約 19 分待った後 `ResourceInUseException: ... is in use.` で失敗。他は成功。現状: distribution は Deployed、Aliases=0、CloudFrontDefaultCertificate=True。証明書は ISSUED で InUseBy は空（未使用）。custom domain の A / AAAA と証明書検証 CNAME は Route53 から消え、本番 custom domain は応答していない。停止時間短縮のため (3) を直ちに準備する（残った証明書の destroy も (3) の apply に含まれる想定）。
  > plan 作成済み（apply は利用者が実行、開始時刻は利用者が決める）: `Plan: 0 to add, 1 to change, 5 to destroy.`。変更は distribution の update in-place（aliases 削除、証明書を CloudFront 既定へ）、destroy は cert 3 件（acm 証明書、検証、検証 record）と dns 2 件（A、AAAA）。`enable_custom_domain = false` は commit・push 済み。
  - [x] plan の変更が distribution の alias・証明書設定の update、cert と dns の destroy だけであることを確認してから承認する
- [x] (3) `module "amplify"`
  > 利用者が apply を実行: `Apply complete! Resources: 1 added, 0 changed, 1 destroyed.`（`aws_amplify_domain_association.this[0]` を作成、(2) で残った ACM 証明書は 1 秒で削除）。親 domain の共有は拒否されなかった。 の `custom_domain` を `var.route53_name` にして apply する
  > plan 作成済み（apply は利用者が実行）: `Plan: 1 to add, 0 to change, 1 to destroy.`。追加は `aws_amplify_domain_association.this[0]`（親 domain、prefix `nanitabe` を `main` へ）、destroy は (2) で残った ACM 証明書のみ。`custom_domain` の変更は commit・push 済み。
  - [x] plan の追加が `aws_amplify_domain_association` だけであることを確認してから承認する
  - [x] apply が「already associated」等で拒否された場合は、(2) を戻す apply（`enable_custom_domain = true`、`custom_domain = null`）を行い、旧構成の応答を確認してから停止し、親 task-design へ戻る
    > 該当せず（拒否されなかった）。
- [x] 証明書の検証完了を待つ
  - [x] `aws amplify get-domain-association --app-id <app_id> --domain-name <hosted zone>` の `domainStatus` が `AVAILABLE` になるまで確認する
    > 結果: `domainStatus` は途中 `AWAITING_APP_CNAME`（Route53 の record は Amplify が作成済みで反映待ち）を経て `AVAILABLE`、sub domain `nanitabe` は verified。
- [x] (4) custom domain で受け入れ基準を確認する
  - [x] TLS 証明書と static asset の配信元を確認する
    > 結果: 証明書は Amazon 発行で有効（2027-05-10 まで、SAN は親 domain とワイルドカード、verify OK）。`/` は `/calendar/week/thisweek` へ redirect の後 200。HTML の `/_next/static/...` はすべて相対 path（同じ origin）。注記: この host の OS resolver は切替前の否定 cache のためか名前解決に失敗したため、`dig` で得た CloudFront の IP を `--resolve` で指定して確認した。
  - [x] ログインとカレンダー画面の表示を利用者に確認してもらう
    > 結果: 利用者が custom domain でログインできたことを確認。
  - [x] 失敗した場合は (2) を戻す apply で旧構成へ戻し、停止して利用者へ報告する
    > 該当せず（確認に成功）。
- [x] ここで作業を停止し、切替の結果を利用者に確認する。次 phase へは進まない
  > 利用者が確認済み。Phase 7 へ進む。

### 各task詳細

#### 証明書の検証が進まない場合

`domainStatus` と、Route53 に Amplify が作った検証用 CNAME を確認する。待つか戻すかは利用者に判断を仰ぐ。戻す場合は (2) を戻す apply を行う。

#### TLS と static asset の確認

`curl -sI https://nanitabe.<hosted zone>/` と、トップページの HTML に含まれる `/_next/static/` の URL が相対 path（同じ origin）であることを確認する。

## Phase 7: 旧構成を撤去し、docs を移行後の状態へ更新する（親 design (5)）

### DoD（完了条件）

- 旧構成の resource（Lambda、API Gateway、CloudFront distribution、static asset 用 S3、ECR、CodePipeline、CodeBuild）が AWS に残っていない。
- `infrastructure/terraform/envs/prod` の `terraform plan` が `No changes` になる。
- custom domain が引き続き Amplify から応答する。
- 親 design の docs 表のうち `infrastructure/README.md`、`frontend/README.md`、`docker.local.md`、`frontend/entrypoint.sh` が更新されている。

### Tasks

- [x] 旧構成の定義を削除する
  - [x] `frontend/terraform/modules/` の apigateway、cicd、cloudfront、ecr、lambda、s3 を `test/` ごと削除する
  - [x] `frontend/buildOnLambda/` を削除する
  - [x] `frontend/terraform/envs/prod/main.tf` から旧 module の呼び出しと旧 variable を削除する
  - [x] prod root から旧 variable と us-east-1 の provider を削除し、`apply_terraform.sh` の対応する export を削除する
  - [x] repository 内に削除した module・variable への参照が残っていないことを `grep` で確認する
    > 結果: frontend の旧 module への参照は無い。`docker-compose.yml` の `frontend_next_lambda` service が `buildOnLambda/Dockerfile` を参照していたため service ごと削除した（tasklist 外だが削除した定義への参照の解消。`docker compose config` は成功）。残る `codebuild_artifact_s3_bucket` 等の grep ヒットは backend / review 自前の module で対象外。
- [x] `terraform validate` を Phase 1 と同じ方法（scratchpad へ複製、`init -backend=false`）で通す。この phase は新規 Terraform file を作らないため `terraform fmt` は適用しない
  > 結果: scratchpad に複製して `init -backend=false` の後 `terraform validate` が Success。新規 module の `terraform fmt -check` も通過。
- [x] 旧構成を撤去する apply を行う
  > 利用者が amplify-6 を apply: `Apply complete! Resources: 0 added, 0 changed, 2 destroyed.`（ECR repository と S3 bucket）。
  > plan 作成済み（apply は利用者が実行）: `Plan: 0 to add, 0 to change, 30 to destroy.`。destroy は旧構成の API Gateway、CloudFront、ECR、Lambda、S3、CodeBuild、CodePipeline 関連のみで、Amplify と state 用 resource の変更は無い。注意: static asset 用 S3 bucket は versioning 有効で非空（現行 53 object、delete marker 多数）、`force_destroy` は無いため bucket の destroy は失敗する見込み。bucket を空にする操作は利用者の確認が要る。
  - [x] plan の destroy が旧構成の resource だけで
  - [x] static asset 用 S3 bucket が空でないため
    > 実際に失敗し、利用者の操作で bucket と ECR を空にしてから再実行して成功した。
    > 経緯: 利用者が amplify-5 を apply し、ECR repository（image 10 件残存で `RepositoryNotEmptyException`）と S3 bucket（`BucketNotEmpty`）の 2 件だけ失敗、他 28 件は destroy 済み。利用者が S3 の全 version・delete marker（3,557 件）と ECR の image 10 件を削除して空にした。state が変わったため amplify-6 を作成。
    > plan 作成済み（apply は利用者が実行）: `Plan: 0 to add, 0 to change, 2 to destroy.`（`ecr.aws_ecr_repository.repo` と `s3_for_assets.aws_s3_bucket.static_files_bucket` のみ。Amplify と state 用 resource の変更なし）。
- [x] apply 後に `terraform plan` が `No changes`
  > 結果: `No changes. Your infrastructure matches the configuration.`（`-detailed-exitcode` で exit 0）。
- [x] 旧 resource が残っていないことを AWS CLI で確認する
  > 結果: stage `prod` の旧 resource（Lambda、CloudFront、API Gateway、ECR、CodePipeline、CodeBuild、S3）は無い。残っているのは stage `verify-infra` の同名系 resource（Lambda、CloudFront、API Gateway、ECR、CodePipeline、CodeBuild、S3 各 1）で、この Terraform state の管理外の別環境のため、触っていない。CloudWatch Logs は対象外。
- [x] custom domain が応答することを確認する
  > 結果: custom domain は `/calendar/week/thisweek` への redirect の後 HTTP 200。
- [x] docs を更新する
  - [x] `infrastructure/README.md`
  - [x] `frontend/README.md`
  - [x] `frontend/docs/ai_guideline
  - [x] `frontend/entrypoint.sh`
  - [x] emit 前に document-review を通す
    > document-review: 濃さ・記法・指示対象・機密性（domain 名、本番 backend の所在を書いていない）を確認済み。
- [x] ここで作業を停止し、撤去の結果を利用者に確認する。次 phase へは進まない
  > 利用者の指示により Phase 8 まで続行。

### 各task詳細

#### 旧 resource の確認

`aws lambda list-functions`、`aws cloudfront list-distributions`、`aws apigateway get-rest-apis` と `aws apigatewayv2 get-apis`、`aws ecr describe-repositories`、`aws codepipeline list-pipelines`、`aws codebuild list-projects`、`aws s3 ls` で、旧構成の名前（`nanitabe-front` を含む）が残っていないことを確認する。

#### docs の更新内容

親 design の「Amplify 移行で更新する docs」の表のとおり。domain 名と本番 backend の所在は書かない。

## Phase 8: 品質check

### DoD（完了条件）

- frontend と backend の全 test が green。
- repository 全体の lint に error が無い。

### Tasks

- [x] 全 test を実行する
  > 結果: backend rspec 744 examples 0 failures、frontend jest 35 suites / 192 tests green。
  - [x] `docker compose exec backend bundle exec rspec`
  - [x] `docker compose exec frontend yarn test`
- [x] repository 全体の lint を実行する
  - [x] `docker compose exec backend bundle exec rubocop`
  - [x] `docker compose exec frontend yarn lint`
  - [x] error があれば修正して再実行し、error zero を確認する
    > 結果: rubocop 451 files no offenses、`yarn lint` error 0。
- [x] `terraform fmt -check` を、このtasklistで新規作成した Terraform file（`frontend/terraform/modules/amplify/main.tf`）に対して実行する。既存 file は元から fmt に適合しておらず対象外とする（`implementation_review.md` 論点2）

## Phase 9: 旧 module 用の spike 環境 `verify-infra` を撤去し、手元の旧 module directory を片付ける

`verify-infra` は、旧構成の各 module の `test/` から local state で Terraform を実行し、ローカル実行で動くかを確かめる spike 的な環境である。対象の module を Phase 7 で削除したため、この環境は何も確かめていない。用途（module をローカル実行で確かめる）は残り、新しい構成での持ち方は roadmap の phase `terraform-on-github-actions` で設計する。経緯は `implementation_review.md` 論点8。

### DoD（完了条件）

- AWS 上に `verify-infra` の resource（Lambda `nanitabe-front-verify-infra`、API Gateway、CloudFront distribution と証明書・Route53 record、ECR、CodeBuild・CodePipeline、static asset 用 S3）が残っていない。
- 手元の `frontend/terraform/modules/` に、`amplify` 以外の directory が無い。
- `frontend/terraform/modules/amplify/README.md` に、移行期間中の兄弟 module についての記述が無い。
- 本番の custom domain が引き続き応答する。

### Tasks

- [x] 旧 module のコードを、削除 commit（`5ab7f0d`）の直前の版から scratchpad へ復元し、手元の各 `test/` の state と `.terraform` をそこへ複製する
  > 結果: `git archive 5ab7f0d^ frontend/terraform` を scratchpad の `verify-infra-old/` へ展開し、手元 `test/` の `terraform.tfstate*`、`.terraform`、lock を複製した（cloudfront/test、apigateway/test、lambda/test、s3/for_assets/test、cicd/test、ecr/test。cert/test と dns/test の state は resource 0 件）。
  - [x] 手元の旧 directory は、撤去を確認するまで消さない（state が唯一の管理手段であるため）
- [ ] 中身を持つ resource を先に空にする: `verify-infra` の ECR repository の image と、static asset 用 S3 bucket の全 version・delete marker。削除は利用者が `!` で実行する script を scratchpad に用意して止まる
  > 用意済み（実行は利用者）: scratchpad の `empty_verify_infra_storage.sh`（S3 は現在 402 version + 82 delete marker、ECR は 8 image）。
- [ ] 各 `test/` の state について `terraform plan -destroy -out=<scratchpad>/verify-infra-<module>.tfplan` を作る
  > plan 作成済み（`verify-infra-{cloudfront,apigateway,lambda,s3,cicd,ecr}.tfplan`）: cloudfront 7、apigateway 8、lambda 4、s3 4、cicd 9、ecr 2 の計 34 destroy。対象は stage `verify-infra` の resource だけで、prod・Amplify・state 用 resource は含まない。
  - [ ] 依存の向きに合わせ、cloudfront（cert、dns を含む）→ apigateway → lambda → s3 → cicd → ecr の順で destroy する
  - [ ] 各 plan の destroy が `verify-infra` の resource だけで、prod・Amplify・state 用 resource を含まないことを確認する
  - [ ] apply は利用者が `!` で実行する。plan の要約と、各 plan file を順に apply するコマンドを添えて止まる
  - [ ] CloudFront から外した証明書が `ResourceInUseException` で消えない場合は、反映を待って plan を作り直す
- [ ] 撤去後、AWS CLI で `verify-infra` の resource が残っていないことを確認する（log group は対象外）
- [ ] 手元の `frontend/terraform/modules/` から `amplify` 以外の directory を削除する
- [ ] `frontend/terraform/modules/amplify/README.md` から、移行期間中の兄弟 module についての記述を削除する
- [ ] 本番の custom domain が応答することを確認する
- [ ] 変更を commit し、`feature-258` と `feature-258-amplify-migration` へ push する
- [ ] ここで作業を停止し、撤去の結果を利用者に確認する

## Documentation reviewと実装後振り返り

- [x] code readingまたは実装で永続化候補を得た場合、その場でdoc-enricherを提案modeで適用する
  - [x] 提案がある場合だけユーザー承認後に既存READMEまたは既存docsへ反映する
  - [x] 提案・承認判断を別taskへ先送りしない
  > 結果: 追加の永続化候補なし（移行の知識は amplify module README と各 docs に反映済み）。提案なし。
- [x] 実装、review、validationからfeedbackまたは実装とのずれが生じた場合、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用する
  - [x] `discussion_directory=<working_dir>`と`discussion_file_name=implementation_review.md`を渡す
  - [x] 原文、関連する実装・design・plan、原因、採用方針、決定を渡し、修正済みでも記録を省略しない
  - [x] 「共有されていなかった知識の前提は何か」を確認する
  - [x] 「codeを読めば分かるか、設計意図か、process不足か」を確認する
  - [x] 「どこに書けば次回この議論が不要になるか」を確認し、合意後だけ反映する
  - [x] decisionをcallerへ返し、designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す
  - [x] review後に実装を自動再開しない
  > 実行中の feedback は steering が `implementation_review.md` の論点1〜6 に記録・処理済み（論点6 は保留で、phase 完了報告の後に扱う）。この executor は再実装していない。

---

## 動作確認

### DoD

Tasks に挙げた確認をユーザーが行い、期待どおりであることを確認した。

### Tasks

- [x] ユーザーに動作確認を依頼する（custom domain を普段使う端末で開き、ログイン、カレンダー画面の週・月表示、献立の登録を行い、従来どおり動くこと）
  > 結果: 利用者が custom domain でログイン、カレンダーの週・月表示、献立の登録の 3 つともできたことを確認。
- [x] feedbackがあれば、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用し、decisionをcallerへ返す
  - [x] designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す
  - [x] feedbackがなければ`[x] ~~feedback収集~~（feedbackなし）`の形式で完了扱いにする
    > 実行中の feedback は steering が `implementation_review.md` 論点1〜6 に記録済み。動作確認後の新たな feedback は無し。

---

## 完了後のaction

> ⚠️ 動作確認phaseが完了するまでcommit、push、PRを促したり実行したりしない。急かすことも禁止する。

- [x] commit（phase単位かつ意味単位で分割）
  > phase 単位・意味単位で commit 済み（steering 記録、amplify 設定、Terraform 定義、README、旧定義の削除、docs、tasklist の記録）。
  - MUST: まとめて一commitにしない
  - phaseごとに別commitにする（Phase 2 で push 済みの Phase 1 の commit を除く）
  - 同一phase内でも意味的に異なる変更を分割する（例: Terraform 定義の削除、docs の更新、tasklist の checkbox と `implementation_review.md`）
  - ユーザーが一部だけ承認した場合は承認範囲だけをcommitし、残りは待つ
  - ユーザーが不要と回答した場合は`[x] ~~commit~~（ユーザーが不要と回答）`の形式で完了扱いにする

- [x] `feature-258` を push し、PR #283 を `main` へ merge できる状態にする
  - [x] commit taskの結果としてlocal commitが実際に一件以上あることを確認する。一件もなければpushを実行しない
  - [x] current branchが `feature-258` であることを確認する
  - [x] `git push origin feature-258` を実行する
  - [x] PR #283 の本文から `Closes: #258` を外し、「issue #258 の完了を意味しない。roadmap の後段 phase（Terraform の Actions 移行）が残る」と参照 `#258` を書く。この merge は plugin の `development_flow/branch_pr_issue.md` の経路 2 にあたる
  - [ ] merge は利用者が行う

---

## 参照

- 設計の正本: 同じdirectoryの `./design.md` と、そこから参照する親 design
- 完了条件、取消完了、subtask分割、checkbox更新timingの規則の正本: `tasklist-executor/SKILL.md`
- tasklistへ載せるtaskの範囲の正本: `task-design/tasklist-design.md`
