# 正常な利用者操作と業務仕様を保つ適用範囲の修復

## 目的と判断基準

通常の利用者が行う操作、既存の業務仕様、運用構成を保ちながら、共通化・認可・内部の不具合修正を残す。正常操作を変えない所有者確認、型不整合の解消、保存・非同期処理の不具合修正は今回の適用対象である。既存の有効な業務操作を新たに拒否する条件、情報の扱いを選び直す処理、利用者へ追加する操作、環境構成や費用を変える変更は個別に判断する。

利用者の具体的な例は「IDOR対応とかは関数の挙動を変えているだけでユーザの挙動も変わらず内部だけの話だから問題ない」。この例と「共通化や認可・内部の不具合修正を残し、新しい業務制約や構成変更を個別判断」という方針への継続指示を根拠とする。正常操作とは、本人の対象を正しい型・値で操作する既存の業務操作を指す。他人の識別子へのアクセスや無効な識別子の受理を互換要件にはしない。既存の有効な操作を制限するかは、既存画面、README、schema、specを突き合わせて判定する。

この先行実行範囲は以下の採否表で確定している。個別判断が必要な項目は先行範囲の対象外として残し、親steeringで再評価する。確定項目の実行は、その判断へ依存しない。合意経緯は[task-design-discussion.md](task-design-discussion.md)に記録する。

## 完成後の姿

### 比較基点と保持する範囲

| 基点 | 用途 |
| --- | --- |
| `d58c47364bc9c3774a1a4b3636938c9c83bd3abc` | 先行8件、FR-031、明示保留のFR-001 WIPを含む業務仕様の比較基点 |
| `608ed3d2e8c3a94a54bd8a43aa48ee7a2d777665` | 元の全適用実装、test、証拠を復元できるsnapshot |
| `c6e07af` | 24件の適用取消がcommit済みで、FR-011の取消だけがworktreeにある設計再開時点 |

先行8件（RV-001/012/013/014/015/025/026/029）、FR-031、FR-032、FR-033と明示保留のFR-001 WIPを保持する。FR-002〜011の認可も保持する。FR-011のworktree取消は先に撤回し、料理の所有者に基づく評価認可を残す。

利用者変更の`.gitignore`、`frontend/Dockerfile`、`frontend/src/lib/generateApiOrigin.ts`は内容・modeを保ち、stageしない。保全hashは`/tmp/nanitabe-scope-repair-preserved-hashes.json`。既存`.codex/rules/default.rules`と別作業`.steering/2026/202611/20261106-limit-user-checks-to-what-only-users-verify/`にも触れない。

FR-032の入力schema共有は[evidence/fr032-migration.md](evidence/fr032-migration.md) S01〜S08、FR-033の入力値転記共有は[evidence/fr033-migration.md](evidence/fr033-migration.md) I01〜I05を保持する。FR-006の認可も維持するため、更新Commandのactorを共通化の混入として除去しない。

### 操作から見た確定する修正

以下の正常操作を維持し、その操作を壊していた内部処理を復帰する。新しい業務上の選択肢や拒否規則はこの表に含まない。

