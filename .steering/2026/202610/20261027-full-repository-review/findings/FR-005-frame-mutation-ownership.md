# FR-005: 枠名変更・枠削除・枠エントリ削除がIDだけで実行される

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-007（現行コードで再確認）。

## 対象

- [backend/app/domain/business/food/meal/frame/usecase/update_command.rb](../../../../../backend/app/domain/business/food/meal/frame/usecase/update_command.rb)
- [backend/app/domain/business/food/meal/frame/usecase/remove_command.rb](../../../../../backend/app/domain/business/food/meal/frame/usecase/remove_command.rb)
- [backend/app/domain/business/food/meal/frame/entry/usecase/remove_command.rb](../../../../../backend/app/domain/business/food/meal/frame/entry/usecase/remove_command.rb)

## 問題と根拠

user_id属性はあるが対象取得には使われない。AがBの枠を改名でき、使用されていない枠や枠エントリは他人のIDでも削除できる。利用中の枠を削除させないガードは所有者確認とは別の条件である。

## 改善案

最初にuser_idを含めて対象を取得し、その後に利用状況を検証する。関連件数や存在を他人に知らせないエラー契約を揃える。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

AからBの枠・エントリの変更削除を拒否し、Bの名前と関連が変化しないことを確認する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
