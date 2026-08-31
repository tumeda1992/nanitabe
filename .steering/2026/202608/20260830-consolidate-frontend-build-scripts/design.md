# Design: frontend build script の責務を package.json へ集約する

## 元の依頼内容

frontend側のビルドスクリプトがentrypoint.shに漏れ出しているからpackage.jsonで用意したスクリプトを最低限組み合わせる程度までにしたい。 環境ごとに変えること自体に何の問題もないんだけど、tailwindのbuildとか、開発環境でのwatchモードでのビルドとか。さらには、buildにtailwindのbuildが含まれておらず、外からは両方使わなきゃいけないのがセンス悪い

---

## 1. TL;DR

`frontend/package.json` の `build` は `next build` だけを行い、Tailwind CSS のコンパイルを含まない。そのため build を呼ぶ側（`frontend/entrypoint.sh`、`frontend/buildOnLambda/Dockerfile`、`.github/workflows/ci-frontend-build-verification.yml`）が全員、`node_modules/.bin/tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css` という同じコマンド詳細を各自で持っている。Tailwind の入出力 path を変えると 4 箇所を追随させる必要がある状態を解消する。

終了時には、Tailwind の入出力 path は `frontend/package.json` の `build:css` だけが持ち、`build` は `build:css` を、`dev` は `watch:css` を随伴する。CSS の処理は、それを必要とする Next.js コマンドに随伴するという原則が package.json 内で一貫し、caller は build 経路でも dev 経路でも CSS の存在を知らずに済む。`frontend/entrypoint.sh` は環境分岐と script の呼び出しだけを行い、Tailwind に関する記述を持たない。

---

## 前提とする既存仕様

- `frontend/package.json` の `scripts`（確認元: `frontend/package.json`）:
  - `dev`: `next`
  - `build`: `next build`
  - `start`: `next start`
  - `test`: `jest` / `lint`: `eslint`
  - Tailwind に関する script は存在しない。
- `frontend/postcss.config.mjs`: `plugins: {}` で空。Tailwind は PostCSS へ統合せず、`tailwindcss` CLI の独立プロセスでコンパイルする方針。理由はコメントに明記されている — `@tailwindcss/postcss` を PostCSS へ統合すると Turbopack の dev compile が 2 分超になるため。
- `frontend/src/app/tailwind-output.css` は `frontend/.gitignore:39` で ignore されており、git 管理外の生成物である。したがって build を行う全ての環境が自前で生成する必要がある。
- `frontend/entrypoint.sh`（確認元: 実ファイル）:
  - `port=18100` を変数で保持し、`yarn start -p ${port}` / `yarn dev -p ${port}` へ渡す。
  - `build_tailwind()` 関数で `node_modules/.bin/tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css` を実行。
  - `NODE_ENV=production` のとき: `yarn install --production=false` → `build_tailwind` → `NODE_ENV=production yarn build` → `yarn start -p 18100`。
  - それ以外のとき: `yarn install` → `build_tailwind` → 同じ tailwind コマンドを `--watch` 付きで background 起動 → `NODE_ENV=production yarn build`（開発では使わないが、Lambda 用イメージのビルドが失敗しないことの確認） → `yarn dev -p 18100`。
- `frontend/buildOnLambda/Dockerfile:39-41`: `yarn install --production=false` → `node_modules/.bin/tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css` → `yarn build`。
- `.github/workflows/ci-frontend-build-verification.yml`: `yarn install --frozen-lockfile` → `Generate Tailwind CSS` step で同じ tailwind コマンド → `yarn build`。
- `frontend/docs/ai_guideline/development_standard/docker.md`「Tailwind watcher のトラブルシューティング」: **MUST として、`docker compose exec frontend` で `tailwindcss` を手動実行しない**。起動済み watcher と競合して OOM が発生し、watcher プロセスが死ぬ。復旧は `docker compose restart frontend`。
- `frontend/yarn.lock` は `yarn lockfile v1`（Yarn Classic）。`package.json` に `packageManager` フィールドはない。frontend container 内の実測は `yarn 1.22.22` / `node v24.13.0` / `corepack 0.34.5`。Yarn Classic は `pre<script>` / `post<script>` の lifecycle script をサポートし、`yarn run <script> <args>` の追加引数を script 末尾へ連結する。後者は既存の `lint` script が `sh -c '... eslint "$@"' sh` として依存している。また yarn script 実行時の `PATH` には `/root/nanitabe_front/node_modules/.bin` が含まれる（`yarn run env` で実測）。
- 実行環境は container 内が原則（確認元: `frontend/docs/ai_guideline/development_standard/docker.md`）。test は `docker compose exec frontend yarn test`、lint は `docker compose exec frontend yarn lint`。

