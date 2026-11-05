# 挙動維持へ戻すtasklist

仕様の正本は[design.md](design.md)。2026-11-04の利用者訂正に基づく修復の実行計画である。
以前の全件適用tasklistの完了チェックは旧snapshotの実行履歴であり、今回の完了を意味しない。
旧版はgit show 608ed3d:.steering/2026/202610/20261027-full-repository-review/tasklist.mdで参照できる。
同directoryにroadmapは作らず、このtasklistだけを実行状態の正本とする。

## 0. 保持対象と記録の開始

- [x] 復元baseline d58c473、修復開始snapshot608ed3d、branch feature-287を照合し、修復前差分の対象pathを固定する。
  .gitignore、frontend/Dockerfile、frontend/src/lib/generateApiOrigin.tsのbinary patchとhash保全を照合する。
  親の保全先は/tmp/nanitabe-preserved-user-20261104.patchと/tmp/nanitabe-scope-repair-preserved-hashes.jsonである。
  .codex/rules/default.rulesも復元対象に含めない。利用者変更をstageしない。
- [x] 既存README/applicationの訂正noticeを確認し、実行開始とbaselineをapplicationへ記録する。
  親が797a929でcommitしたnoticeを保持し、実行担当が以後のapplication/finding/tasklistのsingle writerになる。
  旧designの制限解除は利用者の合意ではなかったことを記録する。
  CR側のdesign/tasklistも、今回のdesignが優先され再適用しない状態へ訂正する。

DoD: baselineと利用者変更の保持先を実装担当が特定でき、旧完了表示を今回の許可・完了根拠として使わない。

## 各復元項目に共通する実行契約

以下を掲載順に実行する。一項目の関連testがgreenになる前に次項目へ進まない。
各項目は、記載した挙動を加える前の実装へ戻す一つの検証・追加commit単位である。

1. 指定commitの実差分とcallerを読み、production・test・運用説明を閉じた範囲として限定する。
   .steeringの元finding/evidenceを逆patchで消さない。保全対象3fileへ触れない。
2. その項目で変更された既存testを戻し、新挙動専用の追加testを実行treeから除く。
   原版はGit608ed3dで保存される。skip/pending化で件数を維持しない。
   既存testが残す入力・出力・例外・副作用と実装の対応を確認する。
3. worktreeへの限定した逆patchまたはrevisionからの再構成で実装を戻す。
   git revert、reset、rebase、amend、force pushを使わない。
   FR-032/033の純粋な抽出と先行8件、FR-031、FR-001 WIPを保持する。
4. 変更した領域の既存関連test、変更箇所lint、diff checkを既存開発containerで実行する。
   失敗は旧testとの比較から切り分け、新しい業務判断で修正しない。
   運用系は外部I/Oをstubにした検査かbaselineとの全量比較・構文検査で検証し、AWS/Webhookは呼ばない。
5. findingの現在状態を「挙動維持のため適用取消」に訂正し、元指摘・元実装・元検証は履歴として残す。
   applicationへ復元範囲・検証・制約を記録し、tasklistを実測直後に更新する。
6. plan-commitsで今回の実差分を再確認し、同じ指摘のproduction/caller/test/現在状態の記録だけを追加commitする。
   commitはrevert:に対象効果と指摘IDを付ける。履歴・既存commitは書き換えない。

## 1. 依存の逆順で範囲外の挙動変更を戻す

### 1. CR-004: 延期・予定食事の変換に加えたrow lockと所有者絞込みを戻す

- [x] 元変更 `02e2caf` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: 両GraphQL resolver、Business::Food::Meal::Postponed::Usecase::RemoveCommand、conversion_atomicity_spec、
  spec_mysql/meal_conversion_concurrency_spec.rb。mysql_spec_helper.rbの変換用checkpointだけを戻し、
  FR-019のframe_assignment_spec.rbが使う接続guard・cleanup・RSpec設定は項目FR-019まで保持する。

DoD: 食事延期・予定化がbaselineと同じ取得・例外・保存順になる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-cr004-1 / attempt1 passed。RSpec25 examples / 0 failures、RuboCop4 files / 0 offenses、
production3file旧版byte一致とFR-019残部保持を確認。[結果](evidence/scope-repair/cr004-attempt-1/result.md)。

### 2. CR-003: 関連料理がある出典のtype変更拒否を戻す

- [x] 元変更 `45074dc + 852718f` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: DishSource validation、TypeChangePolicy、境界spec、後から変更したlegacy source spec。

