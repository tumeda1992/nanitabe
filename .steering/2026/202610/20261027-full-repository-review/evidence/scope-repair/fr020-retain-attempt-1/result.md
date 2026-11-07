# FR-020 logical historyの検証

request: `scope-repair-fr020-retain-1`、attempt: 1、status: passed。

- 指定Jest: 4 suites、20 tests成功。Next route/query遷移、独自push、popstate、古いNext snapshot後の現在URL読取とcalendar関連テストを含む。
- `yarn tsc --noEmit`と指定2 pathのfrontend lintは終了コード0。
- 指定2 pathの実file blob hashは`d8afcf0`と一致。未追跡specも実fileを比較した。
- HEADはFR-017復帰commit `ea3b9f1`。未commitのapplication差分は指定production fileと保護対象2 file、未追跡の指定specのみで、FR-002〜017を保持する。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。
- `git diff --check` 成功。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
