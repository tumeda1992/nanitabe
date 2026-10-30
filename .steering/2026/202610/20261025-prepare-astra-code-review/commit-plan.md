# レビュー記録のコミット計画

- 作成日: 2026-10-26
- 対象repository: `tumeda1992/nanitabe`
- branch: `feature-287`（比較先: `main`）
- 計画時のHEADとremote main: `46ad16a84c2d4c0cc82d23136573ac139493215e`
- 計画時の差分: staged/unstagedのtracked変更はなし。この作業ディレクトリのみuntracked。
- 依頼: コミット計画を立ててコミットし、PRでレビュー記録を共有する。
- 使用手順: [plan-commits](https://github.com/tumeda1992/ai_agent_dev_skill_plugin/blob/main/plugins/tumeda-dev/skills/plan-commits/SKILL.md)、[share-work-in-progress](https://github.com/tumeda1992/ai_agent_dev_skill_plugin/blob/main/plugins/tumeda-dev/skills/share-work-in-progress/SKILL.md)。指定されたshare-in-progressの現行名称は後者。

## 1. レビュー結果を独立して参照・採否判断できる記録として保存する

- コミットメッセージ: `レビュー29件と採否判断用の索引を記録する`
- 仕事: Gitに未保存のレビューを、29件の個別指摘・索引・確認範囲・記録規約の揃った成果物にする。指摘の修正実装は含めない。
- 対象: このディレクトリのREADME.md、coverage.md、finding-template.md、commit-plan.md、findings/RV-001〜029と既存の.gitkeep。
- 取り消す効果: 今回のレビュー記録一式が消える。アプリケーション、インフラ、CI、既存の作業記録は残る。
- 依存・制約: 対象コミットのコードに対するレビューである。索引の件数・リンク・適用順は個別指摘に依存するため同時に保存する。1件ごとの採否は各ファイルで独立して更新できる。採否と修正実装の履歴は後続工程とする。

## 境界と検証

今回はレビュー成果物の保存という意味単位の1コミットとする。ファイル種類や確認した順序による分割はしない。
アプリの変更が混在していないこと、ID・必須項目・リンク・件数の整合と差分の空白を確認する。
中間版の再構成・revert試験は行わない。アプリのテスト・動的再現は未実施であり、詳細はcoverage.mdに記載する。

コミット後、未コミット変更がない状態で共有手順へ進む。追加のWIP/空コミットは不要。
feature-287を通常pushし、同じheadのopen PRがあれば再利用、なければmain向けに作成する。mergeは行わない。
