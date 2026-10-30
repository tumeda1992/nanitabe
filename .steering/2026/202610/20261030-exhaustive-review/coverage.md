# 確認範囲と限界

## 対象

repository全体を対象として入口から選択的に追跡した。全file全行の精読や全実行経路の検証を完了したという意味ではない。生成物、lockfileの全依存監査、画像、nativeのplatform生成コードは精読対象から除外した。

- backend: GraphQL schema・認証controller・登録、料理/出典/タグの更新、検索、食事・枠・パターン・延期のCommandとActiveRecord永続化、関連DB制約を確認。
- frontend: Apollo構築・cookie認証・ログイン/登録後の遷移、query wrapper、カレンダー日付計算、タグフォームとmutation入力・既存テストを確認。
- CI/infra: GitHub workflows、terraform-run action、prod/review rootのmodule参照、CodeBuild、起動entrypoint、停止scriptを確認。IAM・起動rollback・Host境界・webhook・path typoの既存未対応事項は追加指摘にしない。
- native: WebView入口・復帰時reload・package設定を確認。旧calender URLはNext redirectsが存在するため404問題として指摘しない。

## 棄却・区別

ログイン後はwindow.locationによる再読込があるため、Apolloが初期tokenをcaptureする点だけで「ログイン後も認証不能」とは指摘しない。既存タグはUIで直接編集できないためCR-002はGraphQL公開入力の保存契約として限定した。出典更新は旧Commandの認可も先行するため、局所的なuser_id未使用だけを新規の越権指摘にしない。

## 実測

Dockerの既存テスト専用backendでevidence/probes.rbを実行した。テストDBに一時レコードを作り、全処理をrollbackした。3件の問題を再現。アプリ実装の変更、実AWS操作、デプロイは行っていない。

## 未確認

CR-004のMySQL二接続での並行再現、ブラウザ/実機操作、実環境設定、負荷限界、依存ライブラリ全体の脆弱性監査、全自動テストの再実行は未実施。未確認を問題なしとは判定しない。

## 除外した既存指摘

前回のapplication.mdに基づきFR-001〜030・032〜034をスキップ。FR-001はWIPでCSRF対応も未完了のため完了扱いにしない。旧RVの対応関係も照合した。既存未対応の原因を新しい名前で再登録しない。
