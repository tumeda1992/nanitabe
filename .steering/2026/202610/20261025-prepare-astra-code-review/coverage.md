# 確認範囲と検証記録

- 対象コミット: `46ad16a84c2d4c0cc82d23136573ac139493215e`
- 作業ブランチ: `feature-287`
- 完了日: 2026-10-26
- 方法: 主要経路の静的コードレビュー。入口から業務処理・永続化・呼び出し元を追い、関連するテストと設計文書を照合した。

## 確認した範囲

| 領域 | 確認内容 | 残る確認 |
| --- | --- | --- |
| 方針・設計 | AGENTS、backend/frontend指示、設計・テスト方針、food/mealと旧dishの設計文書 | 文書全体の整合性監査は未実施 |
| backendの入口 | routes、ApplicationController、GraphqlController、Schema、Query/Mutation/Field基底、ログイン・登録周辺 | 実際の認証ヘッダーと稼働設定での到達性 |
| 食事 | 登録・変更・削除・日付交換・先送りのmutation、food mealのusecase/root/policy、Mealモデル | DBを使ったユーザー間操作・例外時の再現 |
| 食事枠・パターン | 枠、枠エントリ、パターンのCRUD・適用・割当、出力型、関連モデル、旧FrameEntry実装との比較 | 動的定数参照、実行時SQL数、同時更新 |
| 料理 | 登録・変更・検索・固定表示、出典、タグ、正規化ワードのusecaseとモデル、旧評価command/repository/entity | 全検索条件の組合せ、既存データ不整合の有無 |
| 管理機能 | 正規化ワード・手間レベルのcontroller、routes、認証前提 | 稼働環境でのアクセス制限・利用者要件 |
| frontend基盤 | layout/provider、Apollo client、認証、API origin、warmup、mutation/query共通処理 | 実ブラウザの通信・Cookie・SSR境界 |
| frontend入力 | 料理・食事の入力変換とフォーム、手間レベル、出典、パターン作成・編集、検索・一括タグ | 全UI部品、アクセシビリティ、表示崩れ |
| カレンダー | 週/月ページと日付処理、割当・移動・交換・先送りモード、カード、再取得、論理履歴 | 通信遅延・失敗時の画面操作とキャッシュ挙動 |
| CI・ビルド | frontend build/test/lint、backend test/rubocop/deploy、Terraform review plan/apply、terraform-run action、buildspec、Amplify設定、Docker関連設定 | CIの実走、本番Terraform workflowは所在確認に留まる |
| インフラ・運用 | GitHub OIDC role、Amplify、ECS/API gateway/scheduler関連定義、起動・停止スクリプト | Terraform plan/apply、AWS上の実設定・外部制限。root module・pipeline/codebuild/alarmは関連宣言の検索確認に留まる |

## 関連テストの確認

以下を重点的に併読した。テストファイル全体・全ケースを網羅して確認したという意味ではない。

- `update_dish_with_new_source_spec.rb`: 任意引数の省略ケースの有無。
- GraphQLとusecaseの`swap_meals_between_days_spec.rb` / `swap_meals_between_days_command_spec.rb`: 同一日付・ユーザー限定の前提。
- `fill_meal_frame_entry_spec.rb`: 他ユーザーの実在mealを検証しているか。
- `normalizer_spec.rb`: 特殊文字とDB検索を組み合わせた検証の有無。
- 管理用手間レベルのrequest spec: 未認証での成功を期待する現状。
- 料理更新のeffort関連spec: 明示的nullで値を消す契約。
- frontendの`queryUtils.spec.ts`: 共通API処理の期待値。

その他の関連specは所在・対象ケースを検索し、各指摘の検証計画に記載した。

## 実行した確認と未実施の検証

レビュー成果物のID連番・重複、必須項目、索引から各指摘へのリンク、相対リンクの存在、末尾空白を機械的に確認した。
Gitの差分・状態で、アプリケーションコードを変更せずレビュー記録のみ追加していることを確認した。

プロジェクトのテスト、lint、ビルド、動的再現は実行していない。指定のDocker実行環境を確認した際、Docker socketへのアクセスが環境の権限制限で拒否された。
各指摘は静的根拠と検証計画を示すもので、テストによる再現確認済みとは扱わない。
稼働サービスへの攻撃検証、Webhook送信、AWS変更、Terraform適用は行っていない。

生成コード・ロックファイル・画像資産の全内容、全UI部品、全テスト、全インフラモジュールの逐行確認は対象に含めていない。
レビュー完了は上記主要経路の静的確認と記録の完了を意味し、未記載領域に問題がないという保証ではない。
