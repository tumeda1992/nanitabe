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

- [ ] `Calender/index.tsx` を `Calender/old/index.tsx` に移動
    - [ ] `frontend/src/components/calender/calenderComponents/Calender/old/` ディレクトリを作成
    - [ ] `Calender/index.tsx` → `Calender/old/index.tsx` に移動
    - [ ] `Calender/index.module.scss` → `Calender/old/index.module.scss` に移動（存在する場合）

- [ ] WeekCalender・MonthCalender のインポートパスを修正
    - [ ] `WeekCalender/index.tsx`: `../calenderComponents/Calender` → `../calenderComponents/Calender/old`
    - [ ] `MonthCalender/index.tsx`: 同上
    - [ ] 他に `Calender/index.tsx` を参照している箇所を grep で確認し修正

- [ ] テスト・ESLint 実行で動作確認
    - [ ] `docker compose exec frontend yarn test`（全テストグリーン）
    - [ ] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ2: DateCard コンポーネント実装

### DoD（完了条件）
- `DateCard.tsx` が単体でレンダリングでき、表示・機能テストが全てグリーン

### タスク

- [ ] `DateCard.tsx` を新規作成（`calenderComponents/DateCard.tsx`）
    - [ ] Props 定義
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
    - [ ] カードラッパー: `rounded-xl border bg-card px-2.5 py-1.5`
    - [ ] 今日ハイライト: `isSameDay(date, new Date())` のとき `ring-2 ring-primary/40` を追加
    - [ ] 土曜（getDay=6）: 日番号・曜日ラベルに青色クラス（例: `text-blue-500`）
    - [ ] 日曜（getDay=0）: 日番号・曜日ラベルに赤色クラス（例: `text-red-500`）
    - [ ] 日付ヘッダーエリア
        - [ ] 日番号: 丸囲みスタイル（例: `size-6 rounded-full flex items-center justify-center text-xs`）
        - [ ] 曜日ラベル: 日番号の隣に表示
        - [ ] 日付クリック: `startSwappingMealsMode(date)` を呼び出す
        - [ ] + ボタン（表示モード時のみ）: `isDisplayCalenderMode=true` のとき表示、クリックで AddMealIcon 相当の動作
    - [ ] 料理一覧エリア
        - [ ] meals が存在する場合: 既存の `CalenderMealIcon` を各 meal に対してレンダリング（暫定流用）
        - [ ] meals が空 かつ 表示モード: 点線ボーダーの追加エリアを表示

- [ ] `DateCard.spec.tsx` を追加
    - [ ] 表示テスト
        - [ ] 今日の日付にハイライトクラス（`ring-2 ring-primary/40`）が付くこと
        - [ ] 土曜に青色クラスが付くこと
        - [ ] 日曜に赤色クラスが付くこと
        - [ ] 料理名が表示されること
        - [ ] isDisplayCalenderMode=true のとき + ボタンが表示されること
        - [ ] isDisplayCalenderMode=false のとき + ボタンが表示されないこと
        - [ ] meals が空 かつ isDisplayCalenderMode=true のとき点線の追加エリアが表示されること
    - [ ] 機能テスト
        - [ ] + ボタンをクリックすると onAddMeal コールバックが呼ばれること
        - [ ] 日付ヘッダーをクリックすると startSwappingMealsMode が該当 date を引数に呼ばれること
        - [ ] meals が存在するとき CalenderMealIcon が meal の数だけレンダリングされること

- [ ] テスト・ESLint 実行
    - [ ] `docker compose exec frontend yarn test`（全テストグリーン）
    - [ ] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ3: 新 Calender/index.tsx 実装・接続

### DoD（完了条件）
- 週・月ビューともに DateCard カード形式でカレンダーが表示される
- 既存の全操作（追加・移動・交換・割当）の底部バーが動作する
- 全テストがグリーン・ESLint エラーがゼロ

### タスク

