# FR-005: 枠名変更・枠削除・枠エントリ削除がIDだけで実行される

- 優先度: P1
- 採否: 採用
- 対応状況: 完了
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

- ユーザー判断: 2026-11-01の反映指示により採用
- 適用コミット: `f7b3e68`

## 適用結果（2026-11-01）

枠更新でrootの所有者を確認し、枠削除・枠エントリ削除は利用者で絞った取得へ変更した。枠削除の所有者確認を利用状況の確認より先に行い、他人へ関連の有無を返さない。

追加`spec/domain/business/food/meal/frame/ownership_spec.rb`で他人の枠の改名・未使用枠削除・使用中枠削除・エントリ削除の4 examples / 4 failuresを確認した。修正後は追加specと対象3Command、枠更新・枠削除・エントリ削除のGraphQL specで19 examples / 0 failures。名前と関連エントリの不変、本人操作の既存動作を確認した。変更4ファイルのRuboCopは違反なし。すべて既存開発用Compose内で実行した。
