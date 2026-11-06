# FR-012: 省略可能なGraphQL引数がRubyでは必須になっている

- 優先度: P2
- 採否: 採用
- 対応状況: 再適用・検証完了
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

- ユーザー判断: 2026-11-01の反映指示により採用
- 適用コミット: `ceb1da7`

## 適用結果（2026-11-01）

`updateDish`の`dish_source_relation`と`updateDishWithNewSource`の`dish_source_relation_detail`へ`nil`既定値を追加した。省略は明示nullと同じ既存更新契約とし、維持を表す別のpresence契約は導入しない。

追加`spec/graphql/mutation/dish/optional_arguments_spec.rb`で両mutationの省略/null/有効値を検証した。修正前は6 examples / 2 failuresで省略だけ失敗し、保存されたエラーsnapshotの`missing keyword`も確認した。修正後は追加specと既存料理更新3 specで10 examples / 0 failures。変更3ファイルのRuboCopは違反なし。既存開発用Compose内で実行した。

## 適用取消と旧挙動の復元（2026-11-05）

Ruby keywordの既定値追加をceb1da7親版の2resolverへ戻し、専用optional specを除いた。
実差分はresolver2fileと専用specの3fileであり、対象外のMeal resolverを追加で変更していない。
[復元結果](../evidence/scope-repair/fr012-attempt-1/result.md)はRSpec13 examples / 0 failures、RuboCop2 files / 0 offensesを逐次確認し、
3path旧比較・先行入力変換/純抽出/利用者変更保持・diff checkが成功した。
元の省略時keyword不整合と過去の検証は保存し、解消済みとは数えない。

## 再適用（2026-11-06）

省略可能な2引数にnil既定値を復帰し、GraphQLの省略/null/有効値を既存更新処理へ届ける。関連RSpec 19 examples / 0 failures、3 file RuboCop 0 offenses。[結果](../evidence/scope-repair/fr012-retain-attempt-1/result.md)。
