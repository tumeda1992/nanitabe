# 確認範囲

対象はREADME記載の現行HEAD全体。直近差分だけを対象としない。主要経路の静的追跡と、一部の問題の追加再現を行った。全558候補ファイルの逐行監査を意味しない。

| 領域 | 確認した経路・観点 | 結果・限界 |
| --- | --- | --- |
| 方針・設計 | AGENTS、backend/frontend指示、food/meal README、旧レビューの記録形式 | 現行namespaceと設計契約を確認。文書全体の監査ではない |
| backend入口 | routes、ApplicationController、GraphqlController、Schema、BaseField、QueryType/MutationType、登録/ログイン補助 | 認証と所有者認可を区別。管理GETの未認証アクセスを実測 |
| 食事 | 登録3経路、更新、削除、交換、延期/確定、root/policy/model、カレンダーFinder | 所有者・関連先・移動時の整合性を追跡。越境料理参照と移動時不整合を実測 |
| 料理・出典・タグ | CRUD、検索固定ID、検索scope、関連付け、手間レベル、評価旧Command/Repository、出典別Finder | IDの伝播と保存処理まで確認。全検索条件の組合せや実MySQL実行は未検証 |
| 辞書・管理 | CRUD controller、正規化・全件反映、モデル、関連spec | RegexpErrorを実測。途中失敗の原子性とrescue経路は静的確認 |
| 枠・パターン | CRUD、適用、fill/unassign、親子入力、Dataloader、モデル・FK/index、旧namespace | 越境枠参照と同じ食事の二重割当を実測。同時リクエストの実験は未実施 |
| frontend基盤 | layout、Apollo provider/client、認証hook、共通mutation/query、論理history、warmup | history同期欠落をProvider単体で実測。SSR多利用者・実ブラウザ通信は未確認 |
| frontend入力 | 料理/食事フォームと変換、手間select、パターン作成編集、schema、検索panel | placeholder再選択のNaNを実測。全UI部品の見た目・アクセシビリティは未監査 |
| カレンダー | 週/月route、日付解釈、共通Calendar、移動/交換/延期hook、FrameCard/MealCard、refresh | 日付/関連ID/Promiseの流れを確認。ブラウザの遅延・モバイル操作は未検証 |
| テスト | frontend全Jest、backend food domain/GraphQL、認証helper、追加probe | 既存215件/568件成功。追加probe 2件/6件で問題挙動を実測。backend全体RSpecと新しい型検査は完了結果なし |
| CI | frontend build/test、backend test/deploy、review Terraform plan/apply、terraform-run action | 変更検出・HTTP失敗判定・権限を確認。GitHub Actionsの実行はしていない |
| インフラ運用 | OIDC role、ECS、API Gateway、CodeBuild/CodePipeline、scheduler、alarm、起動停止script | state書込み範囲、公開経路、起動失敗時cleanupを確認。AWS実設定・Terraform plan/apply・通知/Webhook送信は未実施 |

生成GraphQLの全内容、lockfile依存脆弱性、画像/CSS全体、全テストの逐行確認、prod Terraform root全体、実運用ネットワーク到達性は未監査。これらについて問題なしとは判定しない。

## 前回適用8件の現状

入力変換（frontend/backend）、辞書属性生成、モードliteral型、共通パターンフォーム、日付パーサー、一覧のbatch取得、food責務文書の変更を現行コードと旧コードで照合した。今回、これらの抽出自体による確定的な新規回帰は発見していない。ただし元から残る不正入力・認可・画面状態の問題は別途指摘した。batch取得のSQL応答順はORDER BY契約がないためDBをまたぐ厳密保証まではしていない。

## 適用時の確認追加（2026-11-01、FR-013まで）

FR-002〜012の反映後、既存開発用Compose内でbackend全体821 examples / 0 failuresを確認した。frontend変更前のJestは39 suites / 215 tests、型検査も成功した。

FR-013の変更後は料理/食事フォーム10 suites / 52 tests、backend料理詳細/カレンダー7 examples、型検査と変更箇所lintに成功。実ブラウザは人工データのGraphQLモックで手間の表示・送信4項目を検証し、画像4枚を目視した。実DB保存の再読込は含まない。390px幅の横はみ出しは別観測であり、変更前比較は未確認。既存専用Composeを追加せず、開発用`compose.dev.local.yml`を使用する。

