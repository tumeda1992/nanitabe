# レビュー適用の検証記録

テストは作業専用Dockerコンテナで実施。backendはRAILS_ENV=testのSQLiteを使用。

## テストデータの型補完

MealCardのmealFrameEntryId、料理出典relationのdishId/type、タグのdishIdを補完した。送信payloadの期待値はid/contentを明示し、fixtureと分けた。2026-10-27の最終working treeではJest全39 suites / 215 tests、tsc、変更24ファイルのESLintが成功した。
