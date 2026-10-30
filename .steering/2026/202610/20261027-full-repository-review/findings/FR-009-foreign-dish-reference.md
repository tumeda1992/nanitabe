# FR-009: 他人の料理を自分の食事に登録すると内容を取得できる

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [backend/app/domain/business/food/meal/usecase/add_command.rb](../../../../../backend/app/domain/business/food/meal/usecase/add_command.rb)
- [backend/app/domain/business/food/meal/policy/attach_dish_policy.rb](../../../../../backend/app/domain/business/food/meal/policy/attach_dish_policy.rb)
- [backend/app/domain/business/food/meal/usecase/date_meals_finder.rb](../../../../../backend/app/domain/business/food/meal/usecase/date_meals_finder.rb)

## 問題と根拠

食事登録はdish_idの所有者を検証しない。更新時のAttachDishPolicyも存在確認だけ。Aの食事にBの料理を関連付けると、ユーザー内の食事一覧が関連dishの内容を返す。ローカルGraphQL登録とFinderで、Bの非公開料理名がAの結果に出ることを実測した。検索固定IDを直すだけでは残る別経路である。

## 改善案

料理関連付け時にDishを操作ユーザーで限定する。登録・更新・延期確定など全経路で共有できる認可契約とし、既存の越境関連の扱いも確認する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

AでBの料理を指定した登録と更新を拒否し、レコードを残さないことを検証する。今回の証拠はevidence/backend-probes.rbの最初のケース。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
