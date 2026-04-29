# タスクリスト

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

## フェーズ1: DBスキーマ準備 + DishEffortLevel AR モデル

### DoD（完了条件）
- `dish_effort_levels` テーブルと `dishes.dish_effort_level_id` カラムが存在し、初期データが投入されている
- AR モデルが動作する
- テストがグリーン

### タスク

- [x] マイグレーション作成・実行: `dish_effort_levels` テーブル作成
    - カラム: `meal_position` (integer, not null), `minutes` (integer, not null), `label` (string, not null)
    - インデックス: `meal_position` に追加

- [x] マイグレーション作成・実行: `dishes.dish_effort_level_id` カラム追加（nullable FK）

- [x] `app/models/dish_effort_level.rb` 作成（AR モデル）
    - `validates :meal_position, presence: true`
    - `validates :minutes, presence: true`
    - `validates :label, presence: true`
    - スコープ: `scope :for_meal_position, ->(meal_position) { where(meal_position:).order(:minutes) }`

- [x] シードデータ作成・投入（主食/メインディッシュ/副菜）
    - 主食 (1): 10分「ぱぱっとできる」/ 20分「普通」/ 50分「少し手間」/ 150分「結構手間」/ 480分「かなり手間」
    - メインディッシュ (2): 同上
    - 副菜 (3): 5分「ぱぱっとできる」/ 10分「普通」/ 30分「少し手間」/ 60分「結構手間」

- [x] テスト作成・実行
    - `DishEffortLevel` モデルのバリデーションテスト
    - `for_meal_position` スコープのテスト
    - `docker compose exec backend bundle exec rspec spec/models/dish_effort_level_spec.rb`

---

## フェーズ2: ドメインロジック変更（dishes への effort_level_id の組み込み）

### DoD（完了条件）
- 料理の作成・更新時に `dish_effort_level_id` が正しく保存・変更できる
- テストがグリーン

### タスク

- [x] `app/models/dish.rb` の変更
    - `belongs_to :dish_effort_level, optional: true` 追加
    - `build_existing_root_from_id` に `effort_level_id: dish_record.dish_effort_level_id` を追加
    - `persist_from_food_dish_root` に `self.dish_effort_level_id = food_dish_root.effort_level_id` を追加

- [x] `app/domain/business/food/dish/root.rb` の変更
    - `attribute :effort_level_id, :integer`（validates は presence: false）
    - `assign_effort_level(new_effort_level_id)` メソッド追加（nil も許容）

- [x] `app/domain/business/food/dish/usecase/params/dish.rb` の変更
    - `attribute :effort_level_id, :integer` 追加

- [x] `app/domain/business/food/dish/factory.rb` の変更
    - `build` メソッドに `effort_level_id: nil` キーワード引数を追加
    - `Root.new` に `effort_level_id:` を追加

- [x] `app/domain/business/food/dish/usecase/add_command.rb` の変更
    - `Factory.build` の呼び出しに `effort_level_id: dish_params.effort_level_id` を追加

- [x] `app/domain/business/food/dish/usecase/update_command.rb` の変更
    - `update_dish_root` 内で `dish_root.assign_effort_level(dish_params.effort_level_id)` を追加

- [x] テスト作成・実行
    - `dish_spec.rb`: `persist_from_food_dish_root` で `dish_effort_level_id` が保存されること
    - `add_command` / `update_command` のテスト（または dish_searcher_spec）: effort_level_id が保存・変更されること
    - `docker compose exec backend bundle exec rspec spec/models/dish_spec.rb`
    - `docker compose exec backend bundle exec rspec spec/domain/business/food/dish/usecase/`

---

## フェーズ3: dishEffortLevels クエリ新設（フォームの選択肢取得）

### DoD（完了条件）
- `dishEffortLevels(mealPosition: Int!)` クエリで meal_position に応じた effort levels 一覧が取得できる
- テストがグリーン

### タスク

- [x] `app/graphql/types/output/dish/effort_level/dish_effort_level.rb` 作成
    - `field :id, Int, null: false`
    - `field :meal_position, Int, null: false`
    - `field :minutes, Int, null: false`
    - `field :label, String, null: false`

