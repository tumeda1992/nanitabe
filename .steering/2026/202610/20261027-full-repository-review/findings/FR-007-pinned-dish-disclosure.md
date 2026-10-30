# FR-007: 検索の先頭固定IDがユーザー条件を迂回する

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-009（現行コードで再確認）。

## 対象

- [backend/app/domain/business/food/dish/usecase/dish_searcher.rb](../../../../../backend/app/domain/business/food/dish/usecase/dish_searcher.rb)
- [backend/app/graphql/queries/dish/existing_dishes_for_registering_with_meal.rb](../../../../../backend/app/graphql/queries/dish/existing_dishes_for_registering_with_meal.rb)

## 問題と根拠

通常一覧はfor_user(access_user_id)だが、dish_id_registered_with_mealの取得はDish.where(id:)のみ。結果を検索条件から独立して先頭に追加するため、他人のIDを指定すると料理名・コメント等が応答へ混ざる。

## 改善案

先頭固定料理の取得にもfor_userを適用する。検索条件を迂回してよいことと所有者条件を迂回してよいことを分離する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

他人の固定ID、本人の検索条件不一致ID、不存在IDを指定し、本人の固定だけを許すことを確認する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
