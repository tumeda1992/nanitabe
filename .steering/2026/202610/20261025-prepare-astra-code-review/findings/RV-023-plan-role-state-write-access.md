# RV-023: Terraform plan用roleがstate全体への書き込み権限を持つ

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: infrastructure/terraform/modules/github_oidc/main.tf: plan_state_access、plan_sub_conditions; .github/actions/terraform-run/action.yml: finish
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

plan roleにstate bucketの全キーへのs3:GetObjectとs3:PutObjectを付与している。plan出力の保存にはplans配下の書き込みが必要だが、この指定はprod/reviewのstateファイル自体の上書きも許可する。同roleはrepository内のPRと任意branchのOIDCで引き受けられるため、planを実行する権限がstate改変権限にもなる。fork PRを除外していても同一repository内の権限境界は分かれていない。

## 改善案

state keyの読み取りとplans prefixへの出力書き込みを分離する。現行のDynamoDB lock権限を維持し、S3 lockへ変更する場合はlock専用キーへ必要権限を限定する。

## 振る舞いを維持する条件

IAM権限を変更するため対象外。運用に必要なstate操作はplan roleに便乗させず別の権限として扱う。

## 検証方法

IAM policy simulation等でstateへのPutObject拒否、state読み取りとplans出力保存の許可を確認する。実stateを試験的に上書きしない。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
