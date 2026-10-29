# FR-002: 日付交換が他ユーザーの食事まで移動する

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-004（現行コードで再確認）。

## 対象

- [backend/app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb](../../../../../backend/app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb)
- [backend/app/models/meal.rb](../../../../../backend/app/models/meal.rb)
- [backend/app/graphql/mutations/meal/swap_meals_between_days.rb](../../../../../backend/app/graphql/mutations/meal/swap_meals_between_days.rb)

## 問題と根拠

Commandはuser_idを受け取るが、両日の取得にMeal.fetch_by_date(date)だけを使う。モデルもwhere(date:)のみである。同じ日付にBの食事があれば、Aの日付交換でBの食事も反対の日へ保存される。認証済みであることでは防げない。

## 改善案

両日の取得をuser_idとdateで限定する。取得APIにもuser_idを必須にして、将来の呼び出しで条件を落とせない形にする。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

A/Bそれぞれに両日の食事を作り、Aのmutation後にBの全属性が不変であること、同日交換と空の日の結果を検証する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
