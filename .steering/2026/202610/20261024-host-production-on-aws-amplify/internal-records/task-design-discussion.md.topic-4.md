# 内部検討記録: 論点4 — Amplify app の build・実行設定

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点4

## 開始context

論点3の手順 (1) で作る Amplify app が、nanitabe の frontend をどう build し、何を実行時へ渡すか。

- 決める範囲: `amplify.yml` の内容、Amplify app の環境変数、access gate の有無、旧構成専用だった frontend 側設定の扱い。
- 既決条件: 論点1〜3。Amplify が GitHub へ接続する token は移行中 host の `.env` に置く（論点2）。
- 残る不足: nanitabe 固有の差（monorepo、yarn、Node version、`NEXT_PUBLIC_*` の使い方、旧構成専用の設定）の洗い出し。

<a id="iteration-0"></a>

## イテレーション0: nanitabe の frontend を Amplify でどう build し、何を渡すか

<a id="iteration-0-record-1"></a>

### 調査: x_favorites との差と、旧構成専用の設定

#### 問いと探索範囲

- 問い: x_favorites の `amplify.yml` と Amplify app 設定のうち、nanitabe でそのまま使えないものは何か。旧構成のために frontend 側に入っている設定は何か。
- source: `frontend/package.json`、`frontend/next.config.js`、`frontend/src/lib/generateApiOrigin.ts`、`frontend/src/app/system/warmup/route.ts`、`frontend/terraform/modules/cloudfront/main.tf`、`.github/workflows/ci-frontend-build-verification.yml`、`frontend/Dockerfile`、x_favorites の `amplify.yml`・`terraform/modules/amplify/`。

#### 見つかった事実

- monorepo: nanitabe の Next.js は repository 直下ではなく `frontend/` にある。x_favorites は repository 直下だった。
- package manager: nanitabe は yarn（`yarn.lock`）。x_favorites は npm。
- build の実績: PR ごとの `ci-frontend-build-verification.yml` が `frontend/` で Node `24.11.1`、`yarn install --frozen-lockfile`、`yarn build` を実行し、通っている。local の `frontend/Dockerfile` は Node `24.13.0`。`yarn build` は `build:css`（Tailwind）を随伴する。
- 実行時の値: frontend が参照する環境変数は `NEXT_PUBLIC_ENVIRONMENT`、`NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`（`generateApiOrigin.ts`）、`NEXT_PUBLIC_ASSET_ORIGIN`（`next.config.js` の `assetPrefix`）の三つだけである。`NEXT_PUBLIC_` 接頭辞の値は build 時に bundle へ埋め込まれるため、x_favorites のような `.env.production` への書き出しは不要である。`NEXT_PUBLIC_ENVIRONMENT` は未設定なら本番の分岐へ入る。
- 旧構成専用の設定: `assetPrefix` は static asset を S3 + CloudFront の別 origin から配信するためのもので、`NEXT_PUBLIC_ASSET_ORIGIN` はその origin を指す。`compress: false` は「API Gateway で gzip させるため」とコメントされている。`/system/warmup` は Lambda の cold start 対策として作られ、旧 CloudFront だけがこの path を cache しない behavior を持つ。repository 内にこの path の呼び出し元は無い（`grep` で確認。外部から呼ばれているかは未確認）。
- access gate: x_favorites は application に認証が無いため Basic authentication を置いた。nanitabe は application にログインがある（`frontend/src/app/login`、`backend` の devise）。

#### 言える範囲

x_favorites の `amplify.yml` は、monorepo の指定、yarn、Node version の指定を変えれば使える。実行時へ渡す値は `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` だけで足りる。`assetPrefix` と `compress: false` は旧構成を前提にした設定である。

#### 取得できていないこと

- Amplify の build image で Node 24 を使えるか（未実測）。論点3の手順 (1) で build log から確認する。

<a id="iteration-0-record-2"></a>

### 判断: 設定の内容

- 評価軸: CI で通っている build と同じ条件にする。旧構成を前提にした設定を残さない。不要な access gate を足さない。
- 推奨: discussion の提案0の表のとおり。
- warmup route は残す。route 自体は Lambda に依存せず、外部から呼ばれていても Amplify 上で応答するだけである。cache しない behavior は Amplify の SSR route が既定で持つため、別途の設定は要らない見込み。
- 代償: Node 24 が Amplify の build image で使えなかった場合は、手順 (1) で止まって design へ戻る。
