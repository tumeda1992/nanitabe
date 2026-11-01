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
| [FR-001: 管理CRUDに認証・管理権限の確認がない](findings/FR-001-admin-authorization.md) | 保留 | Basic認証実装とspecを作成。green受付不能、未検証のWIPとして現状保存。CSRF強化は設計確定・未実施 |
| [FR-002: 日付交換が他ユーザーの食事まで移動する](findings/FR-002-swap-user-scope.md) | 完了 | 2026-11-01: Dockerで18 examples成功、変更箇所lint成功。commitは下記 |
| [FR-003: 食事の更新・削除が所有者を検証しない](findings/FR-003-meal-mutation-ownership.md) | 完了 | 開発用Composeで関連31 examples成功、変更3ファイルlint成功 |
| [FR-004: 料理・出典・一括タグの更新が所有者を検証しない](findings/FR-004-dish-source-tag-ownership.md) | 完了 | 追加3件のred確認後、関連41 examples成功、変更4ファイルlint成功 |
| [FR-005: 枠名変更・枠削除・枠エントリ削除がIDだけで実行される](findings/FR-005-frame-mutation-ownership.md) | 完了 | 追加4件red後、関連19 examples成功、変更4ファイルlint成功 |
| [FR-006: パターン更新・削除は操作ユーザーを受け取らない](findings/FR-006-pattern-mutation-ownership.md) | 完了 | 追加6件中4件red後、関連24 examples成功、変更7ファイルlint成功 |
| [FR-007: 検索の先頭固定IDがユーザー条件を迂回する](findings/FR-007-pinned-dish-disclosure.md) | 完了 | 固定関連5件中1件red後、関連34 examples成功、変更2ファイルlint成功 |
| [FR-008: 枠割当の認可が入口ごとに異なり関連先の所有者を検証しない](findings/FR-008-frame-fill-ownership.md) | 完了 | 追加16件中13件red後、関連50 examples成功、変更7ファイルlint成功 |
| [FR-009: 他人の料理を自分の食事に登録すると内容を取得できる](findings/FR-009-foreign-dish-reference.md) | 完了 | 不正関連付けと一覧漏洩をred確認後、関連179 examples成功、変更8ファイルlint成功 |
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

## ローカルでの再開（2026-11-01）

利用者の「.steering/2026/202610 の*-review系…レビュー指摘後の反映をしていって」を、既存レビューの未対応指摘の適用指示として受領した。旧RVは対応するFRで追跡し二重修正しない。CR-001〜004も反映対象とする。FR-001だけは既存の明示保留を維持する。レビュー担当Astraと今回の適用担当gpt-6.1-solを区別する。

開始HEAD: `affd7ec1eb9105e27795bcc9ecbdd4f9071af628`。既存の`.gitignore`と`frontend/src/lib/generateApiOrigin.ts`の未コミット変更を適用差分に含めない。作業directoryは既存の本directoryと`../20261030-exhaustive-review`を再利用する。各directory内のtemporary-overrides候補は存在しない。

Docker権限を取得し、外部ネットワークなし・実環境env_fileなし・`RAILS_ENV=test`の専用コンテナを起動した。FR-002のCommand・GraphQL・旧Commandの関連18 examplesは成功。変更3ファイルのRuboCopは違反なし。FR-002のWIPを検証済みとして確定し、利用者ID必須の取得APIで再発を防止した。FR-003以降は各指摘の依存順で実施し、FR-018/019の枠整合性は認可とは別commitで扱う。

## セッション再起動のための中断（2026-11-01）

利用者がautoモード反映のためセッション再起動を希望したため、新しい修正を停止した。FR-002は`03e4828`で確定済み。FR-003は`backend/spec/graphql/mutation/meal/ownership_spec.rb`を作成し、専用Dockerで6 examples / 3 failuresを確認した。別利用者の食事に対する通常更新・削除・新規料理付き更新が拒否されず失敗し、不在IDの3ケースは成功した。これは問題を再現するredであり、修正完了ではない。アプリ実装は未変更、追加specは未コミットで保存している。

再開位置はFR-003。`UpdateCommand`と`RemoveCommand`の取得を操作利用者で絞り、新規料理付き更新の認可失敗で副作用が残らないことを確認する。その後に上記specと関連既存spec、変更箇所lintを成功させ、記録とFR-003単独commitへ進む。FR-001の保留は維持する。

