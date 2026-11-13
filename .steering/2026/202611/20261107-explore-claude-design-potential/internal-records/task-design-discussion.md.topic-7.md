# 内部検討記録: 論点7 — カレンダーの README の古い記述を今回直すか

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点7

## 開始context

論点6で、デザイン意図の正本を `frontend/src/components/calendar/README.md` に決めた。
この README の先頭には「MUST: ディレクトリ名・コンポーネント名は "calender"（スペルミス）で統一する」とあるが、実際のディレクトリは `calendar` である。

この論点で決めるのは、古い記述を今回の作業で直すか、別の issue へ切り出すかと、直す内容である。

<a id="iteration-0"></a>

## イテレーション0: 古い記述の範囲と、切り出す条件

<a id="iteration-0-record-1"></a>

### 調査: README のどの記述がコードと合っていないか

#### 問い・探索範囲・方法

README に現れる名前を `frontend/src` の `.ts`、`.tsx`（`lib/graphql/generated` を除く）で検索し、件数を数えた。
`calendarComponents` の file 一覧、`app/calender/week/page.tsx`、`MonthCalendar/index.tsx` を読んだ。

#### 見つかった事実

- 検索で 0 件だった名前: `WeekCalender`、`MonthCalender`、`calenderComponents`、`useCalenderMode`、`calenderModeChangers`、`weekCalenderPagePathOf`、`monthCalenderPagePathOf`
- 残っている旧綴り: GraphQL 由来の `mealsForCalender`（8 file）、`app/calender/` の route。`app/calender/week/page.tsx` は `/calendar/week/thisweek` へ転送するだけである。
- `calendarComponents/MealIcon/` に `index.tsx` はなく、`AddMealIcon.tsx` 等がある。
- `useFloatModal` は定義の file の外から参照されていない。単発の入力は `useFullScreenModal` を使っている。
- `NextWeekDisplayButton` は `useCalendarArrowComponent.tsx` の外から参照されていない。`Calendar/index.tsx` の底部バーにもない。
- `T09:00:00` のオフセットは `MonthCalendar/index.tsx:75` に実在する。

#### 言える範囲と限界

検索は文字列の一致であり、動的な参照は拾えない。
README の他の節（`onDataChanged`、`pushHistory` と `<Link>` の使い分け）の正しさは確かめていない。

<a id="iteration-0-record-2"></a>

### 判断: 今回直すか、切り出すか

#### 判断対象・必須条件・根拠

根拠は `docs/development_standards/development_flow/work_scope.md` の二段の判定である。

- 一段目: 結論が変わっても今回の完成後の姿は同じであり、目的の外の不備である。
- 二段目: 大きすぎない。別の commit にすれば単体で revert でき、本番への適用も遅らせない。切り出す条件に当たらない。

#### 当てた結果

今回直すことを推す。
今回の適用の実装者はこの README を読むため、誤った MUST を残すと今回の作業そのものが誤る。

未使用に見える `useFloatModal` と `NextWeekDisplayButton` のコードの削除は含めない。
README の修正とは別の変更であり、参照の不在の確認も文字列の検索に留まるためである。