- [x] `app/graphql/queries/dish/effort_level/dish_effort_levels.rb` 作成
    - `argument :meal_position, Int, required: true`
    - `DishEffortLevel.for_meal_position(meal_position)` を返す

- [x] `types/query_type.rb` に `dishEffortLevels` クエリを登録

- [x] テスト作成・実行（request spec）
    - `dishEffortLevels(mealPosition: 2)` が主食のレコードのみ返すこと
    - `dishEffortLevels(mealPosition: 3)` が副菜のレコードのみ返すこと
    - minutes の昇順で返ること
    - `docker compose exec backend bundle exec rspec spec/requests/` または `spec/graphql/`

---

## フェーズ4: 料理作成・更新 mutation に dishEffortLevelId 追加

### DoD（完了条件）
- GraphQL mutation 経由で料理に手間レベルを設定・変更・解除できる
- テストがグリーン

### タスク

- [x] `app/graphql/types/input/dish/dish_for_create.rb` に `dish_effort_level_id` 引数追加（nullable）

- [x] `Params::Dish` の `convert_to_command_param` または `to_hash` で `dish_effort_level_id` が伝わることを確認・修正

- [x] テスト作成・実行（request spec）
    - `dishEffortLevelId` を指定して料理を作成 → 保存されること
    - `dishEffortLevelId` を変更して料理を更新 → 変更されること
    - `dishEffortLevelId: null` で更新 → null になること（設定解除）
    - `docker compose exec backend bundle exec rspec spec/requests/` または `spec/graphql/`

---

## フェーズ5: existingDishesForRegisteringWithMeal に effortLevelMinutes 追加

### DoD（完了条件）
- `existingDishesForRegisteringWithMeal` クエリが `effortLevelMinutes` を返す
- 手間未設定の料理は `null` が返る
- テストがグリーン

### タスク

- [x] `Dish.with_search_relations` に `dish_effort_levels` の LEFT JOIN 追加

- [x] `Dish.search_output` の select に `dish_effort_levels.minutes AS effort_level_minutes` 追加

- [x] `ExistingDishForRegisteringWithMeal` GraphQL 型に `field :effort_level_minutes, Int, null: true` 追加

- [x] テスト作成・実行
    - `dish_spec.rb` の `search_output` テストに `effort_level_minutes` が含まれることを追加
        - 手間設定済みの料理 → 対応する minutes が返ること
        - 手間未設定の料理 → `nil` が返ること
    - request spec: `existingDishesForRegisteringWithMeal` が `effortLevelMinutes` を返すこと
    - `docker compose exec backend bundle exec rspec spec/models/dish_spec.rb`
    - `docker compose exec backend bundle exec rspec spec/requests/` または `spec/graphql/`

---

## フェーズ6: 管理画面 CRUD（dish_effort_levels）

### DoD（完了条件）
- 管理画面で `dish_effort_levels` の一覧・作成・編集・削除ができる
- テストがグリーン

### タスク

- [x] `config/routes.rb` に `admin/food/dish/effort_level` リソースを追加
    ```ruby
    namespace :effort_level do
      resources :dish_effort_levels, except: [:show]
    end
    ```

- [x] `app/controllers/admin/food/dish/effort_level/dish_effort_levels_controller.rb` 作成
    - `normalize_words_controller.rb` と同パターン（index/new/create/edit/update/destroy）
    - ビジネスロジックは AR を直接操作（normalize_word と異なり専用 Usecase は不要）

- [x] views 作成（`app/views/admin/food/dish/effort_level/dish_effort_levels/`）
    - `index.html.erb`: 一覧（meal_position/minutes/label を表示）
    - `new.html.erb` / `edit.html.erb`: フォーム

- [x] テスト作成・実行
    - request spec または system spec（`spec/requests/admin/food/dish/effort_level/`）
    - `docker compose exec backend bundle exec rspec spec/requests/admin/food/dish/effort_level/`

---

