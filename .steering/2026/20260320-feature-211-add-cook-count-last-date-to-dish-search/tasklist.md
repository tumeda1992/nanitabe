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
- 各タスク・サブタスクが終わったら、そのタイミングで更新する

---

## フェーズ1: バックエンド - 調理回数・最終調理日を GraphQL で返す

### DoD（完了条件）
- `with_search_relations` / `search_output` スコープに `last_cooked_date` が追加されている
- `ExistingDishForRegisteringWithMeal` GraphQL 型に `mealsCount`・`lastCookedDate` フィールドが追加されている
- 全テストがグリーン

### タスク

- [ ] `Dish.with_search_relations` スコープに `last_cooked_date` サブクエリ JOIN を追加
    - `Meal.select("dish_id, MAX(date) as last_cooked_date").group("dish_id")` を LEFT JOIN する
    - テーブル別名: `meal_last_dates`

- [ ] `Dish.search_output` スコープの select に `last_cooked_date` を追加
    - `select_clauses.push("meal_last_dates.last_cooked_date AS last_cooked_date")`

- [ ] `ExistingDishForRegisteringWithMeal` GraphQL 型にフィールドを追加
    - `field :meals_count, Integer, null: false`
    - `field :last_cooked_date, String, null: true`（ISO 日付文字列、食事未登録の場合 null）

- [ ] テスト作成・更新
    - [ ] `spec/models/dish_spec.rb`: `search_output` スコープに `last_cooked_date` が含まれることを確認するテストを追加
        - 食事割り当て済みの料理 → 最新の `meals.date` が返ること
        - 食事未割り当ての料理 → `nil` が返ること
    - [ ] `spec/domain/business/food/dish/usecase/dish_searcher_spec.rb`: `to_searched_values` の結果に `meals_count`・`last_cooked_date` が含まれることを確認するテストを追加

- [ ] テスト実行・グリーン確認
    - `docker compose exec backend bundle exec rspec spec/models/dish_spec.rb`
    - `docker compose exec backend bundle exec rspec spec/domain/business/food/dish/usecase/dish_searcher_spec.rb`

---

## フェーズ2: フロントエンド - DishSearchCard に調理回数・最終調理日を表示

### DoD（完了条件）
- `DishSearchCard` に3行目（最終調理日・調理回数）が表示されている
- 食事未登録の料理は「未調理」「0回」と表示される
- フロントテストがグリーン
- スクリーンショットで実際の見た目を確認済み

### タスク

- [ ] `fetchDishQuery.ts` の `EXISTING_DISHES_FOR_REGISTERING_WITH_MEAL` クエリに `mealsCount`・`lastCookedDate` を追加

- [ ] `DishForSearchCard` 型（`DishSearchCard/index.tsx`）に `mealsCount` と `lastCookedDate` を追加
    - `mealsCount?: number | null`
    - `lastCookedDate?: string | null`（ISO 日付文字列）

- [ ] `DishSearchCard/index.tsx` に3行目（最終調理日・調理回数）の表示を追加
    - CalendarDays アイコン + `lastCookedDate ? \`最終 ${M/D形式}\` : "未調理"`
    - ChefHat アイコン + `${mealsCount ?? 0}回`
    - `text-xs text-muted-foreground` スタイル（v0 デザイン準拠）
    - 日付フォーマット: ISO 文字列から `M/D` 形式への変換（ヘルパーでなくインライン）

- [ ] `DishSearchPanel/index.tsx` の受け渡し確認・修正
    - `dish as DishForSearchCard` キャストで渡しているため、GraphQL クエリが返すフィールドが自動的に含まれることを確認
    - 明示的な変更が不要であればスキップ

- [ ] `DishSearchCard` のテスト追加・更新
    - `mealsCount` と `lastCookedDate` を渡したとき、3行目に正しく表示されることを確認
    - `lastCookedDate: null` のとき「未調理」と表示されることを確認
    - `mealsCount: 0` のとき「0回」と表示されることを確認

- [ ] フロントテスト実行・グリーン確認
    - `docker compose exec frontend yarn test`

- [ ] スクリーンショットで実際の表示を確認
    - `visual-inspector` サブエージェントでスクリーンショットを撮る（直接 playwright 呼び出し禁止）
    - 3行目（CalendarDays アイコン + 最終調理日 / ChefHat アイコン + 調理回数）が表示されていることを確認
    - 未調理の料理に「未調理」が表示されていることを確認

---

## フェーズ3: 品質チェック

### DoD（完了条件）
- 全テストがグリーン
- バックエンド・フロントエンドともにリントエラーなし
- 最終スクリーンショットで全体デザインを確認済み

### タスク

- [ ] 全テスト実行
    - [ ] `docker compose exec backend bundle exec rspec`（全件グリーン確認）
    - [ ] `docker compose exec frontend yarn test`（全件グリーン確認）

- [ ] リント実行・修正
    - [ ] `docker compose exec backend bundle exec rubocop`（エラーがあれば `-a` / `-A` で修正）
    - [ ] `docker compose exec frontend yarn lint`（エラーがあれば `--fix` で修正）
    - [ ] エラーゼロ確認

- [ ] 最終スクリーンショットで見た目を目視確認
    - [ ] `visual-inspector` サブエージェントでスクリーンショットを撮る
    - [ ] カード全体のデザイン・レイアウトが意図通りか確認
    - [ ] 問題があれば修正して再確認

## フェーズ4: ドキュメント更新

- [ ] doc-enricher スキルを利用した README.md を更新（必要な場合。不要な場合に実行は禁止）
- [ ] 実装後の振り返り（このファイルの下部に記録）

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
