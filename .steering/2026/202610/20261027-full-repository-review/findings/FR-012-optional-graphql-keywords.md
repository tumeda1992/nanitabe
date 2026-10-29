# FR-012: 省略可能なGraphQL引数がRubyでは必須になっている

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-003（現行コードで再確認）。

## 対象

- [backend/app/graphql/mutations/dish/update_dish.rb](../../../../../backend/app/graphql/mutations/dish/update_dish.rb)
- [backend/app/graphql/mutations/dish/update_dish_with_new_source.rb](../../../../../backend/app/graphql/mutations/dish/update_dish_with_new_source.rb)

## 問題と根拠

dish_source_relationとdish_source_relation_detailはrequired:falseなのにresolveでは既定値なしのキーワード引数。クライアントが合法的に引数を省略するとresolver呼び出しが失敗する。明示nullを送るテストだけでは検出しない。

## 改善案

resolve引数へnil既定値を付け、省略時の更新契約を明確にする。省略を「維持」、nullを「削除」としたいなら別途入力presenceを保持する設計が必要。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

両mutationで引数省略・明示null・有効値の3ケースを実際のGraphQL経由で検証する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
