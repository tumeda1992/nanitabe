# 挙動維持の適用範囲へ戻す設計

## 目的と指示の訂正

レビュー後の反映を、外部から観測できる振る舞いを維持するリファクタリングへ戻す。
元の契約は[最初のレビューの目的](../20261025-prepare-astra-code-review/README.md#目的と合意済み方針)にある
「バグと思われる現状の挙動も、この工程では変更しない」である。
2026-11-04、利用者は「挙動変えないと言ったのにmigration/AWS apply必要変更をしたのは目的放棄」と訂正した。
この訂正に従い、実装の復元、テスト、記録と既存PRの訂正まで継続する。

過去のdesignとapplicationにある「全件修正指示が挙動維持制限を解除した」という記述はassistantの誤解である。
これを利用者の合意として扱わない。このdesignは以前の全指摘適用設計を置き換える。
履歴・レビュー証拠を保存しながら現在の採否と実装を訂正する。
利用者による再開・訂正・公開の指示があるため、形式的な再承認や開始確認を追加しない。

## 完成後の姿

### contractの保存と明示差分

| 項目 | 固定する内容 |
| --- | --- |
| 修復開始時点 | `608ed3d2e8c3a94a54bd8a43aa48ee7a2d777665`。既存の指摘適用と公開記録を含む |
| 復元baseline | `d58c47364bc9c3774a1a4b3636938c9c83bd3abc`。先行8件、FR-031、明示保留のFR-001 WIPを含む |
| 再開時checkpoint | `affd7ec1eb9105e27795bcc9ecbdd4f9071af628`。baselineにFR-002の途中変更とレビュー記録を加えた状態 |
| 対象scope | 開始時点とbaseline間で変更されたapplication、実行test、schema、Terraform、起動停止script、workflow、対応する運用説明の全範囲 |
| 残す純粋な共通化の証拠 | [FR-032の台帳](evidence/fr032-migration.md) S01〜S08、[FR-033の台帳](evidence/fr033-migration.md) I01〜I05 |

完成後の業務上の意味差分は、復元baselineに対して**なし**とする。
入力の許容・拒否、返却値、例外、保存値、処理順序、副作用、ログ、非同期完了、表示、公開APIを全量保存する。
認可強化や不具合修正も、改善であることを理由に残さない。
FR-001の既存WIPは、利用者が明示保留した作業の保存としてそのまま残す。
FR-001を検証済み・解消済みとは呼ばず、新たな変更も加えない。

先行8件はRV-001/012/013/014/015/025/026/029であり、baselineに入っている実装を保持する。
FR-031の認証test helperも保持する。branch全体をmainや最初のレビュー前へ戻さない。

先行8件の反映完了点はb859f23である。そこからd58c473までのapplication/test差分のうち、
FR-031はbackend/spec/graphql/graphql_auth_helper.rbとgraphql_auth_helper_spec.rbである。
FR-001 WIPはbackend/app/controllers/admin/base_controller.rb、
同food/dish/effort_level/dish_effort_levels_controller.rb、同food/dish/word/normalize_words_controller.rbの認証関連差分と、
admin/README.md、authorization_spec.rb、admin_authentication.rb、および既存admin request/system specの認証適応である。
これらは明示保留による残置であり、FR-001の認証変更は純粋なリファクタリングではない。
完成報告とPRでは「今回の修復対象を挙動維持へ戻した」と「既存FR-001 WIPが残る」を別々に記載する。
PR全体が純粋なリファクタリングになったとは報告しない。

FR-032は入力schemaの共通化だけを保持する。
numberの許容範囲、空配列、unknown keyのstrip、非coerce、更新時のid→name→entriesの検査順、既存のerrorを変えない。
FR-033は3必須Intの値をsymbol keyへ転記する共通化だけを保持する。
入力順、空配列、独立hash、Command呼出しと返却値を保存する。
FR-033より先に混入していた更新Commandへの必須user_idと認可は、共通化の一部として温存しない。
両台帳の旧baselineと過去の検証は保存し、今回のd58c473との再照合を実行担当が追記する。

FR-034は旧namespaceのRoot/Add/Fill/Removeをbaselineへ戻す。
旧Rootの現行Root継承はis_a?と継承関係を変え、旧Commandの委譲には後続の認可・割当制約が流入している。
返却class名だけの検証を完全互換の根拠にしない。重複解消の再実装を今回の復元へ追加しない。

### codeの責務配置と依存構造

baselineの責務配置を保持し、次の共通ownerだけを追加した状態にする。

```text
frontend/src/features/meal/frame/pattern/schema.ts
  ← パターン作成・更新の既存Zod validationの共通owner
addMealFramePatternMutation.ts / updateMealFramePatternMutation.ts
  → schema.tsを参照し、既存の公開型・hook・operationを維持

Types::Input::Meal::Frame::Pattern::MealFramePatternEntryInput#to_command_params
  ← day_offset / meal_type / meal_frame_idの値転記の共通owner
Mutations::Meal::Frame::Pattern::AddMealFramePattern / UpdateMealFramePattern
  → entries.map(&:to_command_params) → baselineのCommand呼出し
```

最終的なproduction差分の許容リストは次の6fileである。
各fileの差分はFR-032/033の抽出・参照変更だけとし、業務条件は加えない。

- frontend/src/features/meal/frame/pattern/schema.ts
- frontend/src/features/meal/frame/pattern/addMealFramePatternMutation.ts
- frontend/src/features/meal/frame/pattern/updateMealFramePatternMutation.ts
- backend/app/graphql/types/input/meal/frame/pattern/meal_frame_pattern_entry_input.rb
- backend/app/graphql/mutations/meal/frame/pattern/add_meal_frame_pattern.rb
- backend/app/graphql/mutations/meal/frame/pattern/update_meal_frame_pattern.rb

許容する追加testは、frontendのschema.spec.tsとbackendのmeal_frame_pattern_entry_input_spec.rb、
およびパターン作成・更新の既存GraphQL specへの値・順序・空配列のassertionである。
それ以外のapplication/test差分はbaselineへ戻す。
FR-002はaffd7ecで既にCommandとspecを変更しているため、03e4828だけの取消で済ませない。
backend/app/domain/business/food/meal/usecase/swap_meals_between_days_command.rbと対応specもd58c473へ戻す。

実装の復元には変更されたpathの限定集合を使う。
利用者変更3file（.gitignore、frontend/Dockerfile、frontend/src/lib/generateApiOrigin.ts）は内容・modeを保ち、stageに含めない。
.codex/rules/default.rulesの既存の操作許可変更も今回の復元対象へ広げない。
新しいpathの一括削除、git reset --hard、branch全体のcheckoutを行わない。

### runtime・設定・環境構築

新しいDB migrationやAWS構成の適用を、このbranchの利用に要求しない。
FR-019が追加したmigration、unique index、割当Policyと呼出しを除き、backend/db/schema.rbをbaselineと一致させる。
既存のmigrationは保持する。実環境でmigrationを実行・逆実行せず、保存済みの利用者データを変更しない。
検証で残ったunique indexは、接続先を確認した専用test DBだけの再作成・schema loadで除く。

FR-026〜030で変えたTerraform、起動停止script、workflow、対応する運用説明はbaselineへ戻す。
FR-028で追加した構成や出力を参照するscriptだけを残す状態を作らない。
Terraform apply、実AWSへのquery・deploy、Webhook送信は実施しない。
運用の復元は固定revisionとの全file比較、構文検査と外部I/Oをstubにした検証で確認する。
実環境へ変更を反映したとは報告しない。

アプリtestは既存のcompose.dev.local.ymlのbackend/frontendで行う。
RailsはRAILS_ENV=testとrepositoryのtest DB設定を使用する。
Cloud向けComposeや重複アプリcontainerを作らず、新たなMySQL serviceも起動しない。
既存の開発DB、外部DB、AWS、Webhookをtestの接続先にしない。

### 記録から判断できる状態

各READMEから、維持した純粋な共通化、範囲外適用を取り消した指摘、FR-001の保留を区別できる。
正しい指摘でも挙動を変えるため今回は適用しないものを、誤指摘・修正済みと数えない。
元のfinding、再現証拠、red/green結果、元commitは消さない。
applicationとcoverageの過去の結果は当時の実装の証拠として残し、現在の状態を先頭から辿れるよう訂正する。

現在の採否のownerは各finding、現在の実行状態のownerはこのtasklist、実測結果のownerはapplication/coverageとする。
旧RVの対応先とFR/CRのREADMEを同時に確認し、全件修正済みという過去の集計を現状説明として残さない。
20261030-exhaustive-reviewのdesign/tasklistには今回の契約が優先され、CR-001〜004は再適用対象ではないことを明示する。
運用説明で実装の復元により不正確になる本文も、対応する修復と同時にbaselineへ戻す。

実行testで範囲外の新挙動を要求する追加specは実行対象のtreeから取り除き、既存specの変更はbaselineへ戻す。
原版はgit show 608ed3d:<path>で再現できる。.steering/の証拠は残す。
testをskip/pendingへ変えて成功数を維持せず、現在の収集対象と件数を測り直す。
MySQL専用specも今回の完成版では要求しない。過去のMySQL実測を今回のbaseline保証へ流用しない。

## 実行単位と依存

追加commitで訂正し、既存commitのrebase、amend、force pushをしない。
指摘単位でproduction・caller・test・関連する現在状態の記録をまとめる。
順序はCR-004→003→002→001→FR-034→030〜002の逆順とし、FR-032/033と既存のFR-031は取り消さない。
CR-003には補完commit852718f、FR-019にはMySQL補完3dcad04を同じ訂正単位へ含める。
FR-028は後続scriptとの依存を先に取り除いてからFR-027を戻す。
FR-006を戻すとき、FR-033の転記共通化を保持して更新actorの追加だけを取り除く。
FR-002はWIP分も同じ訂正commitで戻す。

復元はworktreeへの限定した逆patchまたは指定revisionからのfile再構成で行い、indexやHEADを一括で戻さない。
git revertの新規権限要求は行わず、既存のgit add/commit/push許可を用いる。
各commitの取り消す効果は対応する指摘が加えた挙動であり、他の純粋な共通化を巻き込まない。
messageはrevert:に具体的な変更と指摘IDを付ける。
記録全体の整合確認とPR訂正は、個別の復元結果が確定した後の追加commitにする。

## 受け入れ基準

1. baselineとのcommit済みproduction差分が前記6fileの純粋な共通化だけである。FR-002 WIPも残っていない。
2. 先行8件、FR-031、FR-001 WIP、利用者変更3file、既存操作許可を保持し、FR-034の認可・継承変更を残していない。
3. schema/migration、Terraform、起動停止script、workflowがbaselineと一致し、新migration/AWS applyを要求しない。
4. FR-032/033をbaselineに対して二層台帳で再照合し、未監査・未分類追加・未分類削除が0である。
5. 関連testと全体のRSpec/Jest、型検査、production build、lintを既存containerで実行し、baseline由来の失敗と今回の回帰を分離する。
   baselineにあるFR-001 WIPを修正してlintを消さず、未実施・既存失敗は件数とpathを明記する。
6. frontend復元の表示・入力影響をvisual-inspectorで確認する。検査対象は料理編集、カレンダーの延期・交換、パターン編集である。
   自動検証と利用者による操作確認を区別し、既存の継続・公開許可の範囲でcommit/push/PR訂正を完了する。
7. reviewの現在状態と既存PR #292が挙動維持の適用範囲を説明し、範囲外の指摘を修正完了と数えていない。
8. 実環境DB/AWS/Webhook/mergeへの操作、履歴改変、利用者変更の巻込みがない。

## 付録: 変更の実行区分

### task-design内で対象成果物へ適用済み

なし。今回のdesign/tasklist自身の改訂は設計のlifecycle更新である。

### task-design内の対象成果物反映待ち

なし。

### execution plan対象

| 対象 | 掲載理由 | 参照するdesign section |
| --- | --- | --- |
| FR/CRが加えた挙動の復元とtest適応 | 本番application codingと依存する段階的な取消 | contractの保存と明示差分、codeの責務配置と依存構造 |
| migration・運用構成の復元 | 本番成果物とその起動・適用条件の復元 | runtime・設定・環境構築 |
| 現在状態の記録、全体検証、既存PR訂正 | 復元結果に依存する複数段階の検証・公開 | 記録から判断できる状態、受け入れ基準 |

## 設計確認

2026-11-04、Git履歴と実差分による読取りでbaseline・保持範囲・復元依存を確定した。
今回の設計担当はコード変更、test実行、Git書込み、外部環境操作をしていない。
暫定指示の取得対象はこの元作業directory、consumerはtask-design/think-through/document-review/plan-commits、
実行元はtumeda-dev 8.2.4の配布skillであり、temporary-overridesは存在せずnoneである。
許可されたrepository contextのtask-designと直接利用する共通sectionを使用し、context instanceは変更していない。
文書reviewでは作成時・更新時観点、削除内容、参照先、baselineと保持差分、既存WIPの例外を通読確認した。
技術的な検証結果は実行担当が観測後に記録し、過去のgreenを復元後のgreenとして扱わない。
