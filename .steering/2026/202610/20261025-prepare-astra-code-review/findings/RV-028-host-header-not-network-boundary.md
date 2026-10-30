# RV-028: Hostヘッダー制限を直接アクセスの防止として扱っている

- 観点: 保守性・性能・契約
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/terraform/modules/ecs/main.tf: aws_security_group.task、aws_ecs_service.this; backend/terraform/modules/apigateway/main.tf: request_parameters
- 依存する指摘: なし

## 問題と根拠

ECSはpublic IP付きでアプリポートを0.0.0.0/0へ開き、コメントはRails config.hostsでIP直アクセスを防ぐとしている。しかしHostはクライアントが任意に指定でき、許可されたHostを付けた直接接続を区別できない。HostチェックはDNS rebinding対策であり、API Gateway経由だけに接続を制限する認証にはならない。実環境への接続試験はしていない。

## 改善案

Gatewayだけを通す要件があるならprivate integration/VPC Link等でネットワーク境界を作るか、backendでGateway由来を認証する設計へ変更する。公開アプリとして直接接続を許容するなら、その前提でアプリ認証を保証し説明を訂正する。

## 振る舞いを維持する条件

通信経路・費用・認証が変わるため対象外。Host許可リスト自体は別目的として維持する。

## 検証方法

隔離した検証環境で任意Host付きの直接接続とGateway経由を区別できることを確認する。実IPや非公開構成を公開レビュー文書へ記載しない。

## 採否・対応記録

静的確認のみ。動的再現・テスト未実行、採否未判断、未適用。