FR-014は実ApolloのObservableを保留してloading/error、callback省略、6 mutation経路の集約を検証し、最終14 testsと型検査/lintが成功。FR-015はclearStore/refetchを個別保留・拒否するtestと、実ブラウザの更新失敗→再取得を確認した。実ブラウザは全GraphQLモック、登録mutation1回、5画像目視であり、実DBへの登録確認は含まない。


## 最終検証（2026-11-02）

source/testの固定点は`3dcad04`。当初のAstraレビューを入力にした適用工程であり、新しいAstra全体レビューを実施済みとは扱わない。

| 検証 | 結果 |
| --- | --- |
| backend全RSpec | 937 examples / 0 failures |
| frontend全Jest | 47 suites / 283 tests成功（fixture由来のconsole警告は残る） |
| TypeScript | tsc --noEmit成功 |
| frontend全ESLint | src 239 files、0 errors / 0 warnings |
| backend全RuboCop | 492 files、保留FR-001の既存2 offensesのみ。今回の変更fileは0 offenses |
| 運用・Terraform/IAM・CI条件 | Node 68 tests成功、bash syntax/diff check成功 |
| MySQL並行・migration | CR-004の2件＋FR-019の4件、すべて成功。独立接続・専用fixture DBで実測 |
| eager load | test設定のzeitwerk:check成功。既存libはeager_load対象外という警告は継続 |
| Next production build | 最終commitのsourceを既存container内の一時copyでbuildし、静的19ページ生成まで成功 |
| Terraform | 変更5ファイルfmt、固定依存の隔離copyでreview/prod root init/validate成功 |

RuboCopの残りはapp/controllers/admin/base_controller.rbのStyle/FetchEnvVar 2件。利用者が保留したFR-001の既存WIPであり、作業開始時affd7ecとbyte一致を確認したため今回変更しない。一時検証Rubyの名前/書式も整理済みで、生成artifactを既存source違反として混ぜていない。全体lintが完全greenとは報告しない。

production buildはgit archiveで取得したcommitted sourceを使い、既存node_modulesと生成済みCSSを再利用した。常駐CSS watcherは重複起動していない。外部dependency symlinkを解決するTurbopack root指定は一時copyにだけ設定し、repository/dev設定は変更しない。通常テスト時の作業treeには利用者由来3差分を維持しており、それらはcommit対象外である。

ブラウザ確認は各FRのrequestsにある人工fixture/GraphQL mockで行ったもので、実DBへのUI保存を証明しない。実DB migration、AWS apply/実効IAM権限/Host偽装の直アクセス拒否、実Webhookは今回未実施。FR-019のunique index導入は実データに既存重複があれば停止する設計である。TerraformのARM h1追加は検証copyだけで、repository lockfileのversion/constraint/hashは変更していない。

一時MySQLは検証後にservice/dataを除去済み。既存の開発backend/frontendは継続稼働している。再発防止の恒久documentは提案のみで、未承認の追加規範を適用しない。

## 公開後のCI（2026-11-02）

公開head `b843000`のPR-triggered runではfrontend test/lint/buildとTerraform plan prod/reviewが成功した。backend test（[run 41364503462](https://github.com/tumeda1992/nanitabe/actions/runs/41364503462)）とbackend RuboCop（[run 41364503213](https://github.com/tumeda1992/nanitabe/actions/runs/41364503213)）はSetup Rubyで失敗し、RSpec/RuboCop本体は実行されていない。

両jobの実ログは`Unavailable version 3.3.8 for ruby on ubuntu-26.04`を示す。両workflowの`ubuntu-latest`とRuby3.3.8指定はorigin/mainから変更しておらず、今回の修正によるテスト失敗とは区別する。既存の開発container内で成功したbackend937件/変更箇所lintを、GitHub CI成功とは読み替えない。runner/Ruby対応の改訂は今回のreview指摘の反映に追加せず、CI全greenとは報告しない。保留FR-001の既存RuboCop2件も別に残る。

## FR-018 交換の原子的保存（2026-11-06）

新旧Commandは正常返却class・順序・空/片側/同日・枠属性と後半失敗時の実保存rollback/同一例外を確認。RSpec 30 examples成功。枠解除は移動時の業務契約が未確定のため保留し、契約確定時に再評価する。枠不整合は未解消。
