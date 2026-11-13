# 内部検討記録: 論点2 — Tailwind の色名の値をどこから取るか

**discussion:** [implementation_review.md](../implementation_review.md)

**論点:** 論点2

## 開始context

点数の色について、Design System の `tokens.json` の `rating-text` と、`visual-inspector` への検査の期待値の二箇所で、コードの計算値と違う値を書いた。
決める範囲は、この食い違いの原因と、次に防ぐために何をどこへ書くかである。
論点1で、確定案の値を実装へ渡す手順とは別の問いとして分けた。

開始時の既決条件は次のとおりである。

- `ui_design_management.md` は「作業場はリポジトリから作る」と定めている。
- `tasklist.md` の差13 で、点数の色 `rgb(187, 77, 0)` は Tailwind v4 の `amber-700` の値であり、不具合ではないと判定済みである。Phase 7 で `rating-text` を v4 の値へ直す task がある。

<a id="iteration-0"></a>

## イテレーション0: 食い違いの原因と置き場所

<a id="iteration-0-record-1"></a>

### 調査: Tailwind v4 の色名の値と、v3 の値との違い

#### 問い・探索先・方法

コードが使う Tailwind の色名の値は何で、v3 の値とどれだけ違うか。
`frontend/node_modules/tailwindcss/package.json` の version と、`frontend/node_modules/tailwindcss/theme.css` の定義を grep で確かめた。
計算値は `tasklist.md` の検査の記録から取った。

#### 結果

- Tailwind の version は 4.2.1 である。
- `--color-amber-700: oklch(55.5% 0.163 48.998)`。検査の計算値は `rgb(187, 77, 0)`。v3 の値 `#b45309`（`rgb(180, 83, 9)`）と違う。
- `--color-zinc-700: oklch(37% 0.013 285.805)`。検査の計算値は `rgb(63, 63, 70)`。v3 の値 `#3f3f46` と一致する。

色名ごとに、v3 と値が違うものと一致するものがある。
コードが Tailwind の色名を直接使う時、値はリポジトリの中に現れず、Tailwind の定義が正本になる。

<a id="iteration-0-record-2"></a>

### 診断: v3 の値を書いた原因

#### 期待との差と原因候補

期待は、作業場のトークンと検査の期待値が、コードの計算値と一致することである。
実際は、`rating-text` と検査の期待値が v3 の `amber-700` の値だった。

#### 原因

私が色名から v3 の値を思い出して書いた。
Tailwind の定義も計算値も見ていない。
`zinc-700` のように v3 と一致する色もあるため、記憶で書くと、合っている色と違う色が混ざり、どれが違うかに気づきにくい。

共有知識の不足として扱う。
`ui_design_management.md` は作業場をリポジトリから作るとしているが、値がリポジトリに現れない色名の扱いは書いていない。

<a id="iteration-0-record-3"></a>

### 判断: どこへ書くか

#### 判断対象・必須条件・根拠

`ui_design_management.md` の「Claude Design を使う時の進め方」へ一行足すことを推す。
決め手は、作業場の写し直しと、画面を確かめる時の期待値の両方で同じ問いが起き、どちらも UI のデザインを扱う作業だからである。

必須条件は、作業場を作るセッションと画面を確かめるセッションが読むことである。
比較した置き場所は、`ui_design_management.md`、`global_css.md`、`frontend/README.md` の Tailwind の節である。

#### 当てた結果

- `ui_design_management.md`: frontend を扱うセッションで `@` から読み込まれる。「作業場はリポジトリから作る」の隣に置けば、値の取り方として読める。
- `global_css.md`: 全体に効く CSS が Tailwind の前提と違う点を扱う。色の値の取り方はその範囲ではない。
- `frontend/README.md` の Tailwind の節: 自動では読み込まれず、作業場を作るセッションへ届かない。

例として `amber-700` の v3 と v4 の値を書く。
v4 の中で Tailwind の定義が変わる可能性はあるが、例は v3 と v4 で値が違うことを示すためのものであり、定義の正本を `theme.css` と書くため、例が古くなっても手順は誤らない。

<a id="iteration-0-record-4"></a>

### 判断: 反映の後に、repository の文書へ残す知識がほかにあるか

#### 判断対象・必須条件・根拠

本人の受諾（「ok」）を受け、`ui_design_management.md` へ一行足した。
この論点の提案自体が、原因を repository の知識の不足と分類した後の文書の修正案であり、doc-enricher の提案 review の一回に数える。

#### 当てた結果

候補なしとした。
Design System の `rating-text` を v4 の値へ直すことは文書の追記ではなく、Phase 7 の既存の task が扱う。
