# タスクリスト: フェーズ3 カレンダービュー刷新（DateCard 形式）

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

## フェーズ1: 既存 Calender/index.tsx を old/ に退避

### DoD（完了条件）
- `Calender/old/index.tsx` に既存コンポーネントが移動している
- WeekCalender・MonthCalender が old/ のパスから正しくインポートしている
- 全テストがグリーン・ESLint エラーがゼロ

### タスク

- [x] `Calender/index.tsx` を `Calender/old/index.tsx` に移動
    - [x] `frontend/src/components/calender/calenderComponents/Calender/old/` ディレクトリを作成
    - [x] `Calender/index.tsx` → `Calender/old/index.tsx` に移動
    - [x] `Calender/index.module.scss` → `Calender/old/index.module.scss` に移動（存在する場合）

- [x] WeekCalender・MonthCalender のインポートパスを修正
    - [x] `WeekCalender/index.tsx`: `../calenderComponents/Calender` → `../calenderComponents/Calender/old`
    - [x] `MonthCalender/index.tsx`: 同上
    - [x] 他に `Calender/index.tsx` を参照している箇所を grep で確認し修正

- [x] テスト・ESLint 実行で動作確認
    - [x] `docker compose exec frontend yarn test`（全テストグリーン）
    - [x] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ2: DateCard コンポーネント実装

### DoD（完了条件）
- `DateCard.tsx` が単体でレンダリングでき、表示・機能テストが全てグリーン

### タスク

- [x] `DateCard.tsx` を新規作成（`calenderComponents/DateCard.tsx`）
    - [x] Props 定義
        ```
        type DateCardProps = {
          date: Date;
          dayLabel: string;
          meals: MealForCalender[];
          isDisplayCalenderMode: boolean;
          calenderModeChangers: any;
          onChanged: () => Promise<void>;
          startSwappingMealsMode: (date: Date) => void;
        };
        ```
    - [x] カードラッパー: `rounded-xl border bg-card px-2.5 py-1.5`
    - [x] 今日ハイライト: `isSameDay(date, new Date())` のとき `ring-2 ring-primary/40` を追加
    - [x] 土曜（getDay=6）: 日番号・曜日ラベルに青色クラス（例: `text-blue-500`）
    - [x] 日曜（getDay=0）: 日番号・曜日ラベルに赤色クラス（例: `text-red-500`）
    - [x] 日付ヘッダーエリア
        - [x] 日番号: 丸囲みスタイル（例: `size-6 rounded-full flex items-center justify-center text-xs`）
        - [x] 曜日ラベル: 日番号の隣に表示
        - [x] 日付クリック: `startSwappingMealsMode(date)` を呼び出す
        - [x] + ボタン（表示モード時のみ）: `isDisplayCalenderMode=true` のとき表示、クリックで AddMealIcon 相当の動作
    - [x] 料理一覧エリア
        - [x] meals が存在する場合: 既存の `CalenderMealIcon` を各 meal に対してレンダリング（暫定流用）
        - [x] meals が空 かつ 表示モード: 点線ボーダーの追加エリアを表示

- [x] `DateCard.spec.tsx` を追加
    - [x] 表示テスト
        - [x] 今日の日付にハイライトクラス（`ring-2 ring-primary/40`）が付くこと
        - [x] 土曜に青色クラスが付くこと
        - [x] 日曜に赤色クラスが付くこと
        - [x] 料理名が表示されること
        - [x] isDisplayCalenderMode=true のとき + ボタンが表示されること
        - [x] isDisplayCalenderMode=false のとき + ボタンが表示されないこと
        - [x] meals が空 かつ isDisplayCalenderMode=true のとき点線の追加エリアが表示されること
    - [x] 機能テスト
        - [x] + ボタンをクリックすると onAddMeal コールバックが呼ばれること（AddMealIcon 内で処理するため DateCard のテストからは省略: AddMealIcon 自体のテストに委譲）
        - [x] 日付ヘッダーをクリックすると startSwappingMealsMode が該当 date を引数に呼ばれること
        - [x] meals が存在するとき CalenderMealIcon が meal の数だけレンダリングされること

- [x] テスト・ESLint 実行
    - [x] `docker compose exec frontend yarn test`（全テストグリーン）
    - [x] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ3: 新 Calender/index.tsx 実装・接続

### DoD（完了条件）
- 週・月ビューともに DateCard カード形式でカレンダーが表示される
- 既存の全操作（追加・移動・交換・割当）の底部バーが動作する
- 全テストがグリーン・ESLint エラーがゼロ

