# FR-008: 枠割当の認可が入口ごとに異なり関連先の所有者を検証しない

- 優先度: P1
- 採否: 採用
- 対応状況: 完了
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

- ユーザー判断: 2026-11-01の反映指示により採用
- 適用コミット: `a2ca053`

## 適用結果（2026-11-01）

現物では全4入口が利用者IDを渡しており、共通Commandの確認不足が原因だった。割当前に枠エントリ、関連する枠マスタ、食事の所有者を確認する。枠エントリ作成時にも枠マスタの所有者を確認し、不正な関連の新規作成を拒否する。旧namespaceの割当Commandを現行へ委譲し、旧作成Commandにも同じ認可を追加した。残る旧namespace整理はFR-034に分離する。

追加2 specの16 examples / 13 failuresで現行/旧Commandの不足と3登録経路の不正割当を再現した。既存GraphQL specの「他人の食事」が本人fixtureとID 0で代用されていたため、実在する他人の料理・食事を送る検証へ修正した。修正後は現行/旧の枠エントリCommand、枠エントリGraphQL、既存料理・新規料理・新規出典付き料理の食事登録GraphQLで50 examples / 0 failures。拒否時の枠全属性とMeal/Dish/DishSource/DishSourceRelation/DishTag件数の不変を検証した。変更7ファイルのRuboCopは文字列表記1件を修正後、違反なし。既存開発用Compose内で実行した。