| 指摘 | 完成後の操作と結果 | 既存仕様・根拠 | 復帰する元commit |
| --- | --- | --- | --- |
| FR-012 | 料理更新時にGraphQL上省略可能な出典関係引数を省略しても、明示nullと同じ既存更新処理へ届く | `required:false`とRuby keywordの不整合。省略を別の「現状維持」操作にはしない | `ceb1da7` |
| FR-013 | 手間ID17の料理の名前だけを編集すると17が送信・保存される。明示解除や位置づけ変更の解除は既存どおり | フォームの初期値と取得queryが既存保存値を欠落させていた | `fb59312` |
| FR-014 | 既存の送信操作でApolloのloading/errorが呼出側に届き、callback省略も許容される | Apolloの実プロパティ名との不整合。交換開始日未選択のguardは未成立操作から不正日付を送らない内部防御 | `601d722` |
| FR-015 | 延期確定後の既存callbackがclearStore、calendar再取得の完了を順に待ってから既存の一覧再取得・モード終了へ進む | 既存hookがすでに`await onDataChanged()`を持つ。失われたPromiseだけを接続する | `c05d21d`の2箇所のみ |
| FR-016 | 検索パネルA/Bの入力が互いの検索を取り消さず、閉じたパネルの検索を実行しない。同じパネルの400msは維持する | module共有timerの不具合 | `5319fbd` |
| FR-017 | 枠を選択後に未選択へ戻すと既存の必須入力エラーになり、再選択すれば同じ枠IDで送信できる | 対象は`mealFrameId`だけ。通常のoptionは保存済み枠の正整数PKであり、NaN/Infinity/0/負数/小数の拒否は有効な枠選択を制限しない | `62359ad`全体 |
| FR-018 原子的保存 | 両日の食事交換は従来の取得・保存・返却順序と枠属性を保って完了し、途中保存失敗では先行保存も戻して元の例外を伝える | 一つの既存交換操作の部分保存を防ぐ内部transaction修正。枠の業務契約を選ばず独立適用できる | `25471fd`の新旧交換Command wrapperだけ |
| FR-020 | 今週リンク、週/月切替、戻る/進むでURLと表示日付が一致し、履歴を重複追加しない | Next router更新を初期stateだけで読む内部同期不具合 | `d8afcf0` |
| FR-021 | 有効日付にquery/hashが付いてもその日を表示し、存在しない日付は既存のfallback方針である今日09:00へ戻す | 既存parserの形式検査とfallbackを実在日付へ整合。新しい404画面は加えない | `c240b94` |
| FR-022 | 食事編集画面で元から選べる出典なしの新規料理へ差し替えると、source/relationを作らず保存できる | UI/schema/normalizerがoptional、登録側もoptionalであるのに編集GraphQLだけ必須だった | `5b54e45` |
| FR-024 | 辞書の追加・更新・削除と全料理への反映が同時に確定し、途中失敗なら全体が戻る | 一つの既存管理操作の部分保存を防ぐtransaction | `9b1df0a` |
| FR-025 | 辞書削除の内部反映が失敗すると元のエラーを既存一覧のalertへ出し、rescue内の別例外で隠さない | 本文なしDELETEで存在しないword paramsを読む不具合。新たな操作ボタンは加えない | `4a12564` |
| FR-026 | planが既存の`plans/<root>/<run id>.txt`へログを保存でき、state本体の上書き権限を持たない | `infrastructure/README.md`の既存出力先と一致。IAM権限修正でありresource構成追加なし | `df42ad7` |
| FR-027 | 既存の起動操作が途中失敗すると停止を試み、起動済み再実行でも既存の停止予定を整合する | 起動・自動停止という既存運用の失敗処理。private integration構成へは変えない | `7772f90` |
| FR-029 | デプロイ依頼のHTTP失敗/timeoutを失敗として返す。成功時は従来どおり1回だけ送信する | 既存依頼の成功判定不具合。未確認の再試行は加えない | `d3e4515` |
| FR-030 | frontend build workflow自身の変更でも既存build検証を実行する | 実ファイル名のtypo訂正 | `a871b4c` |
| FR-034 | 旧枠入口をそのまま呼べ、本人操作の保存値・返却classを維持して現行Commandへ委譲する。他人の削除は拒否する | 旧定数を残した共通化と認可。内部の継承関係が変わることだけを取消理由にしない | `fcac860` |
| CR-001 | 既存のAND検索で`alpha beta`が別々のタグへ一致する同じ料理を返す | 料理単位の語条件を一つのJOIN行へ誤って閉じた内部検索不具合 | `ddfef5a` |
| CR-002 | 料理編集で既存タグの内容を変更すると新しい内容が保存・再取得される | 同じタグID集合なら保存を飛ばす不具合。本人scopeと原子保存も復帰 | `30c86bb` |
| CR-004 | 同じ延期/予定食事を同時確定しても一度だけ消費し、本人の操作だけを処理する | 既存の変換操作の多重消費・認可不具合。業務操作を追加しない | `02e2caf` |

この表の元commitにあるproduction/caller/testを単位として復帰する。FR-015とFR-018は以下に記載する部分だけを復帰する。元commitより後の別指摘の実装をsnapshotから丸ごと取り込まない。FR-025ではcontrollerのFR-001 WIPを保持し、FR-034では旧Fillの既存委譲を保持する。

FR-015は`Calendar/index.tsx`の`onDataChanged: refreshData`と`useRefreshCalendarData.tsx`の`await refetchMealsForCalendar()`だけを復帰する。`usePostponedMealMode.ts`と`ScheduleChosenPostponedMealForDate.tsx`は現在版を保ち、追加の再取得ボタン・エラーUI・状態機械を持ち込まない。既存callbackへ成功/失敗のPromiseを伝え、再取得完了前のモード終了を防ぐことをtestする。

FR-018のproduction変更は次の2pathの`call`全体を`::Meal.transaction`で囲むだけとする。

- `backend/app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb`
- `backend/app/domain/business/dish/meal/command/swap_meals_between_days_command.rb`

