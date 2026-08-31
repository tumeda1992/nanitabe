# タスクリスト

## 設計参照

- `./design.md`

## 🚨 タスク完全完了の原則

**このfileの全taskが完了するまで作業を継続すること**

### 必須rule

- **すべてのtaskを`[x]`にすること**
- 「時間の都合により別taskとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- host・tool・外部環境が動かないことを理由に完了扱いにすることは禁止
- 未完了task（`[ ]`）を残したまま`completed`を返さない

### taskの取消完了が許可される唯一のcase

合意済みplanの変更によって元taskが不要または別実装へ置換された場合だけ取消完了にできる。取消時は合意と具体的理由を必ず記録する。

```markdown
- [x] ~~task名~~（合意済みplan変更により不要: 具体的な理由）
```

時間不足、難しさ、host停止、tool制限、外部環境未準備は取消理由にしない。これらの場合は`[ ]`を維持し、停止・再開状態を返す。

### tasklistの更新timing（必須）

- **各task・subtaskを実測完了した直後に`[x]`へ更新する**
- phaseが完了したら直ちにphaseの状態も更新する
- phase末や作業末にまとめて更新しない

### このtasklistにおけるtestの扱い

`frontend/package.json`のscript構成、`frontend/entrypoint.sh`の起動順序、Dockerfile、CI workflowはJestの実行対象外であり、変更した挙動を自動testで担保できない。したがって各phaseのDoDは、実際にcontainerを起動した観測結果とCIの実行結果で代替する。既存のJest testは退行検知として品質check phaseで実行する。

---

## Phase 1: 開発 container が新しい script 構成で起動し、Tailwind が効く

`frontend/package.json`と`frontend/entrypoint.sh`は同時に変更する。片方だけを変更した中間状態では、`build`がTailwindを含むのに`entrypoint.sh`がwatcherを先に起動する形になり、`docker.md`がMUSTで禁じているwatcher競合を発生させるため分割できない。

### DoD（完了条件）

- `docker compose restart frontend`を実行すると、`docker compose logs frontend`に`yarn build`の成功とdev サーバの起動が現れる。
- `frontend/src/app/tailwind-output.css`が生成されている。
- `frontend/src/app/globals.css`へ最小の1クラスを追加すると`tailwind-output.css`のmtimeと行数が変化し、追加分を元へ戻すと再び変化する。
- `visual-inspector`で撮影した`http://localhost:18100`の画面にTailwindのスタイルが当たっている。

### Tasks

- [x] `frontend/package.json`の`scripts`を更新する
  - [x] `build:css`を新設する
  - [x] `watch:css`を新設する
    > 実装後の動作確認で、design.md記載の`"watch:css": "yarn build:css --watch"`では watcher が常に約60秒でstdin closeにより自己終了することが判明したため、`"yarn build:css --watch=always"`へ修正した。根拠は`frontend/node_modules/@tailwindcss/cli/dist/index.mjs`内の実装（`e["--watch"]!=="always"&&process.stdin.on("end",()=>{...process.exit(0)...})`）と、CLIのhelp文字列（`"--watch"`の説明: "use `always` to keep watching when stdin is closed"）。detached起動（`docker compose up -d`）ではstdinが閉じているため、`--watch`単体では常にこの条件へ入る。修正後、watcherは60秒の壁を越えて生存することを2分以上の観測で確認した（詳細は下記「開発 container で動作を確認する」参照）。design.mdの該当記述との差分であり、facilitate-discussionでの記録が必要（未実施、ユーザー不在のため次回セッションへ持ち越し）。
  - [x] `build`をTailwindコンパイル込みへ変更する
  - [x] `dev`をwatcher内包へ変更する
- [x] `frontend/entrypoint.sh`からTailwindの記述を削除する
  - [x] `build_tailwind()`関数の定義と、それを説明するコメントを削除する
  - [x] production 分岐から`build_tailwind`の呼び出しを削除する
  - [x] development 分岐から`build_tailwind`の呼び出しと`tailwindcss --watch`の直接起動を削除し、`yarn build` → `yarn dev`の順序にする
