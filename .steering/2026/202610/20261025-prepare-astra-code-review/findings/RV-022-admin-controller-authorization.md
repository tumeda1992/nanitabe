# RV-022: 管理CRUDにアプリケーション側の認証・権限ガードがない

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/config/routes.rb: namespace :admin; backend/app/controllers/application_controller.rb; backend/app/controllers/admin/food/dish/word/normalize_words_controller.rb; backend/app/controllers/admin/food/dish/effort_level/dish_effort_levels_controller.rb
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

管理ルートは環境条件なしで定義され、両controllerと親controllerに認証必須・管理権限のbefore_actionがない。SetUserByTokenのincludeだけでは管理者権限検証にならない。手間レベルrequest specも認証なしのPOST成功を期待している。API Gateway設定はANY /{proxy+}転送で、リポジトリ上はadminを除外していない。ただし実環境の到達性・追加防御は未検証。

## 改善案

管理controller共通の認証と管理権限判定を導入し、ブラウザフォームのCSRF方針も合わせて定める。ネットワーク制限を補助として使ってもアプリ側の権限判定を省略しない。

## 振る舞いを維持する条件

アクセス制御とフォームの挙動変更のため対象外。外部から実際に操作できたとの報告ではなく、コードと既存specに基づく指摘。

## 検証方法

未認証・一般ユーザー・管理権限ありの3者で一覧/作成/更新/削除を確認する。拒否時のDB不変とCSRFをrequest specで確認する。公開環境への書き込み試験は行わない。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
