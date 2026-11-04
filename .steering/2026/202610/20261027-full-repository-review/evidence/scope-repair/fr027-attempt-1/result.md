# FR-027 復元検証

- request_id: `scope-repair-fr027-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-04

旧起動scriptのstub suiteは7 tests / 0 failures。start/stopのbash構文検査も成功した。

実行command:

```text
node --test .steering/2026/202610/20261027-full-repository-review/evidence/scope-repair/fr027-attempt-1/baseline-start.spec.mjs
bash -n scripts/review_backend/start.sh scripts/review_backend/stop.sh
```

通常成功は停止scheduleを2件作成する。既起動時はintegration/scheduleを修復せずreturnする。wait/IP/integrationの各失敗ではdesired countが1のまま、schedule作成失敗では旧rollbackを行いexit1となることを確認した。aws/jq/dateとenvはfixtureに限定し、実AWSは呼び出していない。

start.shは`7772f90^`、stop.shは`d58c473`とbyte一致した。start.spec.mjsとcommon.shは実行treeから除去済み。証拠suiteは元のstub/runを保持し、読取pathと旧契約向けの7ケースへ適応されている。利用者変更3fileの保存hash一致とgit diff --checkも成功した。

失敗はない。これは起動失敗の全経路rollback拡張を取り消した検証であり、途中失敗の自動停止保証を追加した結果ではない。実script/実env/実DB/AWS/Webhook操作は行わず、実装・tasklist・finding・applicationは変更していない。
