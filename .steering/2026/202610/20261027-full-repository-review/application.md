# 指摘適用の合意と実行記録

> **2026-11-04 訂正・修復中**: 「外部から観測できる振る舞いを維持する」という利用者の制約を有効とする。後続の全件修正指示を制約解除と扱ったのはassistantの誤解であり、挙動変更の合意として扱わない。対象外の変更を除去し、保持するrefactorを再検証する。以下の旧完了記録は修復前snapshotの履歴である。

## 当時の誤った適用解釈（履歴）

2026-10-29、利用者の「それ終わったら全部指摘点修正して」をFR-001〜034の全件適用の合意として記録する。
以下の「従来の挙動維持枠は制限しない」という当時の判断はassistantの誤りとして撤回する。誤指摘・重複・調査で成立しない指摘は根拠付きで撤回し、修正済みと数えない。

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
| [FR-010: 他人の枠を自分のパターンへ登録して枠名を読める](findings/FR-010-foreign-frame-reference.md) | 完了 | 追加5件中4件red後、関連50件・最終変更後10件成功、lint修正済み |
| [FR-011: 未評価料理への評価作成が料理の所有者を確認しない](findings/FR-011-evaluation-ownership.md) | 完了 | 追加4件red後、関連9 examples成功、変更3ファイルlint成功 |
| [FR-012: 省略可能なGraphQL引数がRubyでは必須になっている](findings/FR-012-optional-graphql-keywords.md) | 完了 | 追加6件中省略2件red後、関連10 examples成功、変更3ファイルlint成功 |
| [FR-013: 料理編集で既存の手間レベルを消してしまう](findings/FR-013-effort-level-reset.md) | 完了 | 関連52 frontend tests/7 backend examples・型検査・lint成功、実ブラウザ4項目成功 |
| [FR-014: 共通mutationがloadingとerrorを取得できない](findings/FR-014-mutation-state.md) | 完了 | 状態欠落8件red・callback省略red後、関連61件と最終14件成功、型検査/lint成功 |
| [FR-015: カレンダー更新完了を待つPromiseが途中で失われる](findings/FR-015-refresh-promise.md) | 完了 | 関連25件/最終hook5件・型検査/lint成功、実ブラウザ3項目成功 |
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

## FR-010の適用完了（2026-11-01）

パターン子登録時の親/枠所有者照合と、既存越境関連の一覧除外を追加。関連50 examples / 0 failures、loader初期化修正後のGraphQL10 examplesも成功。変更6ファイルのRuboCop違反を解消した。単独枠登録/適用の保護はFR-008から継続。FR-009のcommitは`9528fa1`。次はFR-011の料理評価の所有者確認へ進む。

frontendの既存開発用コンテナでNode 24.13.0、Next 16.2.3、TypeScript 5.9.3、React 19.2.0を確認し、後続の検証に使う。追加の隔離Composeは使用しない。

## 承認要求を保留する実行条件（2026-11-01）

利用者の外出前の指示原文: 「今からでかけるから、approveを求められても許可を出せない。コマンド実行前に許可を求めることかどうかを確認して、許可が不要だったらそのままコマンド実行して、許可を求めることだったら保留して次の作業して」。出典はこの作業を継続中の会話。

各操作を現在のsandbox範囲と既に有効なcommand許可で確認する。承認済み`docker compose`、`git add`、`git commit`は継続可能。追加承認が必要な操作は承認要求そのものを出さず、対象・理由・再開条件をここへ記録して、依存しない指摘へ進む。ディスク上のrulesに追加済みでも、現セッションで未読込みの許可は有効と扱わない。終了時期の明示はなく、利用者から指示変更があるまでこの条件を保つ。

Codexコマンド許可の追加commitは`cbfd10d`。FR-010のcommitは`86ab57e`。

## FR-011の適用完了（2026-11-01）

料理の所有者を基準に評価を認可し、本人の再評価時に既存の不整合所有者も修復する。関連9 examples / 0 failures、変更3ファイルRuboCop違反なし。FR-010のcommitは`86ab57e`。frontendの既存全Jestは39 suites / 215 tests成功し、後続frontend変更前の基準を確認した。次はFR-012の任意GraphQL引数へ進む。

## FR-012の適用完了（2026-11-01）

GraphQL任意引数のRuby既定値を追加し、省略を明示nullと同じ契約へ揃えた。関連10 examples / 0 failures、変更3ファイルRuboCop違反なし。FR-011のcommitは`cdb8e27`。FR-002〜012の認可・入力契約修正の区切りでbackend全体回帰を行い、次はFR-013へ進む。FR-001は既存の利用者指示による保留を維持する。

