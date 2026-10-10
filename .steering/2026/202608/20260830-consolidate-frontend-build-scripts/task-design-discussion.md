# 議論記録

## 論点1: `build` に Tailwind コンパイルを含めた時、開発 container で watcher と競合させない実行順序

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0: 開発分岐の実行順序を確定し、watcher 競合を構造的に発生させない形を選ぶ

#### 提案0

**推奨:** a。tailwindcss の実行が逐次のまま 1 系統に収まり、`frontend/entrypoint.sh` から Tailwind の記述が完全に消え、かつ開発者から見た dev サーバ起動時間が現状から悪化しないため。

- **a. 開発分岐の順序を「`yarn build`（Tailwind 込み）→ watch 起動 → `yarn dev`」へ入れ替える**
  - 現状の冒頭 `build_tailwind` は `yarn build` に吸収されるため、entrypoint.sh から消える。初回の `tailwind-output.css` は `yarn build` が生成する。
  - watch を起動する時点で `yarn build` は完了しているため、tailwindcss プロセスは同時に 2 つ存在しない。`docker.md` が禁じる「起動済み watcher と競合する tailwindcss 実行」に構造的に該当しなくなる。
  - 開発者から見た dev サーバ起動時間は変わらない。現状も `NODE_ENV=production yarn build` は `yarn dev` の前に実行されており、待ち時間は既に発生している。変わるのは watch が使えるようになる時刻が build 完了後へずれる点だけで、これは `yarn dev` の起動時刻と同じである。
  - 開発分岐が呼ぶ build が Lambda イメージビルドと同じ `yarn build` のままなので、「Lambda に載せるイメージのビルドでコケないことの確認」という現行の検証目的が維持される。
  - 完成後の開発分岐: `yarn install` → `NODE_ENV=production yarn build` → watch script を background 起動 → `yarn dev -p ${port}`。
- **b. `build` は Tailwind 込みにするが、開発分岐だけ Tailwind を含まない別 script（例 `build:next`）を呼ぶ**
  - 現状の実行順序を変えずに済む。watch 起動後に呼ぶのが Tailwind を含まない script なので競合しない。
  - 一方で、Lambda イメージビルドが実行するのは Tailwind 込みの `build` であるのに、開発分岐が確認するのは `build:next` になる。「Lambda ビルドの成否確認」という目的に対して検証経路が本番と食い違い、要件 MUST の「現行 4 実行経路が同じ検証範囲を維持する」を満たさない。
  - `build` と `build:next` の使い分け基準を entrypoint.sh の読み手が判断する必要が生じ、責務を package.json へ集約する目的にも逆行する。
- **c. watch script に初回ビルドを兼ねさせ、`build` 側で Tailwind を skip する条件分岐を持つ**
  - tailwindcss の実行を 1 回に抑えられる。
  - skip 判定の条件（環境変数、watcher の生存確認など）を新たに設計・保守する必要があり、`build` が「単独で成果物を揃える」という要件 MUST と両立しない。呼び出し側が条件を知らないと `build` の結果が変わる。

#### 提案背景

ユーザーの依頼は「`build` に Tailwind の build が含まれておらず、外からは両方使わなきゃいけないのがセンス悪い」であり、`build` へ Tailwind を含めること自体は方向として確定している。この論点が扱うのは、含めた結果として開発 container で発生する副作用をどう回避するかである。

`frontend/docs/ai_guideline/development_standard/docker.md`「Tailwind watcher のトラブルシューティング」は、起動済み watcher がいる状態での tailwindcss 実行を MUST として禁じている。理由は OOM が発生し watcher プロセスが死ぬためで、`globals.css` を変更しても `tailwind-output.css` が更新されなくなるという実害が既に観測されている。

現状の開発分岐は `build_tailwind` → `tailwind --watch &` → `NODE_ENV=production yarn build` → `yarn dev` の順であり、`yarn build` が `next build` だけなので tailwindcss は重複起動しない。ここで `build` に Tailwind を含めると、**順序を変えないかぎり** watch 稼働中に tailwindcss がもう 1 プロセス起動し、docker.md が禁じる状態を新規に作り込むことになる。この論点の結論が出ないと `frontend/entrypoint.sh` の完成後の姿が確定せず、下位の TBD-1（`build` へ含める方法）と TBD-3（watch script と `dev` script の関係）も決められない。

提案0の 3 案は、いずれも「tailwindcss を同時に 2 プロセス走らせない」を満たすが、満たし方が異なる。a は実行順序で、b は呼ぶ script の使い分けで、c は skip 条件で回避する。判断の分かれ目は、要件 MUST の「現行 4 実行経路が同じ成果物・同じ検証範囲を維持する」と「`yarn build` 単独で成果物が揃う」を壊さずに回避できるかである。

#### 提案0へのフィードバック

**結果:** a を仮支持。ただし順序の抽象比較だけでは判断できず、a と b それぞれの完成後 `package.json` と `entrypoint.sh` の実物が必要。

> 方向性はaでいいような気がするけど、a,bはそれぞれどんなpackage.jsonになり、どんなentrypoint.shになる？

提案0は「tailwindcss を同時に 2 プロセス走らせない」という回避条件の満たし方だけを比較しており、各案が entrypoint.sh をどこまで薄くできるかを示していなかった。依頼の主目的は「entrypoint.sh への漏れ出しを最低限の script 組み合わせまで減らす」ことなので、その目的に対する差が判断材料として不足していた。

### イテレーション1: a と b の完成後 `package.json` / `entrypoint.sh` を実物で比較する

#### 提案1

script 名（`build:css`、`watch:css`）は論点2以降で確定する暫定値として扱う。この提案で判断するのは名前ではなく、**a と b それぞれで entrypoint.sh に何が残るか**である。

##### a: 開発分岐の順序を入れ替える

`frontend/package.json` の `scripts`:

```json
{
  "dev": "next",
  "build": "yarn build:css && next build",
  "build:css": "tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css",
  "watch:css": "yarn build:css --watch",
  "start": "next start",
  "codegen": "graphql-codegen --config codegen.yml",
  "test": "jest",
  "lint": "sh -c 'if [ $# -gt 0 ]; then eslint \"$@\"; else eslint src/; fi' sh"
}
```

`frontend/entrypoint.sh`:

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
  # ファイル変更を検知してCSSを再生成
  yarn watch:css &
  yarn dev -p ${port}
