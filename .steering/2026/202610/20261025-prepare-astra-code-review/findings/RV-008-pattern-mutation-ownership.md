# RV-008: パターン更新・削除が操作ユーザーを受け取らない

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 採用（後続の全件反映指示）
- 対応状況: 完了（FR-006で追跡）
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/graphql/mutations/meal/frame/pattern/update_meal_frame_pattern.rb; delete_meal_frame_pattern.rb; backend/app/domain/business/food/meal/frame/pattern/usecase/update_command.rb; remove_command.rb
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

更新・削除resolverはcurrent_user_idをCommandへ渡さず、CommandもIDだけで対象を取得する。対してApplyMealFramePatternは所有者確認を行う。更新では他人のパターン名変更に加え、既存エントリ全削除・再作成まで到達する。

## 改善案

両Commandに必須user_idを追加して対象を限定し、resolverからcontextのIDを渡す。更新transactionと親子の一括置換を維持する。

## 振る舞いを維持する条件

認可の挙動変更のため対象外。パターン適用の独立性は維持する。

## 検証方法

他人の実在するパターンを更新・削除しても親と子が変わらないこと、本人による置換は成功することをGraphQL specへ追加する。

## 採否・対応記録

- ユーザーの判断: 後続の全件反映指示により採用（FR-006）
- 初回確認: コードと記載した関連specの静的確認。後続の検証結果は以下のFR記録を参照。
- 適用コミット: `d34ce8c`

## 後続の反映（2026-11-02）

本fileの「今回の適用対象」は初回の挙動維持枠を指す。後続の全件反映指示による現行状態・検証は[FR-006](../../20261027-full-repository-review/findings/FR-006-pattern-mutation-ownership.md)へ集約する。適用commitは`d34ce8c`。
