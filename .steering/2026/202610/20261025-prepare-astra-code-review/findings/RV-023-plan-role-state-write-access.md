# RV-023: Terraform plan用roleがstate全体への書き込み権限を持つ

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 採用（後続の全件反映指示）
- 対応状況: 完了（FR-026で追跡）
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

- ユーザーの判断: 後続の全件反映指示により採用（FR-026）
- 初回確認: コードと記載した関連specの静的確認。後続の検証結果は以下のFR記録を参照。
- 適用コミット: `df42ad7`

## 後続の反映（2026-11-02）

本fileの「今回の適用対象」は初回の挙動維持枠を指す。後続の全件反映指示による現行状態・検証は[FR-026](../../20261027-full-repository-review/findings/FR-026-plan-role-state-write.md)へ集約する。適用commitは`df42ad7`。
