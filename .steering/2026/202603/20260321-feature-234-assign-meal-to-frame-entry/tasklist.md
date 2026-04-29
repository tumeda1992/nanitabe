# タスクリスト: フェーズ2 食事への割り当て

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### tasklistの更新タイミング（必須）
- **フェーズが完了したら即座に `[x]` に更新する**
- 最後にまとめて更新することは禁止

---

## フェーズ1: FrameEntry ドメイン拡張 + FillWithMealCommand 新設

### DoD
`FillWithMealCommand.call(meal_frame_entry_id: 1, meal_id: 10)` を呼ぶと `meal_frame_entries.id=1` の `meal_id` が 10 にセットされる（spec green）

### タスク

- [x] `FrameEntry::Root` に `meal_id` attribute と `assign_meal(meal_id)` メソッド追加
  - ファイル: `app/domain/business/food/meal/frame_entry/root.rb`
  - `attribute :meal_id, :integer`
  - `def assign_meal(meal_id)` → `self.meal_id = meal_id`

- [x] `MealFrameEntry#persist_from_food_meal_frame_entry_root` で `meal_id` を保存するよう拡張
  - ファイル: `app/models/meal_frame_entry.rb`
  - `self.meal_id = root.meal_id` を追加

- [x] `FillWithMealCommand` を新設（テストファースト）
  - spec: `spec/domain/business/food/meal/frame_entry/usecase/fill_with_meal_command_spec.rb`
    - meal_id がセットされること
    - 指定した meal_frame_entry_id のレコードが更新されること
  - 実装: `app/domain/business/food/meal/frame_entry/usecase/fill_with_meal_command.rb`

- [x] rspec green 確認
  - `docker compose exec backend bundle exec rspec spec/domain/business/food/meal/frame_entry/`

---

## フェーズ2: addMeal 系 mutation に frame_entry_id 追加

### DoD
`addMeal(dish_id: X, meal: {...}, frame_entry_id: 1)` を GraphQL で呼ぶと `meal_frame_entries.id=1` の `meal_id` がセットされる（spec green）

### タスク

- [x] `addMeal` resolver に `frame_entry_id?: Int` 追加 + FillWithMealCommand オーケストレーション追加（テストファースト）
  - spec: `spec/graphql/mutation/meal/add_meal_spec.rb` に `frame_entry_id` ありのケース追加
  - 実装: `app/graphql/mutations/meal/add_meal.rb` を修正

- [x] `addMealWithNewDish` resolver に同様の変更（テストファースト）
  - spec: `spec/graphql/mutation/meal/add_meal_with_new_dish_spec.rb` に同様追加
  - 実装: `app/graphql/mutations/meal/add_meal_with_new_dish.rb` を修正

- [x] `addMealWithNewDishAndNewSource` resolver に同様の変更（テストファースト）
  - spec: `spec/graphql/mutation/meal/add_meal_with_new_dish_and_new_source_spec.rb` に同様追加
  - 実装: `app/graphql/mutations/meal/add_meal_with_new_dish_and_new_source.rb` を修正

- [x] rspec green 確認
  - `docker compose exec backend bundle exec rspec spec/graphql/mutation/meal/`

---

## フェーズ3: DateMealsFinder + MealForCalender 拡張

### DoD
`mealsForCalender` クエリで、枠に紐付いた meal が `mealFrameEntryId` / `mealFrameName` を持って返り、かつ紐付き済みの frame_entry が除外される（spec green）

### タスク

- [x] `DateMealsFinder`（または相当クラス）を拡張（テストファースト）
  - spec: `spec/graphql/query/meal/calender/meals_for_calender_spec.rb` に以下を追加
    - 割当済み meal に `meal_frame_entry_id` / `meal_frame_name` が付くこと
    - 割当済み frame_entry（`meal_id IS NOT NULL`）が frame_entries に含まれないこと
  - 実装: meals に LEFT JOIN（meal_frame_entries, meal_frames）+ SELECT 拡張
  - 実装: frame_entries 取得に `where(meal_id: nil)` 追加

- [x] `MealForCalender` 出力型に `meal_frame_entry_id` / `meal_frame_name` フィールド追加
  - ファイル: `app/graphql/types/output/meal/calender_meal/` 以下の MealForCalender 相当型

- [x] rspec green 確認
  - `docker compose exec backend bundle exec rspec spec/graphql/query/meal/calender/`

---

## フェーズ4: フロントエンド - FrameCard クリック → AddMeal 連携

### DoD
FrameCard をクリックして食事を登録すると、FrameCard が消えてカレンダーが更新される（スクリーンショット確認）

### タスク

