# FR-022 出典なし料理の検証

request: `scope-repair-fr022-retain-1`、attempt: 1、status: passed。

- 指定RSpec: 11 examples、0 failures。省略・nullの出典なし、source/relation件数、認可失敗時rollback、出典あり操作を含む。
- 指定Jest: 4 suites、34 tests成功。`yarn tsc --noEmit --incremental false`とfrontend lintは終了コード0。backend RuboCopは2 files、0 offenses。
- developmentの`BackendSchema.to_json`をRails runnerで一時出力し、schemaと出力先を一時pathに差し替えた設定でcodegenを実行。生成されたTypeScriptとintrospection JSONは現行生成物とそれぞれ完全一致。test schemaやmigrationは使っていない。一時出力は`backend/tmp/fr022-retain-schema.json`、`frontend/tmp/fr022-retain/`。
- `5b54e45`のapplication 8 pathの実file blob hashは同commitと一致。未追跡specも実fileを比較した。
- HEADはFR-021復帰commit `e21a44f`。未commitのapplication差分は指定8 pathと保護対象2 fileのみで、FR-002〜021を保持する。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。
- `git diff --check` 成功。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
