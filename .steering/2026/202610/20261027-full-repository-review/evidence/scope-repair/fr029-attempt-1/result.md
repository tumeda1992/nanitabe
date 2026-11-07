# FR-029 復元検証

- request_id: `scope-repair-fr029-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-04

次のNode commandで旧workflowの実curl commandを127.0.0.1限定のHTTP fixtureへ実行し、5 tests / 0 failuresだった。

```text
node --test .steering/2026/202610/20261027-full-repository-review/evidence/scope-repair/fr029-attempt-1/baseline-deploy.spec.mjs
```

旧commandにfail/timeout/retry optionがないこと、およびHTTP 200/401/404/500のすべてでcurl exit0となり各1回だけ要求したことを確認した。子processのenvはPATH・loopback fixture URL・人工tokenだけで、実Webhook envを継承していない。各子processには検証側の3秒deadlineがあり、旧commandを無期限待機させるHTTP timeout fixtureは起動しなかった。

backend-deploy.ymlは`d3e4515^`とbyte一致し、scripts/github/backend_deploy.spec.mjsは除去されている。証拠側suiteは旧HTTP応答の期待へ適応されている。利用者変更3fileの保存hashとgit diff --checkも成功した。

失敗はない。これは旧HTTP判定の復元を確認したもので、HTTPエラー時の失敗検知を保証する結果ではない。実Webhook/AWS/GitHubサービス/DB操作は行わず、実装・tasklist・finding・applicationは変更していない。
