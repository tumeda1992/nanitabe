# RV-006: 料理・出典・タグ更新に所有者確認が不足する

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 採用（後続の全件反映指示）
- 対応状況: 完了（FR-004で追跡）
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/domain/business/food/dish/usecase/update_command.rb; source/usecase/update_command.rb; tag/usecase/add_tag_to_dish_command.rb; backend/app/domain/business/food/dish/factory.rb: build_existing_from_id
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

料理更新・出典更新・タグ追加はいずれもIDだけで対象Rootを取得する。操作ユーザーは渡されるが対象所有者と比較しない。タグでは操作ユーザーのタグを別ユーザーの料理へ保存する経路になる。料理・出典の削除Commandはuser_idを含めて検索しており、同じ資源でも操作ごとに認可が異なる。

## 改善案

各変更用取得を操作ユーザーで限定し、BulkAddTagToDishesCommandの全対象も確認する。bulk途中の不正IDは既存transaction全体を失敗させる。

## 振る舞いを維持する条件

認可を追加する挙動変更なので対象外。異なる集約を一つの巨大Commandへ統合する必要はない。

## 検証方法

2ユーザーで料理・出典を作り、他人のIDを通常更新・新規出典付き更新・bulkタグ追加へ渡す。全対象の不変とrollbackを確認する。

## 採否・対応記録

- ユーザーの判断: 後続の全件反映指示により採用（FR-004）
- 初回確認: コードと記載した関連specの静的確認。後続の検証結果は以下のFR記録を参照。
- 適用コミット: `8adcbd6`

## 後続の反映（2026-11-02）

本fileの「今回の適用対象」は初回の挙動維持枠を指す。後続の全件反映指示による現行状態・検証は[FR-004](../../20261027-full-repository-review/findings/FR-004-dish-source-tag-ownership.md)へ集約する。適用commitは`8adcbd6`。