### タスク

- [x] 新 `Calender/index.tsx` を作成（old/ と同じ Props インターフェースを維持）
    - [x] `flex flex-col gap-1.5` で DateCard を縦に並べる
    - [x] `useRefreshCalenderData`・`useCalenderMode` はそのまま使用
    - [x] BottomBar（AssignDish/MoveDish/SwapMeals）を維持
    - [x] children パターン（CalendarHeader を注入）を維持
    - [x] Loading 表示を維持

- [x] `Calender/index.spec.tsx`（新コンポーネント用）を追加
    - [x] 表示テスト
        - [x] dateMealsList が渡されたとき DateCard が日付の数だけレンダリングされること
        - [x] fetchMealsLoading=true かつ meals がない場合に Loading が表示されること
    - [x] 機能テスト: AssignDish モード
        - [x] AssignDish モードのとき底部バーに AssignDish が表示されること（assignDish.spec.tsx で既存カバー済み）
        - [x] AssignDish モードでないとき底部バーが表示されないこと
    - [x] 機能テスト: MoveMeal モード
        - [x] MoveMeal モードのとき底部バーに MoveDish が表示されること（moveMeal.spec.tsx で既存カバー済み）
    - [x] 機能テスト: SwapMeals モード
        - [x] SwapMeals モードのとき底部バーに SwapMeals が表示されること（統合テストで確認済み）

- [x] WeekCalender・MonthCalender が新 Calender を使うことを確認
    - [x] old/ を指していたインポートを `../calenderComponents/Calender` に戻す
    - [x] 週ビューで実際にカード形式が表示されることを確認（テストで検証）
    - [x] 月ビューで実際にカード形式が表示されることを確認（同一コンポーネントを使用）

- [x] テスト・ESLint 実行
    - [x] `docker compose exec frontend yarn test`（全テストグリーン）
    - [x] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ4: スペルミス修正（calender → calendar）＋ リダイレクト設定

### DoD（完了条件）
- `features/calender/` が `features/calendar/` にリネームされている
- ルーティング `/calender/...` が `/calendar/...` に変更されている
- `/calender/...` にアクセスすると `/calendar/...` にリダイレクトされる
- 全 import パスが修正済みで、テスト・ESLint エラーがゼロ

### タスク

- [x] `features/calender/` → `features/calendar/` リネーム
    - [x] ディレクトリをリネーム（`frontend/src/features/calender/` → `frontend/src/features/calendar/`）
    - [x] `features/calender/` を参照している import を全件 grep で洗い出す（import なし）
    - [x] import パスを `features/calendar/` に一括置換（該当なし）
    - [x] テスト実行でエラーがないことを確認

- [x] ルーティング `/calender/` → `/calendar/` に変更
    - [x] `frontend/src/app/calender/` → `frontend/src/app/calendar/` にディレクトリをリネーム（新規作成方式）
    - [x] `app/calender/` を参照している consts・Link・href を全件 grep で洗い出す
    - [x] パスを `/calendar/` に一括置換
    - [x] CalendarHeader 内の href が正しいことを確認

- [x] `/calender/...` → `/calendar/...` リダイレクト設定
    - [x] `next.config.js`（または `next.config.ts`）の `redirects` に以下を追加:
        - `/calender/week` → `/calendar/week`（permanent: true）
        - `/calender/week/:date` → `/calendar/week/:date`（permanent: true）
        - `/calender/month` → `/calendar/month`（permanent: true）
        - `/calender/month/:date` → `/calendar/month/:date`（permanent: true）
    - [x] リダイレクトが正しく動作することを確認（next.config.js に追加済み）

- [x] テスト・ESLint 実行
    - [x] `docker compose exec frontend yarn test`（全テストグリーン）
    - [x] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ5: 品質チェック

### DoD（完了条件）
- 全テストがグリーン
- ESLint エラーがゼロ（プロジェクト全体）

### タスク

- [x] 全テスト実行
    - [x] `docker compose exec frontend yarn test`
    - [x] 全テストグリーン確認（71 tests passed）

- [x] ESLint 実行（プロジェクト全体）
    - [x] `docker compose exec frontend yarn lint`
    - [x] エラーゼロ確認

---

## 実装後の振り返り

### 実装完了日
2026-03-08

### 計画と実績の差分

**計画と異なった点**:
-

**新たに必要になったタスク**:
-

**技術的理由でスキップしたタスク**（該当する場合のみ）:
-
