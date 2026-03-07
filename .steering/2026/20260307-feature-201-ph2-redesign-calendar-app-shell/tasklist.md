# タスクリスト: カレンダーアプリシェル・ヘッダー刷新（フェーズ2）

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

- 各タスク完了後に `[x]` に更新する
- テスト失敗・ESLint エラーを残したまま次タスクへ進まない

---

## フェーズ1: CalendarHeader コンポーネント作成

### DoD（完了条件）
- CalendarHeader が単体でレンダリングでき、全ボタンが表示される
- テスト全グリーン

### タスク

- [ ] `frontend/src/components/calender/calenderComponents/CalendarHeader/index.tsx` を新規作成
    - 使用コンポーネント: `@/components/ui/button`（Button）、`@/components/ui/dropdown-menu`（DropdownMenu 系）
    - 使用アイコン（lucide-react）: `ChevronLeft`, `ChevronRight`, `CalendarRange`, `CalendarDays`, `EllipsisVertical`, `UtensilsCrossed`
    - Props:
        ```ts
        type CalendarHeaderProps = {
          viewType: 'week' | 'month';
          displayLabel: string;       // 期間ラベル（例: "2026年3月7日〜13日"）
          currentDate: Date;          // 週月切替・今日ボタンのリンク計算に使う
          refreshToPrev: () => void;
          refreshToNext: () => void;
          isDisplayCalenderMode: boolean;
          onStartAssigningDish: () => void; // 食事割当てモード起動
        }
        ```
    - リンク計算はコンポーネント内で行う（props として注入しない）:
        - 今週ボタン: `WEEK_CALENDER_PAGE_PATH_OF_THIS_WEEK`（週）/ `MONTH_CALENDER_PAGE_PATH_OF_THIS_MONTH`（月）
        - 週切替: `weekCalenderPagePathOf(currentDate)`
        - 月切替: `monthCalenderPagePathOf(currentDate)`
    - レイアウト（v0 デザインに合わせる）:
        ```
        <header sticky top-0 z-10 border-b bg-background/95 backdrop-blur>
          <div flex items-center justify-between>
            左: ChevronLeft + "今週"/"今月" + ChevronRight
            中央: displayLabel (truncate)
            右: CalendarRange(週) + CalendarDays(月) + EllipsisVertical(dropdown)
          </div>
        </header>
        ```
    - DropdownMenu の内容:
        - `isDisplayCalenderMode` が true のとき: 「食事割当て」（onStartAssigningDish を呼ぶ）
        - 常時: 「(admin)ワード正規化」（`https://nanitabe_back.kibotsu.com/admin/food/dish/word/normalize_words` への外部リンク）
    - 週月切替ボタン・今週/今月ボタン: `<Link>`（next/link）
    - 前後ナビ: `onClick={refreshToPrev}` / `onClick={refreshToNext}`

---

## フェーズ2: Calender/index.tsx の children callback 拡張

### DoD（完了条件）
- children callback が `refreshToPrev`・`refreshToNext` を返す
- 既存の PreviousWeekDisplayButton/NextWeekDisplayButton の描画が Calender 内から除去される
- テスト全グリーン

### タスク

- [ ] `Calender/index.tsx` の children callback に `refreshToPrev`・`refreshToNext` を追加
    - 変更前: `children({ isDisplayCalenderMode, useAssignDishModeResult })`
    - 変更後: `children({ isDisplayCalenderMode, useAssignDishModeResult, refreshToPrev, refreshToNext })`
    - `refreshToPrev`・`refreshToNext` は Calender の props からそのまま渡す

- [ ] Calender/index.tsx 内の `<PreviousWeekDisplayButton />` と `<NextWeekDisplayButton />` の描画を削除
    - `useCalenderArrowComponent` の呼び出しも削除（CalendarHeader が直接 refreshToPrev/Next を使う）
    - `BottomBar` エリアの `<NextWeekDisplayButton />` も削除
    - ※ `requireDisplayingBottomBar` や bottom-bar の構造自体は維持（次フェーズで AssignDish 等に使う）

- [ ] TypeScript の型エラーがないことを確認
    - `docker compose exec frontend yarn lint`

---

## フェーズ3: WeekCalender に CalendarHeader を組み込む

### DoD（完了条件）
- 週ビューで新ヘッダーが表示される
- 前後ナビ・今週ボタン・週月切替・ドロップダウン（食事割当て・admin）が動作する
- 既存の操作モード（AssignDish/MoveMeal/SwapMeals）が引き続き動作する
- テスト全グリーン

### タスク

- [ ] `WeekCalender/index.tsx` の children を CalendarHeader に置き換える
    - `viewType`: `"week"`
    - `displayLabel`: `format(firstDisplayDate, 'yyyy年M月d日')` + 週末日付（例: "2026年3月7日〜13日"）
        - `addDays(firstDisplayDate, 6)` で週末を計算
    - `currentDate`: `firstDisplayDate`（リンク計算は CalendarHeader 内で行う）
    - `refreshToPrev`: children callback から受け取る
    - `refreshToNext`: children callback から受け取る
    - `isDisplayCalenderMode`: children callback から受け取る
    - `onStartAssigningDish`: `useAssignDishModeResult.startAssigningDishMode`

- [ ] テスト実行: `docker compose exec frontend yarn test` → 全グリーン確認

---

## フェーズ4: MonthCalender に CalendarHeader を組み込む

### DoD（完了条件）
- 月ビューで新ヘッダーが表示される
- 週ビューと同様に動作する

### タスク

- [ ] `MonthCalender/index.tsx` の children を CalendarHeader に置き換える
    - `viewType`: `"month"`
    - `displayLabel`: `format(firstDayOfMonth, 'yyyy年M月')`
    - `currentDate`: `firstDayOfMonth`（リンク計算は CalendarHeader 内で行う）
    - その他（refreshToPrev/Next, isDisplayCalenderMode, onStartAssigningDish）は WeekCalender と同様

- [ ] テスト実行: `docker compose exec frontend yarn test` → 全グリーン確認

---

## フェーズ5: CalenderMenu の削除

### DoD（完了条件）
- 旧 CalenderMenu コンポーネントが削除されている
- 参照箇所がゼロ（ESLint・TypeScript エラーなし）

### タスク

- [ ] `WeekCalender/CalenderMenu.tsx` を削除
    - 削除前に import 参照がなくなっていることを確認

- [ ] `calenderComponents/CalenderMenu/useCalenderMenuComponent.tsx` を削除
    - 削除前に import 参照がなくなっていることを確認

- [ ] `calenderComponents/CalenderMenu/` ディレクトリを削除

---

## フェーズ6: 品質チェックと修正

### DoD（完了条件）
- 全テストグリーン
- ESLint エラーゼロ（プロジェクト全体）

### タスク

- [ ] 全テスト実行
    - [ ] `docker compose exec frontend yarn test`
    - [ ] 全グリーン確認。失敗があれば原因を修正して再実行

- [ ] ESLint 実行（新規・変更ファイル）
    - [ ] `docker compose exec frontend yarn lint src/components/calender/`
    - [ ] エラーがあれば修正して再実行

- [ ] ESLint 実行（プロジェクト全体）
    - [ ] `docker compose exec frontend yarn lint`
    - [ ] エラーがあれば修正して再実行

---

## 実装後の振り返り

### 実装完了日
{YYYY-MM-DD}

### 計画と実績の差分

**計画と異なった点**:
-

**新たに必要になったタスク**:
-

**技術的理由でスキップしたタスク**（該当する場合のみ）:
-
