# 要件ドキュメント

## はじめに

カレンダーデザイン移行フェーズ2として、アプリシェル・ヘッダーを v0 デザインに刷新する。
週ビュー・月ビューは既存の WeekCalender/MonthCalender をそのまま内包し、ヘッダーのみを置き換える。
ルーティング構造（`/calender/week/[date]`・`/calender/month/[date]`）は変えない。

## 元の依頼内容

`.steering/2026/20260307-feature-201-apply-v0-calendar-design/tasklist.md` フェーズ2:
- 新ヘッダー実装（前後ナビ・今週/今月・週月切替・ドロップダウンメニュー）
- 中身は既存の WeekCalender/MonthCalender をそのまま内包して正常動作させる
- 既存テストが全てグリーン

## 要件

### 要件1: 新ヘッダーが表示される
**ユーザーストーリー:** ユーザーがカレンダーを開いたとき、v0 デザインと同等のスティッキーヘッダーが表示される

#### 受け入れ基準
1. WHEN カレンダーを開く THEN 前後ナビ（ChevronLeft/Right）+ 今週/今月ボタン + 期間ラベル + 週月切替 + ドロップダウンが表示される
2. WHEN 前後ナビを押す THEN 既存の週送り/月送りロジックが動く
3. WHEN 今週/今月ボタンを押す THEN 今日の週/月に移動する
4. WHEN 週月切替を押す THEN 対応するビューに切り替わる
5. WHEN ドロップダウンを開く THEN 食事割当て・(admin)ワード正規化 のメニューが表示される

### 要件2: 既存コンテンツが正常動作する
**ユーザーストーリー:** ヘッダーが変わっても週ビュー・月ビューの中身と既存操作が引き続き動く

#### 受け入れ基準
1. WHEN ヘッダーを差し替えた後 THEN 週/月カレンダーの表示・操作（AssignDish/MoveMeal/SwapMeals）が壊れない
2. WHEN `docker compose exec frontend yarn test` を実行する THEN 全テストグリーン
3. WHEN `docker compose exec frontend yarn lint` を実行する THEN エラーゼロ

---

# 設計ドキュメント

## TL;DR

新しい `CalendarHeader` コンポーネントを `calenderComponents/CalendarHeader/` に作成し、
既存の `Calender/index.tsx` の children callback に `refreshToPrev`/`refreshToNext` を追加して
WeekCalender/MonthCalender から CalendarHeader に渡す。
週月切替は Next.js の `<Link>` で物理ルートを切り替える（LogicalHistory ではない）。
ルーティング構造は変えない。

## 重要な既存実装の理解

### LogicalHistory と物理ルーティングの使い分け
- **日付ナビ（前週/次週）**: `pushHistory` で論理URL変更（SPA的・フルリロードなし）
- **週月切替**: 物理ルート `/calender/week/` ↔ `/calender/month/` の切り替えが必要 → `<Link>` を使う
  - `pushHistory` で `/calender/month/...` に変えてもコンポーネントが切り替わらないため

### CalenderMenu の現状
現行の CalenderMenu（`WeekCalender/CalenderMenu.tsx`）が持つ機能:
- 食事割当て（useAssignDishModeResult.startAssigningDishMode）
- 今週に移動（Link to /calender/week/thisweek）
- (admin) ワード正規化（外部リンク）

→ 新ヘッダーに統合する。「今週/今月ボタン」で今週移動は代替。

## 変更点サマリ

| 変更 | ファイル |
|------|--------|
| 新規作成 | `frontend/src/components/calender/calenderComponents/CalendarHeader/index.tsx` |
| 修正 | `frontend/src/components/calender/calenderComponents/Calender/index.tsx`（children callback 拡張） |
| 修正 | `frontend/src/components/calender/WeekCalender/index.tsx`（CalendarHeader を使うよう変更） |
| 修正 | `frontend/src/components/calender/MonthCalender/index.tsx`（CalendarHeader を使うよう変更） |
| 削除対象 | `frontend/src/components/calender/WeekCalender/CalenderMenu.tsx`（CalendarHeader に統合） |
| 削除対象 | `frontend/src/components/calender/calenderComponents/CalenderMenu/` ディレクトリ（不要になる） |

## 設計選択と理由

### ルーティング構造を変えない
週月で `/calender/week/[date]` と `/calender/month/[date]` の物理ルートを維持する。
LogicalHistory の pushState では物理ルートの切り替えができないため、
統合ページを作ると LogicalHistory 全体の設計変更が必要になる。
フェーズ2のスコープは「見た目のヘッダー刷新」であり、ルーティング変更はリスクが大きいため棄却。

### CalendarHeader を calenderComponents/ に配置
WeekCalender・MonthCalender 両方から使う共有コンポーネントのため、
`calenderComponents/` 直下が責務上適切。
新規ディレクトリは "calendar"（正しいスペル）で命名する。

### children callback に refreshToPrev/refreshToNext を追加
CalendarHeader が prev/next ボタンを持つため、Calender の children callback から
`refreshToPrev` と `refreshToNext` を受け取れるよう拡張する。
既存の PreviousWeekDisplayButton / NextWeekDisplayButton（Calender 内の矢印ボタン）は不要になるため削除する。

### CalendarHeader の週月切替
- 週ビュー → 月ビュー: `weekCalenderPagePathOf(currentDate)` → `monthCalenderPagePathOf(currentDate)` へ Link
- 月ビュー → 週ビュー: その逆
- `viewType: 'week' | 'month'` と `currentDate` を props で受け取る

### CalenderMenu の統合・削除
CalenderMenu（食事割当て・管理リンク）は新ヘッダーのドロップダウンに統合するため不要になる。
CalenderMenu コンポーネント自体は削除する。

### DishLibraryDrawer は実装しない
フェーズ2のスコープ外（料理一覧はスコープ外）。ドロップダウンに「料理一覧」は入れない。

## 代替案と棄却理由

### 代替案1: 統合ページ（/calender）を作り週月をタブで管理
理想形だが、LogicalHistory の設計変更・既存 useCalenderMode の接続し直しが必要で複雑。
フェーズ2のスコープを超えるため棄却。後フェーズで検討可。

### 代替案2: 既存 Calender 内の PreviousWeekDisplayButton を活かして CalendarHeader に前後ボタンを入れない
prev/next が分離すると v0 デザインの統一ヘッダーにならないため棄却。

## リスクと対策

| リスク | 対策 |
|--------|------|
| children callback 拡張で既存コードの型エラー | WeekCalender/MonthCalender の children も同時に修正してエラーをゼロにする |
| CalenderMenu 削除で既存テストが壊れる | CalenderMenu.tsx の参照箇所を全て確認・修正してから削除 |
| 週月切替 Link で意図しないリロードが発生 | `<Link>` の Next.js デフォルト動作で SPA 遷移するため問題ないはず |
| 今週/今月ボタンの日付計算が既存と異なる | 既存の `WEEK_CALENDER_PAGE_PATH_OF_THIS_WEEK` 等の定数を流用する |

## テスト方針

- 新規コンポーネント（CalendarHeader）に最小限の表示テストを追加
- CalenderMenu の削除に伴い、Menu.spec.tsx（存在する場合）は削除または更新
- `docker compose exec frontend yarn test` で全グリーン確認
- `docker compose exec frontend yarn lint` でエラーゼロ確認
