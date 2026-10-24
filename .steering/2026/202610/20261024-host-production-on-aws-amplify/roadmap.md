# ロードマップ: 本番環境を AWS Amplify で構築する

## 設計参照

- `./design.md`

## 概要

frontend の本番配信を自前構成から Amplify Hosting へ移して旧構成を撤去し、その後に Terraform の適用を手元から GitHub Actions へ移す。

一つの tasklist にしないのは、Actions 移行の設計完了まで Amplify 移行の実行を待たせないためである。現行の CodeBuild は本番 build に失敗していて、Amplify 移行の完了がその停止を解消する。Actions 移行で決める事項（apply role の権限、GitHub secrets へ移す値）は、Amplify 移行の後に root に残る resource と variable の実物で決まる。そのため Actions 移行は、Amplify 移行の結果を入力にした別の design loop で設計する。

このroadmapは子scopeの構造一覧である。各phaseは独立した子steeringを通じて設計・実装し、各phase完了時点でappまたは成果物が正常に利用できる状態を保つ。

roadmapの構造fieldはtask-designが設計・reviewする。各phaseの子steering path、status、完了日だけをsteeringが実行時に更新する。

## 構造field（task-designが設計・reviewする）

---

## Phase: amplify-migration — Amplify 移行

### 目的

frontend の本番配信を Amplify Hosting へ移し、旧構成（Lambda、API Gateway、CloudFront、static asset 用 S3、ECR、CodePipeline、CodeBuild）を撤去する。本番 build の停止を解消する。

### Scope

- 親 design の「移行の手順」(1-a)〜(5) と「runtime・設定・環境構築」の全内容。子 task-design はこれらを上位制約として受け取り、再設計しない。
  - `amplify.yml` の新設、`frontend/next.config.js` の設定削除
  - `frontend/terraform/modules/amplify/` の新設と `frontend/terraform/envs/prod/main.tf` からの呼び出し
  - `frontend/terraform/modules/cloudfront/` への `enable_custom_domain` の追加
  - prod root の variable の追加・削除と `apply_terraform.sh` の export の更新
  - 旧構成の module（`test/` を含む）と `frontend/buildOnLambda/` の削除
  - 現行の手元 apply による各段階の適用と確認
  - 「Amplify 移行で更新する docs」の各 file

### Scope外

- Terraform の適用経路の変更（GitHub Actions、OIDC、GitHub secrets）。phase `terraform-on-github-actions` が扱う。
- `infrastructure/README.md`「構成上の前提」のうち、GitHub 側の credentials と OIDC に関する前提の書き換え。phase `terraform-on-github-actions` が扱う。
- `infrastructure/terraform/envs/review` と backend。

### DoD（完了条件）

- 親 design の受け入れ基準のうち、phase「Amplify 移行」の全項目を満たす。
- 本番 frontend が custom domain で Amplify から配信され、`main` への push で deploy される。
- Terraform は現行どおり手元 apply で運用でき、`infrastructure/terraform/envs/prod` の `terraform plan` が `No changes` になる。

### 依存

- 依存phase: なし
- dependency results: なし
- 子designで解消する制約: なし

### 親DoDとの対応

- frontend の本番配信を Amplify Hosting へ移す。
- 移行後に旧構成を撤去する。
- Amplify 構成は branch を list で持ち、custom domain を branch ごとの sub domain の集合で持つ。
- 旧構成の撤去までは、旧 CloudFront へ custom domain を戻す rollback の手段を残す。

### 運用field（steeringだけが更新する）

- 子steering: `.steering/2026/202610/20261024-migrate-frontend-hosting-to-amplify/`
- status: 進行中
- 完了日: 未完了

---

## Phase: terraform-on-github-actions — Terraform の Actions 移行

### 目的

`infrastructure/terraform/envs/prod` と `envs/review` の適用を GitHub Actions へ移し、Terraform の変更が PR で plan され、`main` への merge で apply される状態にする。

### Scope

- 二つの root（`envs/prod`、`envs/review`）の plan・apply workflow
- OIDC の identity provider と、plan 用・apply 用の AWS role
- host の `.env` から GitHub secrets へ移す値の移動
- state の lock の扱い
- `infrastructure/README.md`「構成上の前提」の GitHub と AWS の関係の書き換えと、適用手順の記述の更新
- branch protection の扱い
- module をローカル実行で Terraform が動くか確かめる用途（旧構成では各 module の `test/` から local state で立てる spike 的な環境 `verify-infra` が担っていた）を、新しい構成でどう持つか。「値を必要とする Terraform は Actions だけで実行する」方針と両立させる

### Scope外

- Amplify app の構成と frontend の配信。phase `amplify-migration` で確定している。
- frontend の常設 review branch と backend の本番 deploy。

### DoD（完了条件）

- `envs/prod` と `envs/review` の変更を含む PR で `terraform plan` の結果が PR に出る。
- `main` への merge で `terraform apply` が実行され、適用後の `terraform plan` が `No changes` になる。
- 値を必要とする `terraform plan` / `apply` を実行する場所が GitHub Actions だけになっている。
- `infrastructure/README.md` が新しい適用経路と前提を説明している。
- 本番 frontend と backend の review 環境が、移行前と同じく利用できる。

### 依存

- 依存phase: amplify-migration
- dependency results: phase `amplify-migration` 完了時点の `infrastructure/terraform/envs/prod` が持つ resource と variable の一覧、`apply_terraform.sh` が読む `.env` の key の一覧、実施中に `implementation_review.md` へ記録された逸脱、旧構成の `verify-infra` 環境を撤去した結果（新しい構成にはローカル実行で module を確かめる手段がまだ無い）
- 子designで解消する制約: apply role と plan role に与える権限の範囲、GitHub secrets へ移す値の一覧、`envs/review` の destroy 拒否判定と agent の実行権限の扱い。dependency results の resource や variable が親 design の想定（Amplify と state 用 resource だけ）を超えている場合は、親 task-design へ戻る。

### 親DoDとの対応

- Terraform の適用を GitHub Actions へ移す。

### 運用field（steeringだけが更新する）

- 子steering: 未割当
- status: 未着手
- 完了日: 未完了

---

## 親DoD coverage

| 親DoD | 担当phase |
| --- | --- |
| frontend の本番配信を Amplify Hosting へ移す | amplify-migration |
| 移行後に旧構成を撤去する | amplify-migration |
| Terraform の適用を GitHub Actions へ移す（Amplify 移行の後に行う） | terraform-on-github-actions |
| Amplify 構成は branch を list で持ち、custom domain を branch ごとの sub domain の集合で持つ | amplify-migration |
| 「Amplify 移行」の完了時点で本番が正常に利用できる状態にする | amplify-migration |
| 旧構成の撤去までは rollback の手段を残す | amplify-migration |

## Dependency DAG

`amplify-migration -> terraform-on-github-actions`
