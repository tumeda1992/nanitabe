# Tailwind のビルドと watch

Tailwind CSS v4 を Next.js（Turbopack）と組み合わせたときの特性と、それに対する工夫。
特定のマシンや Docker 環境に依存しない内容を扱う。

ローカル開発マシンで実際にコンテナが壊れたときの症状と復旧手順は
@../../ai_guideline/development_standard/docker.local.md を参照。

## 構成

`@tailwindcss/postcss` を PostCSS へ統合せず、`@tailwindcss/cli` を独立プロセスで実行する。
PostCSS へ統合すると Turbopack の dev compile が 2 分超になるため。

- `package.json` の `build:css` が入出力 path を持つ唯一の場所
- `build` は `build:css && next build`、`dev` は `watch:css & next`
- 生成物 `src/app/tailwind-output.css` は gitignore 対象。`layout.tsx` が import する

したがって Next.js から見ると、Tailwind の出力は「別プロセスが書き出したファイルを import している」
形になる。以下の特性はこの構成に起因する。

## watch は `--watch=always` で起動する

`--watch` の tailwindcss CLI は **stdin が閉じられると watcher を自己終了させる**。
background 起動した場合、およそ 60 秒で stdin が閉じて watcher が黙って終了する。

エラーを出さないため、「`globals.css` を変更しても `tailwind-output.css` が更新されない」
という症状としてのみ現れる。`--watch=always` は stdin の状態に関わらず watcher を継続させる。

```json
"watch:css": "yarn build:css --watch=always"
```

## 出力が変わらないことは watcher の停止を意味しない

`globals.css` を変更しても `tailwind-output.css` が変わらないとき、
watcher が生きていても起こり得るケースが 2 つある。

### `@layer utilities` は tree-shake される

`@layer utilities` へ書いたカスタム CSS は、`globals.css` の `@source` が対象とするファイル内で
参照されていなければ出力に現れない。tailwindcss は内容が同一なら出力ファイルを書き直さないため、
mtime も変わらない。

`@layer base` は tree-shake されない。watcher の生死を確かめたいときは `@layer base` を使う。

```css
/* 出力に現れない（未参照なので tree-shake される） */
@layer utilities {
  .tmp-check { color: red; }
}

/* 出力に現れる */
@layer base {
  hr { border-top-width: 3px; }
}
```

### 反映に遅延がある

変更が出力へ届くまで十数分かかることがある。変更直後の 1 回の観測で判定しない。

実測例: `@layer base` のルールを 1 個追加 → 出力反映まで約 12 分。
その後 revert → さらに約 2 分で元のサイズへ復帰。

## 再コンパイル時にメモリが大きく膨張する

dev サーバ稼働中、コンテナ全体のメモリ使用量が数分で数百 MB 台から 5〜6GB へ急増する。

**`globals.css` の編集と因果関係がない。** 実測での再現パターン:

| 操作 | 経過 | 到達量 |
| --- | --- | --- |
| CSS ルール 1 個を追加して即座に削除 | 4 秒 | 2.5GiB |
| CSS ルール 1 個を追加のみ | 25 秒 | 4.45GiB |
| **編集せず定点観測のみ** | 45 秒 | 5.25GiB |
| CSS ルール 1 個を追加（別機会） | — | 6.43GiB |

したがって「変更量を小さくすれば安全」という回避策は成立しない。

原因は tailwindcss CLI の watcher 単体ではなく、`tailwind-output.css` を import している
`layout.tsx` を Turbopack が再コンパイルする経路にあると推測される。
同経路で `FATAL: An unexpected Turbopack error occurred` の panic ログが観測されている。

この性質は上記の構成そのものに起因し、build script をどこに置くかとは独立している。

## 起動済み watcher があるときに Tailwind を二重に走らせない

- **MUST**: watcher が常駐している状態で、Tailwind をコンパイルする操作を別に実行しない
  - `build` は `build:css` を含むため `yarn build` も該当する
  - 競合すると OOM が発生し watcher が死ぬ

ビルドが通るかを確かめたいだけなら、CI の `CI Frontend Build Verification` が
同じ検証を行う。watcher が動いている環境で実行する必要はない。