---

## 2. 要件（Requirements）

### MUST（必達）

- Tailwind CSS のコンパイルコマンド（入力 path、出力 path、CLI 呼び出し形式）の定義箇所を `frontend/package.json` の 1 箇所にする。
- `yarn build` を呼べば、Next.js アプリを配信できる状態のビルド成果物が揃う。呼び出し側が Tailwind のコンパイルを別途行う必要をなくす。
- `frontend/entrypoint.sh` に残るのは、環境分岐、port の受け渡し、`package.json` の script の呼び出しだけにする。Tailwind CLI とその引数を entrypoint.sh へ書かない。
- 現行の 4 つの実行経路（開発 container、production container、Lambda イメージビルド、CI build verification）が、変更後も同じ成果物・同じ検証範囲を維持する。
- `docker.md` が MUST として禁じている「起動済み watcher と競合する tailwindcss の重複実行」を新たに発生させない。

### SHOULD（できれば）

- 開発環境の watch 起動も、Tailwind CLI の引数を持たない形にする。
- `frontend/buildOnLambda/Dockerfile` と `.github/workflows/ci-frontend-build-verification.yml` から、重複した Tailwind コンパイル step を削除する。

### MAY（あれば嬉しい）

- なし

### 非目標

- Tailwind を PostCSS へ再統合すること。Turbopack の dev compile が 2 分超になる問題は解決していないため、CLI 独立実行の方式自体は維持する。
- `frontend/entrypoint.sh` から環境分岐そのものを消すこと。環境ごとに実行内容を変えること自体は問題ないとユーザーが明言している。
- backend 側の `backend/entrypoint.sh` の変更。
- Next.js、Tailwind CSS のバージョン変更、および `src/app/globals.css` の内容変更。
- `port=18100` の定義箇所の変更。port は build の手順ではなく起動時の実行パラメータであり、`frontend/entrypoint.sh` に 1 箇所しかないため今回解消する重複を持たない。`frontend/entrypoint.sh` の `port` 変数と `-p ${port}` の受け渡しはそのまま残す。

### 受け入れ基準

- `grep -rn "tailwindcss -i" frontend/ .github/`（`node_modules` を除く）の結果が `frontend/package.json` の 1 行だけになる。
- 開発 container を再起動すると、`yarn build` が成功し dev サーバが起動し、`frontend/src/app/tailwind-output.css` が生成されている。
- `frontend/src/app/globals.css` へ最小の 1 クラスを追加すると `tailwind-output.css` の mtime と行数が変化する（watcher が生存している）。
- `http://localhost:18100` の画面に Tailwind のスタイルが当たっている。
- `ENV=production docker compose up -d frontend` で production 分岐が `yarn install --production=false` → `yarn build` → `yarn start` の順に進み、`http://localhost:18100` が応答する。
- `docker compose exec frontend yarn test` と `docker compose exec frontend yarn lint` が通る。
- PR 上で `CI Frontend Build Verification` / `CI Frontend Test` / `CI Frontend Lint` が green になる。
- `frontend/docs/troubleshooting/tailwind/build_and_watch.md`、`frontend/docs/ai_guideline/development_standard/docker.local.md`、同 `docker.md`、同 `README.md`、`frontend/README.md` の Tailwind に関する記述が、変更後の実態と食い違わない。

---

## 3. 完成後の姿

### callerが依存するcontract

**変更・新設する caller-facing script（`frontend/package.json` の `scripts`）:**

- `build`: `"yarn build:css && next build"`
  - caller から見た責務: Next.js アプリを配信できる状態のビルド成果物を単独で揃える。呼び出し側が Tailwind コンパイルを別途行う必要はない。
  - `build` の行そのものが 2 段構成であることを示すため、`package.json` を読む側が追加の知識なしに build の内容を把握できる。`&&` により Tailwind コンパイルの失敗時点で `next build` へ進まない。
  - `prebuild` lifecycle script は使わない。`build` の行から Tailwind への依存が読めなくなり、package manager の lifecycle 機能へも依存するため。
