# FR-027 startup cleanupの検証

request: `scope-repair-fr027-retain-1`、attempt: 1、status: passed。

- 人工env・stubによる指定Node harness: 31 tests成功、0 failures。起動各段階の失敗、SIGINT/SIGTERM時のcleanupと終了code、起動済み再実行時の再整合、cleanup失敗を含む。
- `bash -n scripts/review_backend/start.sh` は終了コード0。
- 指定2 pathの実file blob hashは`7772f90`と一致。未追跡specも実fileを比較した。start.shはpublic IPからintegration URIを設定し、private/common参照はない。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。`git diff --check`成功。
- 実AWSに対するstart.shの実行やAWS query・applyは行っていない。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