DoD: 出典更新の許容条件と関連先の扱いがbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-cr003-1 / attempt1 passed。RSpec135 examples / 0 failures、RuboCop2 files / 0 offenses、
旧版byte一致、保護対象の保持、diff check成功。[結果](evidence/scope-repair/cr003-attempt-1/result.md)。

### 3. CR-002: 既存タグ内容の保存と再正規化caller適応を戻す

- [x] 元変更 `30c86bb` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: Dish/DishTag、ReflectLatestNormalizeWordCommand、タグ更新・置換spec。FR-024の既存transactionはその項目まで残す。

DoD: 料理編集の既存タグと辞書再反映がCR-002以前の保存経路になる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-cr002-1 / attempt1 passed。RSpec360 examples / 0 failures、RuboCop3 files / 0 offenses、
旧版byte一致、FR-024/FR-004と利用者変更保持、diff check成功。[結果](evidence/scope-repair/cr002-attempt-1/result.md)。

### 4. CR-001: 単語ごとの相関EXISTSによる検索結果変更を戻す

- [x] 元変更 `ddfef5a` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: DishSearcherと既存検索spec。

DoD: 複数タグにまたがる語の検索結果がbaselineの条件へ戻る。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-cr001-1 / attempt1 passed。RSpec36 examples / 0 failures、RuboCop2 files / 0 offenses、
旧版byte一致、FR-007と利用者変更保持、diff check成功。[結果](evidence/scope-repair/cr001-attempt-1/result.md)。

### 5. FR-034: 旧Rootの継承と旧Add/Removeの委譲を戻す

- [x] 元変更 `fcac860` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: 旧frame_entryのRoot/Add/Remove、互換spec、food README。旧FillのFR-008由来変更はFR-008で戻す。

DoD: 旧Rootの継承関係と旧Add/Removeの認可・返却がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr034-1 / attempt1 passed。RSpec74 examples / 0 failures、RuboCop3 files / 0 offenses、
eager load・旧継承・4file旧byte一致・旧Fill/利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr034-attempt-1/result.md)。

### 6. FR-030: frontend workflow自身のfilter変更を戻す

- [x] 元変更 `a871b4c` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: .github/workflows/ci-frontend-build-verification.yml、専用Node検査。

DoD: workflowの起動条件がbaselineと一致する。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr030-1 / attempt1 passed。Node3 cases / 0 failures、旧workflow byte一致・専用suite除去・
利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr030-attempt-1/result.md)。

### 7. FR-029: デプロイWebhookのHTTP失敗判定・timeout追加を戻す

- [x] 元変更 `d3e4515` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: .github/workflows/backend-deploy.yml、専用Node検査。実Webhookは呼ばない。

DoD: Webhook呼出しのcommandがbaselineと一致する。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr029-1 / attempt1 passed。Node5 cases / 0 failures、旧curl byte一致・loopback限定・
利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr029-attempt-1/result.md)。

### 8. FR-028: private integrationと新規AWS構成への依存を戻す

- [x] 元変更 `2bf938d` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: backend/terraformの4module/env、start/stop/common、対応する運用説明、private integration検査とreadiness spec。

DoD: TerraformとscriptがFR-027時点の同じ契約で動作し、新規構成のapplyを要求しない。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr028-1 / attempt1 passed。Node31 tests / 0 failures、bash構文、13path旧byte比較・
FR-027保持・運用3doc訂正・利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr028-attempt-1/result.md)。

### 9. FR-027: 起動失敗時rollback拡張を戻す

- [x] 元変更 `7772f90` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: scripts/review_backend/start.sh/stop.sh/common.shと専用stub/test、対応する運用説明。

DoD: 起動停止の入出力・失敗経路がbaselineと一致する。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr027-1 / attempt1 passed。Node7 cases / 0 failures、bash構文・start/stop旧byte一致・
利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr027-attempt-1/result.md)。

### 10. FR-026: plan用roleの権限縮小を戻す

- [x] 元変更 `df42ad7` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: infrastructure/terraform/modules/github_oidc/main.tfと専用検査。

DoD: plan role定義がbaselineと一致する。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr026-1 / attempt1 passed。静的Node3 cases / 0 failures、旧policy byte一致・専用suite除去・
利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr026-attempt-1/result.md)。

### 11. FR-025: 辞書削除rescueのinstance変数修正を戻す

- [x] 元変更 `4a12564` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: NormalizeWordsControllerとadmin request spec。FR-001の既存認証は保持。

