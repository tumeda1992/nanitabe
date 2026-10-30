# RV-006: 料理・出典・タグ更新に所有者確認が不足する

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
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

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
