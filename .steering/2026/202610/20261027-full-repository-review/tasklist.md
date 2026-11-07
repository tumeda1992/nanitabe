# 正常操作を保つ内部改善復帰tasklist

仕様は[design.md](design.md)。利用者の正常操作・業務仕様を基準に確定した先行範囲だけを実行する。旧全取消計画は`git show c6e07af:.steering/2026/202610/20261027-full-repository-review/tasklist.md`にある。24件の取消済み記録は履歴であり、この計画の復帰完了には流用しない。同workdirのplanはこのtasklistだけとする。

## 共通の実行・検証・commit契約

- 方針検討・実装feedbackの判断・結果監督はSol、実装・検証・記録作業はTerraとする。single writerを実行担当へ引き渡した後、別担当はdesign/tasklistを重ねて更新しない。
- 各phaseは一指摘のproduction/caller/test/現在状態記録を閉じた単位で復帰する。元commitの非steering差分を読み、現在の採用範囲だけを限定patchで戻す。snapshot全fileの一括復帰・履歴改変は行わない。
- `.gitignore`、frontend/Dockerfile、frontend/src/lib/generateApiOrigin.tsの既存hash/modeを毎phase確認しstageしない。FR-001 WIP、先行8件、FR-031〜033、別作業directory、操作許可を保持する。
- アプリtest commandは下記の`backend ...`を`docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend ...`、`frontend ...`を`docker compose -f compose.dev.local.yml exec -T frontend ...`として実行する。アプリtestをhostで実行しない。標準test DB以外へ接続しない。
- 各phaseで追加/復帰した退行testと関連test、変更箇所lint、frontend変更時はtscを実行する。表示/入力/状態へ影響するfrontend phaseはvisual-inspector childで人工fixtureの目視確認も行う。結果は新request/attemptへ保存し、旧取消testのgreenを流用しない。
- 各phaseのDoDを実測後、findingの現在採否を訂正し、applicationに復帰範囲/正常操作case/検証/未実測を記録する。元の指摘・取消・red/green証拠は残す。チェックは実測直後に更新する。
- 一指摘ごとにplan-commitsで実差分を確認し、一つの追加commitを作る。既存の指摘単位commit/publication指示とgit add/commit/push許可を使い、形式的な再承認を追加しない。保護fileはstageしない。
- 実DB migration/down、実AWS query/apply/deploy、実Webhook送信、merge、新Compose/追加serviceは行わない。外部I/Oはstub/loopbackだけとする。

## 1. FR-011の未commit取消を撤回し、認可を維持する

- [x] 現在HEADのFR-011実装がcdb8e27を保持することを確認し、次の3pathだけを現在HEADへ戻す。
  `backend/app/domain/business/dish/dish/evaluation/command/evaluate_command.rb`、
  `backend/app/domain/business/dish/dish/evaluation/repository.rb`、
  `backend/spec/domain/business/dish/dish/evaluation/command/ownership_spec.rb`。
  staged差分を作らず、他のworktree差分を巻き込まない。
- [x] `requests/scope-repair-fr011-1.json`と`evidence/scope-repair/fr011-attempt-1/result.json/result.md`を履歴として保存し、取消目的が失効したため`superseded`と現在の範囲を記録する。失敗/成功の実測結果を別の結果へ書き換えない。
- [x] `backend bundle exec rspec spec/domain/business/dish/dish/evaluation spec/models/dish_evaluation_spec.rb spec/graphql/mutation/dish/evaluation`と対象2RubyのRuboCopを実行する。3pathのHEAD一致、FR-002〜010の認可保持、保護対象のhash保持とdiff checkを確認する。
- [x] finding/applicationへ料理ownerに基づく認可の保持を記録し、取消撤回記録だけをFR-011の追加commitへまとめる。codeに差分がないことは正常である。

DoD: 本人料理の評価は従来の操作で成功し、他人の料理への評価作成を拒否する。3pathがHEAD一致で、以降FR-002〜011を取消対象にしない。

## 2. FR-012: 省略可能な料理更新引数を実際に省略できる

- [x] 元commit `ceb1da7` の限定差分を読み、backend/app/graphql/mutations/dish/update_dish.rb、update_dish_with_new_source.rb、optional_arguments_spec.rbを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `backend bundle exec rspec spec/graphql/mutation/dish`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: GraphQL経由の省略/null/有効値で同じ既存更新処理へ到達する。

