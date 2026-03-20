# Business::Food::Dish

料理（Dish）ドメインのルートモジュール。

## 変更ガイド

### Dish::Root に属性を追加する
Root に新しい属性を追加するとき、以下の3箇所を必ず連動して変更すること:

- `factory.rb` — `Factory.build` のキーワード引数と `Root.new` への渡し方
- `app/models/dish.rb` — `build_existing_root_from_id` でのマッピング（DB → Root）
- `app/models/dish.rb` — `persist_from_food_dish_root` での保存（Root → DB）

片方だけ変更すると、取得はできるが保存されない（またはその逆）という不整合が発生する。