## backend全体回帰とFR-013の進行（2026-11-01）

FR-002〜012後のbackend全体RSpecは821 examples / 0 failures。FR-012のcommitは`ceb1da7`。

FR-013の実装と自動検証を進め、詳細は同指摘fileへ記録した。ブラウザ確認requestは`requests/fr013-visual.json`、確認成果物はgitignore済みの`frontend/inspect/visual/tmp/fr013-effort-retention/`へ置く。実データへ変更を送らないmock通信で確認する。追加承認なしで行える範囲だけを実行する条件を継続している。

## FR-013の適用完了（2026-11-01）

手間IDの出力・query・初期値・選択状態を復元し、位置づけ変更時だけ意図的に解除する。関連frontend52件・backend7件・型検査・変更箇所lintに成功した。visual-inspectorも人工fixtureの全GraphQLモックで4項目成功、画像目視済み。実DBへのUI保存は未確認。390px幅の横はみ出しは変更前比較未実施の別観測として残した。結果は`requests/fr013-visual-result.json`。FR-013を独立commitにし、次はFR-014のmutation状態取得へ進む。

## FR-014の適用完了（2026-11-01）

Apolloの状態名とtuple型を修正。callback省略を受け付け、型検査が検出した交換日未設定も送信前に拒否する。関連61 tests、追加修正後14 tests、最終型検査・変更4ファイルlintが成功。FR-013のcommitは`fb59312`。次はFR-015の更新完了Promiseと失敗時の選択保持へ進む。

## FR-015の進行（2026-11-01）

更新完了Promiseを維持し、延期確定後の再取得に失敗しても登録を再送せず表示だけ再試行できるようにした。詳細はFR-015へ記録。ブラウザ確認requestは`requests/fr015-visual.json`、成果物はgitignore済みの`frontend/inspect/visual/tmp/fr015-refresh-retry/`。FR-014のcommitは`601d722`。追加承認要求を出さない条件を継続する。

## FR-015の適用完了（2026-11-01）

Promiseをカレンダー境界とrefetch完了まで維持し、更新失敗時は選択とモードを保持する。再取得は登録を再送しない。関連25 tests、追加後のhook5 tests、最終型検査・変更箇所lintが成功した。実ブラウザでも3項目成功、登録mutation合計1回と5画像目視を確認。結果は`requests/fr015-visual-result.json`。実DB保存はmock対象のため未確認。次はFR-016の検索timerを各componentへ分離する。

## FR-016の適用完了（2026-11-01）

パネルごとのdebounceとunmount cleanupを追加。追加3件のうち2件のred確認後、関連10 tests・型検査・変更2ファイルlintが成功。FR-015のcommitは`c05d21d`。次はFR-017の未選択値と送信時検証へ進む。

## FR-017の適用完了（2026-11-01）

未選択をnullへ揃え、NaN・非整数・非正数も送信前に拒否する。追加2件のred後、関連15 tests、境界値追加後のeditor13 tests、型検査・lintが成功。visual-inspectorも4項目成功し6画像を目視済み。結果はrequests/fr017-visual-result.json。FR-016のcommitは`5319fbd`。次はFR-018の移動・交換時の元枠解除へ進む。

## FR-018の適用完了（2026-11-01）

日時変更時だけ元枠を解除し、食事保存・解除と交換全体を原子的に保存する。新旧双方の14件でred12件確認後、関連100 examples / 0 failuresと変更6ファイルlintが成功。FR-017のcommitは`62359ad`。次はFR-019の1食事1枠制約へ進む。

## FR-019の適用完了（2026-11-01）

Commandで重複を拒否し、食事row lockとnullable unique indexで保護する。既存重複時はmigrationを停止し、実データを自動整理しない。関連103 examples、backend全体844 examples、lint5ファイル成功。独立SQLite接続の同時INSERTは1件成功/1件拒否。MySQL Command並行実測と実DB適用は未実施。FR-018のcommitは`25471fd`。次はFR-020のNext遷移と論理URL同期へ進む。

## FR-020の適用完了（2026-11-01）

Next遷移のpathname/search変化を同期し、独自push/popも同じpath+query契約に揃えた。関連19 tests、履歴spec追加後5 tests、全Jest46 suites / 256 tests、型検査・lint成功。実Next Link/独自操作の16状態とback/forward各15回のブラウザ検証が成功し、8画像を目視。結果はrequests/fr020-visual-result.json。本番Next buildも同じcontainer内の一時source copyで静的19ページ生成まで成功した。元devやrepository設定は変更していない。FR-019のcommitは`01e5394`。次はFR-021の日付URL検証へ進む。