- `build:css`（新設）: `"tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css"`
  - caller から見た責務: `src/app/globals.css` から `src/app/tailwind-output.css` を 1 回生成する。
  - **Tailwind の入出力 path を記述する repository 内で唯一の箇所**である。
  - 現行 `frontend/entrypoint.sh` が使っている `node_modules/.bin/` の prefix は付けない。yarn script 実行時の `PATH` に `node_modules/.bin` が含まれるため、bare な `tailwindcss` で解決される。
- `watch:css`（新設）: `"yarn build:css --watch=always"`
  - caller から見た責務: `build:css` と同じ生成を、ファイル変更を検知して継続的に行う。呼び出し側が終了させるまで常駐する。
  - Tailwind の入出力 path を持たず、`build:css` へ `--watch=always` を追加引数として渡す。Yarn Classic が `yarn run <script> <args>` の追加引数を script 末尾へ連結する挙動に依存する。既存の `lint` script が同じ挙動へ依存しており、repository 内で裏付けが取れている。
  - **`--watch` ではなく `--watch=always` を使う。** `--watch` の tailwindcss CLI は stdin が閉じられると watcher を自己終了させる。`entrypoint.sh` から `yarn dev` 経由で background 起動した場合、container 起動後およそ 60 秒で stdin が閉じ、watcher が黙って終了する。`--watch=always` は stdin の状態に関わらず watcher を継続させる。実装中に watcher の生存を `ps` で定点観測して確認した。
- `dev`: `"yarn watch:css & next"`（現状は `"next"`）
  - caller から見た責務: dev サーバを起動し、あわせて Tailwind watcher を background で常駐させる。呼び出し側が watcher を別途起動する必要はない。
  - 追加引数は script 末尾の `next` へ届く。`yarn dev -p ${port}` は `next -p ${port}` として解決される。

`start` / `codegen` / `test` / `lint` は変更しない。

**この script 群を貫く設計意図:**

`package.json` 内で「CSS の処理は、それを必要とする Next.js コマンドに随伴する」という原則を一貫させている。`build` が `build:css` を伴うのと同じ理由で、`dev` は `watch:css` を伴う。これにより caller は build 経路でも dev 経路でも CSS の存在を知らずに済み、「呼び出し側が 2 つを組み合わせなければならない」という現状の defect が両経路から消える。`build` だけを直して `dev` を据え置く形は、同じ defect を dev 経路に残すことになるため採らない。

`build` と `start`、`watch:css` と `dev` の対に対称性はない。前者は `build` が実態で `start` は成果物を配信するだけであり、後者は `dev` が実態で `watch:css` が随伴する。随伴させる基準は対称性ではなく、その Next.js コマンドが CSS を必要とするかである。

命名根拠: 生成物で命名し、ツール名（`build:tailwind`）では命名しない。`build` が別に存在するため、`build:css` が Next.js の CSS 処理全体を指すと誤読される可能性は低い。

**caller（この script に依存する側）:**

| caller | 現在の依存 | 完成後の依存 |
| --- | --- | --- |
| `frontend/entrypoint.sh`（production 分岐） | tailwind CLI 直呼び + `yarn build` + `yarn start` | `yarn build` + `yarn start`。tailwind CLI 直呼びを削除 |
| `frontend/entrypoint.sh`（development 分岐） | tailwind CLI 直呼び + tailwind CLI `--watch` 直呼び + `yarn build` + `yarn dev` | `yarn build` + `yarn dev` のみ。tailwind CLI 直呼びを 2 箇所とも削除し、watcher 起動も `dev` へ移す |
| `frontend/buildOnLambda/Dockerfile` | tailwind CLI 直呼び + `yarn build` | `yarn build` のみ |
| `.github/workflows/ci-frontend-build-verification.yml` | tailwind CLI 直呼び + `yarn build` | `yarn build` のみ。`Generate Tailwind CSS` step を削除 |

**`frontend/entrypoint.sh` の完成後の実行順序:**

| 分岐 | 実行順序 |
| --- | --- |
| `NODE_ENV=production` | `yarn install --production=false` → `NODE_ENV=production yarn build` → `yarn start -p ${port}` |
| それ以外 | `yarn install` → `NODE_ENV=production yarn build` → `yarn dev -p ${port}` |

production 分岐は `build_tailwind` の呼び出しが 1 行消えるだけで、他は現状と同じである。`build_tailwind()` 関数の定義自体も削除する。

