# 指摘適用の合意と実行記録

## 適用合意

2026-10-29、利用者の「それ終わったら全部指摘点修正して」をFR-001〜034の全件適用の合意として記録する。
従来の挙動維持だけの枠は今回の修正を制限しない。誤指摘・重複・調査で成立しない指摘は根拠付きで撤回し、修正済みと数えない。

## 完了条件

各指摘の必要な回帰テストを追加・更新し、関連テスト成功後にその指摘だけをコミットする。共有基盤が必要なら最初に必要とする指摘に含めて依存を記録する。最後に全体回帰とドキュメント更新案をまとめ、既存PRへpushする。

## 実行環境の障害

プラグインの取得は接続済みGitHub経由へ変更し復旧。消失した/tmpのcheckoutは/workspaceへ再配置した。
Dockerへの通常接続は権限拒否。権限要求が返らないため、呼出し全体を55秒で打ち切る制御を入れて状態確認中。テストを未実行のまま完了とはしない。

## 指摘ごとの状態

| 指摘 | 状態 | commit・検証 |
| --- | --- | --- |
| [FR-001: 管理CRUDに認証・管理権限の確認がない](findings/FR-001-admin-authorization.md) | 未着手 | 未実行 |
| [FR-002: 日付交換が他ユーザーの食事まで移動する](findings/FR-002-swap-user-scope.md) | 未着手 | 未実行 |
| [FR-003: 食事の更新・削除が所有者を検証しない](findings/FR-003-meal-mutation-ownership.md) | 未着手 | 未実行 |
| [FR-004: 料理・出典・一括タグの更新が所有者を検証しない](findings/FR-004-dish-source-tag-ownership.md) | 未着手 | 未実行 |
| [FR-005: 枠名変更・枠削除・枠エントリ削除がIDだけで実行される](findings/FR-005-frame-mutation-ownership.md) | 未着手 | 未実行 |
| [FR-006: パターン更新・削除は操作ユーザーを受け取らない](findings/FR-006-pattern-mutation-ownership.md) | 未着手 | 未実行 |
| [FR-007: 検索の先頭固定IDがユーザー条件を迂回する](findings/FR-007-pinned-dish-disclosure.md) | 未着手 | 未実行 |
| [FR-008: 枠割当の認可が入口ごとに異なり関連先の所有者を検証しない](findings/FR-008-frame-fill-ownership.md) | 未着手 | 未実行 |
| [FR-009: 他人の料理を自分の食事に登録すると内容を取得できる](findings/FR-009-foreign-dish-reference.md) | 未着手 | 未実行 |
| [FR-010: 他人の枠を自分のパターンへ登録して枠名を読める](findings/FR-010-foreign-frame-reference.md) | 未着手 | 未実行 |
| [FR-011: 未評価料理への評価作成が料理の所有者を確認しない](findings/FR-011-evaluation-ownership.md) | 未着手 | 未実行 |
| [FR-012: 省略可能なGraphQL引数がRubyでは必須になっている](findings/FR-012-optional-graphql-keywords.md) | 未着手 | 未実行 |
| [FR-013: 料理編集で既存の手間レベルを消してしまう](findings/FR-013-effort-level-reset.md) | 未着手 | 未実行 |
| [FR-014: 共通mutationがloadingとerrorを取得できない](findings/FR-014-mutation-state.md) | 未着手 | 未実行 |
| [FR-015: カレンダー更新完了を待つPromiseが途中で失われる](findings/FR-015-refresh-promise.md) | 未着手 | 未実行 |
| [FR-016: 検索debounceが別パネルとアンマウントをまたいで残る](findings/FR-016-search-timer.md) | 未着手 | 未実行 |
| [FR-017: パターンの枠を未選択へ戻すとNaNを送信する](findings/FR-017-pattern-placeholder.md) | 未着手 | 未実行 |
| [FR-018: 食事移動後も枠が旧日付の割当済み状態に残る](findings/FR-018-frame-meal-date.md) | 未着手 | 未実行 |
| [FR-019: 1食事を複数枠へ割り当てられhas_one契約が破れる](findings/FR-019-frame-meal-cardinality.md) | 未着手 | 未実行 |
| [FR-020: Nextの画面遷移で論理URLが更新されず日付がずれる](findings/FR-020-logical-history.md) | 未着手 | 未実行 |
| [FR-021: 日付URLが形式だけの検査で無効日付を画面へ渡す](findings/FR-021-calendar-invalid-date.md) | 未着手 | 未実行 |
| [FR-022: 食事編集で出典なしの新規料理を選ぶと送信契約に違反する](findings/FR-022-new-dish-without-source.md) | 未着手 | 未実行 |
| [FR-023: 正規化辞書の文字列を未エスケープの正規表現として扱う](findings/FR-023-dictionary-regexp.md) | 未着手 | 未実行 |
| [FR-024: 辞書更新と全料理への再反映が一体で保存されない](findings/FR-024-dictionary-partial-write.md) | 未着手 | 未実行 |
| [FR-025: 辞書削除後の反映失敗をrescue自身が別例外で隠す](findings/FR-025-dictionary-delete-rescue.md) | 未着手 | 未実行 |
| [FR-026: Terraform plan roleがstate全体を書き換えられる](findings/FR-026-plan-role-state-write.md) | 未着手 | 未実行 |
| [FR-027: 起動途中の失敗で自動停止なしの稼働状態が残る](findings/FR-027-startup-rollback.md) | 未着手 | 未実行 |
| [FR-028: Host制限を直接アクセス防止として扱っている](findings/FR-028-host-not-access-control.md) | 未着手 | 未実行 |
| [FR-029: デプロイWebhookのHTTPエラーを成功扱いする](findings/FR-029-deploy-webhook.md) | 未着手 | 未実行 |
| [FR-030: ビルドworkflow自身だけの変更で検証をskipする](findings/FR-030-build-filter.md) | 未着手 | 未実行 |
| [FR-031: 認証テストhelperの再ログイン分岐が存在しない引数を送る](findings/FR-031-auth-test-helper.md) | 対応中 | 連続要求・ユーザー切替の回帰テストと補助処理を変更。Docker実行待ち、未コミット |
| [FR-032: パターン作成・編集で入力schemaが重複している](findings/FR-032-pattern-schema-duplication.md) | 未着手 | 未実行 |
| [FR-033: パターンのGraphQL子入力変換が作成・更新に重複する](findings/FR-033-pattern-input-conversion.md) | 未着手 | 未実行 |
| [FR-034: 旧FrameEntryと現行Frame::Entryの実装が併存する](findings/FR-034-legacy-frame-entry.md) | 未着手 | 未実行 |
