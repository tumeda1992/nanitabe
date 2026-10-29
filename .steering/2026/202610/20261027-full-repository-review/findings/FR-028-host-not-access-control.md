# FR-028: Host制限を直接アクセス防止として扱っている

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-028（現行コードで再確認）。

## 対象

- [backend/terraform/modules/ecs/main.tf](../../../../../backend/terraform/modules/ecs/main.tf)
- [backend/terraform/modules/apigateway/main.tf](../../../../../backend/terraform/modules/apigateway/main.tf)
- [backend/config/environments/production.rb](../../../../../backend/config/environments/production.rb)

## 問題と根拠

ECSのportを0.0.0.0/0へ開放してpublic IPを付与し、コメントではconfig.hostsで直接アクセスを防ぐとしている。HTTP Hostは接続元が任意に送れるため、許可Hostを指定した直接接続をこの検査では識別できない。API Gateway経由という境界の保証にならない。稼働環境の実到達性は検証していない。

## 改善案

必要な境界をネットワーク制限・private integration・検証可能なorigin認証などで実装する。Hostチェックはホスト名検証として残し、アクセス制御の代替にしない。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

Terraform上の経路とsecurity groupを検査し、隔離した検証環境で許可Hostを使った直接接続が拒否されることを確認する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
