# FR-029: デプロイWebhookのHTTPエラーを成功扱いする

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-020（現行コードで再確認）。

## 対象

- [.github/workflows/backend-deploy.yml](../../../../../.github/workflows/backend-deploy.yml)

## 問題と根拠

curlに--fail/--fail-with-bodyがないため、WebhookがHTTP 401/404/500を返しても通信が成立すればjobは成功になる。デプロイの依頼が失敗した事実をCIで検出できない。

## 改善案

curl --fail-with-body --show-error等でHTTP失敗をexit statusへ反映する。timeoutを設け、再試行はWebhookの冪等性を確認してから追加する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

ローカルstub endpointの200/401/500/timeoutに対する終了コードを確認する。実Webhookは呼ばない。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
