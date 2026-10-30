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
