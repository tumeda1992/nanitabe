# 全指摘の適用tasklist

仕様の正本は同directoryのdesign.mdと各指摘file。利用者の全件適用指示で合意済み。完了条件は各指摘の修正・関連テスト成功・記録・指摘単位のcommitである。各項目の実行結果はapplication.mdと指摘fileへ残す。

## 指摘別作業

- [x] [FR-031: 認証テストhelperの再ログイン分岐が存在しない引数を送る](findings/FR-031-auth-test-helper.md)
  - 実装ecfcb96、追加2件・関連回帰570件成功。検証記録1ea7ef7。
- [ ] [FR-001: 管理CRUDに認証・管理権限の確認がない](findings/FR-001-admin-authorization.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-002: 日付交換が他ユーザーの食事まで移動する](findings/FR-002-swap-user-scope.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-003: 食事の更新・削除が所有者を検証しない](findings/FR-003-meal-mutation-ownership.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-004: 料理・出典・一括タグの更新が所有者を検証しない](findings/FR-004-dish-source-tag-ownership.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-005: 枠名変更・枠削除・枠エントリ削除がIDだけで実行される](findings/FR-005-frame-mutation-ownership.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-006: パターン更新・削除は操作ユーザーを受け取らない](findings/FR-006-pattern-mutation-ownership.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-007: 検索の先頭固定IDがユーザー条件を迂回する](findings/FR-007-pinned-dish-disclosure.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-008: 枠割当の認可が入口ごとに異なり関連先の所有者を検証しない](findings/FR-008-frame-fill-ownership.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-009: 他人の料理を自分の食事に登録すると内容を取得できる](findings/FR-009-foreign-dish-reference.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-010: 他人の枠を自分のパターンへ登録して枠名を読める](findings/FR-010-foreign-frame-reference.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-011: 未評価料理への評価作成が料理の所有者を確認しない](findings/FR-011-evaluation-ownership.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-012: 省略可能なGraphQL引数がRubyでは必須になっている](findings/FR-012-optional-graphql-keywords.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-013: 料理編集で既存の手間レベルを消してしまう](findings/FR-013-effort-level-reset.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-014: 共通mutationがloadingとerrorを取得できない](findings/FR-014-mutation-state.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-015: カレンダー更新完了を待つPromiseが途中で失われる](findings/FR-015-refresh-promise.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-016: 検索debounceが別パネルとアンマウントをまたいで残る](findings/FR-016-search-timer.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-017: パターンの枠を未選択へ戻すとNaNを送信する](findings/FR-017-pattern-placeholder.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-018: 食事移動後も枠が旧日付の割当済み状態に残る](findings/FR-018-frame-meal-date.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-019: 1食事を複数枠へ割り当てられhas_one契約が破れる](findings/FR-019-frame-meal-cardinality.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-020: Nextの画面遷移で論理URLが更新されず日付がずれる](findings/FR-020-logical-history.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-021: 日付URLが形式だけの検査で無効日付を画面へ渡す](findings/FR-021-calendar-invalid-date.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-022: 食事編集で出典なしの新規料理を選ぶと送信契約に違反する](findings/FR-022-new-dish-without-source.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-023: 正規化辞書の文字列を未エスケープの正規表現として扱う](findings/FR-023-dictionary-regexp.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-024: 辞書更新と全料理への再反映が一体で保存されない](findings/FR-024-dictionary-partial-write.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-025: 辞書削除後の反映失敗をrescue自身が別例外で隠す](findings/FR-025-dictionary-delete-rescue.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-026: Terraform plan roleがstate全体を書き換えられる](findings/FR-026-plan-role-state-write.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-027: 起動途中の失敗で自動停止なしの稼働状態が残る](findings/FR-027-startup-rollback.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-028: Host制限を直接アクセス防止として扱っている](findings/FR-028-host-not-access-control.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-029: デプロイWebhookのHTTPエラーを成功扱いする](findings/FR-029-deploy-webhook.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-030: ビルドworkflow自身だけの変更で検証をskipする](findings/FR-030-build-filter.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-032: パターン作成・編集で入力schemaが重複している](findings/FR-032-pattern-schema-duplication.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-033: パターンのGraphQL子入力変換が作成・更新に重複する](findings/FR-033-pattern-input-conversion.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。
- [ ] [FR-034: 旧FrameEntryと現行Frame::Entryの実装が併存する](findings/FR-034-legacy-frame-entry.md)
  - DoD: design契約に沿って改善案を適用し、当該回帰テストを実行して成功を確認する。採否・状態・検証結果を記録し、この指摘だけをcommitする。

## 最終検証と公開

- [ ] frontend全体・backend回帰・型検査・変更箇所lintを実行して成功する。
- [ ] 再発防止のdocument更新案を具体的なpathと内容で提案する。
- [ ] 全指摘の採否・状態・commit・検証が一致することを確認し、READMEの状態とPR本文を更新する。
- [ ] feature-287をpushし、既存PR #292で結果を読めることを確認する。

## 完了後のアクション

利用者はcommit/push/PR更新を許可済み。動作確認待ちや形式的な再承認を挟まない。未完了を完了扱いにしない。mergeや実環境変更は行わない。
