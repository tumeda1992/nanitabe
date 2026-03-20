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

- [x] `Dish.with_search_relations` スコープに `last_cooked_date` サブクエリ JOIN を追加
    - `Meal.select("dish_id, MAX(date) as last_cooked_date").group("dish_id")` を LEFT JOIN する
    - テーブル別名: `meal_last_dates`

- [x] `Dish.search_output` スコープの select に `last_cooked_date` を追加
    - `select_clauses.push("meal_last_dates.last_cooked_date AS last_cooked_date")`

- [x] `ExistingDishForRegisteringWithMeal` GraphQL 型にフィールドを追加
    - `field :meals_count, Integer, null: false`
    - `field :last_cooked_date, String, null: true`（ISO 日付文字列、食事未登録の場合 null）

- [x] テスト作成・更新
    - [x] `spec/models/dish_spec.rb`: `search_output` スコープに `last_cooked_date` が含まれることを確認するテストを追加
        - 食事割り当て済みの料理 → 最新の `meals.date` が返ること
        - 食事未割り当ての料理 → `nil` が返ること
    - [x] `spec/domain/business/food/dish/usecase/dish_searcher_spec.rb`: `to_searched_values` の結果に `meals_count`・`last_cooked_date` が含まれることを確認するテストを追加

- [x] テスト実行・グリーン確認
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

- [x] `fetchDishQuery.ts` の `EXISTING_DISHES_FOR_REGISTERING_WITH_MEAL` クエリに `mealsCount`・`lastCookedDate` を追加

- [x] `DishForSearchCard` 型（`DishSearchCard/index.tsx`）に `mealsCount` と `lastCookedDate` を追加
    - `mealsCount?: number | null`
    - `lastCookedDate?: string | null`（ISO 日付文字列）

- [x] `DishSearchCard/index.tsx` に3行目（最終調理日・調理回数）の表示を追加
    - CalendarDays アイコン + `lastCookedDate ? \`最終 ${M/D形式}\` : "未調理"`
    - ChefHat アイコン + `${mealsCount ?? 0}回`
    - `text-xs text-muted-foreground` スタイル（v0 デザイン準拠）
    - 日付フォーマット: ISO 文字列から `M/D` 形式への変換（ヘルパーでなくインライン）

- [x] `DishSearchPanel/index.tsx` の受け渡し確認・修正
    - `dish as DishForSearchCard` キャストで渡しているため、GraphQL クエリが返すフィールドが自動的に含まれることを確認
    - 明示的な変更が不要であればスキップ

- [x] `DishSearchCard` のテスト追加・更新
    - `mealsCount` と `lastCookedDate` を渡したとき、3行目に正しく表示されることを確認
    - `lastCookedDate: null` のとき「未調理」と表示されることを確認
    - `mealsCount: 0` のとき「0回」と表示されることを確認

- [x] フロントテスト実行・グリーン確認
    - `docker compose exec frontend yarn test`

- [x] スクリーンショットで実際の表示を確認
    - `visual-inspector` サブエージェントでスクリーンショットを撮る（直接 playwright 呼び出し禁止）
    - 3行目（CalendarDays アイコン + 最終調理日 / ChefHat アイコン + 調理回数）が表示されていることを確認
    - 未調理の料理に「未調理」が表示されていることを確認
  > 確認日時: 2026-03-20 13:58
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260320-feature-211-add-cook-count-last-date-to-dish-search/result.md
  >
  > 項目1: 料理カードに最終調理日・調理回数の3行目が表示されている ✅
  >   期待値: CalendarDays アイコン + 最終調理日 / ChefHat アイコン + 調理回数が表示される
  >   結果: 表示されている（例: 「最終 3/14 / 27回」「最終 11/14 / 5回」）
  >
  > 項目2: 調理済みの料理に「最終 X/X」と「N回」が表示されている ✅
  >   期待値: 「最終 X/X」（月/日形式）と「N回」が表示される
  >   結果: 「最終 3/14 27回」「最終 11/14 5回」等が正しく表示されている
  >
  > 項目3: 未調理の料理に「未調理」と「0回」が表示されている ✅
  >   期待値: 「未調理」と「0回」が表示される
  >   結果: 「切り干し大根の煮物」「ペペロンチーノ」等の未調理料理に「未調理 0回」が表示されている
  >
  > 項目4: 既存の1行目・2行目のレイアウトが壊れていない ✅
  >   期待値: 料理名（1行目）、レシピ元・評価（2行目）が正常に表示される
  >   結果: 既存のレイアウトは崩れておらず、3行目が追加されている

---

## フェーズ3: 品質チェック

### DoD（完了条件）
- 全テストがグリーン
- バックエンド・フロントエンドともにリントエラーなし
- 最終スクリーンショットで全体デザインを確認済み

### タスク

- [x] 全テスト実行
    - [x] `docker compose exec backend bundle exec rspec`（全件グリーン確認）: 585 examples, 0 failures
    - [x] `docker compose exec frontend yarn test`（全件グリーン確認）: 106 passed

- [x] リント実行・修正
    - [x] `docker compose exec backend bundle exec rubocop`（エラーがあれば `-a` / `-A` で修正）: no offenses
    - [x] `docker compose exec frontend yarn lint`（エラーがあれば `--fix` で修正）: no errors
    - [x] エラーゼロ確認

- [x] 最終スクリーンショットで見た目を目視確認
    - [x] `visual-inspector` サブエージェントでスクリーンショットを撮る
    - [x] カード全体のデザイン・レイアウトが意図通りか確認
    - [x] 問題があれば修正して再確認
  > 確認日時: 2026-03-20 14:05
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260320-feature-211-add-cook-count-last-date-to-dish-search/result.md
  >
  > 項目1: 調理済み料理の表示 ✅
  >   期待値: 「最終 X/X」と「N回」が表示される
  >   結果: 「最終 3/14 / 27回」「最終 11/14 / 5回」等が正しく表示
  >
  > 項目2: 未調理料理の表示 ✅
  >   期待値: 「未調理」と「0回」が表示される
  >   結果: 「未調理 / 0回」が正しく表示
  >
  > 項目3: 既存レイアウトの維持 ✅
  >   期待値: 1行目（料理名）・2行目（レシピ元・評価）が壊れていない
  >   結果: 既存のレイアウトは維持されており、3行目が追加されている

## フェーズ4: ドキュメント更新

- [x] ~~doc-enricher スキルを利用した README.md を更新~~（技術的理由: UIの表示追加のみでユーザー向けドキュメント変更不要）
- [x] 実装後の振り返り（このファイルの下部に記録）

---

## 実装後の振り返り

### 実装完了日
2026-03-20

### 計画と実績の差分

**計画と異なった点**:
- GraphQL codegen の再実行が必要だったことを tasklist に記載していなかった。バックエンドで新しいフィールドを追加した後、フロントエンドの generated/graphql.ts を更新するために `yarn codegen` が必要だった。

**新たに必要になったタスク**:
- `yarn codegen` の実行（generated/graphql.ts の再生成）

**技術的理由でスキップしたタスク**（該当する場合のみ）:
- README.md の更新: UIの表示追加のみのため不要
