# FR-019: 1食事を複数枠へ割り当てられhas_one契約が破れる

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [backend/app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb](../../../../../backend/app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb)
- [backend/app/models/meal.rb](../../../../../backend/app/models/meal.rb)
- [backend/db/schema.rb](../../../../../backend/db/schema.rb)

## 問題と根拠

FillWithMealCommandは対象枠へmeal_idを代入するだけ。meal_frame_entries.meal_idのindexもuniqueではない。一方Mealはhas_oneを宣言し、クエリとUIは単一mealFrameEntryIdを前提にする。2枠への連続割当で同じmeal_idを持つ行が2件できることを実測した。UIの候補除外だけでは古い画面や並行要求を防げない。

## 改善案

1食事1枠が契約なら既存重複を整理したうえでnullableなmeal_idにunique制約を置く。既存割当を移すのか拒否するのかをCommandで明示し、transactionで保証する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

同じ食事を2枠へ割り当てる逐次・並行要求、解除、削除を検証する。今回、逐次要求で重複作成を実測。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