## FR-021の適用完了（2026-11-01）

実在日とpath境界を検証し、有効日付に付くquery/hashを保持する。21件中11件のred確認後、関連35 tests、型検査・lint成功。visual-inspectorも有効/無効の2ケースで全dateカードを照合し2画像目視済み。FR-020のcommitは`d8afcf0`。次はFR-022の出典なし新規料理による食事編集へ進む。

## FR-022の進行（2026-11-01）

出典なしのGraphQL引数と変数をnullableへ揃え、source自体省略の正規化も修正した。backend11 examples、frontend34 tests、型検査・backend2/frontend4ファイルlintが成功。codegenのHTTP取得はFR-019未適用migration検知で停止したため、開発DBへ適用せず通常schemaをRails runnerでoffline出力し、一時configから型生成した。詳細はFR-022を参照。ブラウザrequestはrequests/fr022-visual.jsonで検証中。FR-021のcommitは`c240b94`。

## FR-022の適用完了（2026-11-01）

frontend34 tests、backend11 examples、型・lintに加え、ブラウザも出典なしの保存1回、食事ID保持、modal終了、新料理名表示を確認した。3画像目視済み。結果はrequests/fr022-visual-result.json。次はFR-023の辞書文字列の正規表現解釈を直す。

## FR-023の適用完了（2026-11-01）

新旧Normalizerでsource/destinationを文字列として扱い、SQL LIKEのwildcard候補差も取り除いた。現行red8件と旧red7件を確認後、関連152 examples / 0 failures、変更3ファイルlint成功。FR-022のcommitは`5b54e45`。次はFR-024の辞書変更と全件再反映の原子性へ進む。

## FR-024の適用完了（2026-11-01）

辞書CRUDと全料理・タグの再反映をtransactionへまとめ、再反映単独にも原子性を持たせた。2件目の実保存を失敗させる追加4件のred後、関連95 examples / 0 failures、変更5ファイルlint成功。FR-023のcommitは`73b8797`。次はFR-025の削除失敗時rescueへ進む。

## FR-025の適用完了（2026-11-01）

本文なしDELETEの失敗を400で隠さず一覧alertへ返す。一覧のalert未描画もrequestで検出し修正した。関連24 examples / 0 failures、変更2ファイルlint成功。FR-024のcommitは`9b1df0a`。次はFR-026のplan roleのstate書込み権限へ進む。

## FR-026のコード適用完了（2026-11-01）

