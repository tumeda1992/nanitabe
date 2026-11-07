# CR-002 復元検証

- request_id: `scope-repair-cr002-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-04

既存開発Composeのbackend/test環境で、関連RSpecは360 examples / 0 failures。復元production 3 filesのRuboCopは0 offensesだった。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/domain/business/food/dish spec/graphql/mutation/dish
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/domain/business/food/dish/word/usecase/reflect_latest_normalize_word_command.rb app/models/dish.rb app/models/dish_tag.rb
```

ReflectLatestNormalizeWordCommand、Dish、DishTagの3 production fileは`30c86bb^`とbyte一致した。CR-002専用のexisting_tag_update_spec.rbとdish_tag_replacement_spec.rbだけを除去し、旧版のtransaction・所有者条件を保持している。既存の辞書再反映・性能・所有者回帰を含む指定関連RSpecが成功した。利用者変更3fileは保存hashと一致し、git diff --checkも成功した。

失敗はない。これは既存タグ保存の追加挙動を取り消した時点の検証であり、既存タグ内容の保存を新たに保証する結果ではない。FR-024とFR-004は後続項目まで維持される。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作も行っていない。
