# FR-011 認可維持の検証

request: `scope-repair-fr011-retain-1`、attempt: 1、status: passed。

- 指定RSpec: 9 examples、0 failures。既存の本人料理への新規・更新評価と、復帰したownership specの他人料理への新規評価拒否・更新拒否、本人による不整合評価の修復、不在料理拒否を含む。
- 指定RuboCop: 2 files inspected、0 offenses。
- 指定3 pathはworktree・indexともHEADと差分なし。HEADと`cdb8e27`の3 pathも差分なし。
- `86ab57e`（FR-010）はHEADの祖先。そこからHEADへのbackend production差分はFR-011の2 fileと、pattern entryの3 fileのみ。後者は3値の変換を共通methodに移し、既存のcurrent user渡しを維持する変更であり、FR-002〜010の認可実装を保持する。
- 保護3 fileのSHA-256は `/tmp/nanitabe-scope-repair-preserved-hashes.json` の保存値と一致。Git追跡modeは全て100644、worktree modeは全て644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。
- `git diff --check` は成功。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