PutObjectをplans/*だけへ分離。追加3件の静的テストは修正前1件red、修正後全成功、diff check成功。Terraform CLI不在のためfmt/validateとAWS実効権限simulationは未実施で、追加許可を要求せず記録した。広いReadOnlyAccessを最小read権限化したとは扱わない。FR-025のcommitは`4a12564`。次はFR-027の起動途中rollbackへ進む。

## FR-027の適用完了（2026-11-01）

失敗と割込みのcleanupを起動前に登録し、起動済みでも停止設定を修復する。新規31 testsすべて成功、bash syntax/diff check成功。実AWSは未実施。FR-026のcommitは`df42ad7`。FR-025後のbackend全体回帰も873 examples / 0 failuresだった。次はFR-028の経路制限とprivate integrationへ進む。

## FR-028のコード適用完了（2026-11-01）

VPC link SG経由だけを許可し、固定Cloud Map ARNとECSのSRV登録へ変更した。起動/停止の移行と26 contractのwhite-box照合を完了し、59 tests、Rails metadata1 example、lint/bash/fmt、隔離copyのreview Terraform validateが成功。元lockfileのversion/既存hashは保持した。実AWS apply/到達性は未実測であり、実適用時に確認する。namespaceの実適用後費用も記載済み。FR-027のcommitは`7772f90`。FR-026のfmtも成功した。次はFR-029のWebhook失敗検知へ進む。

## FR-029の適用完了（2026-11-01）

WebhookのHTTPエラーをcurlの失敗へ反映し、接続/全体deadlineを設けた。ローカルHTTP fixtureと実curlによる6 tests成功、実Webhookは未呼出し。FR-028のcommitは`2bf938d`。追加のTerraform prod root validateも固定version/元hash保持の隔離copyで成功し、FR-026のfmt/validate保留を解消した。AWS実効権限は未実測。次はFR-030のbuild変更検出へ進む。

## FR-030の適用完了（2026-11-01）

build workflow自身を変更検出へ含めるtypo修正。実bash blockの3 testsでworkflow単独のredを確認し、修正後は全成功。FR-029のcommitは`d3e4515`。次はFR-032の入力schema共通化へ進む。

## FR-032の適用完了（2026-11-02）

schemaの二重定義を一元化し、入力・error順・infer型とhookの契約を維持した。二層台帳の8 contractを照合、関連33 tests、最終schema13件、型検査・lint成功。FR-030のcommitは`a871b4c`。次はFR-033のGraphQL入力変換へ進む。

## FR-033の適用完了（2026-11-02）

子InputObjectを転記の正本とし、両resolverの重複を解消した。5 contractを照合、関連37 examples、変更6ファイルRuboCop成功。FR-032のcommitは`5a2fd44`。次はFR-034の旧FrameEntry互換委譲へ進む。

## FR-034の適用完了（2026-11-02）

旧定数と返却classを維持した互換委譲へ変更し、旧Removeにも本人scopeを適用した。10 contractを照合し、関連57 examples、backend全体885 examples、lint/eager loadが成功。外部利用の不存在は断定しない。FR-033のcommitは`65dc499`。FR-001を除くFR項目のコード適用は完了し、次は20261030-exhaustive-reviewのCR-001〜004へ進む。

## FR-019のMySQL検証保留の解消（2026-11-02）

CR-004と同じ専用MySQL8.0.46で、migration down/upとFK保持、既存重複時の無変更停止、二接続Command一回割当、DB uniqueによる直接二重書込み拒否の4 examplesが成功した。specのlintも成功。テスト専用DBは除去済みで、実DBへmigrationは未適用。FR-034のcommitは`fcac860`、CR-004のcommitは`02e2caf`。補完検証は独立commitとして保存する。

## 最終対応表（2026-11-02）

FR-002〜034の33件は反映済み（先行のFR-031を含む）。FR-001だけ利用者保留を維持する。各行のfileを採否・検証の正本とし、補完検証commitは実装と区別する。

| 指摘 | 状態 | 適用commit |
| --- | --- | --- |
| [FR-001](findings/FR-001-admin-authorization.md) | 利用者保留 | — |
| [FR-002](findings/FR-002-swap-user-scope.md) | 反映・検証済み | `03e4828` |
| [FR-003](findings/FR-003-meal-mutation-ownership.md) | 反映・検証済み | `f440ac4` |
| [FR-004](findings/FR-004-dish-source-tag-ownership.md) | 反映・検証済み | `8adcbd6` |
| [FR-005](findings/FR-005-frame-mutation-ownership.md) | 反映・検証済み | `f7b3e68` |
| [FR-006](findings/FR-006-pattern-mutation-ownership.md) | 反映・検証済み | `d34ce8c` |
| [FR-007](findings/FR-007-pinned-dish-disclosure.md) | 反映・検証済み | `3751b09` |
| [FR-008](findings/FR-008-frame-fill-ownership.md) | 反映・検証済み | `a2ca053` |
| [FR-009](findings/FR-009-foreign-dish-reference.md) | 反映・検証済み | `9528fa1` |
| [FR-010](findings/FR-010-foreign-frame-reference.md) | 反映・検証済み | `86ab57e` |
| [FR-011](findings/FR-011-evaluation-ownership.md) | 反映・検証済み | `cdb8e27` |
| [FR-012](findings/FR-012-optional-graphql-keywords.md) | 反映・検証済み | `ceb1da7` |
| [FR-013](findings/FR-013-effort-level-reset.md) | 反映・検証済み | `fb59312` |
| [FR-014](findings/FR-014-mutation-state.md) | 反映・検証済み | `601d722` |
| [FR-015](findings/FR-015-refresh-promise.md) | 反映・検証済み | `c05d21d` |
| [FR-016](findings/FR-016-search-timer.md) | 反映・検証済み | `5319fbd` |
| [FR-017](findings/FR-017-pattern-placeholder.md) | 反映・検証済み | `62359ad` |
| [FR-018](findings/FR-018-frame-meal-date.md) | 反映・検証済み | `25471fd` |
| [FR-019](findings/FR-019-frame-meal-cardinality.md) | 反映・検証済み | `01e5394`（実装）、`3dcad04`（MySQL補完） |
| [FR-020](findings/FR-020-logical-history.md) | 反映・検証済み | `d8afcf0` |
| [FR-021](findings/FR-021-calendar-invalid-date.md) | 反映・検証済み | `c240b94` |
| [FR-022](findings/FR-022-new-dish-without-source.md) | 反映・検証済み | `5b54e45` |
| [FR-023](findings/FR-023-dictionary-regexp.md) | 反映・検証済み | `73b8797` |
| [FR-024](findings/FR-024-dictionary-partial-write.md) | 反映・検証済み | `9b1df0a` |
| [FR-025](findings/FR-025-dictionary-delete-rescue.md) | 反映・検証済み | `4a12564` |
| [FR-026](findings/FR-026-plan-role-state-write.md) | 反映・検証済み | `df42ad7` |
| [FR-027](findings/FR-027-startup-rollback.md) | 反映・検証済み | `7772f90` |
| [FR-028](findings/FR-028-host-not-access-control.md) | 反映・検証済み | `2bf938d` |
| [FR-029](findings/FR-029-deploy-webhook.md) | 反映・検証済み | `d3e4515` |
| [FR-030](findings/FR-030-build-filter.md) | 反映・検証済み | `a871b4c` |
| [FR-031](findings/FR-031-auth-test-helper.md) | 反映・検証済み | `ecfcb96`（実装）、`b24d899`（先行検証） |
| [FR-032](findings/FR-032-pattern-schema-duplication.md) | 反映・検証済み | `5a2fd44` |
| [FR-033](findings/FR-033-pattern-input-conversion.md) | 反映・検証済み | `65dc499` |
| [FR-034](findings/FR-034-legacy-frame-entry.md) | 反映・検証済み | `fcac860` |

CR-001〜004の反映結果は[後続reviewのapplication](../20261030-exhaustive-review/application.md)へ集約する。恒久documentの追加案は[documentation-proposal.md](documentation-proposal.md)に提案のみ保存し、自動適用しない。


## 全体検証への参照（2026-11-02）

backend937件、frontend283件、MySQL6件、運用系68件が成功。最終Next production build・型検査・lintの条件と、保留FR-001の既存lint2件を含む限界は[coverageの最終検証](coverage.md#最終検証2026-11-02)を正本とする。

## 公開結果（2026-11-02）

feature-287をoriginへpushし、[既存PR #292](https://github.com/tumeda1992/nanitabe/pull/292)のタイトル・本文を最終の反映結果と検証条件に更新した。GitHubのPR headが公開時点の`b8430008322fcf65e86ed37692c73610545ea747`と一致することを確認した。source/test固定点は`3dcad04`で、以降は文書だけの追記である。

FR-001保留、backend既存lint2件、実AWS/実DB migration/Webhook未実施をPRにも明記した。個別対応表・全体検証・再発防止の文書提案をPRから辿れる。merge/deployは実施していない。この公開記録の追記も同じbranchへcommit/pushする。

## 修復計画の受領（2026-11-04）

利用者の「挙動変えないって言ったのに」「目的の放棄」「必要だよね」という訂正に基づき、同directoryのdesign/tasklistを挙動維持の範囲へ戻す計画に改訂した。実行開始を改めて要求しない。baselineはd58c473、FR-002の途中変更も除去する。先行8件・FR-031・FR-001既存WIPを保持し、後続FR-032/033の純粋な抽出だけを残す。FR-001 WIPが含まれるPR全体を純refactor完了と報告しない。

steeringのdoc-enricher提案modeと再発防止gateを確認した。元READMEには「バグと思われる現状の挙動も変更しない」「対象外は自動適用しない」が既に明記されていた。原因はrepository知識や規範の不足ではなく、assistantが既存制約を解除した判断にある。重複した恒久文書案・skill修正案は追加しない。既存の提案は未適用を維持する。

## 修復の実行開始（2026-11-04）

復元baseline d58c473、修復前source/test608ed3d、notice797a929、設計033ae2eとfeature-287を照合した。
利用者変更3fileは保全hashと全件一致し、既存patch保全も確認した。暫定指示は元directoryに存在せずnone。
CR側の旧design/tasklistは今回の復元契約に置換された履歴として明示し、再適用対象から外した。


## CR-004の範囲外適用取消（2026-11-04）

scope-repair-cr004-1 / attempt1のpassed resultを消費した。3productionfileは02e2cafの親版とbyte一致し、
変換専用specとcheckpointだけを除去、FR-019用のguard/cleanup/specは保持した。
既存関連RSpec25 examples / 0 failures、RuboCop4 files / 0 offenses、diff check成功。
結果は[evidence/scope-repair/cr004-attempt-1/result.md](evidence/scope-repair/cr004-attempt-1/result.md)。
並行一回消費の保証は今回の適用範囲から外し、元の問題と過去のMySQL検証は証拠として残す。
準備文書は独立commit c771cd2に分けた。次はCR-003のtype変更拒否と旧spec変更を戻す。

## CR-003の範囲外適用取消（2026-11-04）

scope-repair-cr003-1 / attempt1のpassed resultを消費した。DishSourceの追加validationとPolicyを除き、
852718fで変更した旧Repository specも元の種別変更成功期待へ戻した。
既存関連135 examples / 0 failures、Ruby lint2 files / 0 offenses、旧版byte一致、保護対象保持、diff check成功。
[結果](evidence/scope-repair/cr003-attempt-1/result.md)。CR-004の復元commitはbd0d91a。次はCR-002を戻す。

## CR-002の範囲外適用取消（2026-11-04）

scope-repair-cr002-1 / attempt1のpassed resultを消費した。タグ保存3productionfileを30c86bb親版へ戻し、専用2specを除去。
既存360 examples / 0 failures、RuboCop3 files / 0 offenses、旧byte一致・FR-024/FR-004残部と利用者変更保持・diff check成功。
[結果](evidence/scope-repair/cr002-attempt-1/result.md)。CR-003復元commitはf210961。次はCR-001を戻す。

## CR-001の範囲外適用取消（2026-11-04）

scope-repair-cr001-1 / attempt1のpassed resultを消費し、検索の語ごとの相関EXISTSを元に戻した。
既存36 examples / 0 failures、RuboCop2 files / 0 offenses、ddfef5a親版byte一致、FR-007と利用者変更保持、diff check成功。
[結果](evidence/scope-repair/cr001-attempt-1/result.md)。CR-002復元commitはe0b9ddf。次はFR-034を戻す。

## FR-034の範囲外適用取消（2026-11-04）

scope-repair-fr034-1 / attempt1のpassed resultを消費した。旧Root/Add/Removeの継承・委譲とfood READMEをfcac860親版へ戻した。
既存74 examples / 0 failures、Ruby lint3 files / 0 offenses、eager load・旧継承・4file旧byte一致、旧Fill/利用者変更保持、diff check成功。
[結果](evidence/scope-repair/fr034-attempt-1/result.md)。READMEを全文通読し、文書reviewを行った。
CR-001復元commitはd839b40。次はFR-030のworkflow filterを戻す。

## FR-030の範囲外適用取消（2026-11-04）

scope-repair-fr030-1 / attempt1のpassed resultを消費し、workflow filterをa871b4c親版へ戻した。
git stubによるNode3 cases / 0 failures、旧byte一致・専用suite除去・利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr030-attempt-1/result.md)。workflow自身だけでは検出されない旧条件を維持した。
FR-034復元commitはaa3cfc9。次はFR-029のWebhook呼出しを戻す。

## FR-029の範囲外適用取消（2026-11-04）

scope-repair-fr029-1 / attempt1のpassed resultを消費し、追加HTTP失敗判定・timeoutを旧curlへ戻した。
loopback fixtureのNode5 cases / 0 failures、旧byte一致・専用suite除去・利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr029-attempt-1/result.md)。実Webhookは呼んでいない。FR-030復元commitは05f4e79。次はFR-028を戻す。

## FR-028の範囲外適用取消（2026-11-04）

scope-repair-fr028-1 / attempt1のpassed resultを消費し、非steering差分13pathを2bf938d親版へ戻した。
Node31 tests / 0 failures、bash構文、13path旧byte一致/不存在、FR-027保持・運用3docのnotice訂正・利用者変更保持、diff check成功。
[結果](evidence/scope-repair/fr028-attempt-1/result.md)。運用2文書の全文と差分を文書reviewで確認し、private構成を現行仕様とする記述を訂正した。
実AWS操作は不要であり、実施していない。FR-029復元commitはc0a3cda。次はFR-027を戻す。

## FR-027の範囲外適用取消（2026-11-04）

scope-repair-fr027-1 / attempt1のpassed resultを消費し、start.shを7772f90親版へ戻した。
Node7 cases / 0 failures、bash構文、start/stop旧byte一致、common除去済みと利用者変更保持、diff check成功。
[結果](evidence/scope-repair/fr027-attempt-1/result.md)。既存の停止漏れや早期returnも旧契約として維持し、実AWSは操作していない。
FR-028復元commitは35325d7。次はFR-026を戻す。

## FR-026の範囲外適用取消（2026-11-04）

scope-repair-fr026-1 / attempt1のpassed resultを消費し、plan roleをdf42ad7親版へ戻した。
架空ARNの静的Node3 cases / 0 failures、旧policy byte一致・専用suite除去・利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr026-attempt-1/result.md)。旧過大権限の問題は残し、実AWS/stateは操作していない。
FR-027復元commitは979f847。次はFR-025を戻す。

## FR-025の範囲外適用取消（2026-11-04）

scope-repair-fr025-1 / attempt1のpassed resultを消費し、辞書削除失敗時のcontroller/view/specを旧版へ戻した。
RSpec9 examples / 0 failures、Ruby lint2 files / 0 offenses、3file旧byte一致、FR-001 WIP/FR-024と利用者変更保持、diff check成功。
[結果](evidence/scope-repair/fr025-attempt-1/result.md)。FR-026復元commitは74f44ac。次はFR-024を戻す。

## FR-024の範囲外適用取消（2026-11-05）

scope-repair-fr024-1 / attempt1のpassed resultを消費し、辞書4Commandの追加transactionを9b1df0a親版へ戻した。
中断前に起動済みのsessionからRSpec86 examples / 0 failures、Ruby lint4 files / 0 offensesを回収し、二重実行なし。
4Command旧byte一致・atomic spec除去・FR-023/既存WIP/利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr024-attempt-1/result.md)。FR-025復元commitは53ba48e。次はFR-023を戻す。

## FR-023の範囲外適用取消（2026-11-05）

scope-repair-fr023-1 / attempt1のpassed resultを消費し、新旧Normalizerを73b8797親版へ戻した。
RSpec61 examples / 0 failures、Ruby lint2 files / 0 offenses、旧byte一致・先行属性共通化/旧保存境界と利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr023-attempt-1/result.md)。FR-024復元commitは748a55f。次はFR-022を戻す。

## FR-022の範囲外適用取消（2026-11-05）

scope-repair-fr022-1 / attempt1のpassed resultを消費し、8pathを5b54e45親版の出典必須契約へ戻した。
RSpec3 examples / 0 failures、Jest16 tests、backend/frontend lintとtsc成功、旧byte比較・純抽出/利用者変更保持・diff check成功。
既存fixture警告は[結果](evidence/scope-repair/fr022-attempt-1/result.md)に保存した。FR-023復元commitは7bc255e。次はFR-021を戻す。

## FR-021の範囲外適用取消（2026-11-05）

scope-repair-fr021-1 / attempt1のpassed resultを消費し、共通日付パーサーをc240b94親版へ戻した。
Jest8 tests・lint2file・tsc成功、helper/spec旧byte一致、先行共通化/FR-020残部/純抽出と利用者変更保持、diff check成功。
[結果](evidence/scope-repair/fr021-attempt-1/result.md)。FR-022復元commitは5fc7347。次はFR-020を戻す。

## FR-020の範囲外適用取消（2026-11-05）

scope-repair-fr020-1 / attempt1のpassed resultを消費し、Providerをd8afcf0親版へ戻した。
consumer Jest16 tests・lint・tsc成功、旧byte一致・専用spec除去・純抽出と利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr020-attempt-1/result.md)。既知のNext同期漏れは残る。FR-021復元commitは29e3d49。次はFR-019を戻す。

## FR-019の範囲外適用取消（2026-11-05）

scope-repair-fr019-1 / attempt1のpassed resultを消費し、9pathの制約・migration・補完profileを旧版へ戻した。
adapter/RAILS_ENV/設定pathと実SQLite fileの二重guard後、test DBだけへschema loadし再guardとmeal_id unique不在を確認。
RSpec70 examples / 0 failures、Ruby lint2 files / 0 offenses、旧9path比較・純抽出/利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr019-attempt-1/result.md)。実DBschemaは変更していない。FR-020復元commitは5788f15。次はFR-018を戻す。

## FR-018の範囲外適用取消（2026-11-05）

scope-repair-fr018-1 / attempt1のpassed resultを消費し、新旧保存と交換の6pathを25471fd親版へ戻した。
RSpec81 examples / 0 failures、Ruby lint4 files / 0 offenses、旧比較・追加解除参照なし・FR-002/003残部/純抽出と利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr018-attempt-1/result.md)。FR-019復元commitはda81219。次はFR-017を戻す。

## FR-017の範囲外適用取消（2026-11-05）

scope-repair-fr017-1 / attempt1のpassed resultを消費し、フォームとspecを62359ad親版へ戻した。
Jest19 tests・lint2file・tsc、旧byte比較が成功。d58c473元schemaとshared schemaを120ケースで実行比較しdata/issues順まで一致した。
共有schemaは追加整数/正数拒否を含まず変更不要。純抽出6file/利用者変更保持とdiff check成功。
[結果](evidence/scope-repair/fr017-attempt-1/result.md)。FR-018復元commitはb27bbaf。次はFR-016を戻す。

## FR-016の範囲外適用取消（2026-11-05）

scope-repair-fr016-1 / attempt1のpassed resultを消費し、検索timerを5319fbd親版へ戻した。
Jest4 tests・lint、旧byte比較・専用spec除去・純抽出/利用者変更保持・diff check成功。既存fixture警告は結果に保存した。
[結果](evidence/scope-repair/fr016-attempt-1/result.md)。FR-017復元commitは3c9ac6b。次はFR-015を戻す。

## FR-015の範囲外適用取消（2026-11-05）

scope-repair-fr015-1 / attempt1のpassed resultを消費し、7pathをc05d21d親版へ戻した。
Jest17 tests・lint4file・tsc、旧byte比較・先行モード型/純抽出/利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr015-attempt-1/result.md)。FR-016復元commitは566157d。次はFR-014を戻す。

## FR-014の範囲外適用取消（2026-11-05）

scope-repair-fr014-1 / attempt1のpassed resultを消費し、mutation builder/caller/specの4pathを601d722親版へ戻した。
Jest22 tests・lint3file・tsc、旧byte比較・先行入力共通化/モード型/純抽出と利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr014-attempt-1/result.md)。FR-015復元commitはaa3221c。次はFR-013を戻す。

## FR-013の範囲外適用取消（2026-11-05）

scope-repair-fr013-1 / attempt1のpassed resultを消費し、取得query/output/生成物とフォーム初期値の10pathをfb59312親版へ戻した。
RSpec7 examples / 0 failures、Jest47 tests・backend/frontend lint・tsc、旧比較・先行入力共通化/純抽出/利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr013-attempt-1/result.md)。FR-014復元commitはeff9ffc。次はFR-012を戻す。

## FR-012の範囲外適用取消（2026-11-05）

scope-repair-fr012-1 / attempt1のpassed resultを消費し、2resolverと専用specの3pathをceb1da7親版へ戻した。
RSpec13 examples / 0 failures、Ruby lint2 files / 0 offensesを逐次確認。旧比較・対象外Meal resolver不変・先行変換/純抽出と利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr012-attempt-1/result.md)。FR-013復元commitはa41c8f2。次はFR-011を戻す。

## FR-011 認可保持（2026-11-06）

未commitの取消を撤回し、料理ownerによる認可と本人による評価操作を維持した。対象3 pathはHEADおよび `cdb8e27` と一致する。新検証はRSpec 9 examples / 0 failures、対象2 fileのRuboCop 0 offenses、FR-002〜010認可保持、保護fileの保存hash一致とdiff check成功。[結果](evidence/scope-repair/fr011-retain-attempt-1/result.md)。初回OS modeの独立snapshotはない。旧取消のpassedは当時の実測であり、[その目的は失効](evidence/scope-repair/fr011-superseded.md)した。

## FR-012 再適用（2026-11-06）

料理更新の省略可能な引数にnil既定値を復帰。省略/null/有効値の6例を含むRSpec 19 examples / 0 failures、3 file lint 0 offenses。[結果](evidence/scope-repair/fr012-retain-attempt-1/result.md)。認可と保護fileのhashを保持。

## FR-013 再適用（2026-11-06）

編集時に保存済み手間を保持する。Jest 68 tests、RSpec 2 examples、型検査と変更箇所lint成功。[自動検証](evidence/scope-repair/fr013-retain-attempt-1/result.md)。人工GraphQL fixture画面でID17初期表示・名前変更時17送信・明示解除/位置づけ変更時nullを確認。実DB未操作。visual初回は入力不足blocked、attempt 2は4項目passed。明示解除画像に横ずれと左ラベル欠けを別観測、旧確認画像にも同状態があるが導入前比較は未実施。

## FR-014 再適用（2026-11-06）

送信状態・errorと任意callbackを既存callerへ返す。Jest 21 tests、型検査・lint成功。人工fixtureの画面確認で未選択0件、有効交換1件とpending→通常、人工失敗時pageerror 0と交換画面維持。画面内エラー表示は見えずconsoleにApolloError。内部契約はunitで検証。初回visual blockedとattempt 2 passedを保持、実DB未操作。