development 分岐は現状の「初回 Tailwind コンパイル → watch 起動 → build」から順序が変わる。`yarn build` が Tailwind コンパイルを含むため現状の初回コンパイル行は `yarn build` へ吸収され、watcher の起動は `yarn dev` の内部へ移る。watcher が起動する時点で `yarn build` は完了しているため、tailwindcss プロセスが同時に 2 つ存在しない。

`NODE_ENV=production yarn build` を development 分岐でも実行し続けるのは現状どおりであり、Lambda 用イメージのビルドが失敗しないことを開発 container の起動時に確認するためである。

### runtime・設定・環境構築

**実行条件と設定:**

| identifier / dependency | 値または解決元 | default | 影響する挙動 |
| --- | --- | --- | --- |
| `NODE_ENV` | `docker-compose.yml` の `${ENV:-development}` | `development` | `frontend/entrypoint.sh` の分岐。production なら `yarn start`、それ以外なら `yarn dev` と Tailwind watch |
| Tailwind 入力 | `frontend/package.json` の `build:css` | `src/app/globals.css` | コンパイル対象 |
| Tailwind 出力 | `frontend/package.json` の `build:css` | `src/app/tailwind-output.css` | git ignore 対象の生成物。`.gitignore` により全環境が自前で生成する |
| port | `frontend/entrypoint.sh` の `port` 変数（変更しない） | `18100` | `yarn dev -p` / `yarn start -p`。`docker-compose.yml` の `ports: "18100:18100"` と対応する |

**環境別の完成状態:**

| environment | 配置・起動条件 | 観測可能な結果 |
| --- | --- | --- |
| 開発 container | `yarn install` → `yarn build` → `yarn dev`（`dev` が watcher を内包） | `tailwind-output.css` が生成され、`globals.css` 変更で再生成される。`http://localhost:18100` が dev モードで応答する |
| production container | `yarn install --production=false` → `yarn build` → `yarn start` | `tailwind-output.css` を含むビルド成果物で `yarn start` が応答する |
| Lambda イメージビルド | `yarn install --production=false` → `yarn build` | builder ステージで `.next` と `tailwind-output.css` が生成され、S3 sync が成功する |
| CI build verification | `yarn install --frozen-lockfile` → `yarn build` | `yarn build` が exit 0 |

**不足・不整合時:**

- 開発 container で tailwindcss が同時に 2 プロセス起動する条件: 起動シーケンス上は発生しない。`yarn build` が完了してから `yarn dev` が watcher を起動する順序により構造的に排除される。`docker.md` が MUST で禁じる watcher 競合は、この順序を崩した場合にのみ再発する。
- `tailwind-output.css` が未生成のまま `next build` が走る条件: 発生しない。`build` が Tailwind コンパイルを先に実行してから `next build` を呼ぶため、同じ `build` 内で生成が保証される。
- `docker compose exec frontend` で tailwindcss を手動実行した場合: 起動済み watcher と競合し OOM で watcher が死ぬ。`docker.md` の既存記載どおり `docker compose restart frontend` で復旧する。この禁止事項は変更後も維持される。

**不足・不整合時（watcher の生存）:**

- `watch:css` に `--watch` を使った場合: container 起動後およそ 60 秒で stdin が閉じ、watcher が黙って終了する。エラーは出ないため、`globals.css` を変更しても `tailwind-output.css` が更新されないという症状としてのみ現れる。`--watch=always` を使うことで回避する。

**file配置と既存pattern:**

- `frontend/package.json`: build script の唯一の正本。Tailwind の入出力 path は `build:css` の 1 箇所だけに存在する。
- `frontend/entrypoint.sh`: 環境分岐と script 組み合わせのみ。
- `frontend/buildOnLambda/Dockerfile`: Lambda イメージのビルド手順。
- `.github/workflows/ci-frontend-build-verification.yml`: PR 時のビルド検証。
- `frontend/docs/ai_guideline/development_standard/docker.local.md`: local 開発マシン固有の Docker 事象の正本。
- `frontend/docs/troubleshooting/tailwind/build_and_watch.md`: マシン非依存の Tailwind + Turbopack 特性の正本。

### documentationが成立させる知識

Tailwind の運用を説明する documentation を再構成する。local 開発マシン固有の事象を新設する `docker.local.md` へ分離し、残りを変更後の実態と一致させる。対象は 4 file である。

**file の責務境界:**

