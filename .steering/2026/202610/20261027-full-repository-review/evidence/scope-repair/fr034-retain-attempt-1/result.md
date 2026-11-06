# FR-034 旧枠入口委譲の検証

request: `scope-repair-fr034-retain-1`、attempt: 1、status: passed。

- 指定RSpec: 78 examples、0 failures。旧rootのclass・値と単一保存、他人の削除拒否、旧Fillの返却と既存frame関連認可を含む。
- 指定RuboCop: 4 files inspected、0 offenses。
- `fcac860`のbackend source/spec/README 5 pathの実file blob hashは同commitと一致。未追跡specも実fileを比較した。旧Fillは現行Fill command継承のまま、現行entry側に未commit差分なしでFR-008認可を保持する。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。`git diff --check`成功。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