## 3. FR-013: 料理名だけの編集で既存手間を保持する

- [x] 元commit `fb59312` の限定差分を読み、EssentialDish出力、fetchDish/fetchMeal queryと生成物、DishForm/SelectEffortLevel、対応specを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `frontend yarn test --runInBand --silent DishForm EditMeal AddMeal`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
  > 確認日時: 2026-11-06 10:01 JST以前
  > 総合結果: ✅ 指定4項目正常（人工GraphQL fixture、実DB未操作）
  > ログ: `frontend/inspect/visual/tmp/fr013-retain-attempt-2/result.md`
  > 初期表示: 期待ID17、結果ID17（20分 - 普通）✅
  > 名前変更: 期待ID17送信、結果17 ✅
  > 明示解除: 期待null送信、結果null ✅
  > 位置づけ変更: 期待null送信、結果null ✅
  > 別観測: 明示解除画像に横ずれと左ラベル欠け。旧確認画像にも同状態があるが導入前比較は未実施。

- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 手間ID17の初期表示と名前変更時17送信、明示解除と位置づけ変更のnull送信。

## 4. FR-014: 送信状態とエラーを既存callerへ返す

- [x] 元commit `601d722` の限定差分を読み、frontend/src/features/utils/mutationUtils.tsとspec、useSwapMealsMode.ts、useCalendarMode.spec.tsを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `frontend yarn test --runInBand --silent mutationUtils useCalendarMode dishInputConversion`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
  > 確認日時: 2026-11-06（JST）
  > 総合結果: ✅ 指定3画面項目正常、人工fixture・実DB未操作
  > ログ: `frontend/inspect/visual/tmp/fr014-retain-attempt-2/result.md`
  > 未選択: 期待mutation 0件、結果0件 ✅
  > 有効交換: 期待1回送信しpending後に通常画面、結果一致 ✅
  > 人工失敗: 期待pageerror 0件と交換画面維持、結果一致 ✅（画面内エラー表示なし、consoleにApolloError）

- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 実Apollo状態のfalse→true→falseと同じerror、任意callback、未選択から不正日付を送らない。内部handlerとerror object同一性はunitで確認し、visualは通常UIの未選択・成功・失敗画面を確認する。初回visual blockedは保持する。

## 5. FR-015: 既存カレンダー再取得のPromiseを接続する

- [x] 元commit `c05d21dの限定差分` の限定差分を読み、Calendar/index.tsxのonDataChanged、useRefreshCalendarData.tsxのawaitと両境界のspecを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
  元commitの追加retry UI/state machineを復帰しない。useRefreshCalendarData.spec.tsxとCalendar/refreshContract.spec.tsxを境界testとして復帰・適応し、延期hookは現在の既存制御のままにする。
- [x] `frontend yarn test --runInBand --silent useRefreshCalendarData refreshContract useCalendarMode`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
  > 確認日時: 2026-11-06（JST）
  > 総合結果: ✅ 指定2画面項目正常、人工fixture・実DB未操作
  > ログ: `frontend/inspect/visual/tmp/fr015-retain-attempt-1/result.md`
  > calendar再取得保留: 期待モード継続と一覧再取得なし、結果一致 ✅
  > 解放後: 期待一覧再取得とモード終了、結果一致 ✅

- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: clearStore保留中はcalendar未取得、calendar保留中は既存callbackが未完了、失敗が呼出側へ伝播する。

## 6. FR-016: 検索パネルごとの400ms timerを保持する

- [x] 元commit `5319fbd` の限定差分を読み、DishSearchPanel/index.tsx、debounce.spec.tsxを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `frontend yarn test --runInBand --silent DishSearchPanel ExistingDishesForRegisteringWithMeal`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
  > 確認日時: 2026-11-06（JST）
  > 総合結果: ✅ 指定2画面項目正常、人工fixture・実DB未操作
  > ログ: `frontend/inspect/visual/tmp/fr016-retain-attempt-1/result.md`
  > 検索: 期待400ms後に最終語を送信し結果表示、結果431msで1件・結果表示 ✅
  > 取消: 期待400ms前のpanel除去後にqueryなし、結果167msで既存画面切替後700msで0件 ✅
  > 閉じるiconは不可視で操作できず、既存の新規料理切替でpanelを除去した。

- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 別パネルの検索を取り消さずunmount後にcallbackを実行しない。同一パネルは最終入力から400ms。

## 7. FR-017: 未選択の枠を既存入力エラーへ戻す

- [x] 元commit `62359ad` の限定差分を読み、MealFramePatternFields.tsx、MealFramePatternEditor.spec.tsxを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `frontend yarn test --runInBand --silent MealFramePattern`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
  > 確認日時: 2026-11-06（JST）
  > 総合結果: ✅ 指定2画面項目正常、人工fixture・実DB未操作
  > ログ: `frontend/inspect/visual/tmp/fr017-retain-attempt-1/result.md`
  > 作成: 期待未選択エラー・mutation 0、再選択でID1を1回送信、結果一致 ✅
  > 編集: 期待未選択エラー・mutation 0、再選択でID1を1回送信、結果一致 ✅
  > エラーは再選択直後も残り、送信時に処理される。永続化は未検証。

- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 作成/編集で選択→未選択はAPI0回、再選択は正整数IDで1回。NaN/Infinity/0/負数/小数を送らず通常の選択肢は保存できる。

## 8. FR-020: Nextの遷移と表示日付を同期する

- [x] 元commit `d8afcf0` の限定差分を読み、frontend/src/app/logical-history.tsxと専用specを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `frontend yarn test --runInBand --silent logical-history CalendarHeader Calendar/index.spec useRefreshCalendarData`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
  > 確認日時: 2026-11-06（JST）
  > 総合結果: ✅ 指定2画面項目正常、人工fixture・実DB未操作
  > ログ: `frontend/inspect/visual/tmp/fr020-retain-attempt-1/result.md`
  > 週/月切替: 期待URLと表示一致、結果一致 ✅
  > 前後・今週・browser戻る/進む: 期待URLと表示一致、結果8状態で一致し300ms後も維持 ✅

- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 週/月切替・今週・戻る/進むでURL/表示が一致し、独自pushと古いNext snapshotで巻き戻さない。

## 9. FR-021: カレンダーURLの既存日付解釈を整合する

- [x] 元commit `c240b94` の限定差分を読み、calendarDateFromPath.tsとspecを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `frontend yarn test --runInBand --silent calendarDateFromPath`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
  > 確認日時: 2026-11-06（JST）
  > 総合結果: ✅ 指定2画面項目正常、人工fixture・実DB未操作
  > ログ: `frontend/inspect/visual/tmp/fr021-retain-attempt-1/result.md`
  > 閏日/query/hash: 期待URL維持と指定日の週/月表示、結果一致 ✅
  > 不正日: 期待URL維持と実行日の週/月表示、結果一致 ✅
  > 今日09:00はunitで確認。

- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 有効な閏日/query/hashは同じ日を表示し、存在しない月日は既存方針の今日09:00へ戻る。

## 10. FR-022: 既存の出典なし料理入力を編集APIへ届ける

- [x] 元commit `5b54e45` の限定差分を読み、update_meal_with_new_dish.rbとspec、normalizeFunctions/updateMealMutationとspec、生成物を復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
  frontendでは`yarn test --runInBand --silent dishInputConversion EditMeal.spec AddMeal.spec AddDish.spec`も実行する。生成物は通常schemaのoffline出力で必要差分だけ生成し、開発DBへmigrationを実行しない。
- [x] `backend bundle exec rspec spec/graphql/mutation/meal/update_meal_without_source_spec.rb spec/graphql/mutation/meal/update_meal_with_new_dish_spec.rb spec/graphql/mutation/meal/update_meal_with_new_dish_and_new_source_spec.rb spec/graphql/mutation/meal/ownership_spec.rb`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
  > 確認日時: 2026-11-06（JST）
  > 総合結果: ✅ 指定2画面項目正常、人工fixture・実DB未操作
  > ログ: `frontend/inspect/visual/tmp/fr022-retain-attempt-1/result.md`
  > 出典なし送信: 期待meal10・source/relation null・tags []を1回、結果一致 ✅
  > fixture成功後: 期待modal終了・calendar再取得・新料理名表示、結果一致 ✅
  > 開発環境のissue表示を別観測。永続化と認可rollbackはbackend RSpecで検証。

- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 省略/nullで出典なし新料理へ差替え、source/relation件数不変、認可失敗はrollback。既存出典ありも成功する。

## 11. FR-024: 一つの辞書更新を原子的に保存する