food側をcurrent、dish側をlegacyと呼ぶ。各日のfetch・各食事の保存・date1集合へdate2集合をconcatする順序と引数を維持する。
正常時はcurrentの`Business::Food::Meal::Root`、legacyの`Business::Dish::Meal::Meal`の配列を返し、`user_id/dish_id/meal_type/comment`と関連枠の全属性を保持する。
currentは既存の`user_id:`付き取得で本人の食事だけを扱い、legacyは既存の日付取得と`Repository.update`の認可を維持する。
空/片側空を許容し、同日の交換では同じ食事が返却配列へ2回現れる現行契約を保つ。

後半保存で例外が発生した時は、前半の実保存も含めた交換対象Mealと関連枠のDB値を実行前へ戻し、元の例外instanceを呼出元へ伝える。
両Commandの既存specへ退行testを追加し、reloadしたDB値でrollbackを確かめる。
上記2Command以外のproductionは変更せず、元の`frame_release_spec.rb`全体は復帰しない。
この部分採用で食事移動後の枠不整合を解消したとは報告しない。

### 親steeringで個別判断する対象

以下は今回の先行実行範囲から暫定で外し、現在の取消済み状態を保つ。理由は内部実装差分の存在ではなく、有効な業務操作・情報解釈・構成の選択を要することにある。親steeringが記載の判断を得た時点で同じworkdirのdesignを再開し、独立に適用できる範囲を追加する。先行範囲の完了を全レビュー修復の完了とは呼ばない。

| 指摘・部分 | 既存の根拠と判断が必要な内容 | 再評価の条件 |
| --- | --- | --- |
| FR-018 枠解除 | 枠は日付・時間帯に属するが、食事移動時の解除は旧READMEに明記がない。移動元に枠を残して解除するか、食事とともに移動するかは本人操作の結果を変える。交換全体のtransactionは採用表の範囲で独立復帰する | 食事の移動・時間帯変更・日付交換における枠の扱いが確定した時 |
| FR-019 | `has_one`と単数出力は根拠になるが、別枠への再割当を拒否するか移すかは別の業務判断。unique追加は既存重複整理/migrationを必要とする | 再割当契約、既存重複の扱い、migrationの採否が確定した時 |
| FR-023 | 旧実装はSQL LIKE候補選択とRegexp置換であり、文字列と正規表現のどちらが辞書仕様かを定めた既存文書が見つかっていない | 辞書のsource/targetの解釈と既存登録規則の扱いが確定した時 |
| FR-028 | private integration化は接続経路、resource、費用、起動手順を変える。認可確認の追加とは範囲が異なる | この構成変更を採るという判断が確定した時 |
| CR-003 | 旧Repository specに関連済み出典のtype変更後に詳細を上書きする成功例がある。一律拒否はその有効操作を制限する | 拒否/明示移行/旧情報保持の業務契約が確定した時 |
| FR-015追加UI | 表示更新だけを再試行するボタンと失敗状態保持は、Promise伝播の修正に必須ではない新しい操作・画面状態である | この追加操作・失敗時の画面仕様を採るという判断が確定した時 |

FR-001はこれらと別に、以前からの利用者による明示保留を維持する。FR-001の既存WIPを解消・削除・改善したとは報告しない。

### codeの責務配置と比較

FR-032/033の共通owner、FR-034の現行Commandへの委譲、FR-002〜011のactor所有者確認を保持する。その他の責務配置は各元commitの限定差分を復帰する。対象file数を6fileに固定しない。

最終差分は`d58c473`との差分に対して、先行保持範囲と上記の採用ID/部分採用へ一件ずつ対応付ける。採用されていない業務制約・migration・private integrationを含まないことを逆方向にも確認する。純粋な共通化は前記二層台帳で値・順序・空配列・既存validationを照合する。認可や不具合修正は、この表の正常操作と問題再現ケースで検証する。

### runtimeと検証条件

既存`compose.dev.local.yml`のbackend/frontendでアプリtestを実行する。Railsは`RAILS_ENV=test`と標準test DBだけを使う。新しいCompose、重複アプリcontainer、追加MySQL serviceを作らない。実DBのmigration/rollback、実AWS query/apply/deploy、実Webhook送信、mergeは実施しない。

FR-026はpolicy codeとoffline testの復帰までである。実環境で権限制限を有効にするには既存IAM policyの更新適用が必要であり、その適用actionは今回の実行範囲に含めない。実AWSへ適用済み、またはAWS apply不要とは報告しない。FR-027はpublic-IP integration版のcleanupを復帰し、FR-028由来のprivate用scriptやcommonを復帰しない。運用testは人工envとstub/loopback fixtureだけを用いる。

