# タスクリスト: nanitabe の project skill を共有 plugin へ移行する

## フェーズ1: repository-local plugin 接続

- [x] `nanitabe-plugins` marketplaceとlocal symlinkの仕組みを追加する。
  - DoD: marketplace JSONが`tumeda-dev`のlocal sourceを指し、symlinkがshared checkoutを解決する。
- [x] repository context instanceを作成する。
  - DoD: template構造を保ち、path / commandが現存する文書または`docker-compose.yml`と一致する。

## フェーズ2: host 設定を共有 plugin へ切り替える

- [x] root durable instructionを`AGENTS.md`に集約し、`CLAUDE.md`をsymlinkにする。
  - DoD: backend / frontendの入口、会話方針、`tumeda-dev:think-through`の案内があり、両hostが同じ本文を読む。
- [x] Claude Codeのpermission / hooksをplugin名へ更新する。
  - DoD: 既存Stop / PreToolUse hookを保持し、SessionStart / UserPromptSubmit hookがshared think-throughを案内する。
- [x] 旧local skill / agent定義を退役する。
  - DoD: `.claude/skills`と`.claude/agents`の旧定義がなく、project設定に旧path / agent参照が残らない。

## フェーズ3: Codex marketplace 再導入と静的検証

- [x] nanitabe marketplaceをCodex CLIに登録し、`tumeda-dev`を再導入する。
  - DoD: CLI一覧で`nanitabe-plugins`と`tumeda-dev@nanitabe-plugins`が表示され、そのpathがlocal symlinkを経由する。
- [x] 設定を静的検証する。
  - DoD: marketplace JSONがparseでき、symlink / manifestを解決でき、旧参照が検出されない。

## 非対象

- アプリケーションコード、`.codex/rules/default.rules`、既存frontendの未コミット変更には触れない。
- commit / push / PRは行わない。