| file | 持つもの |
| --- | --- |
| `frontend/docs/ai_guideline/development_standard/docker.md` | container 内実行の原則、基本操作、開発フロー、マルチステージ等の一般規約 |
| `frontend/docs/ai_guideline/development_standard/docker.local.md`（新設） | local 開発マシン固有の事象。壊れ方と復旧手順 |
| `frontend/docs/troubleshooting/tailwind/build_and_watch.md`（新設） | マシンに依存しない Tailwind + Turbopack の特性と工夫 |
| `frontend/docs/ai_guideline/development_standard/README.md` | 上記への索引 |
| `frontend/README.md` | frontend アプリ全体の構成と Tailwind CSS v4 のセットアップ制約 |

**分離の設計意図（2 軸）:** 1 つ目の軸は「local 開発 container だけの話か」である。watcher が動くのは local の開発 container だけである。`.github/workflows/ci-frontend-build-verification.yml` は `yarn build` を一度実行するだけで watcher を起動せず、`frontend/buildOnLambda/Dockerfile` も同様である。したがって「起動済み watcher と競合させない」という MUST 自体が local 限定の規約であり、container 内実行の一般規約と同じ file に置く理由がない。事故と復旧手順だけを切り出して節を分断すると、watcher の情報が 2 file へ分散し、次に踏んだ人がどちらを読むか判断できなくなる。節ごと移す。

2 つ目の軸は「特定のマシンや Docker 環境に依存するか」である。`--watch=always` が必要な理由、`@layer utilities` の tree-shake、反映の遅延、再コンパイル時のメモリ膨張の性質は、Tailwind CSS v4 と Next.js Turbopack の組み合わせに起因し、どのマシンでも成立する。これらを `docker.local.md` へ置くと、Docker 環境固有の事象と混ざって読者が切り分けられなくなる。マシン非依存の特性は `frontend/docs/troubleshooting/tailwind/build_and_watch.md` が持ち、`docker.local.md` は「それが local の Docker 環境でどう壊れ、どう戻すか」だけを持つ。両者は相互に参照し、同じ内容を複製しない。

#### `frontend/docs/troubleshooting/tailwind/build_and_watch.md`（新設）

**読者:** Tailwind のビルドまたは watch の挙動を疑っている人。環境を問わない。

**成立させる判断:** `tailwind-output.css` が期待どおり更新されないとき、watcher の停止、tree-shake、反映の遅延のどれなのかを切り分けられる状態。再コンパイル時のメモリ膨張について、変更量を減らす回避策が成立しないことを知っている状態。

**内容:**

1. 構成。CLI 独立プロセス方式を採る理由と、Next.js から見て「別プロセスが書き出したファイルを import している」形になること
2. `--watch` ではなく `--watch=always` を使う理由。stdin が閉じると watcher が自己終了する
3. 出力が変わらないことが watcher の停止を意味しない 2 つのケース。`@layer utilities` の tree-shake と、反映の遅延
4. 再コンパイル時のメモリ膨張。編集と因果関係がないことを示す実測 4 パターンと、Turbopack 再コンパイル経路という推測
5. 起動済み watcher があるときに Tailwind を二重に走らせない原則

#### `frontend/docs/ai_guideline/development_standard/docker.local.md`（新設）

**読者:** local の開発 container を触る人（AI エージェントを含む）。

**成立させる判断:** container 内で Tailwind をコンパイルする操作を実行してよいかを理由から自分で判断でき、踏んでしまった場合に何が起きているかを表示から読み取り、正しい復旧手段を選べる状態。

**内容:**

1. MUST を禁止コマンドの列挙ではなく理由の側で書く。「起動済み watcher がある状態で、Tailwind をコンパイルする操作を `docker compose exec frontend` から実行しない」とし、競合により OOM が発生して watcher プロセスが死ぬという理由を併記する。
2. 最も踏みやすい具体例として `yarn build` を名指しし、`build:css` を含むため該当することを示す。ビルド確認が目的なら `CI Frontend Build Verification` が同じ検証を行うため container 内で実行する必要がないことを添える。
3. watcher が死んでいる兆候として、`src/app/globals.css` を変更しても `tailwind-output.css` の行数・内容が変わらないことを書く。これは現行 `docker.md` の記述をそのまま引き継ぐ。
4. 通常の復旧手順として `docker compose restart frontend` を書く。再起動経路は `entrypoint.sh` → `yarn dev` → `watch:css` である。
5. **restart が効かない場合の実測事実を書く。** メモリ膨張が Docker VM の Total Memory（実測環境では 7.653GiB）に迫ると、VM 内でプロセス生成が不能になり、`docker compose exec` が `error executing setns process` で失敗する。`next-server` が zombie 化して HTTP が無応答になる一方、`docker compose ps` は `Up` と表示し続けるため、表示だけでは壊れていることが分からない。この状態では `docker compose restart` も `tried to kill container, but did not receive an exit event` で失敗する。復旧には Docker Desktop 本体の再起動が要り、再起動後は全 container が停止するため `docker compose up -d frontend` で起動し直す。
6. **メモリを空けても復旧しないことを書く。** watcher が kill された後はメモリが戻る（実測 909.4MiB / 7.653GiB）。壊れているのはメモリ残量ではなく残存プロセスであるため、host のアプリを閉じても解決しない。