- [ ] 新 `Calender/index.tsx` を作成（old/ と同じ Props インターフェースを維持）
    - [ ] `flex flex-col gap-1.5` で DateCard を縦に並べる
    - [ ] `useRefreshCalenderData`・`useCalenderMode` はそのまま使用
    - [ ] BottomBar（AssignDish/MoveDish/SwapMeals）を維持
    - [ ] children パターン（CalendarHeader を注入）を維持
    - [ ] Loading 表示を維持

- [ ] `Calender/index.spec.tsx`（新コンポーネント用）を追加
    - [ ] 表示テスト
        - [ ] dateMealsList が渡されたとき DateCard が日付の数だけレンダリングされること
        - [ ] fetchMealsLoading=true かつ meals がない場合に Loading が表示されること
    - [ ] 機能テスト: AssignDish モード
        - [ ] AssignDish モードのとき底部バーに AssignDish が表示されること
        - [ ] AssignDish モードでないとき底部バーが表示されないこと
    - [ ] 機能テスト: MoveMeal モード
        - [ ] MoveMeal モードのとき底部バーに MoveDish が表示されること
    - [ ] 機能テスト: SwapMeals モード
        - [ ] SwapMeals モードのとき底部バーに SwapMeals が表示されること

- [ ] WeekCalender・MonthCalender が新 Calender を使うことを確認
    - [ ] old/ を指していたインポートを `../calenderComponents/Calender` に戻す
    - [ ] 週ビューで実際にカード形式が表示されることを確認（目視）
    - [ ] 月ビューで実際にカード形式が表示されることを確認（目視）

- [ ] テスト・ESLint 実行
    - [ ] `docker compose exec frontend yarn test`（全テストグリーン）
    - [ ] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ4: スペルミス修正（calender → calendar）＋ リダイレクト設定

### DoD（完了条件）
- `features/calender/` が `features/calendar/` にリネームされている
- ルーティング `/calender/...` が `/calendar/...` に変更されている
- `/calender/...` にアクセスすると `/calendar/...` にリダイレクトされる
- 全 import パスが修正済みで、テスト・ESLint エラーがゼロ

### タスク

- [ ] `features/calender/` → `features/calendar/` リネーム
    - [ ] ディレクトリをリネーム（`frontend/src/features/calender/` → `frontend/src/features/calendar/`）
    - [ ] `features/calender/` を参照している import を全件 grep で洗い出す
    - [ ] import パスを `features/calendar/` に一括置換
    - [ ] テスト実行でエラーがないことを確認

- [ ] ルーティング `/calender/` → `/calendar/` に変更
    - [ ] `frontend/src/app/calender/` → `frontend/src/app/calendar/` にディレクトリをリネーム
    - [ ] `app/calender/` を参照している consts・Link・href を全件 grep で洗い出す
    - [ ] パスを `/calendar/` に一括置換
    - [ ] CalendarHeader 内の href が正しいことを確認

- [ ] `/calender/...` → `/calendar/...` リダイレクト設定
    - [ ] `next.config.js`（または `next.config.ts`）の `redirects` に以下を追加:
        - `/calender/week` → `/calendar/week`（permanent: true）
        - `/calender/week/:date` → `/calendar/week/:date`（permanent: true）
        - `/calender/month` → `/calendar/month`（permanent: true）
        - `/calender/month/:date` → `/calendar/month/:date`（permanent: true）
    - [ ] リダイレクトが正しく動作することを確認（目視）

- [ ] テスト・ESLint 実行
    - [ ] `docker compose exec frontend yarn test`（全テストグリーン）
    - [ ] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ5: 品質チェック

### DoD（完了条件）
- 全テストがグリーン
- ESLint エラーがゼロ（プロジェクト全体）

### タスク

- [ ] 全テスト実行
    - [ ] `docker compose exec frontend yarn test`
    - [ ] 全テストグリーン確認

- [ ] ESLint 実行（プロジェクト全体）
    - [ ] `docker compose exec frontend yarn lint`
    - [ ] エラーがあれば `yarn lint --fix` で自動修正してから再確認
    - [ ] エラーゼロ確認

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
