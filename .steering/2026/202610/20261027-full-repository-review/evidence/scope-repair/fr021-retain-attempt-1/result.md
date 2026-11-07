# FR-021 calendar日付の検証

request: `scope-repair-fr021-retain-1`、attempt: 1、status: passed。

- 指定Jest: 1 suite、21 tests成功。有効な閏日・query/hashを保持し、存在しない月日を指定された今日09:00へfallbackする例を含む。
- `yarn tsc --noEmit`と指定2 pathのfrontend lintは終了コード0。
- 指定2 pathの実file blob hashは`c240b94`と一致。
- HEADはFR-020復帰commit `4f788d7`。未commitのapplication差分は指定2 pathと保護対象2 fileのみで、FR-002〜020を保持する。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。
- `git diff --check` 成功。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
