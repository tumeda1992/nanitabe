# FR-026: Terraform plan roleがstate全体を書き換えられる

- 優先度: P1
- 採否: 採用
- 対応状況: 完了（静的検証済み、AWS実測未実施）
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

## 適用結果（2026-11-01）

state bucketの全objectにはGetObjectだけを残し、PutObjectをplans/*だけの独立statementへ分離した。共有Terraform actionの保存先plans/<root>/<run>.txtと一致する。apply用roleは別のまま。DynamoDB lock用GetItem/PutItem/DeleteItemも維持した。

追加のNode静的テストは実HCLのinline policyを読み、planログのPutObject許可、tfstate/applyログ/他prefixへのPutObject拒否、DeleteObject拒否、state読取り、lock対象table限定、roleへのpolicy wiringを検証する。修正前はtfstateへの書込みが許可され1/3失敗、修正後は3/3成功。commandは`node --test infrastructure/terraform/modules/github_oidc/plan_policy.spec.mjs`。`git diff --check`も成功した。これは既知のinline statementの静的照合であり、AWS IAM simulatorそのものではない。

[ReadOnlyAccessの公式policy](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/ReadOnlyAccess.html)も確認し、このmanaged policyにS3 PutObjectがないことを確認した。ただし多サービス・多resourceへの広い読取り権限は残り、この変更を最小read権限化と呼ばない。実際のroleへ別途付与されたpolicy、bucket policy、SCPなどを含む実効権限は未実測。

hostと既存backend containerにTerraform CLIがないため、fmt/validateは未実施。新規tool取得やAWS simulationを実行する追加許可は、外出中の利用者指示に従って要求していない。今回のコードは静的検証済みとして保存し、Terraformを利用できるCI/環境でのvalidateと許可されたAWS simulatorでの実効権限確認ができた時点で検証記録を更新する。Terraform applyや実環境のrole更新は今回の対象外で実行していない。適用commitはapplication.mdとGit履歴で追跡する。
