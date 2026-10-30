# FR-026: Terraform plan roleがstate全体を書き換えられる

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-023（現行コードで再確認）。

## 対象

- [infrastructure/terraform/modules/github_oidc/main.tf](../../../../../infrastructure/terraform/modules/github_oidc/main.tf)
- [.github/actions/terraform-run/action.yml](../../../../../.github/actions/terraform-run/action.yml)

## 問題と根拠

PR/任意branchからassume可能なplan roleへ、state bucketの全objectにs3:PutObjectを付与している。planログを保存するための権限が実際のtfstateにも及び、plan用の権限分離が成立しない。forkをworkflow側で除外しても同一repositoryのbranchに対する過剰権限は残る。

## 改善案

state objectはGetObject、ログ保存prefixはPutObjectに分離する。利用するbackendのlock方式に必要な権限だけを別に付与し、ReadOnlyAccessに含まれる機密読取り範囲も棚卸しする。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

IAM policyの静的検査と権限simulationで、planログ保存は許可、tfstate上書きは拒否を確認する。AWS実行は今回未実施。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