fi
```

- 開発分岐が呼ぶ build 系 script は `yarn build` と `yarn watch:css` の 2 つ。
- `build_tailwind()` 関数が消え、Tailwind の入出力 path が entrypoint.sh から完全に消える。
- `yarn build` が完了してから watch を起動するため、`next build` が `tailwind-output.css` を読む時点でそのファイルは必ず存在する。
- production 分岐と開発分岐が呼ぶ build は同じ `yarn build` であり、Lambda イメージビルドが実行するものと一致する。

##### b: 開発分岐だけ Tailwind を含まない build を呼ぶ

`frontend/package.json` の `scripts`:

```json
{
  "dev": "next",
  "build": "yarn build:css && yarn build:next",
  "build:next": "next build",
  "build:css": "tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css",
  "watch:css": "yarn build:css --watch",
  "start": "next start",
  "codegen": "graphql-codegen --config codegen.yml",
  "test": "jest",
  "lint": "sh -c 'if [ $# -gt 0 ]; then eslint \"$@\"; else eslint src/; fi' sh"
}
```

`frontend/entrypoint.sh`:

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
  # watch より先に初回CSSを生成する（生成前に build:next が走ると tailwind-output.css を読めない）
  yarn build:css
  # ファイル変更を検知してCSSを再生成
  yarn watch:css &
  # 開発では使わないけどこれが失敗するとLambdaに載せるイメージのビルドでコケるので、成否確認
  # watcher と競合させないため、Tailwind を含まない build:next を呼ぶ
  NODE_ENV=production yarn build:next
  yarn dev -p ${port}
fi
```

- 開発分岐が呼ぶ build 系 script は `yarn build:css`、`yarn watch:css`、`yarn build:next` の 3 つ。
- Tailwind の入出力 path は entrypoint.sh から消えるが、`build:css` の初回実行を entrypoint.sh 側が忘れてはいけないという順序制約が残る。`watch:css` は初回ビルドも行うが、それを待たずに `build:next` が走る race があるため、明示的な初回 `build:css` を省略できない。
- `build` と `build:next` の使い分け理由（watcher 競合の回避）を entrypoint.sh のコメントで説明する必要がある。package.json 側だけを読んでも `build:next` がなぜ存在するか分からない。
- 開発分岐が検証するのは `build:next` であり、Lambda イメージビルドが実行する `build` とは経路が異なる。`build:css` の失敗は開発 container の起動時に検知されるが、`build` という単位での成否は確認されない。

##### 差分の要点

| 観点 | a | b |
| --- | --- | --- |
| 開発分岐が呼ぶ build 系 script 数 | 2 | 3 |
| package.json の build 系 script 数 | 3（`build` / `build:css` / `watch:css`） | 4（`build` / `build:next` / `build:css` / `watch:css`） |
| entrypoint.sh に残る順序制約 | なし（build → watch は自然な順序） | あり（`build:css` を watch より先に呼ぶ必要がある） |
| 開発分岐が検証する build | Lambda と同じ `yarn build` | Lambda と異なる `yarn build:next` |
| `build:next` の存在理由の説明場所 | 不要 | entrypoint.sh のコメント |

#### 提案背景

feedback は a への仮支持を示しつつ、判断には各案の完成後 file が必要だと述べた。提案0が比較していたのは「回避条件をどう満たすか」だけで、依頼の主目的である「entrypoint.sh をどこまで薄くできるか」の差を示していなかった。提案1はその差を実物で埋める。

実物を書いた結果、提案0の時点では言語化できていなかった b の制約が 2 つ判明した。

1. b の開発分岐では、`watch:css` の初回ビルドを待たずに `build:next` が走る race があるため、明示的な初回 `yarn build:css` を省略できない。結果として entrypoint.sh が呼ぶ build 系 script は 3 つになり、しかも「build:css を watch より先に」という順序制約が entrypoint.sh 側の知識として残る。
2. b は package.json に `build:next` という script を増やすが、その存在理由は「開発 container で watcher と競合させないため」であり、package.json 単体では読み取れない。理由が entrypoint.sh のコメントにしか無い状態は、build の知識を package.json へ集約するという目的と逆方向である。

a ではどちらも発生しない。`yarn build` が完了してから watch を起動するという 1 本の順序だけで両方が解ける。

script 名の `build:css` / `watch:css` は、`watch:css` が `yarn build:css --watch` として Tailwind の引数を再利用できることを示すために暫定採用した。Yarn Classic は `yarn run <script> <args>` の追加引数を script 末尾へ連結するため、入出力 path の記述は `build:css` の 1 箇所に収まる。名前そのものの妥当性はこの論点では確定させず、別論点で扱う。

#### 提案1へのフィードバック

**結果:** a を採用。

> aでok

### 決定

`frontend/entrypoint.sh` の開発分岐を「`yarn install` → `NODE_ENV=production yarn build` → `yarn dev -p ${port}`」の順序にする。現状の `build_tailwind` 呼び出しと `tailwindcss --watch` の直接記述は削除し、Tailwind の入出力 path を entrypoint.sh へ残さない。Tailwind watcher は `yarn dev` の内部で起動する（論点4 の決定により、この論点で決めた「watch script を entrypoint.sh が background 起動する」という表現を現在有効な形へ同期した。この論点が確定させた「`yarn build` の完了後に watcher を起動する」という順序自体は変わっていない）。

この順序により、`yarn build` に Tailwind コンパイルを含めても tailwindcss プロセスが同時に 2 つ存在しないため、`frontend/docs/ai_guideline/development_standard/docker.md` が MUST で禁じる watcher 競合を新たに発生させない。`next build` が `tailwind-output.css` を読む時点でそのファイルが存在することも、同じ順序で保証される。

開発分岐と production 分岐と Lambda イメージビルドがいずれも同じ `yarn build` を呼ぶため、開発 container 起動時の「Lambda に載せるイメージのビルドでコケないことの確認」という現行の検証目的が、本番と同一経路のまま維持される。

Tailwind を含まない build を別 script として設ける案（提案1 の b）は採らない。開発分岐に「初回 `build:css` を watch より先に呼ぶ」という順序制約が残ること、および `build:next` の存在理由が package.json 単体からは読み取れず entrypoint.sh のコメントにしか残らないことが、build の知識を package.json へ集約する目的と逆方向であるため。

提案1 で例示した script 名 `build:css` / `watch:css` は暫定値であり、この決定には含まない。

---

## 論点2: `yarn build` が Tailwind コンパイルを含む形をどう実現するか

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0: 明示連結と `prebuild` lifecycle のどちらで `build` に Tailwind を含めるか

#### 提案0

**推奨:** a。b は間接層を一つ増やすが、その効果は「`build` が Tailwind に依存していることを package.json 上で見えなくする」ことだけであり、依頼の目的と逆方向であるため。

