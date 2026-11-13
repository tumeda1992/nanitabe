# 内部検討記録: 論点5 — 見直しを今回コードへ適用するか

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点5

## 開始context

依頼には「適用できることがあるならついでに適用」とある。
論点1から論点4で、ボード D の骨格が決まった。
残る見た目の論点は、操作欄の開き方、他の日の評価の出し方、区分アイコン、背景色である。
これらを今決める必要があるかは適用の範囲で変わるため、先に範囲を問う。

<a id="iteration-0"></a>

## イテレーション0: 適用の範囲を、作業の目的と規模へ当てる

<a id="iteration-0-record-1"></a>

### 調査: 適用した時の影響範囲はどこまでか

#### 問い・探索範囲・方法

適用の規模と、週カレンダーの外への影響を確かめた。

- `frontend/src/components/calendar/MonthCalendar/index.tsx`、`WeekCalendar/index.tsx` の import
- `frontend/src/components/calendar` 配下の `*.spec.tsx` の行数
- `MealCard/index.spec.tsx` の操作欄の開き方
- `frontend/src` の `.tsx`（spec を除く）で、色指定のない `border` class を使う file を正規表現で検索
- `gh issue view 297`

#### 見つかった事実

- `Calendar` は週と月の両方が import している。
- `MealCard/index.spec.tsx` は 417 行で、「その他のアクション」のラベルで操作欄を開いている。
- 色指定のない `border` class を使う file は8件で、`DateCard`、`FrameCard`、`MealCard` のほかに、`app/dishes/page.client.tsx`、`SourceForm`、`DishFormOfRelatedDishSource`、`DishFormOfOnlyDishFields`、`MealForm` がある。
- issue #297 の題名は「ClaudeDesign使ってみる」で、open である。`feature-297` は `main` と同じ commit にある。

#### 言える範囲と限界

正規表現は1行の `className` を対象としており、複数行の指定は拾えない可能性がある。
どの spec が実際に変更を要するかは調べていない。

<a id="iteration-0-record-2"></a>

### 判断: 適用の範囲をどうするか

#### 判断対象・必須条件・根拠

根拠は依頼の文と、`docs/development_standards/development_flow/work_scope.md` の判定である。
適用は依頼の目的の内にある。

- a: D を週カレンダーへ適用する。
- b: 重さの修正だけを適用し、D の構造の変更は別の issue へ切り出す。
- c: 今回は適用しない。

#### 当てた結果

a を推す。決め手は、キャンバスからコードへの移行が、Claude Design のポテンシャルを知るという目的の一部であることである。

b は小さいが、今日のクローズアップなどの中心が実現しない。
c は本番への影響がないが、案がコードへ移るかが分からないままになる。
本人がどこまでの規模を「ついでに」と考えているかは分からず、これは本人の判断である。

#### 読解として残すもの

本人の「数週分決めるとき」という発言から、複数週の献立は週ビューを送って決めていると読んだ。
本人に確認していないため、月ビューの扱いは未決のままとする。