今回のテスト環境は`/tmp/nanitabe-review-compose.yml`。backend/frontend専用サービスを起動済みで、既存イメージと作業treeを使い、外部ネットワークを無効化、実環境のenv_fileを読み込まない。backendは`RAILS_ENV=test`、SQLiteを使用する。frontendは起動のみでテストは未実行。実行中のRSpecは終了した。

次回の関連テスト受付コマンド: `docker compose -f /tmp/nanitabe-review-compose.yml exec -T backend bundle exec rspec spec/graphql/mutation/meal/ownership_spec.rb`。DockerとGitへの書込みはsandboxの権限が必要。再起動後に設定fileとコンテナ状態を確認してから実行する。

## ローカルの実行条件訂正（2026-11-01）

利用者から「sqliteにしたのはcodexのcloud環境だったから」と訂正を受けた。Cloud向け専用Compose・DB方式をローカルでも必須と扱った判断を取り消し、designの実行条件を既存開発用Composeへ置き換えた。`config/database.yml`のtest設定は従来からSQLiteで、今回変更していない。

追加したテスト用Composeのfrontend依存取得はタイムアウトし、Jestは旧依存のTypeScript設定エラーで未実行だった。取得処理を停止し、追加したbackend/frontendコンテナとネットワークを終了した。既存の開発用backendを使いFR-003の関連RSpecを再開した。frontendの既存node_modulesおよびロックファイルを変更していない。作業中に現れた`frontend/Dockerfile`の別作業の変更も今回のcommitから除外する。

## FR-003の適用完了（2026-11-01）

更新・削除の取得に操作ユーザーの条件を追加。初回green実行で既存の不存在例外契約1件が失敗し、例外を維持する形に修正してから関連31 examples / 0 failuresと変更3ファイルのRuboCop違反なしを確認した。詳細と再実行commandはFR-003の指摘fileに保存した。FR-002の適用commitは`03e4828`。FR-003を独立commitにして次はFR-004へ進む。

## FR-004の適用完了（2026-11-01）

料理・出典・タグ追加の所有者確認を追加し、他人IDの3操作を拒否する。混在した一括タグ追加の副作用rollbackを検証した。関連41 examples / 0 failures、変更4ファイルRuboCop違反なし。FR-003のcommitは`f440ac4`。FR-004を独立commitにし、次はFR-005の枠の所有者確認へ進む。

## FR-005の適用完了（2026-11-01）

枠改名・削除・エントリ削除を所有者に限定し、枠の利用状況より先に認可する。追加4件red確認後、関連19 examples / 0 failures、変更4ファイルRuboCop違反なし。FR-004のcommitは`8adcbd6`。次はFR-006のパターン更新・削除へ進む。

## FR-006の適用完了（2026-11-01）

パターンの更新・削除で認証利用者を必須にし、親子の変更前に認可する。関連24 examples / 0 failures、変更7ファイルRuboCop違反なし。FR-005のcommitは`f7b3e68`。次はFR-007の検索先頭固定IDへ所有者条件を追加する。

## FR-007の適用完了（2026-11-01）

検索先頭固定IDにも所有者条件を追加。関連34 examples / 0 failures、変更2ファイルRuboCop違反なし。FR-006のcommitは`d34ce8c`。次はFR-008の枠割当と関連先の認可へ進む。

## FR-008の適用完了（2026-11-01）

枠エントリ・枠マスタ・食事の所有者を割当前に確認し、旧割当Commandは現行へ委譲する。全3登録経路の拒否時rollbackと既存本人操作を含め50 examples / 0 failures、変更7ファイルRuboCop違反なし。FR-007のcommitは`3751b09`。次はFR-009の食事から料理への関連先認可へ進む。

## FR-009の適用完了（2026-11-01）

料理関連付けPolicyへ利用者IDを必須化し、登録・更新・延期の全経路で適用する。既存越境関連は一覧で非表示とし削除しない。関連179 examples / 0 failures、変更8ファイルRuboCop違反なし。FR-008のcommitは`a2ca053`。次はFR-010のパターンから枠への関連先認可へ進む。