- **a. `build` の中で明示的に連結する**
  - `"build": "yarn <cssコンパイルscript> && next build"`
  - `package.json` の `build` の行を読むだけで、Tailwind コンパイルと `next build` の 2 段で構成されていることが分かる。
  - package manager の lifecycle 機能に依存しないため、Yarn Classic / Yarn Berry / npm / pnpm のいずれでも同じ挙動になる。
  - `&&` により、Tailwind コンパイルが失敗した時点で `next build` へ進まず終了する。
- **b. `prebuild` lifecycle script に任せる**
  - `"prebuild": "yarn <cssコンパイルscript>"`, `"build": "next build"`
  - `yarn build` を呼ぶと Yarn が `prebuild` を自動実行するため、caller から見た使い方は a と同じになる。
  - `build` の行は `next build` のままなので、`package.json` の `build` を読んでも Tailwind が走ることが分からない。「外から両方使わなければならない」という現状の問題が、「見えないところで片方が走る」形へ置き換わるだけで、build の内容が package.json 上で自明にならない。
  - `prebuild` は `<cssコンパイルscript>` を呼ぶだけの中継になる。間接層を一つ増やして得られるのは `build` の行から `&&` が消えることだけで、Tailwind への依存が読めなくなる代償に見合わない。
  - Yarn Berry（v2 以降）は任意の `pre<script>` / `post<script>` の自動実行を持たない。現在の frontend container は `yarn 1.22.22`（実測）であり今は動作するが、将来 package manager を移行した場合、`prebuild` は**エラーを出さずに実行されなくなる**。その結果、CSS を含まないビルド成果物が生成され、CI も `yarn build` の exit 0 を見るだけなので検知できない。

#### 提案背景

論点1 で、開発分岐を「`yarn build` → watch 起動」の順序にすることが決まった。この論点は、その `yarn build` が Tailwind コンパイルを含む形をどう書くかを扱う。

ユーザーの依頼のうち「`build` に tailwind の build が含まれておらず、外からは両方使わなきゃいけないのがセンス悪い」という部分は、`yarn build` を呼ぶ側が Tailwind の存在を知らなくて済む状態を求めている。a と b はどちらも caller から見た使い方を同じにするため、この要件自体はどちらでも満たせる。

判断が分かれるのは、`package.json` を読む側から Tailwind への依存が見えるかどうかである。今回の目的は build の知識を `package.json` へ集約することなので、集約した先で知識が読めなくなる形は目的に反する。b の `prebuild` は、`<cssコンパイルscript>` を呼ぶだけの中継を挟んで `build` の行から `&&` を消すが、その代わりに `build` が Tailwind に依存している事実を `build` の行から消してしまう。

なお、`prebuild` に Tailwind コマンドを直接書く形（`"prebuild": "tailwindcss -i ... -o ..."`）は検討対象から外している。その場合、watch 用 script が同じ入出力 path を自前で持つことになり、コマンド定義箇所を 1 箇所にするという要件 MUST を満たせないためである。b は `prebuild` が css コンパイル script を呼ぶ形に限定して評価している。

Yarn Berry での silent failure は現時点で発生していない仮定上のリスクであり、単独では決定理由にしない。ここでは a を選ぶ副次的な理由として挙げている。

#### 提案0へのフィードバック

**結果:** a を採用。

> a

### 決定

`frontend/package.json` の `build` を `"yarn <cssコンパイルscript> && next build"` という明示的な連結で定義する。`prebuild` lifecycle script は使わない。

`build` の行そのものが Tailwind コンパイルと `next build` の 2 段構成であることを示すため、`package.json` を読む側が build の内容を追加の知識なしに把握できる。`&&` により Tailwind コンパイルの失敗時点で `next build` へ進まず終了する。package manager の lifecycle 機能へ依存しないため、Yarn Classic 以外へ移行しても挙動が変わらない。

`prebuild` 案を採らないのは、css コンパイル script を呼ぶだけの中継層を増やして得られるのが `build` の行から `&&` が消えることだけであり、その代償として `build` が Tailwind に依存している事実が `build` の行から読めなくなるためである。build の知識を `package.json` へ集約するという今回の目的に対し、集約先で知識が読めなくなる形は逆方向にあたる。Yarn Berry へ移行した場合に `prebuild` がエラーなく実行されなくなり、CSS を含まない成果物が CI でも検知されないというリスクは、副次的な理由として記録する。

連結する css コンパイル script の名前はこの決定に含まない。

---

## 論点3: Tailwind コンパイル script と watch script の命名

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0: 2 つの新規 script の名前を決める

#### 提案0

**推奨:** b。この script が独立して存在する理由が Tailwind 固有の事情であり、repository の既存語彙とも一致するため。

- **a. `build:css` / `watch:css`**
  - 生成物で命名する。ツールが変わっても名前が残る。
  - ただし `next build` も CSS Modules 等の CSS を処理するため、`build:css` が「このプロジェクトの CSS ビルド全体」を指すように読める。実際に扱うのは `globals.css` から `tailwind-output.css` を作る 1 経路だけなので、名前が実際の担当範囲より広い。
- **b. `build:tailwind` / `watch:tailwind`**
  - ツール名で命名する。担当範囲が `tailwind-output.css` の生成に限定されることが名前から分かる。
  - この script が独立して存在する理由は「Tailwind を PostCSS へ統合すると Turbopack の dev compile が 2 分超になる」という Tailwind 固有の事情であり、その事情が解消されれば script は改名ではなく消滅する。ツール名で縛ることによる将来の不整合が起きにくい。
  - repository の既存語彙と一致する。現行 `frontend/entrypoint.sh` の関数名は `build_tailwind`、`frontend/docs/ai_guideline/development_standard/docker.md` の見出しは「Tailwind watcher のトラブルシューティング」である。読み手が既存の記述と対応付けられる。
- **c. `build:styles` / `watch:styles`**
  - 生成物をより抽象的に呼ぶ。a と同じく担当範囲より広く読め、かつ repository 内に `styles` という語彙の先例がない。

watch script の定義はいずれの案でも `"<watch script>": "yarn <build script> --watch"` とする。Yarn Classic は `yarn run <script> <args>` の追加引数を script 末尾へ連結するため、Tailwind の入出力 path は build script の 1 箇所だけに置ける。この連結挙動は既存の `lint` script が `sh -c 'if [ $# -gt 0 ]; then eslint "$@"; else eslint src/; fi' sh` として依存しており、repository 内で裏付けが取れている。

なお現行の `scripts` は `dev` / `build` / `start` / `codegen` / `test` / `lint` で、コロン区切りの名前空間を持つ script は存在しない。3 案はいずれもこの慣習を新規に導入する。コロンを使わない `buildTailwind` / `watchTailwind` も形としては可能だが、既存 6 script がすべて小文字単語であることと、npm / yarn の一般的な慣習がコロン区切りであることから、候補に含めていない。

#### 提案背景