- [x] 元commit `9b1df0a` の限定差分を読み、food/dish/word/usecaseのAdd/Update/Remove/ReflectLatestNormalizeWordCommandとatomic_reflection_spec.rbを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `backend bundle exec rspec spec/domain/business/food/dish/word/usecase`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 辞書更新後の反映失敗で辞書・料理・タグが全て元へ戻り、成功時は一括保存される。

## 12. FR-025: 辞書削除の元エラーを既存一覧に表示する

- [x] 元commit `4a12564` の限定差分を読み、normalize_words_controller.rb、一覧template、request spec（FR-001 WIP保持）を復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
  controller全fileを古い版で上書きせず、既存FR-001の認証差分を保持して削除rescueの限定差分だけを復帰する。
- [x] `backend bundle exec rspec spec/requests/admin/food/dish/word/normalize_words_spec.rb spec/system/admin/food/dish/word/normalize_words_spec.rb spec/domain/business/food/dish/word/usecase`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 本文なしDELETEの反映失敗でParameterMissingを起こさず元エラーを表示し、FR-024によって全属性を保持する。

## 13. FR-026: planの既存ログ保存だけに書込権限を限定する

- [x] 元commit `df42ad7` の限定差分を読み、infrastructure/terraform/modules/github_oidc/main.tf、plan_policy.spec.mjsを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
  planのログ保存先が既存READMEのplans/<root>/<run id>.txtと一致することも照合する。offline policy評価までとし実AWSには適用しない。権限制限を実環境で有効にするには既存IAM更新の適用が必要で、適用actionは別であることを結果とPRへ明記する。
- [x] `node --test infrastructure/terraform/modules/github_oidc/plan_policy.spec.mjs`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: plans配下へのPutObject、state読取、lock table操作を保ち、state/applyログへの書込みを許可しない。

## 14. FR-027: 起動失敗時に停止を試みる

- [x] 元commit `7772f90` の限定差分を読み、scripts/review_backend/start.sh、start.spec.mjsを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
  7772f90時点のpublic-IP integration版のみを復帰し、2bf938d以降のprivate用common/出力参照は取り込まない。人工envのNode harnessとbash -nで検査する。
- [x] `node --test scripts/review_backend/start.spec.mjs`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 起動後の各失敗/割込みでcleanupを試み、元終了codeを保持。起動済み再実行でintegrationと停止予定を整合する。

## 15. FR-029: デプロイ依頼のHTTP失敗を返す

- [x] 元commit `d3e4515` の限定差分を読み、.github/workflows/backend-deploy.yml、scripts/github/backend_deploy.spec.mjsを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `node --test scripts/github/backend_deploy.spec.mjs`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: loopbackで200=0、401/404/500=22、timeout=28、各1request。production timeout10/30秒を保持する。

## 16. FR-030: build workflow自身の変更を検出する

- [x] 元commit `a871b4c` の限定差分を読み、.github/workflows/ci-frontend-build-verification.yml、scripts/github/frontend_build_filter.spec.mjsを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `node --test scripts/github/frontend_build_filter.spec.mjs`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: frontend変更とworkflow自身変更がtrue、無関係変更はfalseになる。

## 17. FR-034: 旧枠入口から共通Commandへ委譲する

- [x] 元commit `fcac860` の限定差分を読み、旧FrameEntryのRoot/Add/Remove、compatibility_spec.rb、food/README.md、移行台帳を復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
  旧Fillは既存の委譲を保持する。移行台帳へ内部継承と認可を許容差分として追記し、旧定数/返却class/本人属性の照合を行う。
- [x] `backend bundle exec rspec spec/domain/business/food/meal/frame_entry spec/domain/business/food/meal/frame`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 本人操作の返却class・値・単一保存を維持し、他人の削除を拒否。旧Fill委譲とFR-008を保持する。

## 18. CR-001: 複数タグに分かれた語で同じ料理を検索する

- [x] 元commit `ddfef5a` の限定差分を読み、food/dish/usecase/dish_searcher.rbとspecを復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
- [x] `backend bundle exec rspec spec/domain/business/food/dish/usecase/dish_searcher_spec.rb spec/graphql/query/dish`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 同じ料理の別タグalpha/betaへ一致するAND検索が成功し、別料理/他人のタグを組み合わせない。FR-007保持。

## 19. CR-002: 既存タグの編集内容を原子的に保存する

