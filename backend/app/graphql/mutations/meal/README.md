# Mutations::Meal

食事に関する GraphQL Mutation 群。

## クイックマップ

| ファイル | 内容 |
|---|---|
| `add_meal.rb` | 既存 Dish に対して Meal を登録 |
| `add_meal_with_new_dish.rb` | 新規 Dish + Meal を登録（既存 Source） |
| `add_meal_with_new_dish_and_new_source.rb` | 新規 Dish + 新規 Source + Meal を登録 |
| `update_meal.rb` | 既存 Meal の更新 |
| `remove_meal.rb` | Meal の削除 |
| `swap_meals_between_days.rb` | 日付間の Meal 入れ替え |

## 不変条件・契約（Invariants / Contracts）

### Dish 作成と Meal 作成の責務分担

- MUST: Dish の作成（`Dish::Usecase::AddCommand`）と Meal の作成（`Meal::Usecase::AddCommand`）は resolver 内でそれぞれ別々に呼ぶ
- 理由: Dish と Meal は異なるドメイン集約であり、一方の Command に他方を内包すると ドメイン境界が崩れる。`AddMealCommand` が Dish 作成を知ってはならない

### addMeal 系 3 Mutation の設計構造

3つの Mutation は「**どのように Dish を用意するか**」という1つの次元でバリエーションが分かれている。

| Mutation | Dish の調達方法 |
|---|---|
| `add_meal` | 既存の Dish を指定する |
| `add_meal_with_new_dish` | Dish を新規作成して使う |
| `add_meal_with_new_dish_and_new_source` | Dish と Source を両方新規作成して使う |

新しい操作を設計するとき、それが**「Dish の調達方法の新しいバリアント」なのか「既存操作への付帯情報（別次元）」なのか**を見極めることが起点になる。

- Dish 調達方法の新バリアント → 新しい Mutation として追加する
- 既存操作への付帯情報（別次元） → 既存 3 Mutation それぞれに optional 引数として追加する。独立 Mutation にすると「Dish 調達次元 × 付帯情報次元」の掛け合わせで Mutation 数が爆発する

## 参照

- `Business::Food::Meal::Usecase::AddCommand` — Meal 作成のユースケース層
- `Business::Food::Dish::Usecase::AddCommand` — Dish 作成のユースケース層
