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
| [FR-001: 管理CRUDに認証・管理権限の確認がない](findings/FR-001-admin-authorization.md) | 対応中 | Basic認証実装とspecを作成。green受付不能、未検証のWIPとして現状保存。CSRF強化は設計確定・未実施 |
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
| [FR-031: 認証テストhelperの再ログイン分岐が存在しない引数を送る](findings/FR-031-auth-test-helper.md) | 完了 | ecfcb96。Dockerで追加2件と関連回帰570件が成功 |
| [FR-032: パターン作成・編集で入力schemaが重複している](findings/FR-032-pattern-schema-duplication.md) | 未着手 | 未実行 |
| [FR-033: パターンのGraphQL子入力変換が作成・更新に重複する](findings/FR-033-pattern-input-conversion.md) | 未着手 | 未実行 |
| [FR-034: 旧FrameEntryと現行Frame::Entryの実装が併存する](findings/FR-034-legacy-frame-entry.md) | 未着手 | 未実行 |

## 環境復旧とFR-031検証（2026-10-30）

GitHub連携の許可対象追加によりpluginのpushとPR作成が成功。隔離テストコンテナを再開し、FR-031の追加2 examples・関連回帰570 examplesが成功した。残る33件は未完了であり、全件完了とはしない。

## FR-001の実行ブロック（2026-10-30）

管理基底に環境変数によるBasic認証を置き、両管理controllerの継承と既存認証済みCRUD用のテスト補助、新規認可specを作成した。新規認可specは未認証・誤認証・未設定・不正Basicヘッダーを検証する。今回のredは実行できておらず、旧レビューの未認証GET成功の実測だけを修正前根拠とした。

指定green commandは親でも上限45秒で試行したが、session ID/exit/stdoutを取得できず、開始時のredirect logも作成されなかった。親で1回再試行しても同じ結果であり、host上のRuby/RSpec processも観測されなかった。成功を確認できないためFR-001は未完了、アプリ変更は未コミットのまま凍結する。残るFR-002〜030・032〜034の32件へは進めていない。

確定した追加設計: 管理基底だけでCSRFを例外拒否にし、認証をprependする。認証済みでtokenを欠くPOST/PATCH/DELETEの拒否と、正規フォームtoken付き操作の成功を検証する。一般GraphQLの動作は変えない。このCSRF追加はまだ実装していない。

復旧後は、同時実行が残っていないことを確認し、CSRF追加とそのspecを作成したうえで次のgreenを実行する。

`docker exec -e RAILS_ENV=test nanitabe-review-tests-backend-1 bundle exec rspec spec/requests/admin spec/system/admin/food/dish/word/normalize_words_spec.rb`

同じ受付不能の要求を無制限に再送せず、実行環境の復旧を確認してから再開する。

## 利用者指定による現状保存（2026-10-30）

利用者の「nanitabeはこの時点でコミットpushして、リトライやれそうならやってむりそうなら諦めて教えて」に従い、FR-001の実装途中・未検証の変更と実行記録をWIPコミットで保存して既存PRへpushする。これは指摘解消のコミットではなくチェックポイントであり、FR-001の完了判定は変更しない。CSRF対応は未実装。保存後に実行環境と既存処理の状態を確認し、可能ならテストを再試行する。

## FR-001保留と残りの再開（2026-10-30）

利用者の「FR001以外直せよ」に従いFR-001のみ保留する。FR-002〜030・032〜034の32件を順に修正・検証し、指摘単位でコミットする。FR-001の完了を依存条件にしない。

## 利用者指定の現状共有（2026-10-30）

利用者の「今の状態でコミットしてpushして」に従い、FR-002の修正途中と回帰テスト、FR-001保留の記録、3回目レビューの成果物をWIPとして保存する。FR-002のテスト呼出しは応答未取得であり、成功・完了とは扱わない。FR-001は保留、他の未対応指摘も完了に変更しない。
