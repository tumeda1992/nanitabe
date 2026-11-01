# FR-009: 他人の料理を自分の食事に登録すると内容を取得できる

- 優先度: P1
- 採否: 採用
- 対応状況: 完了
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

- ユーザー判断: 2026-11-01の反映指示により採用
- 適用コミット: `9528fa1`

## 適用結果（2026-11-01）

`AttachDishPolicy.ensure!`に利用者IDを必須化し、料理の所有者まで確認する。食事Factoryと料理変更操作、延期Factoryへ共通適用し、延期確定時も食事Factoryを通る。既存の越境関連は削除せず、食事一覧と延期一覧から取得しないようにした。

追加`spec/domain/business/food/meal/dish_ownership_spec.rb`で登録・更新・延期の不正関連付けと既存越境関連2種の漏洩を再現した。更新テストは当初必須日付/時間帯が不足していたため入力を修正し、改めて不正更新が通るredを確認した。修正後はFactory/Root/Policy/食事Command/延期と食事GraphQL/queryで179 examples / 0 failures。拒否時の未保存と元属性不変、既存データを消さないことを検証した。変更8ファイルのRuboCopは違反なし。既存開発用Compose内で実行。
