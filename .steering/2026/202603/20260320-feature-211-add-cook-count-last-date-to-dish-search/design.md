# 要件ドキュメント

## はじめに
料理検索結果カード（DishSearchCard）に「調理回数」と「最終調理日」を表示する。
v0 デザインには3行目としてすでに定義済みだが、バックエンドがこれらのデータを返していないため未表示になっている。

## 元の依頼内容
調理回数・最終調理日 について、バックエンドでデータを返せるようにして、デザインで用意した通りにフロントエンドで表示したい

## 要件

### 要件1: バックエンドが調理回数・最終調理日を返す
**ユーザーストーリー:** 料理検索結果を見たとき、各料理に「この料理を何回作ったか」「最後にいつ作ったか」が表示されることで、献立を選ぶ判断材料になる。

#### 受け入れ基準
1. WHEN `existingDishesForRegisteringWithMeal` クエリを実行する THEN 各料理に `mealsCount`（調理回数）と `lastCookedDate`（最終調理日の ISO 日付文字列）が含まれて返ってくる
2. WHEN 一度も食事に割り当てられていない料理の場合 THEN `mealsCount` は `0`、`lastCookedDate` は `null` が返ってくる

### 要件2: フロントエンドの DishSearchCard に3行目を表示する
**ユーザーストーリー:** 料理検索結果カードに「最終調理日」と「調理回数」が表示されることで、何を作るか選びやすくなる。

#### 受け入れ基準
1. WHEN 料理が食事に割り当てられたことがある THEN カードに「最終 X/X」と「N回」が表示される
2. WHEN 料理が食事に割り当てられたことがない THEN カードに「未調理」と「0回」が表示される
3. WHEN 表示する THEN v0 デザイン（CalendarDays アイコン + 最終調理日 / ChefHat アイコン + 調理回数）に準拠した見た目になっている

---

# 設計ドキュメント

## TL;DR
バックエンドの `Dish` モデルに `last_cooked_date` サブクエリを追加し、既存の `meals_count` と合わせて GraphQL で返す。フロントエンドはクエリを拡張して `DishSearchCard` の3行目を表示する。

## 変更点サマリ

### バックエンド
| ファイル | 変更内容 |
|---|---|
| `app/models/dish.rb` | `with_search_relations` に `last_cooked_date` サブクエリ JOIN を追加 |
| `app/models/dish.rb` | `search_output` の select に `last_cooked_date` を追加 |
| `app/graphql/queries/dish/existing_dishes_for_registering_with_meal.rb` | `ExistingDishForRegisteringWithMeal` 型に `meals_count`・`last_cooked_date` フィールドを追加 |

### フロントエンド
| ファイル | 変更内容 |
|---|---|
| `src/features/dish/fetchDishQuery.ts` | クエリに `mealsCount`・`lastCookedDate` を追加 |
| `src/components/dish/DishSearchCard/index.tsx` | `DishForSearchCard` 型に追加、3行目（最終調理日・調理回数）を表示 |
| `src/components/dish/DishSearchPanel/index.tsx` | 取得データを DishSearchCard に渡す |

## 設計選択と理由

### 1. `last_cooked_date` をバックエンドで計算する
- `meals_count` と同様に `with_search_relations` スコープでサブクエリ JOIN を追加して `MAX(meals.date)` を取得する
- `search_output` で select に `meal_last_dates.last_cooked_date` を追加
- `to_searched_values` は `attributes` に自動的に入るため変更不要

```ruby
# with_search_relations に追加
last_cooked_date_subquery = Meal.select("dish_id, MAX(date) as last_cooked_date").group("dish_id")
joins("LEFT JOIN (#{last_cooked_date_subquery.to_sql}) AS meal_last_dates ON meal_last_dates.dish_id = dishes.id")

# search_output の select に追加
select_clauses.push("meal_last_dates.last_cooked_date AS last_cooked_date")
```

既存の `meals_count` と同じパターンなので一貫性がある。

### 2. 日付フォーマットはフロントエンドで行う
- バックエンドから ISO 日付文字列（`YYYY-MM-DD`）で返し、フロントで `M/D` 形式にフォーマットする
- バックエンドで文字列フォーマットすると、将来的な表示形式変更がフロント・バックエンドをまたぐ変更になる
- フロント側: `new Date(date).toLocaleDateString('ja-JP', { month: 'numeric', day: 'numeric' })` または単純に split で変換

### 3. フィールド名
- バックエンド: `meals_count`（既存）、`last_cooked_date`（新規）
- フロントエンド（GraphQL / TS）: `mealsCount`、`lastCookedDate`
- v0 デザインの `cookCount`・`lastDate` より意味が明確なため変更する

## 代替案と棄却理由

**案: フロントエンドから別クエリで取得する**
- 検索結果表示のたびに N 件の追加リクエストが発生するため却下

**案: `to_searched_values` に `meals_count`・`last_cooked_date` を明示的にマップする**
- SQL の `select` で取得した値は `attributes` に入るため不要。ただし `evaluation_score` のように関連テーブルの値を上書きする必要がある場合は明示する必要がある。今回は上書きなし。

## リスクと対策
- `meals_count` サブクエリと `last_cooked_date` サブクエリで同じ `meals` テーブルを参照するが、それぞれ独立した LEFT JOIN なのでパフォーマンス劣化は軽微（1クエリ追加のみ）
- `DishForSearchCard` 型に必須フィールドを追加すると、型を使っている呼び出し元でコンパイルエラーが出る可能性がある → `mealsCount` と `lastCookedDate` はオプション（`| null`）で受け取る設計にして、表示側でフォールバックする

## テスト方針
- バックエンド: `spec/models/dish_spec.rb` に `search_output` スコープのテストを追加（`meals_count`・`last_cooked_date` が正しく返ること）
- バックエンド: `spec/domain/business/food/dish/usecase/dish_searcher_spec.rb` に `mealsCount`・`lastCookedDate` が含まれることを確認するテストを追加
- フロントエンド: `DishSearchCard` のテストに `mealsCount`・`lastCookedDate` に応じた表示確認を追加