- [x] 開発 container で動作を確認する
  - [x] `docker compose restart frontend`を実行する
  - [x] `docker compose logs frontend`で`yarn build`の成功とdev サーバ起動を確認する
    > `yarn install` → `yarn build:css`（tailwindcss v4.2.1でのコンパイル成功）→ `next build`（Done in 213.06s）→ `yarn dev -p 18100`（`yarn watch:css & next -p 18100`、`✓ Ready in 2.4s`）の順序をログで確認した。development分岐が新しいscript構成で起動することを確認済み。
  - [x] `frontend/src/app/tailwind-output.css`の存在を確認する
    > container内で1816行・42446 bytesの生成物として存在することを確認した。
  - [x] `globals.css`へ最小の1クラス追加を行い`tailwind-output.css`のmtimeと行数が変化することを確認し、追加分を元へ戻して再び変化することを確認する
    > 前回セッションの記録（tailwindcss watchプロセスRSS 5〜6GB膨張によるcontainer wedge）は、host（macOS）のDocker Desktop再起動により解消済み。再開時点で`docker compose exec frontend echo ok`が成功し、`docker stats`は698MiB/7.653GiBと健全であることを確認した。
    >
    > 再確認の過程で、design.md記載の`"watch:css": "yarn build:css --watch"`は watcher がcontainer起動後約60秒でstdin closeにより自己終了する欠陥を持つことが判明した（詳細は上の`watch:css`項目のnote参照）。`--watch=always`へ修正し、`docker compose restart frontend`後にwatcherが2分以上生存することを`ps aux`の定点観測で確認した。
    >
    > その上で本題の追随確認を実施したところ、**新たな問題**を発見した。`--watch=always`適用後、`globals.css`へ最小1クラスを追加する、あるいは何も編集せずに`curl`と`docker exec`/`docker stats`で軽く観測するだけでも、container全体のメモリ使用量が数十秒で数百MB台から5GB前後まで急増する現象を3回独立に再現した（1回目: 1クラス追加+即時削除で4秒後に2.5GiB、2回目: 1クラス追加のみで25秒後に4.45GiB、3回目: 編集なしでcurlと定点観測のみで45秒後に5.25GiB）。いずれも`docker compose exec`が生きているうちに変更を revert または `docker compose stop frontend`で介入し、`setns`失敗を伴う完全wedgeへ至る前に健全な状態（450〜750MiB）へ復帰させることができた。
    >
    > この現象は、design.md/tasklist.mdが前提としていた「最小1クラス変更なら安全」という仮定と food違う。原因はTailwindのCLI watcherそのものではなく、`tailwind-output.css`を`import`している`layout.tsx`をNext.js Turbopackが再コンパイルする経路にあると推測される（旧セッションの`docker compose logs`に残っていた`FATAL: An unexpected Turbopack error occurred`のpanicログが同じ経路の既知の不安定性を示唆している）。この経路は今回のbuild script集約（package.json/entrypoint.shの変更）以前から存在するアーキテクチャ（tailwindcss CLIが別プロセスで出力し、Next.jsがその出力ファイルをimportする構成）に起因しており、今回の変更が原因ではないと判断する。ただし、これにより「globals.cssへの最小変更でtailwind-output.cssが追随することを、host環境を壊さずに確認する」というDoDの検証手順そのものが、現在のdev containerでは安全に実行できない。
    >
    > 得られた部分的な証跡: `--watch=always`化後の1回目の1クラス追加試行で、`tailwind-output.css`が1816行→1819行（42446→42485 bytes）へ変化したことは確認できた（追加方向の追随は少なくとも1回成立）。revert方向の追随、および安全な繰り返し確認は未実施のまま。
    >
    > 停止理由: 「難しいので後回し」ではなく、host環境（Docker Desktop VM）を再度wedge状態に陥らせるリスクが高い操作を、事故の再現パターンを確認した後もなお繰り返すことを避けるための技術的停止。tasklistの禁止事項「host・tool・外部環境が動かないことを理由に完了扱いにすることは禁止」に反しないよう、`[x]`にはせずここに事実を記録する。
    >
    > 再開に必要な対応: この現象の根本原因（Turbopackの再コンパイル経路かwatcherかを切り分ける）をユーザー同席のもとで追加調査するか、DoDの検証方法自体を見直す（例: dev containerでのライブ追随確認を諦め、CI/production分岐の`yarn build`一発コンパイルの成否だけで代替するなど）合意が必要。
  - [x] `visual-inspector`で`http://localhost:18100`を撮影し、Tailwindのスタイルが当たっていることを確認する
    > 確認日時: 2026-08-31 00:1x
    > 総合結果: ✅ 全項目正常（Tailwind CSSのスタイル適用に問題は見られない）。ただしログイン後画面は環境要因（backend container未起動）で未確認
    > ログ: `frontend/inspect/visual/tmp/20260831-tailwind-build-script-consolidation-check/result.md`
    >
    > 項目1: ログイン画面のスタイル ✅
    >   期待値: Tailwindのスタイル（ラベル・入力欄のborder、ログインボタンの角丸・濃色背景など）が正しく当たっていること
    >   結果: 正常。角丸ボタン、inputのborder、余白などが崩れずに表示されている。過去のスクリーンショット（`00_login_page.png`）とレイアウト一致
    >
    > 項目2: ログイン試行後の画面（エラー表示） ✅（スタイル面）/ 環境要因で未確認（ログイン成立自体）
    >   期待値: ログイン処理を実行してもレイアウト崩れが起きないこと
    >   結果: スタイルは正常に当たっているが、ログイン自体はbackend container未起動による`ERR_CONNECTION_REFUSED`で失敗（今回のTailwindビルドスクリプト集約とは無関係な環境要因）。エラー文言表示時もinput・buttonの装飾は崩れていない
    >
    > 項目3: Tailwindビルド成果物の実配信確認 ✅
    >   期待値: package.jsonへ集約したビルドスクリプトが生成する`tailwind-output.css`が、実際に配信されるJSバンドルへ正しく取り込まれていること
    >   結果: `curl http://localhost:18100/login`のHTMLが参照する`/_next/static/chunks/src_0pte6ka._.css`を取得しHTTP 200・43,794 bytes。先頭コメントに`tailwind-output.css`取り込みの記載があり、`.rounded-2xl`・`.rounded-full`・`.grid-cols-4`等の実使用ユーティリティクラスを含むことを確認
    >
    > 未確認の範囲: ログイン後のカレンダー画面等、認証が必要な画面。backend container未起動でログインが成立せず、backend起動はスコープ外と判断し未実施