DoD: 辞書削除の例外経路がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr025-1 / attempt1 passed。RSpec9 examples / 0 failures、RuboCop2 files / 0 offenses、
3file旧byte一致・FR-001 WIP/FR-024と利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr025-attempt-1/result.md)。

### 12. FR-024: 辞書CRUDと全料理反映をまとめるtransactionを戻す

- [x] 元変更 `9b1df0a` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: 辞書Add/Update/Remove、ReflectLatestNormalizeWordCommand、admin view、原子性spec。

DoD: 辞書保存と再反映の順序・失敗時副作用がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr024-1 / attempt1 passed。RSpec86 examples / 0 failures、RuboCop4 files / 0 offenses、
4Command旧byte一致・専用spec除去・既存WIP/利用者変更保持・diff check成功。起動済みsessionから回収し二重実行なし。
[結果](evidence/scope-repair/fr024-attempt-1/result.md)。

### 13. FR-023: 辞書source/destinationのliteral処理を戻す

- [x] 元変更 `73b8797` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: 新旧Normalizerと正規化spec。

DoD: 辞書置換の正規表現・置換文字列の扱いがbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr023-1 / attempt1 passed。RSpec61 examples / 0 failures、RuboCop2 files / 0 offenses、
新旧Normalizer旧byte一致・先行共通化/旧保存境界/利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr023-attempt-1/result.md)。

### 14. FR-022: 食事編集での出典なし新規料理許容を戻す

- [x] 元変更 `5b54e45` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: GraphQL resolver、frontend入力変換/schema参照、生成物、関連spec。

DoD: 食事編集の出典必須契約と送信形式がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr022-1 / attempt1 passed。RSpec3 examples / 0 failures、Jest16 tests、変更箇所lint・tsc成功。
8path旧byte比較・純抽出と利用者変更保持・diff check成功。既存fixture警告あり。[結果](evidence/scope-repair/fr022-attempt-1/result.md)。

### 15. FR-021: URL日付の実在日・境界検証を戻す

- [x] 元変更 `c240b94` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: calendarDateFromPathと既存spec。RV-029の日付パーサー共通化は保持。

DoD: 無効日付とquery/hashの解釈がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr021-1 / attempt1 passed。Jest8 tests・lint2file・tsc成功、helper/spec旧byte一致・
先行共通化/FR-020残部/純抽出/利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr021-attempt-1/result.md)。

### 16. FR-020: Next pathname/searchとの論理履歴同期を戻す

- [x] 元変更 `d8afcf0` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: logical-history.tsxと専用spec。

DoD: Next遷移・push・popの論理URL更新条件がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr020-1 / attempt1 passed。consumer Jest16 tests・Provider lint・tsc成功、旧byte一致・
専用spec除去・純抽出/利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr020-attempt-1/result.md)。

### 17. FR-019: 一食一枠の制約とmigrationを戻す

- [x] 元変更 `01e5394 + 3dcad04` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: unique migration、schema、AssignMealPolicy、現行Fill、cardinality/migration spec、spec_mysql残部。

DoD: 一つの食事の複数枠割当可否がbaselineに戻り、新migrationが不要になる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr019-1 / attempt1 passed。二重guard後にtest SQLite限定schema load・再guard・unique不在確認。
RSpec70 examples / 0 failures、RuboCop2 files / 0 offenses、9path旧比較・純抽出/利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr019-attempt-1/result.md)。

### 18. FR-018: 食事移動時の枠解除と交換transaction追加を戻す

- [x] 元変更 `25471fd` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: Meal保存、新旧Repository/Swap、ReleaseFrameOnReschedulePolicyと専用spec。

DoD: 日付・時間帯変更と日付交換の枠状態・保存境界がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr018-1 / attempt1 passed。RSpec81 examples / 0 failures、RuboCop4 files / 0 offenses、
6path旧比較・解除参照なし・FR-002/003残部/純抽出/利用者変更保持・diff check成功。[結果](evidence/scope-repair/fr018-attempt-1/result.md)。

### 19. FR-017: 未選択パターン枠のnull処理と拒否を戻す

- [x] 元変更 `62359ad` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: MealFramePatternFields、フォームspec。FR-032のnumber schemaは保持。

DoD: 未選択操作のフォーム値と送信条件がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr017-1 / attempt1 passed。Jest19 tests・lint2file・tsc成功、旧form/spec byte一致。
d58c473元schemaとの120ケースがdata/issues順まで一致しshared schemaの変更不要。純抽出/利用者変更保持・diff check成功。
[結果](evidence/scope-repair/fr017-attempt-1/result.md)。

