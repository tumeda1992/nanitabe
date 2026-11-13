# グローバル CSS の前提

このリポジトリの全体に効く CSS は、Tailwind と shadcn/ui が前提とする状態と二点で違う。
部品のコードだけを読んでも見えないため、Tailwind の class を書く時にここを確かめる。

## 何が Tailwind の前提と違うか

### preflight を読み込んでいない

Tailwind の preflight（ブラウザの既定スタイルのリセット）を読み込んでいない。
読み込まない理由は `frontend/README.md` の「Tailwind CSS v4 セットアップ（制約）」にある。
`src/app/globals.css` は、`button` の枠線と背景だけを `@layer base` で個別にリセットしている。

そのため、preflight が行う次のリセットは効いていない。

- 要素の `box-sizing` は `content-box` のままである。
- `<a>` はブラウザの既定の青い文字と下線を持つ。
- `svg` と `img` は `inline` のままで、文字の baseline に載る。

### `base.css` が要素へ直接スタイルを当てている

`src/components/base/base.css` は、`div`、`span`、`p`、`li` などの要素へ、`color: #333`、`margin: 0`、`padding: 0` などを直接当てている。
`src/app/apollo_provider.tsx` が読み込むため、全ての画面に効く。

文字色は、親から継承される値より、要素自身に当たった指定が優先される。
そのため、親に付けた `text-*` の色は、子の `div`、`span`、`p` へ届かない。

## 書き方

- MUST: 文字色は、色を見せたい要素自身へ付ける。親へ付けて子へ継承させない。
  - `svg` のアイコンは `currentColor` で描かれるため、`svg` のすぐ外の要素に色が付いているかを見る。
- SHOULD: 幅か高さを固定した要素へ padding か border を足す時は、`box-border` を付ける。
  - 付けないと、固定した値の外側へ padding と border が足される。
- SHOULD: リンクを青い文字と下線で見せない時は、`<a>` へ `text-foreground no-underline` などを付ける。
  - shadcn/ui の `Button` を `asChild` で `next/link` にした時も、描画されるのは `<a>` であるため同じである。
- SHOULD: アイコンを文字の行と揃える時は、`svg` を `block` にする。
  - 部品の内側にある `svg` なら、親へ `[&>svg]:block` を付ける。

## やってしまいがちな失敗

週カレンダーの見直しで、次の四つが起きた。

- `CategoryIcon` は外側の `span` へ区分の色を付けているが、内側の `span` が `base.css` の `#333` を持つ。そのため、アイコンは区分の色にならない。
  - これは見直しの前からの状態である。区分の色を活かすかは決めておらず、今も直していない。
- ヘッダーの「今週」のリンクに `min-w-11` と `px-2` を付けた。`<a>` が content-box のため幅が 60px になり、隣の期間ラベルが切れた。
- 区分アイコンの `svg` が inline のまま baseline に載り、料理名の一行目からずれた。
- ヘッダーの「今週」と月間ビューのアイコンが、青い文字と下線で表示されていた。`<a>` の既定の見た目が残っていたためである。

## 全体のリセットで直さない理由

`globals.css` へ preflight と同じリセットを足すか、`base.css` の `color` を外せば、ここに書いた対処は要らなくなる。
しかし全ての画面の見た目が変わるため、画面ごとの見直しの中で扱う。

preflight を読み込んだ時と、`base.css` を外した時は、この文書を見直す。