論点2 で `build` を `"yarn <cssコンパイルscript> && next build"` と定義することが決まり、残るのは 2 つの新規 script の名前だけになった。名前は `frontend/package.json`、`frontend/entrypoint.sh` の両方に現れ、`frontend/docs/ai_guideline/development_standard/docker.md` の watcher に関する記述とも対応するため、決めてから一括で反映する。

判断の分かれ目は、生成物で呼ぶか（a / c）ツールで呼ぶか（b）である。一般には生成物や役割で命名する方が実装への結合が弱く望ましいが、今回は事情が逆になっている。この script は「Tailwind を PostCSS パイプラインへ入れられない」という Tailwind 固有の回避策として存在しており、その前提が消えれば script 自体が不要になる。生成物で命名すると、実際には `tailwind-output.css` の生成しか担当しないのに `next build` が扱う CSS まで含むように読める。

#### 提案0へのフィードバック

**結果:** a を採用。推奨した b の理由（担当範囲より名前が広く読める、既存語彙が `build_tailwind`）は決定を覆すほどの重みを持たないと判断された。

> 別にaでいいんじゃないかな

### 決定

Tailwind コンパイル script を `build:css`、watch script を `watch:css` とする。

- `"build:css": "tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css"`
- `"watch:css": "yarn build:css --watch"`
- `"build": "yarn build:css && next build"`（論点2 の決定に `build:css` を適用したもの）

`watch:css` が Tailwind の入出力 path を持たず `build:css` へ `--watch` を追加引数として渡す形にすることで、コマンド定義箇所を `build:css` の 1 箇所に閉じる。Yarn Classic が `yarn run <script> <args>` の追加引数を script 末尾へ連結する挙動に依存しており、これは既存の `lint` script が `sh -c 'if [ $# -gt 0 ]; then eslint "$@"; else eslint src/; fi' sh` として同じ挙動へ依存していることで裏付けられる。

ツール名で命名する案（`build:tailwind` / `watch:tailwind`）は採らない。生成物で命名する形の方が一般的であり、`build` が別に存在する以上 `build:css` が Next.js の CSS 処理全体を指すと誤読される可能性は低いと判断した。

---

## 論点4: Tailwind watcher の起動責務を `entrypoint.sh` と `dev` script のどちらへ置くか

**ステータス:** 決定

**種別:** 認識齟齬

### イテレーション0: watcher 起動を `dev` script へ内包する案の実体を示し、採否を決める

#### 提案0

**推奨:** a（論点1 の決定を維持する）。b の利点は entrypoint.sh が 1 行減ることと host 実行時の挙動改善だけであり、`dev` script が「dev サーバの起動」以外の責務を持つ代償に見合わないため。

先に前提の訂正を行う。chat で「`dev` 内包には `concurrently` 等の新規依存の追加と、port の渡し方を `-p ${port}` から `PORT` 環境変数へ変える必要がある」と述べたが、これは誤りだった。`&` を script 内で使えば依存追加は不要であり、Yarn Classic が追加引数を script 末尾へ連結するため `-p ${port}` もそのまま `next` へ届く。以下の b は訂正後の形で評価する。

- **a. `entrypoint.sh` が watcher を background 起動する（論点1 の決定どおり）**
  - `"dev": "next"`（現状のまま）
  - `frontend/entrypoint.sh` の開発分岐:
    ```sh
    yarn install
    NODE_ENV=production yarn build
    yarn watch:css &
    yarn dev -p ${port}
    ```
  - `dev` の意味が `next` そのままなので、`yarn dev` を呼んだ時に何が起きるかが `package.json` から一意に読める。
  - watcher を dev サーバと並走させることは「開発 container の起動手順」であり、環境ごとに変わる組み合わせにあたる。ユーザーは「環境ごとに変えること自体に何の問題もない」と述べており、entrypoint.sh がこの組み合わせを持つことは依頼の範囲内である。
  - host で直接 `yarn dev` を実行した場合、watcher は起動しない。ただし `docker.md` はコマンド実行を container 内に限る方針を定めており、host 実行は想定されていない。
- **b. `dev` script が watcher を内包する**
  - `"dev": "yarn watch:css & next"`
  - `frontend/entrypoint.sh` の開発分岐:
    ```sh
    yarn install
    NODE_ENV=production yarn build
    yarn dev -p ${port}
    ```
  - entrypoint.sh の開発分岐が 1 行減り、`&` が entrypoint.sh から消える。
  - watcher と dev サーバがセットであることが `package.json` 上で表現される。host で `yarn dev` を実行した場合も CSS が再生成される。
  - 一方で `dev` が「dev サーバの起動」と「watcher の起動」の 2 つの責務を持つ。`yarn dev` を呼んだ時に background プロセスが 1 つ増えることは、script 名からは読み取れない。
  - `&` の位置が entrypoint.sh から package.json へ移るだけで、background プロセスの管理責任そのものは消えない。watcher が起動直後に失敗しても `next` は起動し続けるという性質は a と同じで、b にしても改善しない。

#### 提案背景

chat で watcher 起動責務について問うた際、`concurrently` の追加と port 渡し方の変更が必要だと説明した。ユーザーからは「いい悪い別に、そのメリットや違いがあまりわかっていない」という応答があり、判断材料が不足していたことが分かった。原因は 2 つある。

1. 前提が誤っていた。`&` を script 内で使えば依存追加も port 渡し方の変更も不要であり、説明していたコストは実在しなかった。誤った前提の上で「既定では現状維持」と述べたため、比較そのものが成立していなかった。
2. 利点と欠点を具体形で示していなかった。「entrypoint.sh がさらに薄くなる」とだけ述べ、実際に何行がどう変わるかを示していなかった。

提案0 は訂正後の b を実物で示し、a との差が「entrypoint.sh の 1 行」と「`dev` script の責務が 1 つ増えること」の交換であることを判断可能にする。

推奨を a とする根拠は、依頼の文面にある。ユーザーは「package.json で用意したスクリプトを最低限組み合わせる程度までにしたい」「環境ごとに変えること自体に何の問題もない」と述べており、entrypoint.sh が環境ごとの組み合わせを持つこと自体は問題視していない。問題視されていたのは Tailwind のコマンド詳細が entrypoint.sh に書かれていることであり、それは論点1〜3 の決定で解消される。b はその先の「組み合わせ自体も package.json へ入れる」段階であり、依頼が求めた水準を超えて `dev` の意味を広げる。

#### 提案0へのフィードバック

**結果:** b を採用。推奨した a は、提案0 自身が受け入れている要件と矛盾していたことが指摘により判明した。

> bいいかもね。buildがcssも含んでいるから。watchもdevに近いし。対称性はないけど、buildとstartは実態はbuildで、watchとdevはdev側が実態だし

