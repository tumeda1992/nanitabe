# RV-004: 日付交換が他ユーザーの食事まで移動する

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb: call; backend/app/models/meal.rb: fetch_by_date; backend/app/graphql/mutations/meal/swap_meals_between_days.rb: resolve
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

認証済みのcurrent_user_idはCommandに渡されるが、取得はMeal.fetch_by_date(date)だけで、モデル側もwhere(date:)のみ。2日間に存在する全ユーザーの食事をrescheduleして保存する。日付のみを送る通常の操作で他ユーザーのデータも変わり得る。既存のfood側Command specは同一ユーザーと同日交換を検証しているが、別ユーザーの混在は検証していない。

## 改善案

fetch_by_dateに必須のuser_idを渡し、where(user_id:, date:)で取得する。取得後の交換順序とtransactionを維持する。

## 振る舞いを維持する条件

他ユーザーを除外する修正は認可・更新対象の変更であり、今回の挙動維持リファクタリングには含めない。同日交換で同じIDを2回返す現状は別判断として維持する。

## 検証方法

ユーザーA・Bの食事を両日に作り、AのGraphQL交換後にBのdate・updated_atが変わらず、応答にもBのIDが含まれないことを検証する。既存swap_meals_between_days_command_spec.rbも維持する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