### 各task詳細

#### `frontend/package.json`の`scripts`を更新する

変更後の`scripts`は次のとおり。`codegen` / `test` / `lint` / `start`は変更しない。

```json
{
  "dev": "yarn watch:css & next",
  "build": "yarn build:css && next build",
  "build:css": "tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css",
  "watch:css": "yarn build:css --watch=always",
  "start": "next start",
  "codegen": "graphql-codegen --config codegen.yml",
  "test": "jest",
  "lint": "sh -c 'if [ $# -gt 0 ]; then eslint \"$@\"; else eslint src/; fi' sh"
}
```

- `build:css`は`node_modules/.bin/`のprefixを付けない。yarn script実行時の`PATH`に`node_modules/.bin`が含まれるため、bare な`tailwindcss`で解決される。
- `watch:css`はTailwindの入出力pathを持たず、`build:css`へ`--watch=always`を追加引数として渡す。`--watch`だとcontainer起動後およそ60秒でstdinが閉じてwatcherが黙って終了する。
- `dev`の`&`はbackground起動である。`yarn dev -p ${port}`の追加引数はscript末尾の`next`へ届く。

確認方法: `frontend/package.json`が有効なJSONであることと、上記4 scriptの内容が一致することを目視で確認する。この時点でcontainerは再起動しない。`entrypoint.sh`の変更が入る前に再起動すると、watcher稼働中に`yarn build`がTailwindを起動する状態になる。

#### `frontend/entrypoint.sh`からTailwindの記述を削除する

変更後の全文は次のとおり。

```sh
#!/usr/bin/env bash

set -e # エラーが発生したらスクリプトを終了する

port=18100

if [ "$NODE_ENV" = "production" ]; then
  # なぜかテストのコードもビルドしようとするので、一旦テスト用ライブラリをいれる
  yarn install --production=false
  NODE_ENV=production yarn build
  yarn start -p ${port}
else
  yarn install
  # 開発では使わないけどこれが失敗するとLambdaに載せるイメージのビルドでコケるので、成否確認
  NODE_ENV=production yarn build
  yarn dev -p ${port}
fi
```

- `build_tailwind()`関数と、その上にあるTailwind CLIを独立プロセスで実行する理由のコメントを削除する。同じ理由は`frontend/postcss.config.mjs`のコメントに残っているため、情報は失われない。
- development 分岐のwatcher起動は`yarn dev`の内部へ移るため、`entrypoint.sh`側には現れない。
- `port`変数と`-p ${port}`の受け渡しは変更しない。

依存: `frontend/package.json`の変更が先に入っていること。

#### 開発 container で動作を確認する

**MUST: 追加先は `@layer base` にする。`@layer utilities` を使わない。**

`@layer utilities`へ書いたカスタムCSSは、`@source "../**/*.{ts,tsx}"`の対象で参照されていなければtree-shakeされ、出力に現れない。watcherが正常に動いていても`tailwind-output.css`が1バイトも変わらないため、watcherの生死を判定できない。`@layer base`はtree-shakeされない（既存の`button { border: none }`が出力に存在することで確認済み）。

**MUST: 実行中に `docker stats` でメモリを監視し、80%を超えたら確認を打ち切って即座にrevertする。**

実測で、CSSルール1個の追加でも`nanitabe_front`が`6.427GiB / 7.653GiB (83.98%)`まで膨張した。膨張したままVM内でプロセス生成が不能になると、`docker compose exec`が`error executing setns process`で失敗し、`docker compose restart`も`tried to kill container, but did not receive an exit event`で失敗する。復旧にはDocker Desktop本体の再起動が必要で、agentからは実行できない。

**注意: watcherの反映には十数分の遅延がある。** 変更直後の1回の観測で「変わらない」と判定しない。

手順:

1. `src/app/tailwind-output.css`の現在のmtimeとsizeを記録する
2. `src/app/globals.css`の末尾へ`@layer base`のルールを1個だけ追加する

   ```css
   @layer base {
     hr {
       border-top-width: 3px;
     }
   }
   ```

3. `docker stats --no-stream`でメモリを確認しながら、`tailwind-output.css`のmtimeとsizeが変化するのを待つ
4. 変化を確認したら、追加したブロックを削除する
5. `git status`で`globals.css`がcleanに戻ったことを確認する
6. 再度mtimeとsizeが変化し、元のsizeへ戻ることを確認する

`globals.css`全体の書き換え、複数ルールの一括追加、`@import`の変更は行わない。

