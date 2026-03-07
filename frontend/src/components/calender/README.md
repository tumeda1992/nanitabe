# components/calender

## 概要
カレンダー画面の表示・操作に関するコンポーネント群。
週ビュー（WeekCalender）と月ビュー（MonthCalender）の両方を含む。

非責務: GraphQL クエリの定義・実行（features/meal/ が担う）

## クイックマップ

- 入口: `WeekCalender/index.tsx`・`MonthCalender/index.tsx`
- 共有レイアウト: `calenderComponents/Calender/index.tsx`
  - **WeekCalender と MonthCalender は両方ともこのコンポーネントを使う。
    Calender を変更すると週・月ビュー両方に影響する。**
- 操作モード管理: `calenderComponents/useCalenderMode.ts`
- 料理アイコン: `calenderComponents/MealIcon/index.tsx`
- ページナビ用パス定義: `app/calender/week/[date]/consts.ts`・`app/calender/month/[date]/consts.ts`
  - `weekCalenderPagePathOf` / `monthCalenderPagePathOf` / `isMonthPath` はここに定義

grep キーワード: `calender`（"calendar" ではなくスペルミス表記で統一）

## 不変条件・契約

- MUST: ディレクトリ名・コンポーネント名は "calender"（スペルミス）で統一する。
  "calendar" に混在させると検索・import が壊れる。
- MUST: データは `useMeal`（features/meal/）から取得した `mealsForCalender` を
  `dateMealsList` 形式に変換して `Calender` に渡す。直接 GraphQL を呼ばない。

## 変更ガイド

- 操作モード（食事追加・移動・交換）を変更するなら `useCalenderMode.ts` を確認する。
  操作中は `requireDisplayingBottomBar=true` になり、NextWeekDisplayButton と
  操作 UI が画面下部固定バーに移動する。
- MonthCalender の日付処理に `T09:00:00` の +9時間オフセットがある（暫定）。
  Rails に日付が前日として送られる問題の回避策。日付処理を変更する場合は注意。
- ナビゲーション実装時は `pushHistory` と `<Link>` を使い分ける:
  - MUST: 同じ物理ルート内の日付移動（前週/次週）は `LogicalHistory.pushHistory` を使う
  - MUST: 週ビュー↔月ビューの切替は Next.js `<Link>` を使う。
    `pushHistory` は `window.history.pushState` ベースのため物理ルート変更ができず、コンポーネントが切り替わらない。
