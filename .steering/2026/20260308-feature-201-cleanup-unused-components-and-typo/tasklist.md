# タスクリスト: 後片付け（不要コンポーネント削除 + calender タイポ修正）

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### タスクスキップが許可される唯一のケース
以下の技術的理由に該当する場合のみスキップ可能:
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

---

## フェーズ1: 不要コンポーネント削除

### DoD（完了条件）
- 削除対象ファイルがすべて存在しない
- テスト全グリーン・ESLint エラーゼロ

### タスク

- [x] `Calender/old/` を削除
    - [x] `components/calender/calenderComponents/Calender/old/index.tsx` を削除
    - [x] `components/calender/calenderComponents/Calender/old/index.module.scss` を削除

- [x] `MealIcon` の旧ファイルを削除（`old/` 含む）
    - [x] `components/calender/calenderComponents/MealIcon/old/` ディレクトリごと削除（index.tsx / Menu.tsx / Menu.spec.tsx / index.module.scss / Menu.module.scss）
    - [x] `components/calender/calenderComponents/MealIcon/index.tsx` を削除
    - [x] `components/calender/calenderComponents/MealIcon/Menu.tsx` を削除
    - [x] `components/calender/calenderComponents/MealIcon/Menu.spec.tsx` を削除
    - [x] `components/calender/calenderComponents/MealIcon/index.module.scss` を削除
    - [x] `components/calender/calenderComponents/MealIcon/Menu.module.scss` を削除

- [x] `Date.tsx` を削除
    - [x] `components/calender/calenderComponents/Date.tsx` を削除

- [x] テスト・ESLint 実行
    - [x] `docker compose exec frontend yarn test`（全テストグリーン）
    - [x] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ2: `calender` タイポ修正

### DoD（完了条件）
- `calender`/`Calender` を grep して、下記対象外を除きヒットゼロ
  - **対象外（バックエンドスキーマ由来）**: `graphql.ts`・`fetchMealQuery.ts` 内の `mealsForCalender`/`MealForCalender`/`useMealsForCalender`
- テスト全グリーン・ESLint エラーゼロ

### 修正方針
1. ディレクトリ・ファイルをリネーム
2. リネーム後に全ファイルの import パス・変数名を一括置換
3. テスト実行

### タスク

- [x] 旧 URL ページの整理（`src/app/calender/`）
    - [x] `src/app/calender/week/[date]/page.tsx` を `/calendar/week/` へ `permanentRedirect` に書き換え
    - [x] `src/app/calender/week/[date]/consts.ts` を削除（redirect のみなので不要）
    - [x] `src/app/calender/week/page.tsx` を `/calendar/week/thisweek` へ `permanentRedirect` に書き換え（または確認して削除）
    - [x] `src/app/calender/month/[date]/page.tsx` を `/calendar/month/[date]` へ `permanentRedirect` に書き換え
    - [x] `src/app/calender/month/[date]/consts.ts` を削除
    - [x] `src/app/calender/month/page.tsx` を `/calendar/month/thismonth` へ `permanentRedirect` に書き換え（または削除）

- [x] ディレクトリ・ファイルのリネーム
    - [x] `components/calender/calenderComponents/useCalenderMode.ts` → `useCalendarMode.ts`
    - [x] `components/calender/calenderComponents/useCalenderArrowComponent.tsx` → `useCalendarArrowComponent.tsx`
    - [x] `components/calender/WeekCalender/useWeekCalenderDate.ts` → `useWeekCalendarDate.ts`
    - [x] `components/calender/useRefreshCalenderData.tsx` → `useRefreshCalendarData.tsx`
    - [x] `components/calender/calenderComponents/` → `calendarComponents/`（ディレクトリリネーム）
    - [x] `components/calender/WeekCalender/` → `WeekCalendar/`（ディレクトリリネーム）
    - [x] `components/calender/MonthCalender/` → `MonthCalendar/`（ディレクトリリネーム）
    - [x] `components/calender/calenderComponents/Calender/` → `Calendar/`（ディレクトリリネーム）
    - [x] `components/calender/` → `components/calendar/`（トップレベルディレクトリリネーム）

- [x] ファイル内容の修正（import パス・変数名・コンポーネント名）
    - [x] リネームしたファイルの import パスを一括修正（grep で漏れ確認）
    - [x] `calenderModeChangers` → `calendarModeChangers`（DateCard.tsx・DishCard/index.tsx 等）
    - [x] `isDisplayCalenderMode` → `isDisplayCalendarMode`
    - [x] `WeekCalender` → `WeekCalendar`（コンポーネント名・型名）
    - [x] `MonthCalender` → `MonthCalendar`
    - [x] `Calender` → `Calendar`（コンポーネント名、ただし GraphQL 由来の `MealForCalender` は除く）
    - [x] `useCalenderMode` → `useCalendarMode`
    - [x] `useCalenderArrowComponent` → `useCalendarArrowComponent`
    - [x] `useWeekCalenderDate` → `useWeekCalendarDate`
    - [x] `useRefreshCalenderData` → `useRefreshCalendarData`
    - [x] `app/calendar/` ページ内の `WeekCalender` import パスを新パスに修正

- [x] テスト・ESLint 実行
    - [x] `docker compose exec frontend yarn test`（全テストグリーン）
    - [x] `docker compose exec frontend yarn lint`（エラーゼロ）
    - [x] `grep -rn "calender\|Calender" frontend/src --include="*.tsx" --include="*.ts"` で対象外以外のヒットがないこと確認
      - 残存するヒット（技術的理由でスキップ）: `MealsForCalenderDocument`・`MealForCalender`・`mealsForCalender`・`refetchMealsForCalender`・`fetchMealsForCalenderParams` は `graphql.ts`（変更禁止）または `fetchMealQuery.ts`（変更禁止）由来のバックエンドスキーマ名。コンポーネントファイル内で使用されている箇所もこれらのAPIインターフェースから来ており変更不可

---

## フェーズ3: 品質チェック

### DoD（完了条件）
- 全テストがグリーン
- ESLint エラーがゼロ（プロジェクト全体）

### タスク

- [x] 全テスト実行
    - [x] `docker compose exec frontend yarn test`
    - [x] 全テストグリーン確認

- [x] ESLint 実行（プロジェクト全体）
    - [x] `docker compose exec frontend yarn lint`
    - [x] エラーゼロ確認

---

## 実装後の振り返り

### 実装完了日
2026-03-08

### 計画と実績の差分

**計画と異なった点**:
- `useCalenderDay.ts` → `useCalendarDay.ts` および `useMonthCalenderDate.ts` → `useMonthCalendarDate.ts` のリネームがタスクリストに未記載だったが、DoD達成のために追加実施

**新たに必要になったタスク**:
- `useCalenderDay.ts`、`useMonthCalenderDate.ts` のリネーム

**技術的理由でスキップしたタスク**（該当する場合のみ）:
- grep DoD の「ヒットゼロ」について: `MealsForCalenderDocument`・`MealForCalender`・`mealsForCalender`・`refetchMealsForCalender`・`fetchMealsForCalenderParams` の参照が `graphql.ts`（自動生成・変更禁止）および `fetchMealQuery.ts`（バックエンドスキーマ由来・変更禁止）から来ているため、コンポーネントファイル内でこれらを参照する箇所も変更できない。バックエンドAPIスキーマとの整合性を保つための技術的制約。
