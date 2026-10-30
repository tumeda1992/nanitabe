# FR-011: 未評価料理への評価作成が料理の所有者を確認しない

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
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

- ユーザー判断: 未判断
- 適用コミット: 未適用
