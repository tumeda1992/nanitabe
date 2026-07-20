# Design: nanitabe の project skill を共有 plugin へ移行する

## 元の依頼内容

~/src/github.com/tumeda1992/x_favorites について、元々ClaudeCodeをメインで使っていたのを、Codexも使えるように設定し .steering/2026/202607/20260720-feature-16-migrate-project-skills-to-shared-plugin ではskill群をリポジトリで定義するのではなく ~/src/github.com/tumeda1992/ai_agent_dev_skill_plugin のプラグインをローカルで参照するようにした。同じことをしたい。x_favorites のskillsは nanitabeのskillsをコピーした後に進化させたから互換性があるはず

## 1. TL;DR

nanitabe 内の Claude Code 専用 skill / agent 定義を、共有 plugin `tumeda-dev` の利用へ移行する。repository は marketplace 接続、durable instruction、repository固有contextだけを保持し、手順の正本を `ai_agent_dev_skill_plugin` に一本化する。Codex CLI と ChatGPT desktop app のいずれでもrepository-local marketplaceから導入できる状態にする。

## 前提とする既存仕様

- root `CLAUDE.md` は backend / frontend の入口、会話方針、詳細な思考・skill 手順を持つ。
- `.claude/skills/` と `.claude/agents/` は旧 local workflow の定義を持つ。
- shared plugin は `tumeda-dev` manifest、9 skill、context templateを持つ。
- `docker-compose.yml` は `frontend` / `backend` サービスと frontendの `18100` を定義する。

## 2. 要件

### MUST

- `tumeda-dev` を nanitabe の local marketplace から参照できる。
- Codex は `AGENTS.md`、Claude Code は同一内容への `CLAUDE.md` symlink を読む。
- 旧 shared skill / agent 本文をrepositoryから退役する。
- 文書、command、UI検査環境などのrepository固有factをcontext instanceにだけ記録する。
- Codex CLIでnanitabe marketplaceからpluginを再導入し、解決先を確認する。

### 非目標

- shared plugin 本体、アプリケーションコード、Docker / test設定、`.codex/rules/default.rules`、既存frontend変更の編集。
- commit、push、PR作成。

### 受け入れ基準

- marketplace sourceがshared checkoutへのlocal symlinkを解決する。
- Codex CLIで`nanitabe-plugins`と`tumeda-dev@nanitabe-plugins`が表示される。
- project設定に旧 `.claude/skills` path、旧agent definitionへの参照がない。
- contextの全path・commandが現存する文書または設定で検証できる。

## 3. 完成後の姿

### 3-1. 操作フロー

1. 開発者がnanitabeを開くと、root `AGENTS.md` がshared pluginとbackend / frontendの詳細instructionを案内する。
2. CodexまたはChatGPT desktop appは`.agents/plugins/marketplace.json`から`tumeda-dev`を発見し、local symlinkがshared checkoutを解決する。
3. skillがrepository固有情報を必要とするとき、`maintenance-plugin-context`がcontext instanceの該当sectionと明示された共通項目だけを渡す。
4. Claude Codeは`CLAUDE.md` symlinkを通じて同じroot instructionを読み、hookから短いthink-through reminderを受け取る。
5. shared skillを更新する時はplugin checkoutを更新し、marketplace経由で再導入する。nanitabeにcopyを作らない。

### 3-2. データモデル

アプリケーションデータ、DB schema、API payloadの変更はない。永続する設定は次の3種類だけである。

| 成果物 | 例 | 意味 |
| --- | --- | --- |
| marketplace entry | `source.path: ./.agents/plugins/local_plugin_sym_links/ai_agent_dev_skill_plugin/` | shared pluginのlocal source |
| context instance | `visual-inspector → http://localhost:18100` | repository固有の確認済みfact |
| instruction | `tumeda-dev:think-through` | 常時適用する共有手順 |

### 3-3. 命名・公開API・モジュール境界

- `nanitabe-plugins` はnanitabe所有のmarketplace名であり、既存`x-favorite-plugins`と区別する。
- `tumeda-dev` はshared plugin manifestのidentifierであり、変更しない。
- `.agents/plugins/` はplugin接続だけ、`.agents/skills/tumeda-dev-plugin-context.md` はrepository固有factだけを持つ。
- `AGENTS.md` はdurable instructionの入口であり、shared skill手順を再コピーしない。

### 3-4. docs・設定・環境構築系 deliverable

- `.agents/plugins/marketplace.json`: `nanitabe-plugins`とlocal `tumeda-dev` source。
- `.agents/plugins/marketplace.sample.json`、`local_plugin_sym_links/.gitignore`: remote sourceの見本とcheckout固有symlinkの非追跡規則。
- `.agents/skills/tumeda-dev-plugin-context.md`: backend / frontendのinstruction、architecture、Docker、test、lint、UI検査の確認済みfact。
- `AGENTS.md`と`CLAUDE.md`: plugin正本への誘導、会話方針、backend / frontend入口。後者は前者へのrelative symlink。
- `.claude/settings.json`とhooks: plugin skill permissionと短いthink-through injection。既存安全hookは保持。

## 4. 設計判断

- shared手順をpluginだけに置く。local copyを残すとx_favorites由来の進化とnanitabe旧版が再び乖離する。
- Codexのrepository instructionは`AGENTS.md`を正本にし、Claude Codeにはsymlinkで同じ内容を提供する。
- marketplace名をrepositoryごとに分ける。同一sourceを使っても接続設定を独立させ、別環境での再現性を確保する。
- context instanceには現存する文書と設定で確認した値だけを書く。

### 代替案と棄却理由

- **旧 `.claude/skills` とagentを残す**: 正本が不明になりshared plugin改善を取り込めない。
- **x_favorites の個人marketplaceだけを使う**: nanitabe単独の導入経路にならない。
- **repository固有値をplugin本文へ書く**: 他repositoryのURL・command・文書を誤参照する。

## 5. リスクと対策

| リスク | 対策 |
| --- | --- |
| local symlinkがない環境でsourceを解決できない | remote source sampleとlocal symlink手順を残す |
| Codexがx_favoritesのcacheを使う | nanitabe marketplaceから再導入しCLI一覧のpathを確認する |
| 常時作法が消える | hookをplugin名に更新し、削除前に旧path参照を検索する |
| 既存の利用者変更を巻き込む | `.codex/rules/default.rules`とfrontend変更は編集しない |

## 6. テスト方針

- JSONを`jq`でparseする。
- symlinkとplugin manifestを解決する。
- `rg`で旧skill path / agent definition参照が残らないことを確認する。
- Codex CLIでmarketplaceとinstalled pluginを確認する。
- アプリケーションコードを変更しないため、backend / frontend test suiteは実行しない。

## 付録: 変更点一覧

- root: `AGENTS.md`を追加し、`CLAUDE.md`をsymlinkへ置換する。
- Claude Code: settings / think-through hooksを更新し、旧skills / agentsを削除する。
- plugin: marketplace、local symlink仕組み、context instanceを追加する。