指摘は、`build` が css コンパイルを含むなら `dev` も css watch を含むのが一貫している、というものである。`build` と `start`、`watch` と `dev` の対には対称性がなく、前者は build 側、後者は dev 側が実態だが、「CSS の処理は対応する Next.js コマンドに随伴する」という原則は両者で成立する。

この指摘により、提案0 の推奨が抱えていた矛盾が明らかになった。a は `build` から「caller が 2 つを組み合わせなければならない」という性質を取り除きながら、`dev` にはその性質を残す。entrypoint.sh は `yarn dev` を呼ぶ前に `yarn watch:css &` を呼ぶことを覚えていなければならず、これはユーザーが「外からは両方使わなきゃいけないのがセンス悪い」と述べた defect そのものである。提案0 は依頼の文面（「最低限組み合わせる程度まで」「環境ごとに変えること自体に問題はない」）を根拠に a を推したが、その文面は entrypoint.sh が肥大しないことを求めたものであり、CSS 処理の責務をどこへ置くかを規定していなかった。根拠の適用先を誤っていた。

##### 実測による確認

`&` を含む script へ Yarn Classic が追加引数を連結する挙動を、frontend container 内の一時 package.json で確認した（Tailwind には触れていない）。

```
scripts: { "child": "echo CHILD_RAN", "parent": "yarn child & echo NEXT_GOT" }

$ yarn parent -p 18100
NEXT_GOT -p 18100
CHILD_RAN
```

追加引数 `-p 18100` は script 末尾のコマンドへ連結され、background 側の script も起動する。`"dev": "yarn watch:css & next"` に対する `yarn dev -p ${port}` は、`next` へ `-p ${port}` を渡しつつ `watch:css` を background 起動する。

出力順が `NEXT_GOT` → `CHILD_RAN` である通り、background 側の起動は非同期であり `next` の起動を待たせない。`next` が読む `tailwind-output.css` は直前の `yarn build` が生成済みのため、この非同期性は問題にならない。

### 決定

`frontend/package.json` の `dev` を `"yarn watch:css & next"` とし、Tailwind watcher の起動責務を `dev` script へ置く。`frontend/entrypoint.sh` は watcher を直接起動しない。

完成後の `frontend/entrypoint.sh` 開発分岐:

```sh
yarn install
NODE_ENV=production yarn build
yarn dev -p ${port}
```

採用根拠は、`package.json` 内で「CSS の処理は対応する Next.js コマンドに随伴する」という原則を一貫させることである。`build` が `build:css` を伴うのと同じ理由で、`dev` は `watch:css` を伴う。これにより caller は build 経路でも dev 経路でも CSS の存在を知らずに済み、「外からは両方使わなきゃいけない」という状態が両経路から消える。`build` だけを直してもう一方を残す形は、同じ defect を dev 経路に残すことになる。

`build` と `start`、`watch` と `dev` の対に対称性はない。前者は `build` が実態で `start` が成果物を配信するだけであり、後者は `dev` が実態で `watch` が随伴する。対称でないことは採用の妨げにならない。随伴させる基準は対称性ではなく、その Next.js コマンドが CSS を必要とするかである。

`yarn dev` が dev サーバ起動と watcher 常駐の 2 つを行うことは、`dev` script の行から読み取れる。background プロセスの管理責任は entrypoint.sh から package.json へ移るが、消えるわけではない。watcher が起動直後に失敗しても `next` が起動し続ける性質は、この決定の前後で変わらない。

---

## 論点5: `build` が Tailwind を含むことで新たに生じる watcher 競合を `docker.md` へどう書くか

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0: 変更後に不正確・不十分になる `docker.md` の記述をどう直すか

#### 提案0

**推奨:** b。禁止の理由を原則として書けば、将来 script が増えても記述が陳腐化せず、かつ最も踏みやすい `yarn build` を具体例として名指しできるため。

現行の `frontend/docs/ai_guideline/development_standard/docker.md` 末尾:

```markdown
## Tailwind watcher のトラブルシューティング

- MUST: `docker compose exec frontend` で `tailwindcss` を手動実行しない（起動済み watcher と競合してOOMが発生し、watcher プロセスが死ぬ）
- watcher が死んでいる兆候: `src/app/globals.css` を変更しても `tailwind-output.css` の行数・内容が変わらない
- 復旧: `docker compose restart frontend`（entrypoint.sh が watcher を再起動する）
```

変更後に生じるずれは 2 つある。

1. MUST が禁じているのは `tailwindcss` の直接実行だけだが、変更後は `yarn build`、`yarn build:css`、`yarn watch:css`、`yarn dev` のいずれを `docker compose exec frontend` で実行しても tailwindcss が起動する。とりわけ `yarn build` は「ビルドが通るか確認したい」という自然な動機で叩かれるコマンドであり、現行の記述を読んだ人が禁止対象だと気付けない。
2. 復旧手順の括弧書き「entrypoint.sh が watcher を再起動する」が不正確になる。変更後の再起動経路は `entrypoint.sh` → `yarn dev` → `watch:css` である。

- **a. 禁止対象の script 名を列挙し、復旧記述を実態へ合わせる**
  - MUST を「`tailwindcss`、`yarn build`、`yarn build:css`、`yarn watch:css`、`yarn dev` を手動実行しない」と書き換える。
  - 具体的で迷いがない。
  - 将来 script が増減したときに列挙が追随せず、記述が実態から外れる。列挙されていない script は安全だと読まれる。
- **b. 禁止の理由を原則として書き、最も踏みやすいコマンドを具体例として添える**
  - MUST を「起動済み watcher がある状態で、Tailwind をコンパイルする操作を `docker compose exec frontend` から実行しない」と理由の側で書く。
  - そのうえで「`yarn build` は `build:css` を含むため該当する」と、最も踏みやすい 1 例を名指しする。ビルド確認が目的なら CI の `CI Frontend Build Verification` が同じことを行うため、container で叩く必要がないことも書く。
  - 将来 script が増えても原則が先にあるため、読み手が該当するかを自分で判断できる。
  - 復旧手順の括弧書きを「`entrypoint.sh` が `yarn dev` を起動し、その中で watcher が再起動する」へ直す。
  - 原則だけでは「どれが該当するか」の判断を読み手に委ねることになるが、具体例を 1 つ置くことで判断の基準点を与える。

いずれの案でも、この変更は `frontend/package.json` と `frontend/entrypoint.sh` の変更が入って初めて正しい記述になる。先に docs だけを更新すると、存在しない状態を説明することになるため、コード変更と同じ実行単位で反映する。

#### 提案背景

