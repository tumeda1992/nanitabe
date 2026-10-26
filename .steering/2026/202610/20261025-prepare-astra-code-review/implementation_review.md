# レビュー適用の検証記録

テストは作業専用Dockerコンテナで実施。backendはRAILS_ENV=testのSQLiteを使用。

## テストデータの型補完

MealCardのmealFrameEntryId、料理出典relationのdishId/type、タグのdishIdを補完した。送信payloadの期待値はid/contentを明示し、fixtureと分けた。2026-10-27の最終working treeではJest全39 suites / 215 tests、tsc、変更24ファイルのESLintが成功した。

## RV-025

food/READMEの責務境界・現行namespaceを統一。相対リンク検査成功。docker exec -e RAILS_ENV=test nanitabe-review-tests-backend-1 bundle exec rspec spec/domain/business/food/meal/usecase/add_command_spec.rb: 8 examples, 0 failures。

## RV-015

モード定数・共有型・setterを限定。Jest: 4 suites, 7 tests成功（切替・Escape、料理割当・移動・延期確定）。未定義モードを@ts-expect-errorで検査。既存fixtureの5件の型不整合は独立した変更で補完し、最終tscも成功した。
