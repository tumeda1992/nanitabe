# FR-026 復元検証

- request_id: `scope-repair-fr026-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-04

架空ARNとrepository HCLだけを使う次の静的Node suiteは3 tests / 0 failuresだった。

```text
node --test .steering/2026/202610/20261027-full-repository-review/evidence/scope-repair/fr026-attempt-1/baseline-plan-policy.spec.mjs
```

bucket全objectへのGetObject/PutObjectを許可しDeleteObjectを許可しない旧条件、対象tableのDynamoDB lock操作、plan roleへの元inline policy/ReadOnlyAccessの接続を確認した。main.tfは`df42ad7^`とbyte一致し、元のplan_policy.spec.mjsは実行treeから除去されている。証拠suiteは読取path、旧Put許可の期待値、対応するtest名だけを適応している。

利用者変更3fileの保存hash一致とgit diff --checkも成功した。失敗はない。これは既存policyへの復元確認であり、state上書きの既知問題を解消した結果でもAWSの実効権限評価でもない。Terraform init/apply、AWS API、DB、Webhook操作は行わず、実装・tasklist・finding・applicationは変更していない。
