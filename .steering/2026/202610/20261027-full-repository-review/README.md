# 適用後リポジトリ全体のゼロベースレビュー

- 対象: `tumeda1992/nanitabe` の現行コード全体。直近差分だけのレビューではない。
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df` (`feature-287`)
- 実施日: 2026-10-27
- 状態: 主要経路のレビュー・指摘記録完了。修正は未実施。

## 結論

現行コードには、ユーザー間のデータ分離が破れる問題と、通常操作で保存値・表示の整合性が崩れる問題が残っている。全体を問題なしとは判定しない。

34件を記録した。P1=15件、P2=17件、P3=2件。P1は優先対応が必要なデータ漏洩・他人のデータ変更・情報消失・運用境界の問題、P2は通常の修正対象、P3は保守性改善である。P0（即時事故の実証）は確認していない。

まず読むべき指摘:

1. [FR-009](findings/FR-009-foreign-dish-reference.md): 他人の料理を自分の食事へ登録すると料理名を取得できる。実測済み。
2. [FR-002](findings/FR-002-swap-user-scope.md): 日付交換が他人の食事まで移動する。
3. [FR-001](findings/FR-001-admin-authorization.md): 管理CRUDに認証・管理権限の確認がない。未認証GET成功を実測。
4. [FR-013](findings/FR-013-effort-level-reset.md): 料理名だけの編集でも手間レベルが消える。
5. [FR-018](findings/FR-018-frame-meal-date.md): 食事移動後、元の日の枠が見えなくなる。実測済み。

## 読み方・適用方針

1指摘1ファイル。各ファイルに問題、具体的根拠、改善案、挙動維持の可否、検証方法を記した。採否の正本は個別ファイルとする。

「対象外」は従来合意の**振る舞いを変えない適用枠から外れる**という意味であり、レビュー対象から外した・修正不要という意味ではない。認可やデータ損失を直す作業は、純粋なリファクタリングと別に優先判断する。

前回の採用/保留を結論として引き継がず、現行の入口・呼び出し先・保存処理を再確認した。重複する観点は旧IDを併記した。前回適用した8件を再び未対応として数えてはいない。新規観点と残存問題を同じ索引に並べた。

## 指摘索引

| 指摘 | 優先度 | 振る舞い維持枠 | 根拠 |
| --- | --- | --- | --- |
| [FR-001: 管理CRUDに認証・管理権限の確認がない](findings/FR-001-admin-authorization.md) | P1 | 対象外 | 実測＋静的 |
| [FR-002: 日付交換が他ユーザーの食事まで移動する](findings/FR-002-swap-user-scope.md) | P1 | 対象外 | 静的 |
| [FR-003: 食事の更新・削除が所有者を検証しない](findings/FR-003-meal-mutation-ownership.md) | P1 | 対象外 | 静的 |
| [FR-004: 料理・出典・一括タグの更新が所有者を検証しない](findings/FR-004-dish-source-tag-ownership.md) | P1 | 対象外 | 静的 |
| [FR-005: 枠名変更・枠削除・枠エントリ削除がIDだけで実行される](findings/FR-005-frame-mutation-ownership.md) | P1 | 対象外 | 静的 |
| [FR-006: パターン更新・削除は操作ユーザーを受け取らない](findings/FR-006-pattern-mutation-ownership.md) | P1 | 対象外 | 静的 |
| [FR-007: 検索の先頭固定IDがユーザー条件を迂回する](findings/FR-007-pinned-dish-disclosure.md) | P1 | 対象外 | 静的 |
| [FR-008: 枠割当の認可が入口ごとに異なり関連先の所有者を検証しない](findings/FR-008-frame-fill-ownership.md) | P1 | 対象外 | 静的 |
| [FR-009: 他人の料理を自分の食事に登録すると内容を取得できる](findings/FR-009-foreign-dish-reference.md) | P1 | 対象外 | 実測＋静的 |
| [FR-010: 他人の枠を自分のパターンへ登録して枠名を読める](findings/FR-010-foreign-frame-reference.md) | P1 | 対象外 | 実測＋静的 |
| [FR-011: 未評価料理への評価作成が料理の所有者を確認しない](findings/FR-011-evaluation-ownership.md) | P1 | 対象外 | 静的 |
| [FR-012: 省略可能なGraphQL引数がRubyでは必須になっている](findings/FR-012-optional-graphql-keywords.md) | P2 | 対象外 | 静的 |
| [FR-013: 料理編集で既存の手間レベルを消してしまう](findings/FR-013-effort-level-reset.md) | P1 | 対象外 | 静的 |
| [FR-014: 共通mutationがloadingとerrorを取得できない](findings/FR-014-mutation-state.md) | P2 | 対象外 | 静的 |
| [FR-015: カレンダー更新完了を待つPromiseが途中で失われる](findings/FR-015-refresh-promise.md) | P2 | 対象外 | 静的 |
| [FR-016: 検索debounceが別パネルとアンマウントをまたいで残る](findings/FR-016-search-timer.md) | P2 | 対象外 | 静的 |
| [FR-017: パターンの枠を未選択へ戻すとNaNを送信する](findings/FR-017-pattern-placeholder.md) | P2 | 対象外 | 実測＋静的 |
| [FR-018: 食事移動後も枠が旧日付の割当済み状態に残る](findings/FR-018-frame-meal-date.md) | P2 | 対象外 | 実測＋静的 |
| [FR-019: 1食事を複数枠へ割り当てられhas_one契約が破れる](findings/FR-019-frame-meal-cardinality.md) | P2 | 対象外 | 実測＋静的 |
| [FR-020: Nextの画面遷移で論理URLが更新されず日付がずれる](findings/FR-020-logical-history.md) | P2 | 対象外 | 実測＋静的 |
| [FR-021: 日付URLが形式だけの検査で無効日付を画面へ渡す](findings/FR-021-calendar-invalid-date.md) | P2 | 対象外 | 静的 |
| [FR-022: 食事編集で出典なしの新規料理を選ぶと送信契約に違反する](findings/FR-022-new-dish-without-source.md) | P2 | 対象外 | 静的 |
| [FR-023: 正規化辞書の文字列を未エスケープの正規表現として扱う](findings/FR-023-dictionary-regexp.md) | P2 | 対象外 | 実測＋静的 |
| [FR-024: 辞書更新と全料理への再反映が一体で保存されない](findings/FR-024-dictionary-partial-write.md) | P2 | 対象外 | 静的 |
| [FR-025: 辞書削除後の反映失敗をrescue自身が別例外で隠す](findings/FR-025-dictionary-delete-rescue.md) | P2 | 対象外 | 静的 |
| [FR-026: Terraform plan roleがstate全体を書き換えられる](findings/FR-026-plan-role-state-write.md) | P1 | 対象外 | 静的 |
| [FR-027: 起動途中の失敗で自動停止なしの稼働状態が残る](findings/FR-027-startup-rollback.md) | P1 | 対象外 | 静的 |
| [FR-028: Host制限を直接アクセス防止として扱っている](findings/FR-028-host-not-access-control.md) | P1 | 対象外 | 静的 |
| [FR-029: デプロイWebhookのHTTPエラーを成功扱いする](findings/FR-029-deploy-webhook.md) | P2 | 対象外 | 静的 |
| [FR-030: ビルドworkflow自身だけの変更で検証をskipする](findings/FR-030-build-filter.md) | P2 | 対象外 | 静的 |
| [FR-031: 認証テストhelperの再ログイン分岐が存在しない引数を送る](findings/FR-031-auth-test-helper.md) | P2 | 対象 | 実測＋静的 |
| [FR-032: パターン作成・編集で入力schemaが重複している](findings/FR-032-pattern-schema-duplication.md) | P3 | 対象 | 静的 |
| [FR-033: パターンのGraphQL子入力変換が作成・更新に重複する](findings/FR-033-pattern-input-conversion.md) | P3 | 対象 | 静的 |
| [FR-034: 旧FrameEntryと現行Frame::Entryの実装が併存する](findings/FR-034-legacy-frame-entry.md) | P2 | 要調査 | 静的 |

## 確認範囲と証拠

[coverage.md](coverage.md)に領域別の確認内容・未確認範囲を記した。[evidence/README.md](evidence/README.md)に追加検証の手順と結果を記した。

既存frontend 215件とbackend food domain/GraphQL 568件は通過した。しかし追加検証では現行の問題を再現したため、既存テストの成功を品質承認の根拠にはしていない。レビューの成果は上の指摘であり、テストは補助証拠である。