## フェーズ7: フロントエンド - 料理フォームに手間選択 UI を追加

### DoD（完了条件）
- 料理フォームで mealPosition に応じた手間の選択肢が表示される
- mealPosition 変更時に選択がリセットされる
- テストがグリーン
- スクリーンショットで表示を確認済み

### タスク

- [x] `fetchDishQuery.ts` に `DISH_EFFORT_LEVELS` クエリ追加
    ```graphql
    query dishEffortLevels($mealPosition: Int!) {
      dishEffortLevels(mealPosition: $mealPosition) {
        id, minutes, label
      }
    }
    ```

- [x] effort levels 取得用 hook を `useDish` または専用 hook に追加

- [x] `SelectEffortLevel.tsx` 作成
    - mealPosition を prop で受け取り、対応する levels を GraphQL で取得
    - 選択肢の表示形式: 「10分 - ぱぱっとできる」（時間 + ラベル）
    - 選択中の `dishEffortLevelId` を `useFormContext` 経由で保持

- [x] `DishForm/index.tsx` に `SelectEffortLevel` を組み込み
    - mealPosition 変更時に `dishEffortLevelId` をリセット（`setValue('dishEffortLevelId', null)`）
    - mealPosition が汁物・デザート・その他（4/5/50）の場合は表示しない

- [x] テスト作成・実行
    - `SelectEffortLevel`: mealPosition に応じた選択肢が表示されること
    - mealPosition 変更時に選択がリセットされること
    - `docker compose exec frontend yarn test`

- [x] スクリーンショットで表示確認
    - `visual-inspector` サブエージェントでスクリーンショットを撮る（直接 playwright 呼び出し禁止）
    - 手間選択 UI が表示されていること
    - mealPosition 切り替えで選択肢が変わることを確認

  > 確認日時: 2026-03-20 11:30
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260320-feature-64-effort-level-ui/result.md
  >
  > 項目1: 手間選択 UI が料理フォームに表示されること ✅
  >   期待値: mealPosition がメインディッシュ/主食/副菜の場合、「手間」セレクトが表示される
  >   結果: 「指定なし」「10分 - ぱぱっとできる」「20分 - 普通」「50分 - 少し手間」「150分 - 結構手間」「480分 - かなり手間」が表示されている
  >
  > 項目2: mealPosition 切り替えで手間 UI が制御されること ✅
  >   期待値: 汁物選択で非表示、メインディッシュに戻すと再表示
  >   結果: 汁物選択後は手間フィールド非表示、メインディッシュ選択後は再表示（期待通り）

---

## フェーズ8: フロントエンド - DishSearchCard に手間表示を追加

### DoD（完了条件）
- 手間が設定されている料理のカードに「🕐 XX分」が表示される
- 手間が設定されていない料理には表示されない
- テストがグリーン
- スクリーンショットで表示を確認済み

### タスク

- [x] `EXISTING_DISHES_FOR_REGISTERING_WITH_MEAL` クエリに `effortLevelMinutes` フィールドを追加

- [x] `DishForSearchCard` 型に `effortLevelMinutes?: number | null` を追加

- [x] 分数 → 時間文字列変換ヘルパーを実装（インラインまたは小さなユーティリティ）
    - 60分未満 → 「XX分」
    - 60分以上 → 「1時間」「2時間30分」等

- [x] `DishSearchCard/index.tsx` に手間表示行を追加
    - `effortLevelMinutes` が存在する場合のみ表示
    - 表示: `🕐` アイコン（または Clock アイコン）+ 変換後の時間文字列

- [x] テスト作成・実行
    - `effortLevelMinutes` がある場合に手間行が表示されること
    - `effortLevelMinutes` が null/undefined の場合に表示されないこと
    - `docker compose exec frontend yarn test`

