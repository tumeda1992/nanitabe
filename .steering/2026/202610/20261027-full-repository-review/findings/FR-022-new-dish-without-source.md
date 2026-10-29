# FR-022: 食事編集で出典なしの新規料理を選ぶと送信契約に違反する

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [frontend/src/features/meal/updateMealMutation.ts](../../../../../frontend/src/features/meal/updateMealMutation.ts)
- [frontend/src/features/dish/schema.ts](../../../../../frontend/src/features/dish/schema.ts)
- [frontend/src/features/dish/normalizeFunctions.ts](../../../../../frontend/src/features/dish/normalizeFunctions.ts)
- [backend/app/graphql/mutations/meal/update_meal_with_new_dish.rb](../../../../../backend/app/graphql/mutations/meal/update_meal_with_new_dish.rb)

## 問題と根拠

編集UIは新規料理＋既存出典選択モードで未選択を許し、schemaもselectedDishSourceをoptionalにする。normalizerは未選択をdishSource:nullへ変換する。しかしupdateMealWithNewDishの変数とbackend引数はSourceForRead!であり、その通常入力を拒否する。登録側では出典がoptionalなので、登録と編集で利用可能な操作が食い違う。

## 改善案

出典なし料理を編集時にも作成できるなら、backend引数とGraphQL operationをnullableにし、resolver既定値を揃えてcodegenする。必須という仕様ならUIの選択とschemaを明示的に必須にする。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

既存食事を出典なし新規料理へ差し替える画面操作を、mockだけでなくGraphQL validationまで含めて検証する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