論点1〜4 で script 構成が確定した結果、変更前には存在しなかった危険が生まれることが分かった。変更前の `yarn build` は `next build` だけなので、開発 container 内で手動実行しても watcher と競合しない。変更後は `yarn build` が `build:css` を含むため、`docker compose exec frontend yarn build` が watcher を殺す。

`docker.md` の「Tailwind watcher のトラブルシューティング」は、この事象を過去に踏んだ結果として書かれた記述である。同じ事象の入口が増えるのに記述が `tailwindcss` の直接実行しか挙げていない状態は、次に踏む人を防げない。

この論点を design の risk 欄へ書くだけで済ませない理由は、risk 欄は今回の変更を設計・実装する人が読むものであり、変更後に container を触る人が読む場所ではないためである。読み手が違うので、`docker.md` 側に記述が要る。

#### 提案0へのフィードバック

**結果:** b を採用。

> b

### 決定

`frontend/docs/ai_guideline/development_standard/docker.md`「Tailwind watcher のトラブルシューティング」を次の方針で更新する。

1. MUST を禁止コマンドの列挙ではなく理由の側で書く。「起動済み watcher がある状態で、Tailwind をコンパイルする操作を `docker compose exec frontend` から実行しない」とし、競合により OOM が発生して watcher プロセスが死ぬという理由を併記する。
2. 最も踏みやすい具体例として `yarn build` を名指しし、`build:css` を含むため該当することを示す。あわせて、ビルド確認が目的なら `.github/workflows/ci-frontend-build-verification.yml` の `CI Frontend Build Verification` が同じ検証を行うため container 内で実行する必要がないことを書く。
3. 復旧手順の括弧書きを実態へ合わせる。再起動経路は `entrypoint.sh` → `yarn dev` → `watch:css` である。
4. 「watcher が死んでいる兆候」の記述は変更しない。変更後も兆候は同じである。

script 名を列挙する案を採らないのは、将来 script が増減したときに列挙が追随せず、列挙されていない script が安全だと読まれるためである。理由を先に書けば、読み手は新しい script が該当するかを自分で判断できる。原則だけでは判断を読み手へ委ねきることになるため、具体例を 1 つ置いて判断の基準点を与える。

この docs 変更は `frontend/package.json` と `frontend/entrypoint.sh` の変更が入って初めて正しい記述になる。先に docs だけを更新すると存在しない状態を説明することになるため、コード変更と同じ実行単位で反映する。

---

## 論点6: `port=18100` を今回の変更対象に含めるか

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0: port の定義箇所を今回動かすかどうかを決める

#### 提案0

**推奨:** a。今回の依頼は build script の漏れ出しを扱っており、port はそれに該当しないため。

- **a. 含めない。`frontend/entrypoint.sh` の `port=18100` を現状のまま残す**
  - 依頼は「frontend側のビルドスクリプトがentrypoint.shに漏れ出している」であり、対象は Tailwind のコンパイルと watch モードの起動である。`port` は build script ではなく、起動時に渡す実行パラメータである。
  - `port` を `package.json` へ移しても定義箇所が entrypoint.sh から package.json へ移るだけで、重複は解消されない。現在 `port` は entrypoint.sh に 1 箇所しかなく、今回解消しようとしている「4 箇所への複製」のような問題を持っていない。
  - `docker-compose.yml` の `ports: "18100:18100"` と対応させる必要があるため、entrypoint.sh 側にある方が compose 定義との距離が近い。
  - `design.md` の非目標へ移し、今回は変更しない。
- **b. 含める。`port` を `package.json` 側へ移す**
  - `dev` / `start` を `"next -p 18100"` のように書き、entrypoint.sh から `-p ${port}` を消す。
  - entrypoint.sh がさらに 1 行減る。
  - 一方で `18100` が `package.json` と `docker-compose.yml` の 2 箇所に現れることになり、片方だけを変えると port が食い違う。現状は entrypoint.sh と docker-compose.yml の 2 箇所なので状況は変わらないが、改善もしない。
  - 今回解消しようとしている問題（コマンド詳細の重複）とは別の問題であり、同じ変更に混ぜると変更の理由が 2 つになる。

#### 提案背景

`design.md` 初稿の時点で、`port` の扱いを MAY の TBD として残していた。論点1〜5 で build script の構成が確定した結果、残るのはこの 1 件と検証方法だけになったため、scope に含めるかを確定させる。

この論点を立てる理由は、結論によって `frontend/entrypoint.sh` の最終形が変わるためである。含めなければ `port=18100` と `yarn dev -p ${port}` がそのまま残り、含めれば両方が消える。

判断の分かれ目は、port が今回の依頼が指す「ビルドスクリプトの漏れ出し」に該当するかである。該当しないと判断する根拠は 2 つある。第一に、port は build の手順ではなく起動時の実行パラメータであり、Tailwind のコンパイルコマンドのように「どう作るか」を記述したものではない。第二に、今回解消する問題は同じコマンド詳細が 4 箇所へ複製されていることだが、port にはその重複がない。

#### 提案0へのフィードバック

**結果:** a を採用。

> a

### 決定

`port=18100` を今回の変更対象に含めない。`frontend/entrypoint.sh` の `port` 変数と `yarn dev -p ${port}` / `yarn start -p ${port}` はそのまま残し、`design.md` の非目標へ移す。

port は build の手順ではなく起動時の実行パラメータであり、今回の依頼が指す「ビルドスクリプトの漏れ出し」に該当しない。また今回解消する問題は同じコマンド詳細が 4 箇所へ複製されていることだが、port は `frontend/entrypoint.sh` に 1 箇所しかなく、その重複を持たない。`package.json` へ移しても定義箇所が移動するだけで重複は解消されず、`docker-compose.yml` の `ports` 定義との距離はむしろ遠くなる。

---

## 論点7: 4 実行経路の検証をどこまで実測で行うか

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0: 受け入れ基準となる検証手順とその範囲を決める

#### 提案0

**推奨:** a。production 分岐と Lambda イメージビルドで今回変わるのは `yarn build` の中身だけであり、その `yarn build` は開発 container と CI の両方で実測されるため。

まず、どの案でも行う検証を示す。