CR-004の通常testと専用MySQL spec/helperは復帰するが、新serviceを起動しない。現在のtest環境に許可済みの専用MySQLがない場合、今回の並行実測は未実施と明記する。以前のMySQL結果はそのsnapshotの証拠として保持し、現在の再実測と取り違えない。

frontendの表示・入力・状態へ影響する各項目は`visual-inspector` childで確認する。自動testや人工GraphQL fixtureによる目視と、利用者だけが確かめられる業務判断を区別する。既存の継続・指摘単位commit・公開許可に従い、形式的な開始確認や再許可を追加しない。

### 記録と履歴

旧全取消design/tasklistは`git show c6e07af:<path>`に保存される。完了した24取消commitとその証拠は履歴として残し、現在の採否・未反映・再適用済みを個別findingから辿れるように訂正する。採否の正本はfinding、現在の実行状態はtasklist、実測結果はapplication/coverageとする。

復帰は一指摘一追加commitで行い、履歴改変・amend・rebase・force pushを行わない。FR-015とFR-018は部分復帰として記録する。FR-018の原子的保存の復帰と枠解除の保留をfinding/application/coverage/READMEで区別し、過去の全適用・取消結果を今回の実測に流用しない。FR-011の未commit取消撤回はcode上の追加commitが不要であるため、結果の失効と記録を同指摘の追加commitへまとめる。保全対象をstageしない。既存のgit add/commit/push承認を使う。

## 受け入れ基準

1. FR-011の3pathが再開時HEADと一致し、未取消FR-002〜010の認可を保持する。全関数の旧契約を保存する目的の取消を継続しない。
2. 上表の各修正が指摘単位で復帰・検証され、FR-015の新UI、FR-018の枠解除とその他の個別判断対象を持ち込まない。FR-018は正常交換・枠属性保持・途中保存失敗の全体rollbackと元例外を新旧Commandで確認する。
3. 正常入力の保存・表示・既存操作をcaseごとに検証し、認可・型不正・多重送信・失敗時の差分は修正対象の期待としてtestする。
4. 先行8件、FR-031〜033、FR-001 WIP、利用者変更、他作業を保持し、許可されていない差分が0件である。
5. 既存containerの全RSpec/Jest、型検査、production build、全lintを確認し、既存FR-001由来のoffenseと今回回帰を分けて報告する。frontendの各確認と全体の目視を実施する。
6. 実環境DB/AWS/Webhook/mergeへの操作、新Compose/追加service起動、履歴改変がない。未実測はそのまま記録する。
7. README/application/coverage/旧RV/CRの現在状態と既存PR #292を今回の採否へ訂正し、先行範囲完了と親steeringに残る個別判断を区別する。

## 付録: 変更の実行区分

### task-design内で対象成果物へ適用済み

なし。design/tasklist/discussionの変更は設計lifecycleの更新であり、application実装は実行担当へ渡す。

### task-design内の対象成果物反映待ち

なし。

### execution plan対象

| 対象 | 掲載理由 | 参照section |
| --- | --- | --- |
| FR-011取消撤回と確定した各FR/CR復帰 | 本番application codingと指摘単位の独立検証 | 操作から見た確定する修正 |
| 運用修正の復帰 | 本番runtime/workflowの修正とoffline検証 | runtimeと検証条件 |
| 現在採否の訂正・全体検証・既存PR訂正 | 実装結果に依存する段階的な公開 | 記録と履歴、受け入れ基準 |

## 設計確認

2026-11-06、Solがユーザーの継続指示、既存finding、元commit、README、specとTerraの読取事実を照合して設計した。使用skillはtumeda-dev 8.2.5。親が元作業exact pathで取得したtemporary-overrides=noneを引き継いだ。task-designのrepository contextと直接利用する共通項目を使用した。

本文は今回の先行実行範囲を確定し、親に残る個別判断はその範囲の設計判断として実装者へ委ねていない。設計担当はapplication/test/Git index/commit/pushを変更していない。文書reviewでは作成時・更新時観点、前版で保持していた保全・履歴・環境制約、採否全件の対応、暫定判断の再評価条件を通読確認した。

### FR-014 検証層の訂正（2026-11-06）

内部handlerのnull分岐とerror object同一性は通常UIから直接到達・観測できないため、real-Apollo unitで確認する。visualは未選択時mutation 0件、有効な2日で1回送信しpendingから成功後の通常画面、人工失敗後pageerror 0件で交換画面維持を確認する。機能DoDは変えず、初回visual blockedの実測を保持する。
