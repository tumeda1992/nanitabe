# FR-017 枠選択validationの検証

request: `scope-repair-fr017-retain-1`、attempt: 1、status: passed。

- 指定Jest: 3 suites、20 tests成功。作成・編集で選択解除時のsubmit 0回、再選択後の数値IDによるsubmit 1回、通常保存、NaN・Infinity・0・負数・小数の拒否を含む。
- `yarn tsc --noEmit`と指定2 pathのfrontend lintは終了コード0。
- 指定2 pathの実file blob hashは`62359ad`と一致。
- HEADはFR-016復帰commit `d1efd8f`。未commitのapplication差分は指定2 pathと保護対象2 fileのみで、FR-002〜016を保持する。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。
- `git diff --check` 成功。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
