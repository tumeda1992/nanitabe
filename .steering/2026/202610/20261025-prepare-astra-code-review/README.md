# Astraによるコードレビュー

- 関連Issue: [#287](https://github.com/tumeda1992/nanitabe/issues/287)
- 作業ブランチ: `feature-287`
- レビュー対象コミット: `46ad16a84c2d4c0cc82d23136573ac139493215e`
- 現在の状態: 挙動維持の対象8件を適用済み（2026-10-27）。全体検証はimplementation_review.mdを参照。

## 目的と合意済み方針

Astraがリポジトリをレビューし、指摘を独立して参照・採否判断できる形で残す。
ユーザーが結果を確認し、見送るもの以外を採用する。適用はレビュー後の別工程とする。
今回の適用対象は、外部から観測できる振る舞いを維持するリファクタリングに限定する。
バグと思われる現状の挙動も、この工程では変更しない。

## 記録構成

- このファイル: レビュー方針、読む順番、確認済み範囲、指摘への索引。
- [commit-plan.md](./commit-plan.md): レビュー記録を共有するコミット計画。
- [implementation-commit-plan.md](./implementation-commit-plan.md): 適用差分のコミット計画と、コミット前の未完了事項。
- [implementation_review.md](./implementation_review.md): 各指摘の実装と自動テスト結果。
- [documentation-proposal.md](./documentation-proposal.md): 再発防止の文書更新案（未適用）。
- [coverage.md](./coverage.md): 確認した範囲、検証と未確認事項。
- [finding-template.md](./finding-template.md): 各指摘のテンプレート。
- [findings/](./findings/): `RV-001-具体的な英語の要約.md` の形式で、1指摘1ファイルを保存する。

1指摘は「独立して採否を判断できる改善」を単位とする。
複数ファイルにまたがっても一括で判断する改善は1指摘とし、同じファイルの別問題は分ける。
IDと保存先は作成後に固定し、採否・対応状況やカテゴリが変わっても移動・再採番しない。
依存関係がある場合は、関連指摘への相対リンクを記載する。

## レビュー時の記述

問題点は具体的なコードと影響を根拠に示す。改善案を出せる場合は、変更する責務と対象を具体的に書く。
安全な改善案を出せない場合は、推測で埋めず追加調査が必要な点を明記する。
対象はコミット・パス・関数やクラス名で特定し、行番号は対象コミットでの補助情報として使う。
このリポジトリは公開されているため、認証情報や非公開の構成情報を記録しない。

各指摘の「今回の適用対象」は、次から選ぶ。

- 対象: 振る舞いを維持する具体的な改善案と、その根拠がある。
- 対象外: 改善に振る舞いの変更が必要。
- 要調査: 振る舞いを維持できるか、または改善案が未確認。

戻り値、例外、I/O、処理順序、副作用、ログ、公開APIなど、影響する契約を指摘ごとに確認する。
性能やタイミングが契約に関係する箇所も明記する。「対象外」「要調査」は自動適用しない。

## 採否と適用

- 採否: `未判断` / `採用` / `見送り` / `保留`
- 対応状況: `未着手` / `対応中` / `完了`

レビュー時は採否を「未判断」、対応状況を「未着手」とする。
ユーザーの確認後、今回の適用対象で見送り・保留以外の指摘を「採用」へ更新する。
採否・対応状況の正本は各指摘ファイルとし、下の索引には状態を複製しない。
適用順は読む順番とは別に決め、指摘間の依存を確認したうえで、小さく独立した変更から検証する。

## 読む順番

1. `AGENTS.md`、README、対象領域の指示・設計文書・実行設定を確認する。
2. 主要なテストと外部との契約から、維持すべき振る舞いを把握する。
3. エントリーポイント、初期化、ルーティングを確認する。
4. 代表的なユースケースを、入口から業務処理、DB・外部APIなどの出口まで追い、関連テストを併読する。
5. 他のユースケース、異常系、共通処理へ広げ、確認済み範囲を更新する。

入口から業務処理・永続化まで追い、frontendの呼び出し元、関連テスト、CI・インフラ設定へ確認を広げた。
具体的な確認範囲と限界は [coverage.md](./coverage.md) を参照する。

## 指摘索引

全29件。今回の適用対象8件を採用・適用済み。対象外20件と要調査1件は未適用。採否・対応状況の正本は各指摘ファイル。
「対象外」は指摘を棄却する意味ではなく、振る舞いを変えない今回の適用工程から除外する意味である。
優先度は問題の影響であり、今回の適用順を表すものではない。

| 指摘 | 優先度 | 今回の適用対象 |
| --- | --- | --- |
| [RV-001: 料理入力変換が登録・食事登録・食事更新に重複](./findings/RV-001-duplicate-dish-input-conversion.md) | 中 | 対象 |
| [RV-002: 共通mutation処理がloadingとerrorを取得できない](./findings/RV-002-mutation-result-field-mismatch.md) | 中 | 対象外 |
| [RV-003: 任意GraphQL引数がRubyでは必須になっている](./findings/RV-003-optional-graphql-required-keyword.md) | 中 | 対象外 |
| [RV-004: 日付交換が他ユーザーの食事まで移動する](./findings/RV-004-swap-meals-user-scope.md) | 高 | 対象外 |
| [RV-005: 食事の更新・削除が操作ユーザーで絞り込まれない](./findings/RV-005-meal-mutation-ownership.md) | 高 | 対象外 |
| [RV-006: 料理・出典・タグ更新に所有者確認が不足する](./findings/RV-006-dish-mutation-ownership.md) | 高 | 対象外 |
| [RV-007: 枠マスタ更新・削除と枠エントリ削除に所有者確認がない](./findings/RV-007-frame-mutation-ownership.md) | 高 | 対象外 |
| [RV-008: パターン更新・削除が操作ユーザーを受け取らない](./findings/RV-008-pattern-mutation-ownership.md) | 高 | 対象外 |
| [RV-009: 検索の先頭固定料理だけユーザー条件を迂回する](./findings/RV-009-pinned-dish-query-ownership.md) | 高 | 対象外 |
| [RV-010: 枠割り当ての所有者確認が経路と関連IDによって抜ける](./findings/RV-010-frame-assignment-contract.md) | 高 | 対象外 |
| [RV-011: 料理編集で既存の手間レベルが未設定へ戻る](./findings/RV-011-dish-effort-level-lost-on-edit.md) | 高 | 対象外 |
| [RV-012: パターン作成・編集フォームの入力操作が二重実装されている](./findings/RV-012-duplicate-pattern-editor.md) | 中 | 対象 |
| [RV-013: 料理出典のGraphQL入力変換が複数resolverへ散在する](./findings/RV-013-duplicate-graphql-dish-conversion.md) | 中 | 対象 |
| [RV-014: 正規化辞書の登録・更新が同じ値変換を重複する](./findings/RV-014-duplicate-normalize-word-values.md) | 中 | 対象 |
| [RV-015: カレンダーモードの型がstringとanyへ広がっている](./findings/RV-015-calendar-mode-literal-types.md) | 中 | 対象 |
| [RV-016: 枠エントリの旧namespace実装と新実装が併存している](./findings/RV-016-legacy-frame-entry-namespace.md) | 中 | 要調査 |
| [RV-017: 料理検索のdebounce timerが全インスタンスで共有される](./findings/RV-017-shared-search-debounce-timer.md) | 中 | 対象外 |
| [RV-018: 延期確定で必要なキャッシュ初期化待ちが呼び出し元で失われる](./findings/RV-018-calendar-refresh-promise-chain.md) | 高 | 対象外 |
| [RV-019: ビルド検証workflow自身の変更が検出されない](./findings/RV-019-build-workflow-self-filter-typo.md) | 中 | 対象外 |
| [RV-020: デプロイwebhookのHTTPエラーが成功扱いになる](./findings/RV-020-deploy-webhook-http-failure.md) | 中 | 対象外 |
| [RV-021: 辞書の置換元が未エスケープの正規表現として評価される](./findings/RV-021-normalize-word-regexp-source.md) | 中 | 対象外 |
| [RV-022: 管理CRUDにアプリケーション側の認証・権限ガードがない](./findings/RV-022-admin-controller-authorization.md) | 高 | 対象外 |
| [RV-023: Terraform plan用roleがstate全体への書き込み権限を持つ](./findings/RV-023-plan-role-state-write-access.md) | 高 | 対象外 |
| [RV-024: 動作確認環境の起動途中失敗が自動停止なしの状態を残す](./findings/RV-024-review-start-rollback-gap.md) | 高 | 対象外 |
| [RV-025: 集約をまたぐ処理の配置について設計文書が矛盾する](./findings/RV-025-conflicting-domain-orchestration-docs.md) | 中 | 対象 |
| [RV-026: パターン一覧が親・子ごとに追加SQLを発行する](./findings/RV-026-pattern-query-n-plus-one.md) | 中 | 対象 |
| [RV-027: 未評価料理への評価作成が料理の所有者を確認しない](./findings/RV-027-evaluation-create-ownership.md) | 高 | 対象外 |
| [RV-028: Hostヘッダー制限を直接アクセスの防止として扱っている](./findings/RV-028-host-header-not-network-boundary.md) | 高 | 対象外 |
| [RV-029: 週・月カレンダーのURL日付解釈が二重実装されている](./findings/RV-029-duplicate-calendar-route-parser.md) | 低 | 対象 |

## 結果を見る順番と適用順の提案

まず認可・ユーザー間のデータ分離に関するRV-004〜010、RV-022、RV-027を確認する。
続いてデータ消失のRV-011と運用境界のRV-023・024・028を確認する。
これらは影響が大きいが振る舞いが変わるため、今回のリファクタリングには混ぜず、別途対応を判断する。

振る舞いを維持する8件は、次の順で小さく適用・検証することを提案する。これは必須依存順ではない。

1. RV-025: 設計文書の責務分担を揃える。
2. RV-015: カレンダーモードの型を明確にする。
3. RV-014: 正規化ワードの値変換を共通化する。
4. RV-013: backendの料理入力変換を共通化する。
5. RV-001: frontendの料理入力変換を共通化する。
6. RV-029: 週・月ページの日付パーサーを共通化する。
7. RV-012: パターン編集フォームを共通化する。
8. RV-026: 一覧の応答と順序を比較しながら関連取得をまとめる。

RV-016は動的参照と旧実装の利用を確認してから採否を判断する。
各項目の検証方法は実施済みテストではなく、適用時の検証計画である。

## 引き継ぎ

対象8件の実装と自動テストを実施済み。対象外20件と要調査1件の判断、再発防止の文書案の採否が残る。
レビュー記録は `feature-287` から `main` へのPRで共有し、採否や記述の修正を受け付ける。
全ファイルの逐行監査や稼働環境の安全性保証を意味するレビューではない。