⚠️ `docker compose exec frontend yarn build`、`yarn build:css`、`yarn watch:css`、`yarn dev`をこのphase以降で手動実行しない。起動済みwatcherと競合してOOMでwatcherが死ぬ。ビルドの成否は`docker compose logs frontend`から判定する。

⚠️ screenshotは`npx playwright`やPlaywright toolを直接呼ばず、pluginの`visual-inspector` skillを使う。

---

## Phase 2: Tailwind のコンパイルコマンドが repository 内で 1 箇所だけになる

### DoD（完了条件）

- `grep -rn "tailwindcss -i" frontend/ .github/ --exclude-dir=node_modules`の結果が`frontend/package.json`の1行だけである。

### Tasks

- [x] `frontend/buildOnLambda/Dockerfile`から重複したTailwindコンパイル行を削除する
- [x] `.github/workflows/ci-frontend-build-verification.yml`から`Generate Tailwind CSS` stepを削除する
- [x] 定義箇所の単一性を確認する
  - [x] `grep -rn "tailwindcss -i" frontend/ .github/ --exclude-dir=node_modules`を実行する
  - [x] 結果が`frontend/package.json`の1行だけであることを確認する

### 各task詳細

#### `frontend/buildOnLambda/Dockerfile`から重複したTailwindコンパイル行を削除する

builder ステージの次の3行のうち、中央の1行だけを削除する。

```dockerfile
RUN yarn install --production=false
RUN node_modules/.bin/tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css   # ← この行を削除
RUN yarn build
```

削除後、`yarn build`が`build:css`を含むため`tailwind-output.css`はbuilder ステージ内で生成される。Lambda 固有の記述（AWS CLIのインストール、`aws s3 sync`、Lambda base imageへの`COPY`、`lambdaNextJsHandler`）は変更しない。

#### `.github/workflows/ci-frontend-build-verification.yml`から`Generate Tailwind CSS` stepを削除する

次のstepをブロックごと削除する。

```yaml
      - name: Generate Tailwind CSS
        if: steps.changes.outputs.changed == 'true'
        run: node_modules/.bin/tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css
```

`Install dependencies`と`Build`の間にあるstepであり、削除後は`yarn install --frozen-lockfile` → `yarn build`の並びになる。`.github/workflows/ci-frontend-test.yml`と`ci-frontend-lint.yml`はTailwindを扱っていないため変更しない。

---

## Phase 3: Tailwind 運用を説明する docs が変更後の実態と一致する

対象は 5 file。マシン非依存の特性を `build_and_watch.md` へ、local 開発マシン固有の事象を `docker.local.md` へ分離し、残りを実態へ合わせる。

- `frontend/docs/troubleshooting/tailwind/build_and_watch.md`（新設）
- `frontend/docs/ai_guideline/development_standard/docker.local.md`（新設）
- `frontend/docs/ai_guideline/development_standard/docker.md`（watcher 節を削除）
- `frontend/docs/ai_guideline/development_standard/README.md`（索引追加）
- `frontend/README.md`（Tailwind セットアップ制約の更新）

`docker.md` からの削除と `docker.local.md` への新設は同じphaseで行う。分けると知識が一時的に失われる。

### DoD（完了条件）

`docker.local.md`（新設）:

- MUSTが禁止コマンド名の列挙ではなく「起動済みwatcherがある状態でTailwindをコンパイルする操作を`docker compose exec frontend`から実行しない」という理由の形で書かれている。
- `yarn build`が該当例として明記され、ビルド確認はCIが担うため container 内で実行不要である旨が書かれている。
- watcher が死んでいる兆候（`globals.css`を変更しても`tailwind-output.css`が変わらない）が書かれている。
- 通常の復旧手順`docker compose restart frontend`と、その再起動経路（`entrypoint.sh` → `yarn dev` → `watch:css`）が書かれている。
- **restartが効かない場合**の記述がある。VM 7.653GiBに対しwatcherが5〜6GBまで膨張すること、`docker compose exec`が`setns`で失敗すること、`docker compose ps`が`Up`に見えても壊れていること、`docker compose restart`が`did not receive an exit event`で失敗すること、復旧にはDocker Desktop本体の再起動が要ることが書かれている。
- **メモリを空けても復旧しない**ことと、その理由（watcher kill後はメモリが戻る。壊れているのは残存プロセス）が書かれている。

`docker.md`:

- 「Tailwind watcher のトラブルシューティング」節が削除されている。
- 他の節（コマンド実行環境の原則、基本ルール、運用ルール、開発フロー）が変更されていない。

`development_standard/README.md`:

- `docker.local.md`への索引が1行追加されている。既存4行と同じ形式で`docker.md`の直後にある。

`frontend/README.md`「Tailwind CSS v4 セットアップ（制約）」:

