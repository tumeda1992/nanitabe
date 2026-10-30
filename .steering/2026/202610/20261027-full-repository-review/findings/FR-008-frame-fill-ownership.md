# FR-008: 枠割当の認可が入口ごとに異なり関連先の所有者を検証しない

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-010（現行コードで再確認）。

## 対象

- [backend/app/graphql/mutations/meal/frame_entry/fill_meal_frame_entry.rb](../../../../../backend/app/graphql/mutations/meal/frame_entry/fill_meal_frame_entry.rb)
- [backend/app/graphql/mutations/meal/add_meal.rb](../../../../../backend/app/graphql/mutations/meal/add_meal.rb)
- [backend/app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb](../../../../../backend/app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb)

## 問題と根拠

fill mutationは枠エントリの所有者だけを確認し、meal_idの所有者は確認しない。一方、食事登録のframe_entry_id経由では枠側の確認すらない。共通FillWithMealCommandは両方をIDのみで保存するため、入口によって他人の枠・食事を関連付けられる。

## 改善案

共通Commandで枠と食事をともにuser_idで取得する。登録系3経路と既存食事割当の認可をここへ揃え、失敗時は食事作成もロールバックする。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

本人/他人の枠と食事の4組合せを、直接fillと全登録経路で検証する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
