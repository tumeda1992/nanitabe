# tumeda-dev plugin context

## think-through

参照する共通項目: [プロジェクト指示](#プロジェクト指示)

## design-consult

参照する共通項目: [アーキテクチャ文書](#アーキテクチャ文書)

## doc-enricher

参照する共通項目: [プロジェクト指示](#プロジェクト指示)、[アーキテクチャ文書](#アーキテクチャ文書)、[公開範囲](#公開範囲)

## task-design

参照する共通項目: [プロジェクト指示](#プロジェクト指示)、[アーキテクチャ文書](#アーキテクチャ文書)、[開発規約](#開発規約)、[テスト方針](#テスト方針)、[全体 test command](#全体-test-command)、[全体 lint command](#全体-lint-command)、[公開範囲](#公開範囲)

### UI 確認環境

- 対象アプリ: `http://localhost:18100`
- UI の目視確認は `visual-inspector` skill を child として使う。`npx playwright` と Playwright tool の直接呼び出しは `frontend/docs/ai_guideline/forbidden-actions.md` で禁止されている。

### Git / GitHub 公開条件

- remote: `origin` の URL は `git@github.com:setsumaru1992/nanitabe.git` だが、GitHub 側の実体は `tumeda1992/nanitabe` である（リダイレクトされる）。push や PR の出力に現れるのは `tumeda1992/nanitabe` 側。`git remote -v` の値だけを見て repository を判断しない。
- default branch: `main`。commit と push を default branch へ直接行わない。
- 公開可能な branch: `feature-<issue番号>` 形式の non-default branch。
- PR: `feature-<issue番号>` から `main` へ作成する。branch 名の番号は同じ番号の GitHub Issue に対応する。
- merge 後の main の commit title には `(#PR番号)` が付く（squash merge 運用）。
- 公開範囲の制約は [公開範囲](#公開範囲) を参照する。

## steering

参照する共通項目: [プロジェクト指示](#プロジェクト指示)、[アーキテクチャ文書](#アーキテクチャ文書)、[開発規約](#開発規約)、[テスト方針](#テスト方針)、[全体 test command](#全体-test-command)、[全体 lint command](#全体-lint-command)、[公開範囲](#公開範囲)

### GitHub

- `origin` は GitHub の `tumeda1992/nanitabe` を指す。

### Branch / issue 契約

- `feature-<issue番号>` branch は、同じ番号の GitHub Issue に対応する。

## visual-inspector

参照する共通項目: [プロジェクト指示](#プロジェクト指示)

### アプリ接続

- 対象アプリ: `http://localhost:18100`

### 検査環境

- browser 設定: `.claude/mcp/playwright/config.jsonc`
- script / screenshot / result の保存先: `frontend/inspect/visual/tmp/`

## tasklist-executor

参照する共通項目: [プロジェクト指示](#プロジェクト指示)、[アーキテクチャ文書](#アーキテクチャ文書)、[開発規約](#開発規約)、[テスト方針](#テスト方針)、[全体 test command](#全体-test-command)、[全体 lint command](#全体-lint-command)、[公開範囲](#公開範囲)

## test-runner

参照する共通項目: [プロジェクト指示](#プロジェクト指示)、[テスト方針](#テスト方針)、[全体 test command](#全体-test-command)

## 共通

### プロジェクト指示

- `AGENTS.md`: repository全体の入口、会話方針、shared pluginの利用規則。
- `backend/CLAUDE.md` と `frontend/CLAUDE.md`: 各アプリケーション固有の指示。
- `backend/docs/ai_guideline/README.md` と `frontend/docs/ai_guideline/README.md`: 開発ガイドラインの入口。

### 公開範囲

- この repository は public である。`.steering/` 配下も tracked であり、design / tasklist / discussion がそのまま公開される。
- repository へ commit する document には、実際の domain 名を書かない。`frontend/terraform/envs/prod/main.tf` が `custom_domain = "nanitabe.${var.route53_name}"` と変数化しているのと同じ扱いにし、document では `<hosted zone>` と表記して `.env` の `ROUTE53_HOSTZONE_NAME` を参照する形にする。
- 本番環境と DB が動いている場所、および開発環境がそれを共有しているかは、repository へ commit する document へ書かない。判断に迷う構成情報はユーザーへ確認する。

### アーキテクチャ文書

- `backend/docs/ai_guideline/development_standard/application_architecture.md`: backendの責務境界と設計方針。
- `frontend/docs/ai_guideline/development_standard/application_architecture.md`: frontendの配置・責務方針。

### 開発規約

- `backend/docs/ai_guideline/development_standard/docker.md`: backendのcontainer内実行方針。
- `frontend/docs/ai_guideline/development_standard/docker.md`: frontendのcontainer内実行方針。
- `backend/docs/ai_guideline/development_standard/formatting.md` と `frontend/docs/ai_guideline/development_standard/formatting.md`: format / lint方針。

### テスト方針

- `backend/docs/ai_guideline/development_standard/testing.md`: RSpecのtest-first・container内実行方針。
- `frontend/docs/ai_guideline/development_standard/testing.md`: Jestのtest-first・container内実行方針。

### 全体 test command

- `docker compose exec backend bundle exec rspec`
- `docker compose exec frontend yarn test`

### 全体 lint command

- `docker compose exec backend bundle exec rubocop`
- `docker compose exec frontend yarn lint`
