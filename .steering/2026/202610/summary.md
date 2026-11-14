# 2026年10月 Steering サマリー

## [20261024-apply-terraform-from-github-actions](./20261024-apply-terraform-from-github-actions/)

**概要:** `infrastructure/terraform/envs/prod` と `envs/review` の適用を手元から GitHub Actions へ移し、PR で plan の差分を読み `main` への merge で apply される形にする。誰が apply するかを毎回判断せず、適用の履歴を PR と workflow に残し、apply が利用者と agent の往復にならないようにするためである。prod と review の state へ書き込むのは Actions だけとし、手元では module をローカル実行で確かめる spike だけを別の state で行う。

**ステータス:** 未完了

---

## [20261024-host-production-on-aws-amplify](./20261024-host-production-on-aws-amplify/)

**概要:** 学習を兼ねて自前で組んだ frontend の配信基盤（Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild）は、Amplify Hosting が managed に提供しているものと同じだった。この自前構成を Amplify Hosting へ移して保守対象を減らし、今後の動作確認環境を自前構成の複製ではなく branch の追加で作れる土台にする。現行の CodeBuild は build 中の apt で特定の version を取得できず本番 build が失敗しており、本番 deploy が止まっているため移行を急ぐ。作業は二段に分ける。先に「Amplify 移行」で本番配信を Amplify へ移して旧構成を撤去し、本番 build の停止を解消する。続く「Terraform の Actions 移行」で、Terraform の適用を手元から GitHub Actions へ移す。

**ステータス:** 完了

---

## [20261024-migrate-frontend-hosting-to-amplify](./20261024-migrate-frontend-hosting-to-amplify/)

**概要:** 親 design（`../20261024-host-production-on-aws-amplify/design.md`）で合意した Amplify 移行を実行する。この design は新しい設計判断を持たず、親 design の該当 section を正本として参照し、実行に必要な順序と停止点だけを tasklist へ渡す。終了時には本番 frontend が custom domain で Amplify から配信され、旧構成の resource と定義が残らない。

**ステータス:** 完了

---

## [20261025-operate-review-environment](./20261025-operate-review-environment/)

**概要:** `main` へ入れる前の変更を、PC 以外の端末から画面の操作で確かめられるようにする。backend の review 環境が API 単体で行っている確認を画面まで広げるため、frontend の動作確認環境を Amplify で立て、backend の review 環境を向かせる。本番の backend は向かない。

**ステータス:** 未完了

---

## [20261025-prepare-astra-code-review](./20261025-prepare-astra-code-review/)

**概要:** 20261025-prepare-astra-code-review（概要抽出不可、design.md 参照）

**ステータス:** 完了

---

## [20261027-full-repository-review](./20261027-full-repository-review/)

**概要:** 20261027-full-repository-review（概要抽出不可、design.md 参照）

**ステータス:** 完了

---

## [20261030-exhaustive-review](./20261030-exhaustive-review/)

**概要:** 20261030-exhaustive-review（概要抽出不可、design.md 参照）

**ステータス:** 完了

---
