# components/calendar

## 概要
カレンダー画面の表示・操作に関するコンポーネント群。
週ビュー（WeekCalendar）と月ビュー（MonthCalendar）の両方を含む。

非責務: GraphQL クエリの定義・実行（features/meal/ が担う）

## クイックマップ

- 入口: `WeekCalendar/index.tsx`・`MonthCalendar/index.tsx`
- 共有レイアウト: `calendarComponents/Calendar/index.tsx`
  - **WeekCalendar と MonthCalendar は両方ともこのコンポーネントを使う。
    Calendar を変更すると週・月ビュー両方に影響する。**
- 操作モード管理: `calendarComponents/useCalendarMode.ts`
- 食事カード: `calendarComponents/MealCard/index.tsx`
- 食事追加: `calendarComponents/MealIcon/AddMealIcon.tsx`
- ページナビ用パス定義: `app/calendar/week/[date]/consts.ts`・`app/calendar/month/[date]/consts.ts`
  - `weekCalendarPagePathOf` / `monthCalendarPagePathOf` / `isMonthPath` はここに定義

grep キーワード: `calendar`。GraphQL の `mealsForCalender` 等と、転送だけを行う `app/calender/` には旧綴りが残る。

## 不変条件・契約

- MUST: ディレクトリ名・コンポーネント名は "calendar" で書く。
- MUST: データは `useMeal`（features/meal/）から取得した `mealsForCalender` を
  `dateMealsList` 形式に変換して `Calendar` に渡す。直接 GraphQL を呼ばない。
- MUST: `onDataChanged`（実体は `useRefreshCalendarData.tsx` の `refreshData`）は
  `apolloClient.clearStore()` を含む**全キャッシュ消去**であり、非同期である。
  この callback と並行して別の `refetch` を走らせない。
    - 並走させると in flight の query が store reset と衝突し、
      `Invariant Violation: Store reset while query was in flight` になる
    - 同じ `onCompleted` 内で他の query も更新したい場合は、
      `await onDataChanged()` を先に完了させてから `refetch` する
    - やってしまいがちな失敗: `onDataChanged` という名前から「変更を通知する軽い callback」と読み、
      中身を確認せずに他の非同期処理と並べる

## 変更ガイド

- 操作モード（食事追加・移動・交換）を変更するなら `useCalendarMode.ts` を確認する。
  操作中は `requireDisplayingBottomBar=true` になり、操作 UI が画面下部固定バーに表示される。
- 料理カードに新しいアクション操作を追加するとき、操作の「起動レベル」で渡し方が変わる:
    - 食事（Meal）レベルの操作（例: 移動）:
        `useCalendarMode.ts` の `calendarModeChangers` に追加し、
        Calendar → DateCard → MealCard と props で伝搬させる
    - 日付（Date）レベルの操作（例: 日付交換）:
        DateCard の props として個別に追加し、MealCard に渡す
        MUST: calendarModeChangers に混ぜない（DateCard が担う操作のため）
- カレンダー上で「操作モード」を実現するとき、UIの選択方針:
    - SHOULD: 継続的な操作（移動先選択・交換対象選択など）は底部固定バー（BottomBar）を使う
        - ページ遷移は使わない（カレンダーを見ながら操作する必要があるため）
        - ドロワーも使わない（操作中に複数日付を選択する必要があるため）
    - SHOULD: 単発の入力（食事追加・編集）は `useFullScreenModal` を使う
    - 実装: `useCalendarMode.ts` でモードを管理し、`requireDisplayingBottomBar=true` のとき
      Calendar/index.tsx の底部に操作UIを固定表示する
- MonthCalendar の日付処理に `T09:00:00` の +9時間オフセットがある（暫定）。
  Rails に日付が前日として送られる問題の回避策。日付処理を変更する場合は注意。
- ナビゲーション実装時は `pushHistory` と `<Link>` を使い分ける:
  - MUST: 同じ物理ルート内の日付移動（前週/次週）は `LogicalHistory.pushHistory` を使う
  - MUST: 週ビュー↔月ビューの切替は Next.js `<Link>` を使う。
    `pushHistory` は `window.history.pushState` ベースのため物理ルート変更ができず、コンポーネントが切り替わらない。
