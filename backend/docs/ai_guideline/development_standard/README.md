このディレクトリには開発ガイドラインが載っています

- Webアプリケーション・APIアーキテクチャ方針 @application_architecture.md
- 自動テスト・テストファースト方針 @testing.md
- dockerコマンド実行方針 @docker.md
- コードフォーマット方針 @formatting.md

## リポジトリ非依存の共通標準

命名やエンティティ設計など、**このリポジトリの事情に依存しない標準**はここに置かない。`tumeda-dev` plugin の正本リポジトリが持つ。

- 入口: `plugins/tumeda-dev/docs/README.md`（正本リポジトリの位置は repository root の `AGENTS.md` を参照）
- 開発標準の群: `plugins/tumeda-dev/docs/development_standards/`

判断の問い: **「この規則は、他のリポジトリでもそのまま成立するか」**

- 成立する → plugin 側の標準を参照する。ここへ複製しない
- このリポジトリ固有の前提（Rails / Next.js の構成、docker 運用、既存モジュール階層）が必要 → ここへ書く

MUST: plugin 側の標準を直接編集しない。修正提案が生じたら `tumeda-dev:escalate-plugin-skill-fix` を起動し、正本リポジトリで扱う。利用先の `.agents/plugins/` 配下は install cache であり、直接編集しても次の再installで失われ、正本にも反映されない。