1. **定義箇所の単一性**: `grep -rn "tailwindcss -i" frontend/ .github/`（`node_modules` 除外）の結果が `frontend/package.json` の 1 行だけであること。今回の MUST が満たされたことを直接観測する。
2. **開発 container の起動**: `docker compose restart frontend` 後、`docker compose logs frontend` で `yarn build` の成功と dev サーバの起動を確認し、`frontend/src/app/tailwind-output.css` が生成されていること。
3. **watcher の生存**: `frontend/src/app/globals.css` に一時的な変更を加え、`tailwind-output.css` の行数・内容が変わること。確認後に元へ戻し、再び追随することを確認する。観測方法は `docker.md` の「watcher が死んでいる兆候」と同じものを逆向きに使う。
4. **画面**: `visual-inspector` で `http://localhost:18100` を撮影し、Tailwind のスタイルが当たっていること。`testing.md` の「UI変更の動作確認」に従い、agent が先に確認して観測結果とスクリーンショットを報告し、ユーザーが必要と判断したときだけ自分で触る。commit / push / PR はユーザーが報告を受けて進めてよいと述べた時点で可能になる。
5. **既存テストと lint**: `docker compose exec frontend yarn test` と `docker compose exec frontend yarn lint`。いずれも tailwindcss を起動しないため watcher と競合しない。
6. **CI**: PR 作成後、`CI Frontend Build Verification` / `CI Frontend Test` / `CI Frontend Lint` が green であること。

- **a. 上記のみ。production 分岐と Lambda イメージビルドは実測しない**
  - production 分岐が実行するのは `yarn install --production=false` → `yarn build` → `yarn start` であり、今回変わるのは `yarn build` の中身だけである。その `yarn build` は開発 container（`NODE_ENV=production yarn build` として同じ条件で実行される）と CI の両方で実測される。`yarn start` は変更しない。
  - `frontend/buildOnLambda/Dockerfile` の変更は tailwind CLI を呼ぶ 1 行の削除のみで、その後の `yarn build` は CI が実行するものと同じである。
  - `.github/workflows/ci-frontend-build-verification.yml` の変更は `Generate Tailwind CSS` step の削除のみで、削除後の `yarn build` が CI 上で実際に走ることで検証される。
  - 残るリスクは entrypoint.sh の production 分岐と Dockerfile の記述ミスであり、いずれも行削除のみなので diff の目視で担保する。
- **b. a に加えて production 分岐を実測する**
  - 開発 container を停止し、`ENV=production docker compose up frontend` で production 分岐を実行して `yarn start` が `http://localhost:18100` で応答することを確認し、その後 development へ戻す。
  - entrypoint.sh の production 分岐そのものを 1 度通せる。
  - 稼働中の開発 container を止める必要があり、`yarn install --production=false` と full build で数分かかる。復帰後に開発 container を再度立ち上げ直す必要がある。
- **c. b に加えて Lambda イメージビルドを実測する**
  - `docker compose build frontend_next_lambda` を実行し、builder ステージの `yarn build` を通過することを確認する。
  - `frontend/buildOnLambda/Dockerfile` は `yarn build` の直後に `aws s3 sync` を 2 回実行するため、AWS 認証情報がない環境では build がそこで失敗する。`yarn build` を通過したこと自体は失敗位置から判定できるが、イメージの完成までは確認できない。
  - AWS CLI のインストールと full な `yarn install` を含むため、実行時間が最も長い。

#### 提案背景

論点1〜6 で変更内容が確定した。残るのは、それが正しく反映されたことをどう観測するかである。`design.md` の受け入れ基準とテスト方針、およびリスク表の「`buildOnLambda/Dockerfile` の変更が本番デプロイに影響する」「CI workflow の変更で build verification が実質空振りになる」の対策欄が、この論点の結論で埋まる。

build script の変更は自動テストの対象外であり、`yarn test` が通ることは今回の変更が正しいことを示さない。したがって観測手順を個別に決める必要がある。

検証範囲の判断は、実測しない経路について「実測しなくても正しさが担保される理由」を言えるかで分かれる。a はその理由を「変わるのは `yarn build` の中身だけであり、それは別経路で実測される」に置いている。b と c は、その論理的な担保では足りず経路そのものを通すべきだという立場をとる。

なお、いずれの案でも `docker compose exec frontend yarn build` は実行しない。論点5 で確認した通り、変更後はこれが watcher を殺すためである。ビルドの成否は開発 container の起動ログと CI で確認する。

#### 提案0へのフィードバック

**結果:** b を採用。production 分岐は経路そのものを 1 度通す。

> b

### 決定

提案0 の共通検証 6 項目に加え、`frontend/entrypoint.sh` の production 分岐を実測する。Lambda イメージビルドは実測しない。

**共通検証:**

1. `grep -rn "tailwindcss -i" frontend/ .github/`（`node_modules` 除外）の結果が `frontend/package.json` の 1 行だけであること。
2. `docker compose restart frontend` 後、`docker compose logs frontend` で `yarn build` の成功と dev サーバの起動を確認し、`frontend/src/app/tailwind-output.css` が生成されていること。
3. `frontend/src/app/globals.css` に一時的な変更を加え、`tailwind-output.css` の行数・内容が追随すること。確認後に元へ戻し、再び追随することを確認する。
4. `visual-inspector` で `http://localhost:18100` を撮影し、Tailwind のスタイルが当たっていること。`testing.md` の「UI変更の動作確認」に従い、agent が先に確認して観測結果とスクリーンショットを報告する。ユーザーが報告を受けて進めてよいと述べるまで commit / push / PR へ進まない。
5. `docker compose exec frontend yarn test` と `docker compose exec frontend yarn lint` が通ること。
6. PR 作成後、`CI Frontend Build Verification` / `CI Frontend Test` / `CI Frontend Lint` が green であること。

**production 分岐の実測:**

7. `docker compose stop frontend` で開発 container を停止する。
8. `ENV=production docker compose up -d frontend` で production 分岐を起動し、`docker compose logs frontend` で `yarn install --production=false` → `yarn build` → `yarn start` の順に進むことを確認する。
9. `http://localhost:18100` が応答することを確認する。
10. `docker compose stop frontend` の後 `docker compose up -d frontend` で development へ戻し、共通検証 2 と 3 を再確認する。production 分岐の実測が開発 container の状態を壊していないことを確かめる。

**この検証範囲を選ぶ判断基準（ユーザーが決定後に明示したもの）:**

本番影響のある変更については、test in production でしか確認できない部分を除き、できるだけローカルで再現して確認する。実行に時間がかかることは事実であり、提案0 が a を推した「変わるのは `yarn build` の中身だけであり、それは別経路で実測される」という論理も基本的には正しい。しかしその論理だけを根拠に、本番影響のある経路そのものを一度も通さないことは選ばない。production 分岐は本番 container が実際に通る経路であり、ローカルで再現できる。したがって通す。

Lambda イメージビルドを実測しないのは、実行コストが理由ではない。`frontend/buildOnLambda/Dockerfile` のうち Lambda 固有の差分（AWS CLI のインストール、`aws s3 sync`、Lambda base image への COPY、`lambdaNextJsHandler`）を今回変更していないためである。今回この Dockerfile で変えるのは tailwind CLI を呼ぶ 1 行の削除だけで、それは Lambda 固有の部分ではなく、production 分岐と CI が実測する `yarn build` と同じ領域にある。変更していない差分を確認するために経路を通す理由はない。