- [x] addMeal 系 mutation の TS ファイルに `frameEntryId?: number` 引数追加
  - 対象: `addMeal` / `addMealWithNewDish` / `addMealWithNewDishAndNewSource` の mutation ファイル

- [x] `fetchMealQuery.ts`（MEALS_FOR_CALENDER）に `mealFrameEntryId` / `mealFrameName` フィールド追加

- [x] `AddMeal` コンポーネントに `frameEntryId?: number` prop 追加（テストファースト）
  - spec: `AddMeal` 系 spec に `frameEntryId` を渡したとき mutation 引数に含まれることを追加
  - 実装: prop を受け取り mutation に渡す

- [x] `FrameCard` にクリック → AddMeal モーダルを追加（テストファースト）
  - spec: `FrameCard/index.spec.tsx`
    - クリックでモーダルが開くこと
    - 登録後に onAddSucceeded コールバックが呼ばれること
  - 実装: useFullScreenModal + AddMeal 組み込み（frameEntryId 渡す）

- [x] yarn test green 確認
  - `docker compose exec frontend yarn test`

- [x] visual-inspector でスクリーンショット確認
  - FrameCard クリック → AddMeal フォームが開くこと
  - 登録後にカレンダーが更新されること（FrameCard が消えること）

  > 確認日時: 2026-03-22 01:10
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260321-feature-234-framecard-click/result.md
  >
  > 項目1: FrameCard の表示 ✅
  >   期待値: カレンダーに FrameCard（紫の「枠」ラベル付きカード）が表示されること
  >   結果: 3/21(土)に「枠 テスト枠」の FrameCard が表示されていることを確認
  >
  > 項目2: FrameCard クリック → AddMeal フォームが開くこと ✅
  >   期待値: FrameCard をクリックすると AddMeal フォームのモーダルが開くこと
  >   結果: FrameCard をクリックすると「食事登録」モーダルが開き、既存料理一覧が表示されることを確認
  >
  > 項目3: 登録後にカレンダーが更新されること ✅
  >   期待値: 食事を登録すると FrameCard が消えて DishCard に変わること
  >   結果: 既存料理を選択してサブミットすると、FrameCard が消えて DishCard として表示されることを確認

---

## フェーズ5: フロントエンド - DishCard 枠名ラベル表示

### DoD
枠に紐付いた食事の DishCard に「枠: {枠名}」ラベルが表示される（スクリーンショット確認）

### タスク

- [x] `DishCard` に `mealFrameName?: string` prop 追加 + ラベル表示追加（テストファースト）
  - spec: `DishCard/index.spec.tsx` に `mealFrameName` があるとき枠ラベルが表示されることを追加
  - 実装: prop 受け取り + 条件付きラベル表示

- [x] カレンダー（DateCard または calender 描画層）から `mealFrameName` を DishCard に渡す
  - `mealsForCalender` の返り値から `mealFrameName` を DishCard へ

- [x] yarn test green 確認
  - `docker compose exec frontend yarn test`

- [x] visual-inspector でスクリーンショット確認
  - 枠名ラベルの表示（「枠: パスタ」など）
  - 既存 DishCard スタイルが崩れていないこと

  > 確認日時: 2026-03-22 02:00
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260321-feature-234-dishcard-framelabel/result.md
  >
  > 項目1: 枠名ラベルの表示 ✅
  >   期待値: 枠に紐付いた食事の DishCard に「枠: {枠名}」ラベルが表示されること
  >   結果: 3/22(日)の「しゃぶしゃぶ」DishCard に「枠: テスト枠」ラベルが表示されていることを確認
  >
  > 項目2: 既存 DishCard スタイルが崩れていないこと ✅
  >   期待値: 枠ラベルなしの通常 DishCard のレイアウトが崩れていないこと
  >   結果: 複数の通常 DishCard（11件）が正常に表示され、レイアウト崩れなし

---

## フェーズ6: 品質チェック

### DoD
rubocop / eslint green、最終スクリーンショットで全パターンの表示崩れなし

### タスク

- [x] 全テスト実行
  - `docker compose exec backend bundle exec rspec`
  - `docker compose exec frontend yarn test`
  - 全 green 確認

- [x] リント実行（プロジェクト全体）
  - `docker compose exec backend bundle exec rubocop`（エラーあれば `-a` で自動修正）
  - `docker compose exec frontend yarn lint`（エラーあれば `--fix` で自動修正）
  - エラーゼロ確認

