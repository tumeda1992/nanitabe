# RV-013: 料理出典のGraphQL入力変換が複数resolverへ散在する

- 観点: 保守性・責務・型
- 優先度: 中
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/graphql/mutations/dish/add_dish.rb; add_dish_with_new_source.rb; update_dish_with_new_source.rb; backend/app/graphql/mutations/meal/add_meal_with_new_dish.rb; add_meal_with_new_dish_and_new_source.rb; update_meal_with_new_dish.rb; update_meal_with_new_dish_and_new_source.rb
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

各resolverが同じpresent?条件、detail_value_of、DishSourceRelation.build_relation、タグのconvert_to_command_paramを繰り返す。出典関係の入力契約を変えると料理単独と食事同時登録で変換がずれる。集約をまたぐCommandの呼び出し順はresolverの責務だが、同じ入力変換の重複はその責務ではない。

## 改善案

GraphQL入力層に出典関係変換を抽出し、出典type・確定済みID・詳細入力を受け取る。タグ変換も同層の共通関数へ寄せる。新規出典作成と料理・食事Commandの順序、transactionはresolverに残す。

## 振る舞いを維持する条件

詳細/出典がblankの場合はnil、タグ未指定は空配列という現状を維持する。新規出典作成前に変換しない。例外とrollback境界、公開GraphQL引数を変えない。

## 検証方法

既存の料理/食事mutation specで既存出典・新規出典・詳細省略・タグ省略を比較し、後段失敗時の全体rollbackも検証する。RV-003の既定値修正は別に扱う。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
