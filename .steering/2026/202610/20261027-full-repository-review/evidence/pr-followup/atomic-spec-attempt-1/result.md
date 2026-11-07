# 辞書反映spec整理 attempt 1

request: `followup-atomic-spec-1`、attempt: 1、status: failed。

- atomic reflection spec: 4 examples、0 failures。
- backend全RSpec: 862 examples、0 failures。
- 親のreviewで、specの期待値確認にinstance variableを使う実装がrepositoryのtesting規約に反すると判明。sourceを修正して再検証するため、このattemptは中断した。
- 全RuboCopと残る変更範囲・保護確認は未実行。テスト成功をもって全checks成功とは扱わない。

直接原因はsnapshotのinstance variable参照。`let`等で規約に沿う形へ変更した後、新しいattemptで全checksを実行する。
