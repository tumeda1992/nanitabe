# RV-005: 食事の更新・削除が操作ユーザーで絞り込まれない

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/domain/business/food/meal/usecase/update_command.rb: call; remove_command.rb: call; backend/app/models/meal.rb: build_existing_root_from_id; backend/app/graphql/mutations/meal/update_meal.rb; remove_meal.rb
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

UpdateCommandはmeal_params.idだけでRootを取得し、RemoveCommandもfind_by(id: meal_id)だけで削除する。user_idはpresence検証だけで所有者確認に使われない。resolverにも所有者確認がない。PostponeMealには所有者条件があるが、通常の更新・削除には適用されない。

## 改善案

更新・削除の取得をIDと操作ユーザーで限定する。新しい料理を同時作成する更新経路も同じ取得契約を使い、失敗時にはtransaction全体をrollbackする。

## 振る舞いを維持する条件

他ユーザー操作を拒否する振る舞い変更。今回対象外。未存在と権限不足の応答設計は適用時に統一する。

## 検証方法

別ユーザーの実在する食事IDを使い、通常更新・新規料理付き更新・削除の各GraphQL呼び出しで食事と関連料理が変更されないことを確認する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