**5 と 6 が必要な理由:** 現行 `docker.md` の記載は「手動実行すると死ぬ」「復旧: `docker compose restart frontend`」までである。実際には restart が通らない状態が存在し、その場合に現行記載どおり restart を試した人は空振りする。また `docker compose ps` が `Up` を表示するため、壊れていること自体に気付くのが遅れる。これらは実際に踏んで実測しないと得られない事実であり、code を読んでも分からない。

#### `frontend/docs/ai_guideline/development_standard/docker.md`

**変更内容:** 「Tailwind watcher のトラブルシューティング」節を削除する。内容は `docker.local.md` へ移す。他の節（コマンド実行環境の原則、基本ルール、運用ルール、開発フロー）は変更しない。

#### `frontend/docs/ai_guideline/development_standard/README.md`

**変更内容:** 索引へ `docker.local.md` の 1 行を追加する。既存の 4 行（`application_architecture.md`、`testing.md`、`formatting.md`、`docker.md`）と同じ形式で、`docker.md` の直後へ置く。

#### `frontend/README.md`「Tailwind CSS v4 セットアップ（制約）」

**読者:** この frontend アプリの Tailwind 構成を初めて触る人。Tailwind 関連の script を追加・変更しようとしている人を含む。

**成立させる判断:** Tailwind のコンパイルがどこで定義され、どの経路で実行されるかを把握でき、新しく Next.js コマンドを叩く script を足すときに CSS の扱いを自分で決められる状態。

**変更内容:**

1. 「`@tailwindcss/cli` を `entrypoint.sh` の `build_tailwind()` で独立プロセス実行する方式を採用」を、`frontend/package.json` の `build:css` で独立プロセス実行する方式へ改める。`build_tailwind()` は削除されるため、この名前を残さない。
2. 「**Lambda ビルド時も要注意**: `buildOnLambda/Dockerfile` では `yarn build` 前に tailwindcss CLI を明示実行すること」の項目を削除する。`yarn build` が `build:css` を含むようになり、この明示実行は不要になるだけでなく、実行すると重複コンパイルになるため、指示として逆方向になる。
3. watcher が死ぬ条件の記述を、`tailwindcss` の手動実行から「Tailwind をコンパイルする操作の手動実行（`yarn build` を含む）」へ広げる。
4. 次の設計原則を同じ節へ追記する。

   > CSS の処理は、それを必要とする Next.js コマンドに随伴させる。`build` は `build:css` を、`dev` は `watch:css` を伴う。新しく Next.js コマンドを叩く script を追加するときは、そのコマンドが CSS を必要とするかで随伴の要否を決める。呼び出し側に 2 つ叩かせない。

**4 が必要な理由:** 変更後の `frontend/package.json` を読めば `build` が `build:css` を伴う構造は分かるが、新しい script を足すときにどう判断するかは読んでも分からない。この原則がないと、`build` だけに CSS を随伴させて `dev` を据え置くような、同じ defect を片側に残す設計へ戻り得る。

**1〜3 が必要な理由:** いずれも変更前の実装を前提にした記述であり、変更後は事実と食い違う。特に 2 は、今回削除する運用そのものを「要注意」として指示しているため、放置すると読み手を誤った操作へ誘導する。

---

## 4. リスクと対策