- [x] 元commit `30c86bb` の限定差分を読み、Dish/DishTag、ReflectLatestNormalizeWordCommand、replacement/GraphQL spec、移行台帳を復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
  先に復帰したFR-024のtransactionを保持して再正規化callerを適応し、cr002-reflection-migration.mdへ現在の対応を追記する。
- [x] `backend bundle exec rspec spec/models/dish_tag_replacement_spec.rb spec/graphql/mutation/dish/existing_tag_update_spec.rb spec/domain/business/food/dish/word`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 既存タグID不変でcontent更新・再取得が成功し、不正所属は副作用前に拒否。辞書再正規化で古いRootが上書きしない。

## 20. CR-004: 延期/予定食事を一度だけ消費する

- [x] 元commit `02e2caf` の限定差分を読み、両変換resolver、Postponed::RemoveCommand、conversion_atomicity_spec.rb、専用MySQL spec/helper（FR-019 specは戻さない）を復帰する。元の追加退行testも現在の採用範囲へ復帰・適応する。
  専用MySQLが現在利用可能でなければ新serviceを作らず、並行再実測は未実施と明記する。旧MySQL結果を今回の再実測へ流用しない。通常testと元commitとの差分照合は実施する。
- [x] `backend bundle exec rspec spec/graphql/mutation/meal/postponed spec/domain/business/food/meal/postponed`、変更箇所lintと必要な型/目視確認を実施し、下記DoDと保持範囲を確認する。
- [x] 共通契約に従いfinding/application/チェックを更新し、この指摘だけを追加commitする。

DoD: 逐次再送/他人を拒否し、変換失敗はrollback。row lockを保持し、新しいMySQL serviceを起動しない。

## 20A. FR-018: 日付交換の保存を原子的にする

- [x] 次の既存2specへtestを先に追加する。
  `backend/spec/domain/business/food/meal/usecase/swap_meals_between_days_command_spec.rb`、
  `backend/spec/domain/business/dish/meal/command/swap_meals_between_days_command_spec.rb`。
  新旧Command直接呼出しでdate1集合→date2集合の返却順序と各返却class、日付以外の業務属性、関連枠の全attributes snapshotを確認する。
  空/片側空/同日（同じ食事を2回返す）を維持し、current本人scopeの既存testとlegacy既存認可を保持する。
  date1側の実保存後にdate2側の保存で特定の例外instanceをraiseし、全Meal/枠のreload結果が実行前snapshotと一致して同instanceが呼出元へ届く退行testのredを確認する。transaction呼出mockだけで済ませない。
- [x] 元commit `25471fd`の限定差分を読み、
  `backend/app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb`と
  `backend/app/domain/business/dish/meal/command/swap_meals_between_days_command.rb`の既存`call`全体を`::Meal.transaction`で囲む部分だけを復帰する。
  fetch/保存/concatの順序・引数を維持する。legacy取得scope、Meal/Root/reschedule/Repository/Policy/Finder/GraphQL resolverを変更せず、元`frame_release_spec.rb`全体を復帰しない。
- [x] `backend bundle exec rspec spec/domain/business/food/meal/usecase/swap_meals_between_days_command_spec.rb spec/domain/business/dish/meal/command/swap_meals_between_days_command_spec.rb spec/graphql/mutation/meal/swap_meals_between_days_spec.rb spec/graphql/mutation/meal/ownership_spec.rb`と、変更した2Command/2specのRuboCopを実行する。
  共通契約の既存container・`RAILS_ENV=test`・標準test DBだけを使い、DoD、production限定2path、保護対象保持、diff checkを確認する。frontend変更/追加visualはない。
- [x] 共通契約に従い新request/attemptへ実測を保存し、finding/application/coverage/READMEの現在状態を「原子的保存は部分復帰、枠解除は親steeringで保留」へ訂正する。
  過去の全適用/取消結果を残し、元の枠不整合を解消済みとは数えない。文書をdocument-reviewへ通し、チェック更新後、この指摘の部分復帰だけを追加commitする。

DoD: 新旧交換Commandが正常保存値・返却class/順序・空/片側空/同日とcurrent本人scopeを保つ。後半保存失敗では先行保存を全体rollbackして元例外が届く。枠attributes、legacy取得scope、Meal/Root/Repository/Policyを変えず、原子的保存の部分復帰と枠解除の保留を実測・現在状態記録で区別する。

