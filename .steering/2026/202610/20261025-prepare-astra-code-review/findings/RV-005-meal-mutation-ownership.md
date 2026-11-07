# RV-005: 食事の更新・削除が操作ユーザーで絞り込まれない

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 採用（後続の全件反映指示）
- 対応状況: 完了（FR-003で追跡）
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

- ユーザーの判断: 後続の全件反映指示により採用（FR-003）
- 初回確認: コードと記載した関連specの静的確認。後続の検証結果は以下のFR記録を参照。
- 適用コミット: `f440ac4`

## 後続の反映（2026-11-02）

本fileの「今回の適用対象」は初回の挙動維持枠を指す。後続の全件反映指示による現行状態・検証は[FR-003](../../20261027-full-repository-review/findings/FR-003-meal-mutation-ownership.md)へ集約する。適用commitは`f440ac4`。