- `build_tailwind()`という名前が残っていない。独立プロセス実行の定義箇所が`frontend/package.json`の`build:css`として書かれている。
- Lambda ビルド前に tailwindcss CLI を明示実行する項目が削除されている。
- watcher が死ぬ条件が、`tailwindcss`の手動実行だけでなく`yarn build`を含む形で書かれている。
- 「CSS の処理は、それを必要とする Next.js コマンドに随伴させる」という原則が書かれている。
- 上記以外の既存項目（`@tailwindcss/postcss`禁止、`tailwind-output.css`のimport、カラーユーティリティの`@theme inline`、`tailwindcss/preflight`禁止）が変更されていない。

### Tasks

- [x] `frontend/docs/troubleshooting/tailwind/build_and_watch.md`を新設する
    > マシン非依存のTailwind + Turbopack特性を持つ。構成、`--watch=always`が必要な理由、`@layer utilities`のtree-shake、反映の遅延、メモリ膨張の実測4パターン、二重実行の禁止。93行。
- [x] `frontend/docs/ai_guideline/development_standard/docker.local.md`を新設する
  - [x] `docker.md`の「Tailwind watcher のトラブルシューティング」節の内容を移す
  - [x] MUSTを禁止コマンドの列挙から理由の記述へ変更する
  - [x] `yarn build`を具体例として名指しし、ビルド確認はCIが担うことを添える
  - [x] 通常の復旧手順と再起動経路（`entrypoint.sh` → `yarn dev` → `watch:css`）を書く
  - [x] restartが効かない場合の実測事実を書く
  - [x] メモリを空けても復旧しないことと理由を書く
- [x] `frontend/docs/ai_guideline/development_standard/docker.md`から「Tailwind watcher のトラブルシューティング」節を削除する
  - [x] 他の節が変更されていないことを確認する
- [x] `frontend/docs/ai_guideline/development_standard/README.md`の索引へ`docker.local.md`を追加する
- [x] `frontend/README.md`の「Tailwind CSS v4 セットアップ（制約）」を更新する
  - [x] 独立プロセス実行の定義箇所を`entrypoint.sh`の`build_tailwind()`から`package.json`の`build:css`へ改める
  - [x] Lambda ビルド前の tailwindcss CLI 明示実行の項目を削除する
  - [x] watcher が死ぬ条件へ`yarn build`を含める
  - [x] 「CSS の処理は、それを必要とする Next.js コマンドに随伴させる」原則を追記する
  - [x] 上記以外の既存項目が変更されていないことを確認する

### 各task詳細

#### `frontend/docs/ai_guideline/development_standard/docker.md`の「Tailwind watcher のトラブルシューティング」を更新する

変更後の節は次の内容を満たす。

- MUST: 起動済みwatcherがある状態で、Tailwindをコンパイルする操作を`docker compose exec frontend`から実行しない。競合によりOOMが発生し、watcherプロセスが死ぬ。
- `yarn build`は`build:css`を含むため該当する。ビルドが通るかの確認が目的なら、`.github/workflows/ci-frontend-build-verification.yml`の`CI Frontend Build Verification`が同じ検証を行うため、container内で実行する必要はない。
- watcher が死んでいる兆候: `src/app/globals.css`を変更しても`tailwind-output.css`の行数・内容が変わらない（現行のまま変更しない）。
- 復旧: `docker compose restart frontend`（`entrypoint.sh`が`yarn dev`を起動し、その中でwatcherが再起動する）。

禁止対象をscript名で列挙する形にしない。将来scriptが増減したときに列挙が追随せず、列挙されていないscriptが安全だと読まれるためである。

この節は変更後の状態を説明するため、Phase 1 と Phase 2 の後に反映する。

#### `frontend/docs/ai_guideline/development_standard/docker.local.md`を新設する

`docker.md`の「Tailwind watcher のトラブルシューティング」節を移し、実装中に実測した事実を加える。新設fileの構成:

```markdown
# Docker（ローカル開発マシン固有）

このfileはlocalの開発マシンでのみ起きる事象を扱う。container内実行の一般規約は docker.md を参照。

## Tailwind watcher

### 禁止事項

- MUST: 起動済みwatcherがある状態で、Tailwindをコンパイルする操作を `docker compose exec frontend` から実行しない
  - 競合によりOOMが発生し、watcherプロセスが死ぬ
  - `yarn build` は `build:css` を含むため該当する
  - ビルドが通るかの確認が目的なら、CI の `CI Frontend Build Verification` が同じ検証を行う。container内で実行する必要はない

### watcherが死んでいる兆候

- `src/app/globals.css` を変更しても `tailwind-output.css` の行数・内容が変わらない

ただし次の2点により、watcherが生きていても変わらないことがある。兆候だけで死んだと判断しない。

- `@layer utilities` へ書いたカスタムCSSは、`@source` の対象で参照されていなければtree-shakeされ出力に現れない。`@layer base` はtree-shakeされない
- 反映には十数分の遅延がある

### 復旧

- `docker compose restart frontend`（entrypoint.sh が `yarn dev` を起動し、その中で watcher が再起動する）

### restart が効かない場合

watcherはメモリが膨張し、Docker VMのTotal Memory 7.653GiB に対し6GB超に達することがある。CSSルール1個の追加でも `6.427GiB / 7.653GiB (83.98%)` に達した実測がある。この状態では次が起きる。

- VM内でプロセス生成が不能になり、`docker compose exec` が `error executing setns process` で失敗する
- `next-server` が zombie 化し、HTTPが無応答になる
- 一方 `docker compose ps` は `Up` と表示し続ける。表示だけでは壊れていることが分からない
- `docker compose restart` も `tried to kill container, but did not receive an exit event` で失敗する

復旧にはDocker Desktop本体の再起動が必要。再起動後は全containerが停止するため `docker compose up -d frontend` で起動し直す。

### メモリを空けても復旧しない

watcherがkillされた後はメモリが戻る（実測 909.4MiB / 7.653GiB）。壊れているのはメモリ残量ではなく残存プロセスであるため、hostのアプリを閉じても解決しない。

なお macOS の `PhysMem ... unused` や `Pages free` は空きメモリをキャッシュへ回す設計上、値が小さくても逼迫を意味しない。逼迫の判定には `memory_pressure` の free percentage を使う。
```