## 21. 全体差分・記録・検証を閉じる

- [x] `d58c473..HEAD`のproduction/test/config差分を採用指摘へ一件ずつ対応付け、逆方向にも確認する。未分類差分0、先行保持範囲不変を確認する。
  FR-032 S01〜S08、FR-033 I01〜I05を現在の認可を含む採用状態で再照合する。
  FR-018枠解除、FR-019/023/028/CR-003とFR-015追加UIは現在の取消状態のままで、FR-018の復帰は20Aのtransaction部分だけ、FR-019 migration/uniqueとFR-028構成が入っていないことを確認する。
- [x] backend全体: `docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec`、
  frontend全体: `docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand`を実行する。
  static checkは同backendの`bundle exec rubocop`、同frontendの`yarn lint`と`yarn tsc --noEmit --incremental false`を実行する。
  FR-001既存offenseを修正対象へ広げず、既存性/今回回帰/未実施を件数とpathで記録する。
- [x] 同frontend container内の一時source copyを使い、既存build手順でproduction buildする。常駐devの出力を上書きせず、必要なら既存検証と同じ生成済みCSSの`NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 yarn next build`を用いる。repositoryの設定や保護Dockerfileを変更しない。
- [x] visual-inspector childで、料理編集の手間保持、パターン未選択/再選択、出典なし食事編集、カレンダーの週/月遷移と延期後再取得を最終目視する。各phaseの目視の代替にはしない。実DB操作は行わない。
  > 確認日時: 2026-11-06（JST）
  > 総合結果: ✅ 指定5群正常、人工fixture・実DB未操作
  > ログ: `frontend/inspect/visual/tmp/full-final-attempt-1/result.md`
  > 料理手間: 期待17/17/null/null、結果一致 ✅
  > パターン: 期待未選択0件・再選択ID1、結果一致 ✅
  > 出典なし食事: 期待source/relation null送信とfixture成功、結果一致 ✅
  > 週/月遷移: 期待URLと表示一致、結果8状態一致 ✅
  > 延期後再取得: 期待calendar待機後一覧再取得・終了、結果一致 ✅
  > 別観測: 手間明示解除画面の横ずれ・左ラベル欠け、再選択直後のエラー残存、開発環境issue表示。内部契約と永続化は自動testの範囲。

- [x] README/application/coverageと関連する旧RV/CRの現在採否・状態を照合して訂正する。個別findingの履歴を残し、旧「全関数契約保存」「6fileだけ」「認可も全取消」を現在の合意として読ませない。文書はdocument-reviewを通す。
- [x] 実装feedbackが出たら、受領ownerが同workdirのimplementation_review.mdで根本原因/コードから読める知識か/恒久記録先を整理する。永続知識はdoc-enricherの提案に留め、未承認のREADME変更を広げない。
  本設計外の有効な業務操作変更が必要になった項目だけを親Solへ戻し、独立した確定項目は続行する。
- [x] 全体訂正記録を追加commitする。既存の継続・公開指示に従いfeature-287をpushし、既存PR #292のtitle/bodyを最終採否・validation・未実測へ訂正する。新しいPR/mergeは行わない。
- [x] 親steeringへ確定先行範囲の実装結果と、FR-018枠解除、FR-019/023/028/CR-003、FR-015追加UIの個別判断を返す。全レビュー作業完了へ読み替えない。

DoD: 確定範囲の正常操作・内部修正と現在の採否が実装/test/記録/PRで一致し、未実測と親に残る判断を明記している。保護差分と実環境を変更していない。

## 22. CI followup: backendの両CIを本体実行・成功まで確認する

- [x] `.github/workflows/ci-backend-test.yml`と`.github/workflows/ci-backend-rubocop.yml`の`runs-on`だけを`ubuntu-24.04`へ固定する。
  Ruby `3.3.8`、Gemfile/.ruby-version/lock、変更検出と本体実行stepを保持する。
  両YAMLをstdinで順に渡し、既存backend containerの`ruby -rpsych -e 'Psych.parse($stdin.read)'`でparseする。
  diffでrunner以外に変更がないことを確認してrunner修正だけを追加commitする。