| リスク | 対策 |
| --- | --- |
| `build` に Tailwind コンパイルを含めた結果、開発 container で watcher と `yarn build` の tailwindcss が競合して OOM が起き、watcher が死ぬ（`docker.md` が MUST で禁じている事象） | 開発分岐を「`yarn build` → `yarn dev`」の順序にし、watcher を起動する `yarn dev` が始まる時点で `yarn build` を完了させることで構造的に排除する |
| `buildOnLambda/Dockerfile` の変更が本番デプロイに影響する | 同 Dockerfile で今回変更するのは tailwind CLI を呼ぶ 1 行の削除だけであり、Lambda 固有の差分（AWS CLI のインストール、`aws s3 sync`、Lambda base image への COPY、`lambdaNextJsHandler`）は変更しない。削除後に残る `yarn build` は production 分岐と CI が実測するものと同一である。変更していない差分を確認するために経路を通す理由がないため実測しない |
| CI workflow の変更で build verification が実質空振りになる | 変更は `Generate Tailwind CSS` step の削除のみで、削除後の `yarn build` が CI 上で実際に走る。`build` が `build:css` を含むため、Tailwind コンパイルの失敗は `yarn build` の失敗として CI に現れる |
| 変更後は `docker compose exec frontend yarn build` が watcher を殺すようになるが、現行 `docker.md` の MUST は `tailwindcss` の直接実行しか禁じていないため、次に踏む人を防げない | MUST を理由の側で書き直し、`yarn build` を具体例として名指しする。記載先は新設する `docker.local.md` とし、コード変更と同じ実行単位で反映する |
| watcher 追随確認のために `globals.css` を変更すると、再コンパイル量に応じて `tailwindcss --watch` が Docker VM の 7.653GiB に対し 5〜6GB まで膨張し、VM 内でプロセス生成が不能になる。`docker compose exec` が `setns` で失敗し、`docker compose restart` も効かなくなる。復旧には Docker Desktop 本体の再起動が要る | 追随確認では `globals.css` を最小の 1 クラス追加に留め、`tailwind-output.css` の mtime と行数の変化だけを観測する。再コンパイル量を抑えて膨張を避ける。観測対象は変わらないため確認の意味は保たれる |

---

## 5. テスト方針

build script の変更は自動テストの対象外であり、`yarn test` が通ることは今回の変更が正しいことを示さない。観測手順を個別に定める。

**共通検証:**

1. `grep -rn "tailwindcss -i" frontend/ .github/`（`node_modules` 除外）の結果が `frontend/package.json` の 1 行だけであること。
2. `docker compose restart frontend` 後、`docker compose logs frontend` で `yarn build` の成功と dev サーバの起動を確認し、`frontend/src/app/tailwind-output.css` が生成されていること。
3. `frontend/src/app/globals.css` へ**最小の 1 クラス追加**だけを行い、`tailwind-output.css` の mtime と行数が変化すること。確認後に追加分を元へ戻し、再び変化することを確認する。観測方法は「watcher が死んでいる兆候」を逆向きに使う。`globals.css` を大きく書き換えると再コンパイル量が増えて watcher が VM を食い潰すため、変更量を最小に保つ。
4. `visual-inspector` で `http://localhost:18100` を撮影し、Tailwind のスタイルが当たっていること。`testing.md` の「UI変更の動作確認」に従い、agent が先に確認して観測結果とスクリーンショットを報告する。ユーザーが報告を受けて進めてよいと述べるまで commit / push / PR へ進まない。
5. `docker compose exec frontend yarn test` と `docker compose exec frontend yarn lint` が通ること。
6. PR 作成後、`CI Frontend Build Verification` / `CI Frontend Test` / `CI Frontend Lint` が green であること。

**production 分岐の実測:**

7. `docker compose stop frontend` で開発 container を停止する。
8. `ENV=production docker compose up -d frontend` で production 分岐を起動し、`docker compose logs frontend` で `yarn install --production=false` → `yarn build` → `yarn start` の順に進むことを確認する。
9. `http://localhost:18100` が応答することを確認する。
10. `docker compose stop frontend` の後 `docker compose up -d frontend` で development へ戻し、共通検証 2 と 3 を再確認する。production 分岐の実測が開発 container の状態を壊していないことを確かめる。

**実行しない操作:**

`docker compose exec frontend yarn build` は実行しない。変更後はこれが起動済み watcher と競合し、OOM で watcher を殺すためである。ビルドの成否は container の起動ログと CI から判定する。

**検証範囲を決める判断基準:**

本番影響のある変更については、test in production でしか確認できない部分を除き、できるだけローカルで再現して確認する。「変わるのは `yarn build` の中身だけであり別経路で実測される」という論理は正しいが、その論理だけを根拠に本番影響のある経路そのものを一度も通さないことは選ばない。production 分岐は本番 container が実際に通る経路であり、ローカルで再現できるため通す。

