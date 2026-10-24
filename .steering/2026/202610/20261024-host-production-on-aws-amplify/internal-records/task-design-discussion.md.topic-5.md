# 内部検討記録: 論点5 — Amplify が監視する branch の移り方

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点5

## 開始context

論点3の手順 (1) で Amplify app を作るとき、どの git branch を監視させ、いつ `main` へ移すか。

- 問題: Amplify は監視 branch に `amplify.yml` が無いと build できない。作業中の `amplify.yml` は `feature-258` にしかなく、`main` には無い。
- 決める範囲: 監視 branch の移り方と、`main` へ途中で merge する内容。
- 既決条件: 論点1〜4。branch・PR・issue の対応は plugin の `development_flow/branch_pr_issue.md` と、`.agents/skills/tumeda-dev-plugin-context.md` の Git / GitHub 公開条件（`feature-<issue番号>` 形式、PR は `main` へ）。
- 残る不足: 途中 merge が既存の自動処理へ与える影響。

<a id="iteration-0"></a>

## イテレーション0: 監視 branch の移り方

<a id="iteration-0-record-1"></a>

### 調査: x_favorites の移り方と、`main` への merge が起こす自動処理

- x_favorites は、Amplify app を作業 branch（`feature-22`）の監視で作って確認した後、`amplify.yml` だけを `main` から切った branch 経由で `main` へ入れ、`main` を `branch_names` へ追加して確認し、最後に作業 branch を外した（x_favorites の `20260906-deploy-amplify-with-terraform/implementation_review.md`）。`branch_name` の差し替えは resource の再作成になるため、追加してから外す順序を採った。
- nanitabe で `main` へ merge すると、旧 CodePipeline が `main` を監視して build を起動する（`frontend/terraform/modules/cicd/codepipeline/main.tf` の `BranchName = var.branch`、値は `main`）。この build は現在 apt の取得で失敗している（issue #258）ため、Lambda は更新されない。あわせて `backend-deploy.yml` が backend の deploy webhook を呼ぶ。backend の差分が無ければ backend の挙動は変わらない。
- `development_flow/branch_pr_issue.md` は、既定 branch 上でしか確認できない仕組みのための途中 merge を「経路 2」とし、`Closes` を付けず、同じ issue に属する派生 branch（推奨形式 `issue-<番号>-<説明>`）で立てるとしている。nanitabe の context は公開可能な branch を `feature-<issue番号>` 形式と宣言しており、派生形式は宣言されていない。

<a id="iteration-0-record-2"></a>

### 判断: 監視 branch の移り方

- 評価軸: `amplify.yml` の試行錯誤で `main` を汚さない。本番の custom domain は最初から `main` の build に向ける。
- 推奨: x_favorites と同じ移り方。途中 merge の branch 名は `feature-258-amplify-build-config` とする。context の宣言（`feature-<issue番号>`）から issue 番号を一意に引ける形を保ったまま、本線 `feature-258` と区別するためである。
- 代償: 途中 merge で旧 CodePipeline と backend の deploy webhook が一度起動する。どちらも本番の挙動を変えない。
