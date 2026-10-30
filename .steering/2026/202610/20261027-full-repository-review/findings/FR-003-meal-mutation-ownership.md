# FR-003: 食事の更新・削除が所有者を検証しない

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
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

- ユーザー判断: 未判断
- 適用コミット: 未適用