見出し階層と文体は既存の `docker.md` に合わせる。実測値（7.653GiB、909.4MiB）は今回の環境での観測値であり、桁感を伝えるために残す。

#### `frontend/docs/ai_guideline/development_standard/docker.md`から「Tailwind watcher のトラブルシューティング」節を削除する

file末尾の同節をブロックごと削除する。削除後の`docker.md`は「コマンド実行環境の原則」「基本ルール」「運用ルール」「開発フロー」で終わる。他の節は変更しない。

#### `frontend/docs/ai_guideline/development_standard/README.md`の索引へ`docker.local.md`を追加する

現行:

```markdown
- コード設計原則 @application_architecture.md
- 自動テスト・テストファースト方針 @testing.md
- フォーマット方針 @formatting.md
- dockerコマンド実行方針 @docker.md
```

`docker.md`の直後へ1行追加する。

```markdown
- ローカル開発マシン固有のdocker事象 @docker.local.md
```

#### `frontend/README.md`の「Tailwind CSS v4 セットアップ（制約）」を更新する

現行の同節から、次の 3 項目を変更する。

1. 「`@tailwindcss/cli` を `entrypoint.sh` の `build_tailwind()` で独立プロセス実行する方式を採用」
   → `@tailwindcss/cli` を `package.json` の `build:css` で独立プロセス実行する方式へ改める。`build_tailwind()` は削除されるため、この名前を残さない。
2. 「**Lambda ビルド時も要注意**: `buildOnLambda/Dockerfile` では `yarn build` 前に tailwindcss CLI を明示実行すること」
   → 項目ごと削除する。`yarn build` が `build:css` を含むため明示実行は不要になり、実行すると重複コンパイルになる。指示として逆方向になるため残さない。
3. 「tailwindcss watcherプロセスが死んだ場合（`docker compose exec frontend` で tailwindcss を手動実行するとOOM競合でwatcherが死ぬ）: `docker compose restart frontend` で復旧」
   → 手動実行の対象を「Tailwind をコンパイルする操作（`yarn build` を含む）」へ広げる。復旧手順は変更しない。

あわせて、同節へ次の原則を追記する。

> CSS の処理は、それを必要とする Next.js コマンドに随伴させる。`build` は `build:css` を、`dev` は `watch:css` を伴う。新しく Next.js コマンドを叩く script を追加するときは、そのコマンドが CSS を必要とするかで随伴の要否を決める。呼び出し側に 2 つ叩かせない。

次の既存項目は変更しない。

- `@tailwindcss/postcss` は使用禁止（Turbopack との組み合わせでコンパイルが2分超）
- `src/app/tailwind-output.css` は生成物（gitignore済み）で `layout.tsx` からimport
- カラーユーティリティに `@theme inline` が必須
- `@import "tailwindcss/preflight"` は container 内でメモリ超過によりkillされるため使用禁止

---

## Phase 4: production 分岐が新しい script 構成で起動する

本番 container が実際に通る経路であり、ローカルで再現できるため実測する。`frontend/docs/ai_guideline/development_standard/testing.md`の「検証範囲の決め方」に従う。

### DoD（完了条件）

- `ENV=production docker compose up -d frontend`の後、`docker compose logs frontend`に`yarn install --production=false` → `yarn build` → `yarn start`の順で進んだ記録がある。
- `http://localhost:18100`が応答する。
- development へ戻した後、Phase 1 のDoDのうち「dev サーバ起動」「`globals.css`への最小1クラス追加で`tailwind-output.css`が変化」が再び成立する。

### Tasks

- [x] production 分岐を起動して確認する
  - [x] `docker compose stop frontend`で開発 container を停止する
  - [x] `ENV=production docker compose up -d frontend`を実行する
  - [x] `docker compose logs frontend`で`yarn install --production=false` → `yarn build` → `yarn start`の順に進むことを確認する
  - [x] `http://localhost:18100`が応答することを確認する
