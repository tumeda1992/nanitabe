# CR-001 復元検証

- request_id: `scope-repair-cr001-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-04

既存開発Composeのbackend/test環境で検索とGraphQL queryのRSpecは36 examples / 0 failures。検索実装/specのRuboCopは2 files / 0 offensesだった。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/domain/business/food/dish/usecase/dish_searcher_spec.rb spec/graphql/query/dish
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/domain/business/food/dish/usecase/dish_searcher.rb spec/domain/business/food/dish/usecase/dish_searcher_spec.rb
```

DishSearcherとdish_searcher_spec.rbは`ddfef5a^`とbyte一致した。語ごとの相関EXISTSを追加するCR-001の変更を除き、既存の本人条件とFR-007の先頭固定owner条件・回帰を保持している。利用者変更3fileは保存hashと一致し、git diff --checkも成功した。

失敗はない。これは検索条件をCR-001前へ戻した時点の検証で、別タグに分散した複数語の検索を新たに保証する結果ではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作も行っていない。
