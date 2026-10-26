# レビュー適用の検証記録

テストは作業専用Dockerコンテナで実施。backendはRAILS_ENV=testのSQLiteを使用。

## テストデータの型補完

MealCardのmealFrameEntryId、料理出典relationのdishId/type、タグのdishIdを補完した。送信payloadの期待値はid/contentを明示し、fixtureと分けた。2026-10-27の最終working treeではJest全39 suites / 215 tests、tsc、変更24ファイルのESLintが成功した。

## RV-025

food/READMEの責務境界・現行namespaceを統一。相対リンク検査成功。docker exec -e RAILS_ENV=test nanitabe-review-tests-backend-1 bundle exec rspec spec/domain/business/food/meal/usecase/add_command_spec.rb: 8 examples, 0 failures。
## RV-015

モード定数・共有型・setterを限定。Jest: 4 suites, 7 tests成功（切替・Escape、料理割当・移動・延期確定）。未定義モードを@ts-expect-errorで検査。既存fixtureの5件の型不整合は独立した変更で補完し、最終tscも成功した。
## RV-014

NormalizeWordAttributes.buildへ保存属性生成を集約し、登録create・更新update!と再反映を維持。空白destinationの回帰ケースを先に追加。RSpec word/usecase全体: 56 examples, 0 failures。
## RV-013

GraphQL層FoodDishInputへ出典relationとタグ変換を抽出。resolverのtransactionと集約間呼出順は維持。入力なし・種別別・新規出典ID・タグ順の7ケース追加。関連dish/meal mutationを含むRSpec: 58 examples, 0 failures。
## RV-001

既存出典/新規出典の入力変換をジェネリック関数へ集約。旧実装へ追加した回帰7件が成功してから抽出し、freeze入力・meal/frameEntryId・タグ・NO_VALUEのnull保持を確認。料理/食事フォームを含むJest: 10 suites, 54 tests成功。
## RV-029

週/月ページのURL日付処理をcalendarDateFromPathへ抽出。09:00、query付きURLのfallback、形式のみ検査、非anchor正規表現を維持。Jest: 日付8ケースとCalendar統合3ケース、計2 suites/11 tests成功。
## RV-012

MealFramePatternFieldsへ入力・検証・DOMを集約し、作成/編集wrapperにAPI呼出と初期値復元を残した。共通化前の回帰6件と既存Form/Listを実行: 3 suites, 13 tests成功。
## RV-026

GraphQL Dataloaderでパターンentriesと枠名をbatch取得。追加SQL数テストは変更前13 SELECTで失敗、変更後3 SELECTで成功。順序・空一覧・他ユーザー除外・欠落枠空文字とpattern mutationを含むRSpec: 12 examples, 0 failures。

## 全体の最終検証

2026-10-27にfrontendのタグ期待値を修正し、Jest全39 suites / 215 tests、TypeScriptのnoEmit検査、変更24ファイルのESLintが成功した。backendはfood domainとGraphQLの568 examples / 0 failures、変更20ファイルのRuboCopが成功した。

コミット作成時はindexのtreeから隔離したソースをコンテナへ展開し、各コミットに対応するテストを実行する。結果は成功した状態だけを保存する。全体の最終状態でもJest・RSpec・型検査・lintを確認する。

ブラウザの目視検査、production build、Terraform操作は実施していない。認可等の対象外20件とRV-016は未適用。
再発防止の文書更新は[documentation-proposal.md](./documentation-proposal.md)の提案に留める。
