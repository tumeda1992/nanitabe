# FR-028 復元検証

- request_id: `scope-repair-fr028-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-04

既存の起動script suiteは31 tests / 0 failures、約34.6秒で成功した。AWS/jq/dateをsuite内fixture stubに置き換えた検証で、実AWSは呼び出していない。start/stopのbash構文検査も成功した。

実行command:

```text
node --test scripts/review_backend/start.spec.mjs
bash -n scripts/review_backend/start.sh scripts/review_backend/stop.sh
```

restored-paths.jsonの13path全てについて、存在する旧pathは`2bf938d^`とbyte一致し、親版にない新規pathは現在も不存在であることを確認した。新規common.sh、cli_stubs.sh、private integration専用検査、readiness specは除去されている。Terraform/scriptの確認対象にはCloud Map/VPC link/private integration前提の参照は残っていない。

FR-027時点の起動script/suiteを保持し、正常起動・各失敗/割込み/cleanup拒否・既存稼働修復の31ケースが成功した。operate-review-environmentのdesign/tasklist/implementation_reviewの3文書は、2026-11-04の取消と旧snapshotの履歴を区別するnoticeへ訂正されている。利用者変更3fileの保存hashとgit diff --checkも成功した。

失敗はない。これはFR-028を戻した中間点であり、FR-027の拡張まで除去した最終状態ではない。Terraform init/apply、新provider取得、実script/実env/DB/Webhookは実行せず、実装・tasklist・finding・applicationは変更していない。
