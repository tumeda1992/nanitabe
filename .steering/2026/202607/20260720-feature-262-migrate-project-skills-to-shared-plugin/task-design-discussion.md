## 論点1: shared skill の正本と repository 固有設定の境界

**ステータス:** 決定

**提起の背景:** nanitabeはx_favoritesより前のlocal skill / agent定義を持つ。一方で、x_favoritesから移植・進化したshared pluginが存在するため、旧定義を残すと更新・実行の正本が揺れる。

### 議論の変遷

#### 事象の記述
- ユーザーはx_favoritesと同じく、repository内でskill群を定義せず`ai_agent_dev_skill_plugin`をlocal参照したいと依頼した。
- nanitabeには`.claude/skills`と`.claude/agents`が残り、Codexのproject-local marketplaceがない。

#### 原因の追跡
- なぜ: shared workflowのcopyがrepositoryに残ると、plugin版との更新時点が独立する。
- なぜ: host接続とrepository固有のURL・commandが同じlocal定義に混在している。
- なぜ: shared procedureとrepository contextの所有境界を分けていない。

#### 根本原因₀ + 提案₀
- **根本原因₀**: shared skillの正本、host接続、repository固有factが別々に管理されていない。
- **提案₀**:
  - 総論: shared手順はpluginへ一本化し、nanitabeにはmarketplace、AGENTS、context instance、host起動設定だけを残す。
  - 各論:
    - ルール: local plugin sourceはrepository-local marketplaceからsymlinkで解決し、shared skill本文の互換copyを残さない。
    - 適用例: `visual-inspector`のURLとartifact pathはcontext instanceに置き、検査手順はplugin skillから読む。

#### イテレーション1

##### 検証
- **観点**: x_favoritesのmarketplaceは既に同じshared checkoutを参照するが、nanitabe単独の導入経路にはならない。
- **弱点**: 個人の`x-favorite-plugins` marketplaceに依存すると、別環境でnanitabeを使う時にplugin接続が再現できない。

##### 修正先の判断
- **提案レベル**: repositoryごとにmarketplace名を分け、同じplugin sourceを参照する構成へ具体化する。

##### 根本原因1 + 提案1
- **根本原因1**: plugin sourceの共有とrepository所有の接続設定を混同している。
- **変更点**: `nanitabe-plugins` marketplaceを追加し、Codex CLIもそのmarketplaceからpluginを再導入する。
- **提案1（現時点）**:
  - 総論: sourceは共有、接続設定はnanitabe所有として分離する。
  - 各論:
    - ルール: `AGENTS.md`をroot instructionの正本とし、Claude Codeは`CLAUDE.md` symlinkを通じて同じ文書を読む。
    - 適用例: rootの会話方針は保持し、詳細なthink-through手順は`tumeda-dev:think-through`へ誘導する。

**決定:** ユーザーが具体的な移行範囲を承認した。shared plugin、repository-local marketplace、context instance、AGENTS / CLAUDE symlink、Claude Code設定の切替、旧定義退役、Codex CLI再導入を実施する。

**ネクストアクション:** tasklistに沿って実装・検証する。
