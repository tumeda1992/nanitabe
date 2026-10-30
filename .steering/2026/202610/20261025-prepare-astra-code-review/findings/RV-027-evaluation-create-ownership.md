# RV-027: 未評価料理への評価作成が料理の所有者を確認しない

- 観点: 保守性・性能・契約
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/graphql/mutations/dish/evaluation/evaluate_dish.rb; backend/app/domain/business/dish/dish/evaluation/command/evaluate_command.rb; backend/app/domain/business/dish/dish/evaluation/repository.rb
- 依存する指摘: なし

## 問題と根拠

EvaluateCommandはdish_idで評価を検索し、なければ操作ユーザーIDとそのdish_idで作成する。Repository.addでも料理の所有者を照合しない。既存評価更新には評価レコードのuser_idチェックがあるため、他人の未評価料理に先に評価を作ると所有者本人の後続更新が拒否される経路がある。

## 改善案

評価の有無にかかわらず最初に料理を操作ユーザーで限定して取得する。既に所有者不一致の評価が存在する場合の修復は通常更新とは別に計画する。

## 振る舞いを維持する条件

認可と更新可能範囲が変わるため対象外。単に旧Business::Dishモジュールを削除すると現役の評価経路を壊す。

## 検証方法

他人の未評価料理への作成が拒否され本人の作成が成功することを検証する。既存評価の更新、別ユーザーが作った評価がある場合も確認する。

## 採否・対応記録

静的確認のみ。動的再現・テスト未実行、採否未判断、未適用。