- [x] `backend/app/controllers/admin/base_controller.rb`の2つの`ENV[]`を`ENV.fetch(key, nil)`へ置き換える。
  `backend/spec/support/admin_authentication.rb`と`backend/spec/requests/admin/authorization_spec.rb`の対応stubを`fetch(key, nil)`へ適応する。
  nil/空文字と正誤credentialの既存意味・認証機能のFR-001保留を保持する。lint抑制/除外、認証仕様変更、記法を写すだけの新testを追加しない。
- [x] 親Solをphysical ownerとするtest-runnerへ依頼し、既存backend container・`RAILS_ENV=test`の標準test DBで`bundle exec rspec spec/requests/admin spec/system/admin`、`bundle exec rspec`、`bundle exec rubocop`を実行する。
  管理認証/管理CRUDの期待を保って成功し、全RuboCopが0 offensesとなることを確認する。失敗は原因を特定して採用範囲内で修正・再実行し、新しい業務判断が必要なものだけ親Solへ戻す。
  実装5file限定、保護3fileのhash/mode保持、index混入なし、diff checkを確認し、認証lint記法とstub適応だけをrunnerとは別の追加commitにする。
- [x] 既承認の指示に従いfeature-287をpushし、既存PR #292の最新source SHAに対するCI Backend Test/CI Backend Rubocopを確認する。
  Setup Rubyが通ったことに加え、RSpecとRuboCopの本体stepが実行され、両jobが成功するまで確認する。変更なしskip、旧SHAの成功、local結果を代替にしない。
  CI失敗時はlogで原因を特定し、この範囲の修正は追加commitで直して再確認する。履歴改変・mergeは行わない。
- [x] 新request/attemptに変更source SHA、local全RSpec/全RuboCop/YAML parse、CI本体の結果・URL・SHAを保存する。
  README/application/coverageとPR #292説明へ後続結果を追記し、source `3d832f5`の既存成功/既存offense/未実測は当時の履歴として保持する。
  FR-001はlint記法だけの修正で認証機能は保留、その他保留と未実測も継続と明記する。文書をdocument-reviewへ通して記録訂正を追加commit/pushし、PRの最終SHAに対する両CI本体の成功を確認してチェックを更新する。

DoD: 既存Rubyと認証仕様を保った限定5fileの修正で、local全RSpec・全RuboCop・YAML parseとPR #292の両CI本体が成功する。最新source/URLへ結び付く後続記録を残し、旧sourceの検証履歴、保留、保護差分、実環境を変更していない。

## 23. PR followup: 旧枠エントリdomainを削除し現行coverageへ集約する

- [x] baseline `94623f6`の旧4file/旧5spec/現行specをdesignの対比へ照合し、編集前に`evidence/fr034-migration.md`へ新時点の構造/機能台帳を追記する。
  利用者の「2:いらない方消して」により旧4定数・旧返却class・旧Rootのunassign非公開をRETIRE、現行の通常保存/認可と有効testをKEEP/MOVEとする。旧台帳・実測は上書きしない。
- [x] `backend/app/domain/business/food/meal/frame_entry/`のRoot/Add/Fill/Removeの4fileを削除する。現行`Business::Food::Meal::Frame::Entry`、GraphQLの`Mutations::Meal::FrameEntry`と`Types::Input::Meal::FrameEntry`、ActiveRecordの`MealFrameEntry`とtable名を維持する。
  旧specのAdd4例/Fill2例/Remove3例は現行と重複するため削除し、旧pathのUnassign3例は`backend/spec/domain/business/food/meal/frame/entry/usecase/unassign_meal_command_spec.rb`へ全移動する。supportへのrequire_relativeを1階層深くし説明を現行Root名へ揃える。
- [x] 旧compatibility specから現行に必要な契約を移管する。新`backend/spec/domain/business/food/meal/frame/entry/root_spec.rb`へ全6属性/型変換・assign_meal・set_id初回成功/再設定拒否・必須4属性を残す。
  現行Add specへ単一persist/DB一件/保存属性一致/private constructor、現行Remove specへ他人削除拒否/全attributes不変を追加してから旧compatibility specを削除する。
  現行ownership specは旧namespace loop分だけ除き、current5例を維持する。旧class identity/unassign非公開は削除許可に基づく廃止、旧Fillの現行Root返却/保存は現行Fillで保持する。
