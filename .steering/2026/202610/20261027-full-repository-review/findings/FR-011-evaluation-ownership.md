# FR-011: 未評価料理への評価作成が料理の所有者を確認しない

- 優先度: P1
- 採否: 採用
- 対応状況: 完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-027（現行コードで再確認）。

## 対象

- [backend/app/domain/business/dish/dish/evaluation/command/evaluate_command.rb](../../../../../backend/app/domain/business/dish/dish/evaluation/command/evaluate_command.rb)
- [backend/app/domain/business/dish/dish/evaluation/repository.rb](../../../../../backend/app/domain/business/dish/dish/evaluation/repository.rb)

## 問題と根拠

評価が存在しない分岐はdish_idと操作user_idでそのまま評価を作る。既存評価の更新だけが評価レコードのuser_idを検査する。AがBの未評価料理へ先に評価すると、その料理の評価をA名義で作れて、Bの後続更新が拒否される。

## 改善案

作成・更新前に料理の所有者を確認する。評価レコードの所有者だけに依存せず、既存の不整合評価への移行方針も検討する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

他人の未評価料理への作成、評価済み料理への更新、本人の初回作成を検証する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 2026-11-01の反映指示により採用
- 適用コミット: `cdb8e27`

## 適用結果（2026-11-01）

評価Commandの冒頭で料理を操作利用者で絞って取得する。更新Repositoryも料理の所有者を認可基準にし、評価行の古い所有者だけに依存しない。既存不整合は一括変更せず、料理の所有者が再評価した時にscoreと評価行のuser_idを同時保存して修復する。既存の明示force_update経路は維持する。

追加`evaluation/command/ownership_spec.rb`の4 examples / 4 failuresで他人の初回評価、不整合評価を使った他人更新、本人の更新阻害、不在IDの例外を再現した。修正後は評価Command/Repository/GraphQL/modelで9 examples / 0 failures。拒否時の未作成と属性不変、本人が再評価した際の所有者修復を確認した。変更3ファイルのRuboCopは違反なし。既存開発用Compose内で実行。

## 現在の対応（2026-11-06）

料理ownerに基づく認可を維持する。未commitの取消を撤回し、対象3 pathはHEADおよび `cdb8e27` と一致した。本人の評価操作と他人料理への拒否を新たに検証し、RSpec 9 examples / 0 failures、対象2 fileのRuboCop 0 offensesを確認した。[検証結果](../evidence/scope-repair/fr011-retain-attempt-1/result.md)。旧取消検証は当時の実測を保持し、その目的は[失効](../evidence/scope-repair/fr011-superseded.md)した。