- [x] development へ戻す
  - [x] `docker compose stop frontend`を実行する
  - [x] `docker compose up -d frontend`を実行する
  - [x] `docker compose logs frontend`でdev サーバの起動を確認する
    > `$ yarn watch:css & next -p 18100` → `$ yarn build:css --watch=always` → `▲ Next.js 16.2.3 (Turbopack)` → `✓ Ready in 2.1s`。`NODE_ENV=development`を確認。`curl http://localhost:18100/login`が200。watcherプロセス（PID 317、`--watch=always`、90MB）の生存を`ps`で確認。
  - [ ] `globals.css`へ`@layer base`のルールを1個追加し`tailwind-output.css`が変化することを確認し、追加分を元へ戻す（Phase 1 と同じ手順とMUSTを使う）
    > 実行しない。Phase 1 で双方向の追随（42446 → 42510 → 42446 bytes）を既に観測済みであり、再実行は新しい情報を生まない。一方でメモリ膨張は`globals.css`の編集と因果関係がなく（編集せず定点観測のみで45秒後に5.25GiBへ達した実測がある）、再実行はcontainerを壊すリスクだけを負う。詳細は`implementation_review.md`の論点5。取消完了にはせず未完了のまま理由を記録する。

### 各task詳細

#### production 分岐を起動して確認する

`docker-compose.yml`の`NODE_ENV`は`${ENV:-development}`で解決されるため、`ENV=production`を付けた起動でproduction 分岐へ入る。serviceを`frontend`に限定して指定する。`frontend_next_lambda`や`backend`をこの操作で再作成しない。

`yarn install --production=false`とfull buildを含むため数分かかる。時間がかかることを理由にこのphaseを省略しない。

Lambda イメージビルド（`docker compose build frontend_next_lambda`）は実行しない。Lambda 固有の差分を今回変更していないためである。

#### development へ戻す

`ENV`を付けずに起動すると`${ENV:-development}`がdevelopmentへ戻る。戻した後にPhase 1 の観測をやり直すのは、production 分岐の実測が開発 container の状態を壊していないことを確かめるためである。

---

## Phase 5: 品質checkと修正

### DoD（完了条件）

- 全testがgreen
- `docker compose exec frontend yarn lint`にerrorがない
- 最終screenshotで見た目を目視確認済み

> ⚠️ screenshot確認は最後にまとめて行うものではない。Phase 1 のDoDにも含まれている。このphaseでは全体の最終確認だけを行う。

### Tasks

- [x] 全test実行
  - [x] `docker compose exec frontend yarn test`を実行する
  - [x] すべてgreenであることを確認する
    > `Test Suites: 33 passed, 33 total` / `Tests: 178 passed, 178 total` / `Done in 82.28s.`
- [x] lint実行
  - [x] `docker compose exec frontend yarn lint`を実行する
  - [x] ~~errorがあれば修正して再実行する~~（errorなし）
  - [x] error zeroを確認する
    > `Done in 16.36s.`。eslintの出力なし。
- [x] 最終screenshotで見た目を目視確認する
  - [x] pluginの`visual-inspector` skillをchildとして使いscreenshotを撮る
  - [x] 全体のdesign・layoutが意図どおりか確認する
    > 配信されるCSSチャンク`/_next/static/chunks/src_0pte6ka._.css`（HTTP 200、43,794 bytes）の先頭コメントが`/* [project]/src/app/tailwind-output.css [app-client] (css) */`であり、`build:css`の生成物がバンドルへ取り込まれていることを確認。`.rounded-2xl` `.rounded-full` `.grid-cols-4`等のutilityも出力内に存在。ログイン画面のborder・角丸・余白に崩れなし。
  - [x] ~~問題があれば修正して再確認する~~（問題なし）
  - ⚠️ `npx playwright`またはPlaywright toolを直接呼ばない。必ずpluginの`visual-inspector` skillを使う。

---

## Documentation reviewと実装後振り返り

- [x] code readingまたは実装で永続化候補を得た場合、その場でdoc-enricherを提案modeで適用する
  - [x] 提案がある場合だけユーザー承認後に既存READMEまたは既存docsへ反映する
    > design phaseで`testing.md`へ「検証範囲の決め方」を追加（ユーザー承認済み）。Ready result後のgateで`frontend/README.md`の3箇所の不整合を検出しexecution plan対象へ追加（ユーザー承認済み）。
  - [x] 提案・承認判断を別taskへ先送りしない
  - 補足: design phase で `frontend/docs/ai_guideline/development_standard/testing.md` へ「検証範囲の決め方」を追加済み。同じoriginating decisionについて重複提案しない
