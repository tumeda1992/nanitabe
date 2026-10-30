# RV-003: 任意GraphQL引数がRubyでは必須になっている

- 観点: 保守性・契約
- 優先度: 中
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/graphql/mutations/dish/update_dish_with_new_source.rb:11 resolve
- 依存する指摘: なし

## 問題と根拠

dish_source_relation_detailはGraphQL定義でrequired: falseだが、resolveのキーワード引数には既定値がない。明示nullを渡す場合と引数を省略する場合でRubyの受け取り契約が異なる。AddDishWithNewSourceでは同じ引数にnilの既定値がある。

## 改善案

resolveのdish_source_relation_detailにnilを既定値として与え、任意引数の省略を受けられるようにする。

## 振る舞いを維持する条件

省略時のエラーを成功へ変える可能性があるため今回の適用対象外。GraphQL-Rubyが省略をどう渡すかはrequest specで確認して確定する。

## 検証方法

backend/spec/graphql/mutation/dish/update_dish_with_new_source_spec.rbに引数省略と明示nullを分けたケースを追加する。更新内容と新規出典作成のtransaction結果を確認する。

## 採否・対応記録

静的コード確認のみ。テスト未実行、未適用。
