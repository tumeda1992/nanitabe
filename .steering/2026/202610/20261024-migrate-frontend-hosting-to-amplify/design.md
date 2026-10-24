# Design: frontend の本番配信を Amplify へ移す

## 元の依頼内容

~/src/github.com/tumeda1992/x_favorites でamplifyで本番環境をAWSに構築できるようになったから、真似したい

（親 roadmap の phase `amplify-migration` として起動した。）

## 上位roadmap制約（子phaseの場合のみ）

- 親roadmap: `.steering/2026/202610/20261024-host-production-on-aws-amplify/roadmap.md`
- 親phase identity: `amplify-migration`
- 親phaseの目的: frontend の本番配信を Amplify Hosting へ移し、旧構成（Lambda、API Gateway、CloudFront、static asset 用 S3、ECR、CodePipeline、CodeBuild）を撤去する。本番 build の停止を解消する。
- 親phaseのscope: 親 design の「移行の手順」(1-a)〜(5) と「runtime・設定・環境構築」の全内容。この子 design はこれらを上位制約として受け取り、再設計しない。
- 親phaseのscope外: Terraform の適用経路の変更（GitHub Actions、OIDC、GitHub secrets）、`infrastructure/README.md`「構成上の前提」のうち GitHub 側の credentials と OIDC に関する前提の書き換え、`infrastructure/terraform/envs/review`、backend。
- 親phaseのDoD: 親 design の受け入れ基準のうち phase「Amplify 移行」の全項目を満たす。本番 frontend が custom domain で Amplify から配信され、`main` への push で deploy される。Terraform は現行どおり手元 apply で運用でき、`infrastructure/terraform/envs/prod` の `terraform plan` が `No changes` になる。
- 依存phaseの確定結果: なし

---

## TL;DR

親 design（`../20261024-host-production-on-aws-amplify/design.md`）で合意した Amplify 移行を実行する。この design は新しい設計判断を持たず、親 design の該当 section を正本として参照し、実行に必要な順序と停止点だけを tasklist へ渡す。終了時には本番 frontend が custom domain で Amplify から配信され、旧構成の resource と定義が残らない。

---

## 完成後の姿

### workflow

完成後の姿の正本は親 design の次の section である。この design へ複製しない。

- [移行の手順](../20261024-host-production-on-aws-amplify/design.md#移行の手順)（(1-a)〜(1-d)、(2)〜(5)、rollback、停止時間の扱い）
- [Amplify 移行後の deploy](../20261024-host-production-on-aws-amplify/design.md#amplify-移行後の-deploy)
- [runtime・設定・環境構築](../20261024-host-production-on-aws-amplify/design.md#runtime設定環境構築)（`amplify.yml`、Amplify app の設定、`frontend/next.config.js`、Terraform の配置、各段階の入力値、variable、更新する docs）

親 design から一意に導ける実行上の事項:

- Amplify は監視 branch の remote の内容を build する。(1-a) の前に、Phase 1 の変更を commit して `feature-258` を push する。この push は (1-a) の前提であり、利用者の確認を経て行う。
- 各 apply は `infrastructure/terraform/envs/prod` で `./init_terraform.sh` の後に `./apply_terraform.sh` を実行し、`terraform apply` が表示する plan を確認してから承認する。
- 旧構成の撤去を含む作業の Terraform 定義は `feature-258` 上にあり、apply はその working copy から行う。phase 完了時に `main` と state を一致させるため、`feature-258` の内容を `main` へ merge する。この merge は roadmap の後段 phase が残るため issue #258 の完了ではなく、PR に `Closes` を付けない（plugin の `development_flow/branch_pr_issue.md` の経路 2）。経路 2 の PR は本線 `feature-258` からではなく、派生 branch `feature-258-amplify-migration` から出す。本線は issue #258 の完了まで使い続け、merge 済みの branch 名を再利用しないためである。merge 後は `main` を `feature-258` へ取り込む。

---

## 要件（Requirements）

### MUST（必達）

- 親 design の MUST のうち、phase「Amplify 移行」に属するものをすべて満たす。
- 作業の外へ残る action（push、AWS への apply、`main` への merge）は、それぞれ独立した phase で行い、phase の最後で停止して利用者の確認を得る。

### SHOULD（できれば）

なし

### MAY（あれば嬉しい）

なし

### 非目標

- 親 phase の scope外のすべて。
- 親 design の設計判断の変更。実行中に親 design の前提が崩れた場合は停止し、親 task-design へ戻る。

### 受け入れ基準

親 design の [受け入れ基準](../20261024-host-production-on-aws-amplify/design.md#受け入れ基準) のうち phase「Amplify 移行」の全項目。

---

## リスクと対策

親 design の [リスクと対策](../20261024-host-production-on-aws-amplify/design.md#リスクと対策) をそのまま適用する。

---

## テスト方針

親 design の [テスト方針](../20261024-host-production-on-aws-amplify/design.md#テスト方針) をそのまま適用する。

---

## （付録）前提とする既存仕様

親 design の [前提とする既存仕様](../20261024-host-production-on-aws-amplify/design.md#付録前提とする既存仕様) を参照する。

---

## （付録）変更の実行区分

### task-design内で対象成果物へ適用済み

なし

### task-design内の対象成果物反映待ち

なし

### execution plan対象

| 対象 | 掲載理由 | 参照するdesign section |
| --- | --- | --- |
| 親 design の「Amplify 移行」の変更一式（code、Terraform、docs、各 apply、merge） | 本番 infrastructure を変え、順序依存する複数段階の apply、中間確認、rollback 境界を持つ | [完成後の姿](#完成後の姿) |
