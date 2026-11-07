# RV-001: 料理入力変換が登録・食事登録・食事更新に重複

- 観点: 保守性・契約
- 優先度: 中
- 採否: 採用
- 対応状況: 完了
- 今回の適用対象: 対象
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: frontend/src/features/dish/addDishMutation.ts、frontend/src/features/meal/addMealMutation.ts、frontend/src/features/meal/updateMealMutation.ts、frontend/src/features/dish/updateDishMutation.ts の convertFrom…InputToGraphqlInput
- 依存する指摘: なし

## 問題と根拠

料理登録・食事登録・食事更新の3ファイルで既存出典の場合のcloneDeep・selectedDishSource取得・normalizeInputOfAddingDishWithExistingSource呼び出し、新規出典の場合のcloneDeep・normalizeDishSourceRelationDetail呼び出しがそれぞれ重複している。新規出典の同じ変換は料理更新にもある。既存出典の料理更新は入力構造が異なるため、一律に統合しない。出典の変換仕様を変更するときに、料理登録だけ直して食事登録・更新を取り残す構造になっている。

## 改善案

normalizeFunctions.tsに既存出典用・新規出典用の入力変換を集約する。mealやframeEntryIdなど呼び出し元固有のフィールドを保持する型を用意し、各mutationから同じ変換を呼ぶ。GraphQL文書や登録・更新スキーマ自体は統合しない。

## 振る舞いを維持する条件

元入力の非破壊性、余剰フィールドの保持、出典IDなしのnull、NO_VALUE時のnull、detailType削除を維持する。最初の抽出ではcloneDeepの回数や順序を変更しない。

## 検証方法

既存出典あり・なし、新規出典、詳細値あり・なし、mealとframeEntryId保持を旧実装と比較する。入力をfreezeした非破壊性テストも追加する。

## 採否・対応記録

- 2026-10-26: ユーザーの適用指示により採用・実装済み。
- 検証: 既存出典/新規出典の入力変換をジェネリック関数へ集約。旧実装へ追加した回帰7件が成功してから抽出し、freeze入力・meal/frameEntryId・タグ・NO_VALUEのnull保持を確認。料理/食事フォームを含むJest: 10 suites, 54 tests成功。
- 適用コミット: 本ファイルの完了記録と同じコミット（git logで参照可能）