### 20. FR-016: インスタンスごとのdebounce cleanupを戻す

- [x] 元変更 `5319fbd` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: DishSearchPanelと専用spec。

DoD: 複数検索パネル・unmountのtimer挙動がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

検証: scope-repair-fr016-1 / attempt1 passed。Jest4 tests・lint成功、旧index byte一致・専用spec除去・
純抽出/利用者変更保持・diff check成功。既存fixture警告あり。[結果](evidence/scope-repair/fr016-attempt-1/result.md)。

### 21. FR-015: refresh待機と失敗時モード保持を戻す

- [ ] 元変更 `c05d21d` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: カレンダーrefresh、延期・交換mode、表示retry、各関連spec。

DoD: 延期・交換後の非同期完了とモード遷移がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 22. FR-014: Apollo mutation tupleのloading/error返却修正を戻す

- [ ] 元変更 `601d722` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: mutationUtilsと専用spec。

DoD: mutationの公開返却tupleがbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 23. FR-013: 料理編集のeffortId取得と初期値保持を戻す

- [ ] 元変更 `fb59312` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: 料理/食事query、フォーム初期値・選択component、GraphQL出力と生成物、関連spec。

DoD: 編集開始・時間帯変更時の手間レベル表示と送信値がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 24. FR-012: GraphQL任意引数のRuby既定値追加を戻す

- [ ] 元変更 `ceb1da7` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: 料理更新GraphQL resolver3箇所と省略引数spec。

DoD: 省略引数の例外契約がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 25. FR-011: 料理評価の所有者照合を戻す

- [ ] 元変更 `cdb8e27` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: legacy評価Command/Repositoryと専用spec。

DoD: 評価保存の対象と取得条件がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 26. FR-010: 関連枠の所有者検証と一覧取得絞込みを戻す

- [ ] 元変更 `86ab57e` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: pattern entry Add、MealFramePatternEntries/MealFrames source、出力typeとspec。RV-026のbatch取得は保持。

DoD: パターン登録・一覧の関連取得がbaselineと同じ条件になる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 27. FR-009: 関連料理の所有者必須条件を戻す

- [ ] 元変更 `9528fa1` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: AttachDishPolicy、MealFactory/Root/Finders、関連spec。

DoD: 食事登録時に関連料理へ適用する条件がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 28. FR-008: 枠割当の全入口の所有者照合を戻す

- [ ] 元変更 `a2ca053` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: 現行Add/Fill、旧Fill、GraphQL割当spec。旧Fillはbaselineの独立classへ戻す。

DoD: 旧新入口の割当可否と返却classがbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 29. FR-007: 検索先頭固定料理の所有者条件を戻す

- [ ] 元変更 `3751b09` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: DishSearcherと既存検索spec。

DoD: 固定IDに対する検索条件がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 30. FR-006: パターン更新削除の必須user_idを戻す

- [ ] 元変更 `d34ce8c` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: Command・GraphQL両入口・既存Command spec。FR-033のmap共通化を保持する。

DoD: パターン更新削除のsignature・取得・例外がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 31. FR-005: 枠・枠エントリの更新削除の所有者条件を戻す

- [ ] 元変更 `f7b3e68` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: Frame Update/Removeと現行Entry Remove、関連spec。

DoD: 枠更新削除の条件がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 32. FR-004: 料理・出典・タグ更新の所有者条件を戻す

- [ ] 元変更 `8adcbd6` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: 料理/出典Update、AddTag、DishTag置換の関連照合とspec。

DoD: 各更新と関連ID参照の取得・拒否条件がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 33. FR-003: 食事更新削除の所有者条件を戻す

- [ ] 元変更 `f440ac4` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: Meal Update/Removeと専用spec。

DoD: 食事更新削除の取得条件と例外がbaselineと同じになる。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

### 34. FR-002: 日付交換の利用者必須取得とWIPのscopeを戻す

- [ ] 元変更 `03e4828 + affd7ecの2コード/spec path` を前記の共通手順で復元・検証・記録し、当該訂正だけを追加commitする。
  対象: Meal.fetch_by_date、新旧Swap、food Swap specをd58c473へ。affd7ecには食事取得scope変更が既にある。

DoD: 交換対象・公開取得API・返却順がd58c473と一致し、FR-002途中変更も残らない。関連testが成功し、元証拠を残した現在状態とcommitが対応する。