Lambda イメージビルド（`docker compose build frontend_next_lambda`）は実測しない。実行コストが理由ではなく、Lambda 固有の差分を今回変更していないためである。今回この Dockerfile で変えるのは tailwind CLI を呼ぶ 1 行の削除だけで、それは production 分岐と CI が実測する `yarn build` と同じ領域にある。

この基準は「ローカルで再現できるか」と「今回その差分を変更したか」の 2 つで構成される。ローカルで再現でき、かつ今回変更した領域を含む経路は通す。今回変更していない差分しか持たない経路は通さない。

---

## （付録）変更の実行区分

### task-design内で対象成果物へ適用済み

| 対象 | 反映内容 | validation結果 | 参照するdesign section |
| --- | --- | --- | --- |
| `frontend/docs/ai_guideline/development_standard/testing.md` | 「UI変更の動作確認」の後へ「検証範囲の決め方」節を追加。自動テストが対象にしない変更について、「ローカルで再現できるか」「今回その経路に固有の差分を変更したか」の 2 問で実測対象を決めることを定め、実行時間を理由に本番影響のある経路の実測を省くことを PROHIBITED とした | 追加 22 行。既存節を変更していないことを diff で確認。`frontend` / `backend` の既存 `testing.md` に同等記述がないことを確認済み | [テスト方針](#5-テスト方針) |

この追加は今回の実装変更へ依存しない。今回の変更が入る前でも後でも正しい内容であるため、`execution plan対象`へ載せずここで適用した。

### task-design内の対象成果物反映待ち

なし

### execution plan対象

| 対象 | 掲載理由 | 参照するdesign section |
| --- | --- | --- |
| `frontend/package.json` | 本番成果物である frontend アプリの build 設定を変更する。`build` / `dev` の内容が変わり、`build:css` / `watch:css` を新設する | [callerが依存するcontract](#callerが依存するcontract) |
| `frontend/entrypoint.sh` | 本番成果物の runtime 起動設定を変更する。development / production 両分岐の実行順序が変わる | [callerが依存するcontract](#callerが依存するcontract) / [runtime・設定・環境構築](#runtime設定環境構築) |
| `frontend/buildOnLambda/Dockerfile` | 本番 Lambda イメージのビルド手順を変更する。tailwind CLI を呼ぶ行を削除する | [runtime・設定・環境構築](#runtime設定環境構築) |
| `.github/workflows/ci-frontend-build-verification.yml` | PR 時のビルド検証手順を変更する。`Generate Tailwind CSS` step を削除する | [runtime・設定・環境構築](#runtime設定環境構築) |
| `frontend/docs/ai_guideline/development_standard/docker.md` | 上記 4 件が入って初めて正しい記述になるため、同じ実行単位で反映する必要がある。先に単独で更新すると存在しない状態を説明することになる | [documentationが成立させる知識](#documentationが成立させる知識) |
| `frontend/README.md` | 上記 4 件が入ると「Tailwind CSS v4 セットアップ（制約）」節の 3 箇所が事実と食い違う。とりわけ Lambda ビルド前の tailwindcss CLI 明示実行は、今回削除する運用を指示したまま残るため、同じ実行単位で反映する必要がある | [documentationが成立させる知識](#documentationが成立させる知識) |
| `frontend/docs/ai_guideline/development_standard/docker.local.md` | 新設。`docker.md` から移す watcher の規約に加え、実装中に実測した壊れ方と復旧手順を持つ。`docker.md` からの削除と同じ実行単位で行わないと、知識が一時的に失われる | [documentationが成立させる知識](#documentationが成立させる知識) |
| `frontend/docs/ai_guideline/development_standard/README.md` | `docker.local.md` の新設に伴う索引の追加。索引に載らない file は探索導線から外れる | [documentationが成立させる知識](#documentationが成立させる知識) |
| `frontend/docs/troubleshooting/tailwind/build_and_watch.md` | 新設。マシンに依存しない Tailwind + Turbopack の特性を持つ。`docker.local.md` と同じ実行単位で作らないと、内容が Docker 環境固有の記述と混ざったまま残る | [documentationが成立させる知識](#documentationが成立させる知識) |

上記 9 件は一つの実装 loop で完了できるため leaf として `tasklist.md` を作る。production 分岐の実測が開発 container の停止と復帰を伴うため、実行時に順序と中間確認が必要である。
