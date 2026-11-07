# FR-003: 食事の更新・削除が所有者を検証しない

- 優先度: P1
- 採否: 採用
- 対応状況: 完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-005（現行コードで再確認）。

## 対象

- [backend/app/domain/business/food/meal/usecase/update_command.rb](../../../../../backend/app/domain/business/food/meal/usecase/update_command.rb)
- [backend/app/domain/business/food/meal/usecase/remove_command.rb](../../../../../backend/app/domain/business/food/meal/usecase/remove_command.rb)
- [backend/app/models/meal.rb](../../../../../backend/app/models/meal.rb)

## 問題と根拠

更新はIDだけで既存rootを取得し、削除もfind_by(id:)だけである。引数user_idは必須だが、対象の所有者との比較に使用されない。AがBのmeal IDを渡せばBの記録を変更・削除できる。延期mutationでは入口で所有者を確認する一方、通常の更新・削除では確認がない。

## 改善案

更新・削除のCommand境界で所有者を絞った取得を行う。新規料理を伴う更新では認可失敗時に新規料理・出典も残らないよう既存transactionを維持する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

通常更新・新規料理付き更新・削除の全経路で別ユーザーIDと不存在IDを検証する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 2026-11-01の既存レビュー反映依頼により採用
- 適用コミット: `f440ac4`

## 適用結果（2026-11-01）

`UpdateCommand`と`RemoveCommand`の対象取得を`id`と`user_id`で絞った。他人のIDを不存在IDと同じ例外で拒否する。更新の不存在IDについては既存の`ActiveRecord::RecordNotFound`とmessageを維持した。新規料理付き更新の既存transactionにより認可失敗時の料理・出典・関連・タグの作成をrollbackする。

追加した`spec/graphql/mutation/meal/ownership_spec.rb`は通常更新・削除・新規料理付き更新を他人ID/不存在IDで検証する。修正前は6 examples / 3 failuresで不正操作を再現した。開発用Composeで追加spec、更新・削除Command、通常更新・削除・新規料理付き更新・新規出典付き更新の既存GraphQL specを実行し、31 examples / 0 failures。変更3ファイルのRuboCopは違反なし。

検証コマンド: `docker compose -f compose.dev.local.yml exec -T backend bundle exec rspec spec/graphql/mutation/meal/ownership_spec.rb spec/domain/business/food/meal/usecase/update_command_spec.rb spec/domain/business/food/meal/usecase/remove_command_spec.rb spec/graphql/mutation/meal/update_meal_spec.rb spec/graphql/mutation/meal/remove_meal_spec.rb spec/graphql/mutation/meal/update_meal_with_new_dish_spec.rb spec/graphql/mutation/meal/update_meal_with_new_dish_and_new_source_spec.rb`。