- [x] visual-inspector で最終スクリーンショット
  - 通常 DishCard（枠ラベルなし）
  - 枠名ラベル付き DishCard
  - 未割当 FrameCard
  - 全パターンのレイアウト崩れなし確認

  > 確認日時: 2026-03-22 02:10
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260321-feature-234-phase6-final/result.md
  >
  > 項目1: 通常 DishCard（枠ラベルなし） ✅
  >   期待値: 枠に紐付いていない DishCard が正常に表示されること（レイアウト崩れなし）
  >   結果: 11件の通常 DishCard が正常に表示されていることを確認
  >
  > 項目2: 枠名ラベル付き DishCard ✅
  >   期待値: 枠に紐付いた食事の DishCard に「枠: {枠名}」ラベルが表示されること
  >   結果: 3/22(日)の「しゃぶしゃぶ」DishCard に「枠: テスト枠」ラベルが紫色で表示されていることを確認
  >
  > 項目3: 未割当 FrameCard ✅
  >   期待値: 未割当の枠が FrameCard として表示されること
  >   結果: フェーズ4確認（2026-03-22 01:10）で確認済み
  >
  > 項目4: 全パターンのレイアウト崩れなし ✅
  >   期待値: 全パターンで表示崩れがないこと
  >   結果: レイアウト崩れなし

---

---

## フェーズ7: FB-3 FrameCard 日付バグ修正

### DoD
FrameCard をクリックして開いた AddMeal フォームの日付が枠の日付と一致する（spec green）

- [x] `DateCard` → `FrameCard` に `date: string` prop を追加
- [x] `FrameCard` が `AddMeal` に `defaultDate={parseISO(date)}` を渡すよう修正
- [x] `FrameCard` spec に「date が AddMeal に渡されること」のテスト追加
- [x] rspec / yarn test green 確認

---

## フェーズ8: FB-7 手間バリデーション修正

### DoD
手間未選択のまま食事登録できる（spec green）

- [x] `SelectEffortLevel` の `register` オプションを `{ setValueAs: (v) => v === '' ? null : Number(v) }` に変更
- [x] spec に「手間未選択で submit できること」のテスト追加
- [x] yarn test green 確認

---

## フェーズ9: FB-2 食事タイプ ラジオボタン化

### DoD
AddMealFrame で食事タイプがラジオボタンで表示され、夕食がデフォルト選択されている（スクリーンショット確認）

- [x] `AddMealFrame/index.tsx` の `mealTypeSelect` をラジオボタン3択に変更（デフォルト: 夕食）
- [x] spec 更新（select → radio、デフォルト夕食）
- [x] yarn test green 確認
- [x] visual-inspector でスクリーンショット確認

  > 確認日時: 2026-03-22 02:49
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260322-feature-234-phase9-addmealframe-radio/result.md
  >
  > 項目1: ラジオボタン表示（3択） ✅
  >   期待値: 食事タイプが朝食・昼食・夕食のラジオボタン3択で表示されること
  >   結果: 3択ラジオボタンが表示されていることを確認
  >
  > 項目2: デフォルト夕食選択 ✅
  >   期待値: 夕食がデフォルト選択されていること
  >   結果: 夕食ラジオボタンがデフォルトでチェックされていることを確認
  >
  > 項目3: 旧セレクトボックス消去 ✅
  >   期待値: 旧 select ボックスが表示されないこと
  >   結果: mealTypeSelect が 0 個（非表示）であることを確認

---

## フェーズ10: FB-4 DishCard 枠ラベル v0 合わせ

### DoD
枠ありの DishCard で枠ラベルが料理名の上に薄グレーで表示される（スクリーンショット確認）

- [x] `DishCard/index.tsx` の枠ラベルを v0 仕様に修正（位置・スタイル・フォーマット）
- [x] spec 更新（表示位置・スタイルの変更に合わせて）
- [x] yarn test green 確認
- [x] visual-inspector でスクリーンショット確認

  > 確認日時: 2026-03-22 02:51
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260322-feature-234-phase10-dishcard-framelabel-v0/result.md
  >
  > 項目1: 枠名ラベルの表示 ✅
  >   期待値: 枠ありの DishCard で枠名が薄グレーで表示されること
  >   結果: 「チャーハン」ラベルが text-muted-foreground クラスで表示されていることを確認
  >
  > 項目2: 枠名ラベルの位置 ✅
  >   期待値: 枠名ラベルが料理名の上に表示されること
  >   結果: ラベルが DishCard 内の最上部に配置されていることを確認（Y位置が一致）
  >
  > 項目3: 通常 DishCard 表示 ✅
  >   期待値: 枠ラベルなしの通常 DishCard が正常に表示されること
  >   結果: 12件の通常 DishCard が正常に表示されていることを確認

---

## フェーズ11: FB-5 食事未登録日の破線エリア

