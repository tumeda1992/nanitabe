# FR-030 復元検証

- request_id: `scope-repair-fr030-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-04

次のNode commandで実workflowの検出bash blockをgit fixture stubとともに実行し、3 tests / 0 failuresだった。

```text
node --test .steering/2026/202610/20261027-full-repository-review/evidence/scope-repair/fr030-attempt-1/baseline-filter.spec.mjs
```

frontend source変更はchanged=true、workflow自身だけの変更はfalse、backend/README変更はfalseとなり、旧契約を確認した。workflowは`a871b4c^`とbyte一致する。scripts/github/frontend_build_filter.spec.mjsは除去され、証拠側のsuiteは読取pathとworkflow自身の期待値falseの2箇所だけを適応した。その他のfixture/stub・実bash実行は元suiteと同じである。

利用者変更3fileの保存hashは一致し、git diff --checkも成功した。失敗はない。この結果は旧workflowの条件復元を示すもので、workflow自身の変更検出を修正した結果ではない。実GitHub API、AWS、Webhook、DB操作は行っていない。実装・tasklist・finding・applicationは変更していない。
