# RV-028: Hostヘッダー制限を直接アクセスの防止として扱っている

- 観点: 保守性・性能・契約
- 優先度: 高
- 採否: 採用（後続の全件反映指示）
- 対応状況: 完了（FR-028で追跡）
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

初回は静的確認のみ。現在の採否・検証・適用commitは下記FR-028の反映記録を参照。

## 後続の反映（2026-11-02）

本fileの「今回の適用対象」は初回の挙動維持枠を指す。後続の全件反映指示による現行状態・検証は[FR-028](../../20261027-full-repository-review/findings/FR-028-host-not-access-control.md)へ集約する。適用commitは`2bf938d`。