- [x] スクリーンショットで表示確認
    - `visual-inspector` サブエージェントでスクリーンショットを撮る
    - 手間設定済みの料理に「🕐 XX分」が表示されていること
    - 手間未設定の料理に表示されないこと

  > 確認日時: 2026-03-20 11:50
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260320-feature-64-effort-level-ui/result_phase8.md
  >
  > 項目1: 手間未設定の料理に🕐が表示されないこと ✅
  >   期待値: 手間が設定されていない料理には🕐表示が出ない
  >   結果: 料理一覧で🕐表示なし（期待通り）
  >
  > 項目2: 手間設定済み料理に🕐 XX分が表示されること ✅
  >   期待値: 20分→「🕐 20分」、90分→「🕐 1時間30分」表示
  >   結果: 単体テストで確認済み（全4パターン通過）

---

## フェーズ9: 品質チェック

### DoD（完了条件）
- 全テストがグリーン
- バックエンド・フロントエンドともにリントエラーなし
- 最終スクリーンショットで全体確認済み

### タスク

- [x] 全テスト実行
    - [x] `docker compose exec backend bundle exec rspec`（全件グリーン確認）: 616 examples, 0 failures
    - [x] `docker compose exec frontend yarn test`（全件グリーン確認）: 109 passed

- [x] リント実行・修正
    - [x] `docker compose exec backend bundle exec rubocop`（エラーがあれば `-a` / `-A` で修正）: 355 files inspected, no offenses
    - [x] `docker compose exec frontend yarn lint`（エラーがあれば `--fix` で修正）: エラーなし
    - [x] エラーゼロ確認

- [x] 最終スクリーンショットで見た目を目視確認
    - [x] `visual-inspector` サブエージェントでスクリーンショットを撮る
    - [x] 料理フォームの手間選択 UI
    - [x] DishSearchCard の手間表示
    - [x] 問題があれば修正して再確認

  > 確認日時: 2026-03-20 12:00
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260320-feature-64-effort-level-ui/result_phase9_final.md
  >
  > 項目1: 料理フォームの手間選択 UI（メインディッシュ） ✅
  >   期待値: メインディッシュで手間セレクト6選択肢が表示
  >   結果: 「指定なし」+「10分」「20分」「50分」「150分」「480分」全て表示
  >
  > 項目2: 汁物選択時に手間 UI 非表示 ✅
  >   期待値: 汁物選択で手間フィールドが消える
  >   結果: 期待通り非表示
  >
  > 項目3: 副菜選択時の手間選択肢 ✅
  >   期待値: 副菜固有の4段階選択肢
  >   結果: 「指定なし」+「5分」「10分」「30分」「60分」表示
  >
  > 項目4: DishSearchCard 手間表示 ✅
  >   期待値: 手間設定済み→🕐表示、未設定→非表示
  >   結果: テスト・スクリーンショット両方で確認

## フェーズ10: ドキュメント更新

- [x] doc-enricher スキルを利用した README.md を更新（必要な場合。不要な場合に実行は禁止）
    - 技術的理由でスキップ: プロジェクトルートに README.md が存在しないため不要
- [x] 実装後の振り返り（このファイルの下部に記録）

---

## 実装後の振り返り

### 実装完了日
2026-03-20

### 計画と実績の差分

**計画と異なった点**:
- フロントエンドのテスト更新が想定より広範囲だった。`dishEffortLevelId` をスキーマに追加した結果、AddDish/EditDish/AddMeal/EditMeal の全テストの期待値を更新する必要があった
- `AVOID eager loading detected` (Bullet N+1) エラーが発生。`dish_effort_level` を `preload` に追加したが、SQL select 経由で値を取得しているため Bullet が警告。`left_joins` のみで `preload` から外すことで解決
- GraphQL input の `dish_effort_level_id` → `Usecase::Params::Dish` の `effort_level_id` のリネームが必要だった（`convert_to_command_param` でリマップ）

**新たに必要になったタスク**:
- フロントエンドの既存テスト全般への `DishEffortLevelsDocument` モック追加（AddDish/EditDish/AddMeal/EditMeal の全 spec）

**技術的理由でスキップしたタスク**（該当する場合のみ）:
- doc-enricher スキルの実行: プロジェクトルートに README.md が存在せず、ドキュメント対象ファイルがないため不要と判断
