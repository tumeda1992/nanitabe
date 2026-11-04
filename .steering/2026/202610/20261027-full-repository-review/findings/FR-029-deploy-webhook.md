# FR-029: デプロイWebhookのHTTPエラーを成功扱いする

- 優先度: P2
- 採否: 今回は見送り（挙動維持の制約により適用取消）
- 対応状況: 適用取消・旧挙動の復元検証完了
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

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `d3e4515`

## 適用結果（2026-11-01）

curlに--fail/--show-error/--silent、接続10秒・全体30秒のdeadlineを追加した。冪等性未確認のため再試行は追加しない。HTTP失敗はjobの失敗として返る。利用可能なcurlとの互換性から--failを使い、失敗bodyの表示は要求しない。

実workflowのrun blockを実curlで実行するローカルHTTP fixtureを追加した。200は0、401/404/500は22、timeoutは28。各ケースのrequestは1回だけで、実Webhookや実tokenには触れない。timeoutケースだけ全体deadlineを0.2秒へ短縮し、productionの10/30秒設定は別途検査する。修正前は6件中5件red、修正後は6 tests成功。GitHub Actionsでの実デプロイ依頼は今回実行していない。commitはapplication.mdとGit履歴で追跡する。

## 適用取消と旧挙動の復元（2026-11-04）

追加したHTTP失敗判定とtimeoutは挙動を変えるため、d3e4515親版のcurlへ戻した。
[復元結果](../evidence/scope-repair/fr029-attempt-1/result.md)はNode5 cases / 0 failures、旧workflow byte一致、
専用suite除去、利用者変更保持とdiff checkが成功した。loopback fixtureのHTTP200/401/404/500でexit0となる旧契約を確認した。
実Webhookは呼び出していない。元のHTTPエラー扱いの問題と旧検証は保存し、解消済みとは数えない。
