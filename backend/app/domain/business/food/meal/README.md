# Business::Food::Meal

食事（Meal）ドメインのルートモジュール。

## 不変条件・契約（Invariants / Contracts）

### Meal = 日付 + 料理（dish_id は常に必須）

- MUST: `Meal::Root.dish_id` は `presence: true` であり、nullable にしてはならない
- 理由: `Meal` は「ある日に、ある料理を食べた記録」として定義されている。料理が未決定の「枠」は `MealFrameEntry` という別モデルで表現する
- 破ると何が起きるか: `DishCard` は `meal.dish` が常に存在することを前提に書かれており、nullable にすると既存フロントエンドコード全体に null ハンドリングが波及する

### MealFrame（枠マスタ）と MealFrameEntry（カレンダーエントリ）の役割分担

| テーブル | 役割 |
|---|---|
| `meal_frames` | 枠のマスタ（例:「パスタ」「魚料理」）。ユーザー別に管理・再利用可能 |
| `meal_frame_entries` | カレンダー上の「その日の枠」。`meal_frame_id` で枠を参照し、`meal_id` に料理が割り当てられたら確定済みになる |

- MUST: 枠マスタは `meal_frames` で一元管理し、同じ枠を複数日に使い回せる設計を維持する（毎回新規作成しない）

## 変更ガイド

### Meal::Root に属性を追加する

以下の3箇所を連動して変更すること:

- `factory.rb` — `Factory.build` のキーワード引数と `Root.new` への渡し方
- `app/models/meal.rb` — `build_existing_root_from_id` でのマッピング（DB → Root）
- `app/models/meal.rb` — `persist_from_food_meal_root` での保存（Root → DB）

## 参照

- `Business::Food::Dish::README.md` — 同様の集約ルートパターン（Dish 側）
- `backend/app/domain/business/food/README.md` — food モジュール全体の役割とアーキテクチャ