この基準は「ローカルで再現できるか」と「今回その差分を変更したか」の 2 つで構成される。ローカルで再現でき、かつ今回変更した領域を含む経路は通す。今回変更していない差分しか持たない経路は通さない。

いずれの検証でも `docker compose exec frontend yarn build` は実行しない。論点5 の通り、変更後はこれが起動済み watcher と競合するためである。ビルドの成否は container の起動ログと CI から判定する。

#### doc-enricher review（論点7 の decision に対する一回限りの起動）

論点7 で確定した検証範囲の判断基準について、`doc-enricher`を提案modeで起動した。

**原因分類:** repository知識。assistant はこの基準を持たずに提案0 で a を推奨した。基準は code を読んでも分からず、`frontend` / `backend` いずれの `testing.md` にも `application_architecture.md` にも記載がなかった。

**抽象化ラダー:**

1. 「frontend の build script 変更時に production 分岐を実測する」— 今回の task に依存しており原則として成立しないため DROP。
2. 「自動テストが対象にしない変更について、どの実行経路まで実測するかを決める基準」— frontend / backend の双方へ適用でき、既存 docs に同等記述がないためここで止めた。
3. 「repository 非依存の思考作法」— `think-through`は議論・思考プロセスの作法を所有しており、検証範囲の決定は test 方針であって思考作法ではないため、ここまでは登らない。

**適用先と結果:** ユーザー承認のうえ `frontend/docs/ai_guideline/development_standard/testing.md` の「UI変更の動作確認」の後へ「検証範囲の決め方」節を追加した。既存の「UI変更の動作確認」が「誰がいつ確認するか」という順序を扱うのに対し、追加した節は「どこまで確認するか」という範囲を扱う。

**backend への横展開:** 同じ基準は `backend/docs/ai_guideline/development_standard/testing.md` にも適用できるが、今回の変更は frontend に閉じており、ユーザーが指定した適用先も frontend である。backend 側で本番影響のある非 application code を変更する機会が生じた時点で、改めて提案する。

---

## 論点8: `frontend/README.md` が変更後に不正確になる問題への対応

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0: Ready result 後の必須gateで検出した設計漏れをどう扱うか

#### 提案0

steering の Ready result 後の必須gate（`doc-enricher`を提案modeで起動する step）で、`frontend/README.md` の「Tailwind CSS v4 セットアップ（制約）」節に、今回の変更で不正確になる記述が 3 箇所あることが判明した。この file は `design.md` の execution plan 対象へ入っていない。

不正確になる記述:

1. 「`@tailwindcss/cli` を `entrypoint.sh` の `build_tailwind()` で独立プロセス実行する方式を採用」— `build_tailwind()` は削除され、`package.json` の `build:css` へ移る。
2. 「**Lambda ビルド時も要注意**: `buildOnLambda/Dockerfile` では `yarn build` 前に tailwindcss CLI を明示実行すること」— 今回削除する運用そのものを指示している。放置すると逆方向の指示が残る。
3. 「tailwindcss watcherプロセスが死んだ場合（`docker compose exec frontend` で tailwindcss を手動実行するとOOM競合でwatcherが死ぬ）」— 変更後は `yarn build` も該当するようになる。

あわせて、論点4 で assistant が誤った推奨を出した根本原因にあたる設計原則を、同じ節へ記録する。

**提案する対応:**

1. `design.md` の「documentationが成立させる知識」と execution plan 対象へ `frontend/README.md` を追加する。`tasklist.md` の Phase 3 を「Tailwind 運用を説明する docs が変更後の実態と一致する」へ広げ、README の 3 箇所を対象へ含める。
2. `frontend/README.md` の同じ節へ「CSS の処理は、それを必要とする Next.js コマンドに随伴させる」という原則を追記する。
3. `task-design` skill の Step 0.75 へ「変更対象 file を説明している既存 docs を探す」観点を追加する提案を、`escalate-plugin-skill-fix`で正本 repository へ引き渡す。

#### 提案背景

**根本原因（三問の 1 番目）:** `task-design` の Step 0.75 で `frontend/README.md` を読んでいなかった。読んだのは `maintenance-plugin-context` が返した範囲（`frontend/CLAUDE.md` とその誘導先である `docs/ai_guideline/**`）だけであり、`frontend/README.md` はその範囲外だった。Step 0.75 が README を読むよう指示しているのは GraphQL mutation または Command を変更・追加する場合に限定されており、build 設定の変更では契機が生じない。

**知識の性質（三問の 2 番目）:** 2 種類ある。

- README の 3 箇所が不正確になること自体は、code と README を突き合わせれば分かる。ただし「変更対象 file を説明している docs がどこにあるか」を探す観点がなければ、突き合わせる契機が生まれない。これは process の不足である。
- 論点4 の推奨を誤った原因は別で、「CSS の処理は、それを必要とする Next.js コマンドに随伴する」という設計原則を持っていなかったことにある。変更後の `package.json` を読めば `build` が `build:css` を伴う構造は分かるが、新しく Next.js コマンドを叩く script を足すときにどう判断するかは読んでも分からない。これは設計意図である。

**保存先（三問の 3 番目）:**

- 設計意図は `frontend/README.md` の「Tailwind CSS v4 セットアップ（制約）」節へ置く。同じ節が既に Tailwind の運用制約を所有しており、README を今回どのみち更新するため、同じ場所へ入る。
- process の不足は `task-design` skill 側の問題であり、この repository の docs では解決できない。正本 repository での対応になる。

#### 提案0へのフィードバック

**結果:** 提案 1 と 2 を採用。提案 3 は後回しとし、この steering では実施しない。

> 1,2ok。3は後回しで

### 決定

`design.md` の「documentationが成立させる知識」と execution plan 対象へ `frontend/README.md` を追加し、`tasklist.md` の Phase 3 を「Tailwind 運用を説明する docs が変更後の実態と一致する」へ広げる。同じ節へ、論点4 の決定の根拠にあたる設計原則を追記する。

`task-design` skill の Step 0.75 へ「変更対象 file を説明している既存 docs を探す」観点を追加する提案は、この steering では実施しない。`escalate-plugin-skill-fix`による正本 repository への引き渡しは、ユーザーが着手を決めた時点で行う。今回の検出事例が必要性の実例になるため、この記録を根拠として参照する。

なお、この漏れは steering の Ready result 後の必須gateが機能して検出された。gate を省略していれば、逆方向の指示（Lambda ビルド前に tailwindcss CLI を明示実行すること）が README に残ったまま実装が完了していた。