## 2. 保持する共通化と全体の契約を確認する

- [ ] d58c473とのcommit済み最終diffを照合する。production差分はdesignの6fileだけ、test差分はFR-032/033の検証だけである。
  先行8件、FR-031、FR-001 WIPと利用者3file、既存操作許可が保たれたことをhash/diffで確認する。
- [ ] FR-032の台帳S01〜S08とFR-033の台帳I01〜I05をd58c473との実差分に再対応付ける。
  構造の全範囲とcontractの順逆照合を行い、未監査・未分類追加・未分類削除を0にする。
  schema.spec.ts、InputObject spec、パターン作成更新GraphQL specで値・error順・空配列・独立hash・返却値を検証する。
- [ ] backend/db/schema.rb、既存migration集合、Terraform、workflow、起動停止script、関連運用本文がbaselineと一致することを確認する。
  追加migrationの消失だけでなく、呼出しや生成物に新契約が残らないことを調べる。
- [ ] 既存test DBのadapter・接続先・RAILS_ENV=test・indexを確認し、追加unique indexが残る場合だけtest DB限定schema loadでbaselineへ戻す。
  開発DB・実DBのmigration/down操作をしない。新たなMySQL serviceを起動しない。
- [ ] 既存compose.dev.local.ymlのbackendで全体RSpecとRuboCopを実行する。
  commandはdocker compose -f compose.dev.local.yml exec -T backend bundle exec rspecとbundle exec rubocopを使う。
  失敗時はtest-runnerで原因を分離し、今回の回帰は復元範囲内で修正する。既存FR-001 lint2件は変更せず記録する。
- [ ] 同じ既存Composeのfrontendでyarn test、yarn lint、repository既定の型検査とproduction buildを実行する。
  既存DockerfileとgenerateApiOrigin.tsの利用者差分を改変せず、実測したcommand・件数・終了値を記録する。
- [ ] UIの復元影響をvisual-inspector childで確認する。
  料理編集、カレンダー延期・交換、パターン編集の初期値・操作・表示を対象とし、スクリーンショットと未確認範囲を報告する。
  これは利用者自身の操作確認とは区別する。既存の継続・公開許可に形式的な再質問を加えない。

DoD: 挙動変更を保持してgreenにすることなく、限定した共通化と復元baselineの対応、現在の検証結果が説明できる。

## 3. 採否・検証結果と既存PRを訂正する

- [ ] 旧RV/FR/CRのfinding・README・application・coverageを通読し、現在の実装と状態の対応を確認する。
  取り消した指摘を適用済み集計から外す。過去の検証・MySQL実測・元commitは当時の結果として残す。
  FR-034は適用取消、FR-001は既存WIP保留、FR-032/033と先行8件/FR-031は保持とする。
  b859f23の先行8件完成点からFR-001 WIPが加わっていることを明記し、PR全体を純粋なリファクタリングと呼ばない。
- [ ] implementation_reviewへ今回の修復結果と原因を記録する。
  既存の挙動維持制約を解除したassistantの誤判断が原因であり、追加のrepository規範不足とは扱わない。
  doc-enricherやplugin修正の新規作業を加えず、既存の未適用提案はその状態を保つ。
- [ ] 全変更mdへdocument-reviewを適用し、作成時・更新時観点、削った情報、相対link、現在状態と歴史の区別を確認する。
  検証件数を旧snapshotから転記せず、今回の実測と未実施・既存失敗を明記する。
- [ ] 記録全体の訂正と残る純粋な共通化の照合結果を追加commitする。
  実差分をplan-commitsで確認し、利用者3fileの未stageと保持を最終照合する。
- [ ] feature-287に追加commitがあることを確認して通常pushし、既存PR #292のtitle/bodyを完成した挙動維持の差分へ書き直す。
  修復中noticeは結果に更新し、先行8件・FR-031・FR-032/033保持、FR-001の既存認証WIP残置、範囲外適用取消、新migration/AWS apply不要を説明する。
  今回の修復対象の挙動維持と、PR全体にFR-001の認証変更が残ることを分けて報告する。
  履歴改変、force push、mainへの直接commit、merge、deployはしない。
- [ ] 公開後のbranch/PRとtasklistを照合し、復元baseline・保持差分・test結果・残る制約を利用者へ報告する。

DoD: 利用者が既存PRを読んで、何を残し何を戻したか、何を検証し何を検証していないかを把握できる。