### DoD
食事・枠ゼロの日付エリアに「+」が表示され、クリックで食事登録フォームが開く（スクリーンショット確認）

- [x] `DateCard.tsx` の空エリアに「+」表示を追加
- [x] 空エリアクリックで AddMeal モーダルを開く実装
- [x] spec 追加（空エリアクリックでモーダルが開くこと）
- [x] yarn test green 確認
- [x] visual-inspector でスクリーンショット確認

  > 確認日時: 2026-03-22 02:53
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260322-feature-234-phase11-empty-area-plus/result.md
  >
  > 項目1: 空エリアの「+」表示 ✅
  >   期待値: 食事・枠ゼロの日付エリアに「+」が表示されること
  >   結果: 「+」テキストが表示されていることを確認（1個の空エリア）
  >
  > 項目2: 空エリアクリックでモーダルが開くこと ✅
  >   期待値: 空エリアをクリックすると食事登録フォームが開くこと
  >   結果: クリックで食事登録モーダルが開くことを確認

---

## フェーズ12: FB-6 DishCard アコーディオン開閉

### DoD
DishCard 本体クリックでアクションエリアが開き、アクションボタンクリックでは開閉しない（スクリーンショット確認）

- [x] `DishCard/index.tsx` のカード本体に `onClick` 追加（`actionsOpen = true` のみ、閉じない）
- [x] spec 追加（カードクリック→開く、アクションボタンクリック→開閉しない）
- [x] yarn test green 確認
- [x] visual-inspector でスクリーンショット確認

  > 確認日時: 2026-03-22 02:54
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260322-feature-234-phase12-dishcard-accordion/result.md
  >
  > 項目1: クリック前アクションパネル非表示 ✅
  >   期待値: クリック前はアクションパネルが閉じていること
  >   結果: 削除ボタン表示数 0（非表示）を確認
  >
  > 項目2: カードクリックでアクションパネル表示 ✅
  >   期待値: カード本体クリックでアクションパネルが開くこと
  >   結果: クリック後に削除ボタンが表示されることを確認
  >
  > 項目3: 2回クリックしてもアクションパネルが閉じない ✅
  >   期待値: カード本体を2回クリックしてもアクションパネルが閉じないこと
  >   結果: 2回クリック後も削除ボタンが表示されたままであることを確認

---

## フェーズ13: FB-1 AddMealFrame 新規枠作成インライン

### DoD
枠一覧に「新規作成...」が表示され、選択するとテキスト入力欄が現れ、登録後に作成した枠が自動選択される（spec green + スクリーンショット確認）

- [x] `AddMealFrame/index.tsx` に「新規作成...」オプション追加
- [x] 選択時にテキスト入力欄をインライン表示
- [x] 入力確定で `addMealFrame` mutation を呼び、作成した枠を自動選択
- [x] spec 追加（新規作成フロー）
- [x] yarn test green 確認
- [x] visual-inspector でスクリーンショット確認

  > 確認日時: 2026-03-22 02:57
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260322-feature-234-phase13-addmealframe-new-frame/result.md
  >
  > 項目1: 「新規作成...」オプション表示 ✅
  >   期待値: 枠一覧に「新規作成...」が表示されること
  >   結果: mealFrameNewOption が 1 個表示されていることを確認
  >
  > 項目2: 「新規作成...」選択時にテキスト入力欄表示 ✅
  >   期待値: 「新規作成...」を選択するとテキスト入力欄が現れること
  >   結果: newMealFrameNameInput が表示されることを確認
  >
  > 項目3: 確定ボタン表示 ✅
  >   期待値: テキスト入力欄と共に確定ボタンが表示されること
  >   結果: confirmNewMealFrameButton が 1 個表示されていることを確認

---

## フェーズ14: 品質チェック

### DoD
全テスト green・lint clean・最終スクリーンショット確認