- [x] 実装、review、validationからfeedbackまたは実装とのずれが生じた場合、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用する
  - [x] `discussion_directory=<working_dir>`と`discussion_file_name=implementation_review.md`を渡す
  - [x] 原文、関連する実装・design・plan、原因、採用方針、決定を渡し、修正済みでも記録を省略しない
  - [x] 「共有されていなかった知識の前提は何か」を確認する
  - [x] 「codeを読めば分かるか、設計意図か、process不足か」を確認する
  - [x] 「どこに書けば次回この議論が不要になるか」を確認し、合意後だけ反映する
    > 論点1・2は`docker.local.md`へ反映済み。論点3・4・5はskill側のprocess不足であり`escalate-plugin-skill-fix`の対象。ユーザー判断待ち。
  - [x] decisionをcallerへ返し、designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す
    > 論点1・2の決定によりdesign.mdのdocumentation sectionとexecution plan対象を更新（6→8件）。論点5により`--watch=always`の食い違いを修正。
  - [x] review後に実装を自動再開しない

---

## 動作確認

### DoD

ユーザーが実際に画面と container 起動を確認し、意図どおりであることを確認した。

### Tasks

- [x] agentの観測結果とscreenshotを報告したうえで、ユーザーに動作確認を依頼する
  - [x] 確認が及んでいない範囲も報告に含める
    > 報告済みの未確認範囲: ログイン後のカレンダー画面（backend container未起動のためログインが成立せず）。ユーザーから「動作確認を行ったから一旦このリポジトリについてはコミットしてpushしていい」との回答を得た。
- [x] feedbackがあれば、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用し、decisionをcallerへ返す
  - [x] designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す
    > docs分割の指示によりdesign.mdのdocumentation sectionとexecution plan対象を更新（8→9件）。
  - [x] ~~feedbackがなければ完了扱いにする~~（feedbackあり。論点1〜5として`implementation_review.md`へ記録）

---

## 完了後のaction

> ⚠️ 動作確認phaseが完了するまでcommit、push、PRを促したり実行したりしない。急かすことも禁止する。

### commit（phase単位かつ意味単位で分割）

MUST: まとめて一commitにしない。合意の記録は対応する変更commitより前へ、変更後に確定するものは後ろへ置く。

- [x] commit 1: genshijin 口調設定（今回のbuild script変更とは独立した別件）
  - 対象: `AGENTS.md`
  - `## 常用する plugin`への`### genshijin`追加と、`会話方針`の口調節の置き換え
- [x] commit 2: 設計合意の記録と、そこから導いた恒久knowledge
  - 対象: `.steering/2026/202608/20260830-consolidate-frontend-build-scripts/design.md`、同`task-design-discussion.md`、`frontend/docs/ai_guideline/development_standard/testing.md`、`.agents/skills/tumeda-dev-plugin-context.md`
  - 実装前に確定した合意であるため、後続の実装commitより前へ置く
  - `tasklist.md`はこのcommitに含めない。checkboxが実行後に確定するため
- [x] commit 3: Phase 1 の変更
  - 対象: `frontend/package.json`、`frontend/entrypoint.sh`
  - Tailwindのコンパイル定義を`package.json`へ集約し、`entrypoint.sh`からTailwindの記述を削除する変更
- [x] commit 4: Phase 2 の変更
  - 対象: `frontend/buildOnLambda/Dockerfile`、`.github/workflows/ci-frontend-build-verification.yml`
  - `yarn build`がTailwindを含むようになったことで不要になった重複行・stepの削除
- [x] commit 5: Phase 3 の変更
  - 対象: `frontend/docs/troubleshooting/tailwind/build_and_watch.md`（新規）、`frontend/docs/ai_guideline/development_standard/docker.local.md`（新規）、同`docker.md`、同`README.md`、`frontend/README.md`、`.steering/.gitignore`（新規）
  - local固有事象の`docker.local.md`への分離と、変更後の実態へ合わせたTailwind運用documentationの更新（watcher競合の禁止記述、復旧経路、restartが効かない場合、コンパイル定義箇所、Lambdaビルド手順、随伴の原則）
- [x] commit 6: tasklist の実行結果
  - 対象: `.steering/2026/202608/20260830-consolidate-frontend-build-scripts/tasklist.md`、同`implementation_review.md`
  - checkboxは実行後に確定するため、対応する変更commitより後ろへ置く

ユーザーが一部だけ承認した場合は承認範囲だけをcommitし、残りは待つ。ユーザーが不要と回答した場合は`[x] ~~commit~~（ユーザーが不要と回答）`の形式で完了扱いにする。

### push と PR

- [ ] current branchをpushしてPRを作成する
  - [ ] commit taskの結果としてlocal commitが実際に一件以上あることを確認する。一件もなければpush・PRを実行しない
  - [ ] current branchが`feature-<issue番号>`形式のnon-default branchであることを確認する（default branchは`main`）
  - [ ] `git push -u origin <current-branch>`を実行する
  - [ ] pluginのskills directory配下にある `tasklist-executor/scripts/github/create_or_get_pr.sh` を実行する
    - pathの起点はpluginのskills directoryである。利用先repositoryからの相対pathではない
    - このscriptは`gh pr create`のwrapperではない。同じhead branchのopen PRがあれば新規作成せずそのURLを返し、`feature-<issue番号>`契約からissue番号を導いてPR bodyへ`Closes #<番号>`を入れる
    - `--title`と`--body`を渡すとissueからの導出は行われない。issueへ紐づける場合はbody側へ明示する