- [x] `backend/app/domain/business/food/README.md`の旧compat説明を現行domainの説明へ置換し、`backend/docs/ai_guideline/development_standard/application_architecture.md`の属性同期例を`Business::Food::Meal::Frame::Entry::Root`へ正す。
  FR-034台帳/finding、README/application/coverageへ最新削除判断とcase移管の対応を記録し、過去の互換維持/取消/復帰は当時の履歴として保持する。文書をdocument-reviewへ通す。
- [x] 親Solをphysical ownerとするtest-runnerで`backend bundle exec rspec spec/domain/business/food/meal/frame/entry spec/graphql/mutation/meal/frame_entry`、`backend bundle exec rspec`、`backend bundle exec rubocop`、`backend bin/rails zeitwerk:check`を実行する。
  test設定でeager loadし旧domain定数が定義されず現行Root/Commandが存在することを確認する。
  `rg -n 'Business::Food::Meal::FrameEntry|Meal::FrameEntry|FrameEntry::Root|meal/frame_entry' backend/app backend/spec backend/docs scripts .github`の結果を分類し、旧domain参照0と別の公開GraphQL/ActiveRecord名保持を確認する。`.steering`の旧履歴は消さない。
  共通契約の既存backend・`RAILS_ENV=test`・SQLiteだけを使用し、保護3file hash/mode、評価Command所有者guard、他保留、diff checkを確認する。結果を新request/attemptへ保存し、この削除/移管だけを追加commitする。

DoD: domainは現行入口に一本化され、旧4定数が消え、GraphQL/ActiveRecord名と通常保存/認可を維持する。旧互換専用期待だけが廃止され、有効caseのKEEP/MOVE先と削除行が台帳で対応し、関連/全backend検証とautoload確認が成功する。

## 24. PR followup: 原子的な辞書反映specを操作ごとに整理する

- [ ] `backend/spec/domain/business/food/dish/word/usecase/atomic_reflection_spec.rb`を4つの具体Command describeへ分ける。
  編集前にbaseline `94623f6`の4操作と全期待の移管先を新attemptへ対応付け、期待の削除なしでshared_context/shared_examplesへ移す。
  `Business::Food::Dish::Word::Usecase::AddCommand`は辞書作成なし、`UpdateCommand`/`RemoveCommand`/`ReflectLatestNormalizeWordCommand`は各既存辞書letを持ち、各subjectはそのCommandを直接呼ぶ。
  共通shared_contextに2料理/各タグ、実行前全attributes snapshot、後半保存失敗注入を一定義にし、各操作の辞書fixtureと共通fixtureを生成した後・subject実行前にsnapshotを固定する。
  operationのeach/case/unlessによる選択や共通側でのsubject切替をなくし、個別describeへ固有事情だけを追加できる構造にする。production4Command/transactionは変更しない。
- [ ] shared_examplesへ共通期待をまとめる。後半保存時の先行料理/先行タグの実保存観測を名前付きhashにし、観測一回・実行前から変更済み・既存例外typeと`late persistence failure`を維持する。
  aggregate_failuresで辞書全行/2料理/各タグの全attributes rollbackを個別に識別できるようにする。位置依存の`observed.first[0]`等を残さず、4操作のcoverageを減らさない。
- [ ] 親Solのtest-runnerで`backend bundle exec rspec spec/domain/business/food/dish/word/usecase/atomic_reflection_spec.rb`、`backend bundle exec rspec`、`backend bundle exec rubocop`を実行する。
  4操作とも先行実保存後の後半失敗と全属性rollbackを確認し、差分がspec整理だけであること・保護3file/評価Commandguard/他保留保持・diff checkを確認する。新sourceの結果を保存し、このspec整理だけを23と別の追加commitにする。
- [ ] 既承認指示に従いfeature-287をpushし、PR #292の最終headでCIが成功すること、特に両backendのRSpec/RuboCop本体が実行され成功することを確認する。
  README/application/coverageとPR説明へ最新指示の対応・source/結果/CI URLを追記し、旧source結果は保持する。文書review後、記録を追加commit/pushした最終headでもCI成功を確認してチェックを閉じる。
  frontendコード変更/local frontend再実行、実DB migration/AWS/Webhook/新Compose service/merge、plugin保留3件解除は追加しない。

DoD: 各操作の固有setupとsubject、一定義の共通fixture/失敗注入、共通rollback期待が分かれ、操作条件分岐と位置依存なく4操作の原子性coverageを維持する。関連/全backend検証と最終headのCIが成功し、23/24は別commit・記録から辿れる。
