# 実装feedback

## FR-018 green attempt 1: lint（2026-11-06）

feedback: RSpec 30例成功、両specの `raise_error` blockに `Lint/AmbiguousBlockAssociation` 各1件。失敗resultは `evidence/scope-repair/fr018-green-attempt-1/result.json` に保持。

原因はRSpec matcherのblock結合を明示しなかったこと。コードとlint結果から読める記法上の不足で、設計意図や恒久的なrepository知識ではない。両matcherを括弧で囲み、同一例外instanceの検証を維持する。設計・planの変更やREADMEへの保存は不要。decision: 同じtaskで新attemptのRSpec/lintを再実行する。
