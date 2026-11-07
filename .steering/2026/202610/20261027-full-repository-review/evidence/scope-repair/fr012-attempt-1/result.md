# FR-012 復元検証

- request_id: `scope-repair-fr012-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeのbackend/test環境で料理更新GraphQLの既存RSpecは13 examples / 0 failures。RSpec終了後、復元2resolverのRuboCopを単独で実行し、2 files / 0 offensesだった。重いcheckは並列起動していない。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/graphql/mutation/dish
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/graphql/mutations/dish/update_dish.rb app/graphql/mutations/dish/update_dish_with_new_source.rb
```

restored-paths.jsonの3pathは`ceb1da7^`とbyte一致または不存在だった。2resolverのkeyword既定値追加を戻し、専用optional_arguments_specを除去した。元FR-012で変更されていないupdate_meal_with_new_dish.rbにこの項目で追加差分はない。先行GraphQL入力変換とFR-032/033の純抽出6 production file、利用者変更3fileの保存hashも保持し、git diff --checkは成功した。

失敗はない。これは旧必須keyword signatureへの復元確認であり、GraphQL任意引数を省略したときの元の問題を解消したものではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作、新service起動も行っていない。