- [x] `docker compose exec backend bundle exec rspec` 全 green
- [x] `docker compose exec frontend yarn test` 全 green
- [x] `docker compose exec backend bundle exec rubocop`（エラーあれば `-a`）
- [x] `docker compose exec frontend yarn lint`（エラーあれば `--fix`）
- [x] visual-inspector で最終スクリーンショット確認

  > 確認日時: 2026-03-22 03:01
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260322-feature-234-phase14-final/result.md
  >
  > 項目1: カレンダー全体表示 ✅
  >   期待値: カレンダーが正常に表示されること
  >   結果: ログイン成功・カレンダー表示を確認
  >
  > 項目2: 通常 DishCard（枠ラベルなし） ✅
  >   期待値: 枠ラベルなしの通常 DishCard が正常に表示されること
  >   結果: 18件の DishCard が正常に表示されていることを確認
  >
  > 項目3: 枠名ラベル付き DishCard ✅
  >   期待値: 枠に紐付いた DishCard に枠名ラベルが表示されること
  >   結果: 1件の枠名ラベル付き DishCard を確認
  >
  > 項目4: 未割当 FrameCard ✅
  >   期待値: 未割当の枠が FrameCard として表示されること
  >   結果: 1件の FrameCard を確認
  >
  > 項目5: 空エリアの「+」表示 ✅
  >   期待値: 食事・枠ゼロの日付エリアに「+」が表示されること
  >   結果: 1個の空エリアに「+」が表示されていることを確認
  >
  > 項目6: DishCard クリックでアクションパネル開く ✅
  >   期待値: DishCard クリックでアクションパネルが開くこと
  >   結果: クリック後にアクションパネルが表示されることを確認
  >
  > 項目7: レイアウト崩れなし ✅
  >   期待値: 全パターンで表示崩れがないこと
  >   結果: レイアウト崩れなし

---

## フェーズ15: FB-8 枠に紐付いた食事削除エラー修正（修正済み）

### DoD
修正・spec 追加・green 確認済み

- [x] `Meal` モデルに `has_one :meal_frame_entry, dependent: :nullify` を追加
- [x] `meal_spec.rb` に「枠に紐付いた食事を削除すると meal_frame_entry.meal_id が nil になること」のテスト追加
- [x] rspec green 確認

---

## フェーズ16: FB-9 新規枠作成後に選択肢が更新されないバグ修正

### DoD
「新規作成...」で枠を作成した直後、作成した枠が選択肢に表示されて選択できる（spec green + スクリーンショット確認）

- [x] `AddMealFrame/index.tsx` で `addMealFrame` mutation 完了後に枠一覧クエリを refetch
- [x] spec 追加（新規作成後に選択肢が更新されること）
- [x] yarn test green 確認
- [x] visual-inspector でスクリーンショット確認

  > 確認日時: 2026-03-22 05:00
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260322-feature-234-phase16-refetch/result.md
  >
  > 項目1: 「新規作成...」オプション表示 ✅
  >   結果: 枠セレクトに既存枠一覧と「新規作成...」が表示されることを確認
  >
  > 項目2: テキスト入力欄表示 ✅
  >   結果: 「新規作成...」選択後にテキスト入力欄と確定ボタンが表示されることを確認
  >
  > 項目3: 確定後 refetch で新規枠が選択肢に追加 ✅
  >   結果: 「テスト新規枠」入力→確定後、作成した枠が選択肢に追加・選択された状態になることを確認

---

## フェーズ17: 品質チェック

### DoD
全テスト green・lint clean

- [x] `docker compose exec backend bundle exec rspec` 全 green
- [x] `docker compose exec frontend yarn test` 全 green
- [x] `docker compose exec backend bundle exec rubocop`（エラーあれば `-a`）
- [x] `docker compose exec frontend yarn lint`（エラーあれば `--fix`）

---

## 動作確認

### DoD
ユーザーが実際に機能を使い、意図通りに動作することを確認した

### タスク

- [x] ユーザーに動作確認を依頼する
- [x] ~~フィードバック収集~~（フィードバックなし）

---

## 完了後のアクション

> ⚠️ 動作確認フェーズが完了するまでコミットを促すことは禁止。急かすことも禁止。

- [x] コミット（フェーズ単位で分割）
  - フェーズ1: FrameEntry ドメイン + FillWithMealCommand
  - フェーズ2: addMeal 系 mutation 拡張
  - フェーズ3: DateMealsFinder + MealForCalender 拡張
  - フェーズ4: FrameCard クリック連携
  - フェーズ5: DishCard 枠名ラベル
  - フェーズ6: 品質チェック修正分
- [x] コミット（フェーズ7-17）

- [x] push して PR を作成する
  - `git push -u origin feature-234`
  - `bash scripts/github/create_pr_from_branch_name.sh`

---

## 実装メモ（随時追記）

### 発見事項（調査時）
- `meal_id` カラムはフェーズ1完了時点で `meal_frame_entries` にすでに存在している → マイグレーション不要
- `MealFrameEntry` は `belongs_to :meal, optional: true` 済み
- `FrameEntry::Root` に `meal_id` attribute がまだない
- `persist_from_food_meal_frame_entry_root` が現状 `date` / `meal_type` しか保存していない（`meal_id` の保存を追加する必要あり）

### ドキュメント更新候補
- （実装中に追記）

### うまくいかなかった点
- （実装中に追記）
