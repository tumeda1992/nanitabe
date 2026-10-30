# FR-013: 料理編集で既存の手間レベルを消してしまう

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-011（現行コードで再確認）。

## 対象

- [frontend/src/components/dish/DishForm/DishForm/DishFormOfOnlyDishFields.tsx](../../../../../frontend/src/components/dish/DishForm/DishForm/DishFormOfOnlyDishFields.tsx)
- [frontend/src/features/dish/fetchDishQuery.ts](../../../../../frontend/src/features/dish/fetchDishQuery.ts)
- [frontend/src/features/meal/fetchMealQuery.ts](../../../../../frontend/src/features/meal/fetchMealQuery.ts)
- [backend/app/domain/business/food/dish/usecase/update_command.rb](../../../../../backend/app/domain/business/food/dish/usecase/update_command.rb)

## 問題と根拠

初回mountでもmealPositionのeffectがdish.dishEffortLevelIdへnullを設定する。編集用クエリも既存IDを取得せず、SelectEffortLevelへ復元値が渡らない。料理名だけを変更して保存しても、backendのassign_effort_levelがnullを保存する。正常操作で既存情報が消える。

## 改善案

クエリへ既存IDを含め、フォームdefaultValuesへ復元する。初回初期化とユーザーによる位置づけ変更を区別し、後者だけ適合しない手間をリセットする。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

手間設定済み料理について、名前のみ変更・無変更保存でID維持、位置づけ変更と明示解除で意図した値になることを画面からmutationまで検証する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
