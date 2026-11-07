# CR-003 復元検証

- request_id: `scope-repair-cr003-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-04

指定の既存開発Composeのbackend/test環境で関連RSpecは135 examples / 0 failures。DishSourceと旧Repository specのRuboCopは2 files / 0 offensesだった。

実行したcommand:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/domain/business/food/dish/source spec/domain/business/dish/dish/source spec/domain/business/dish/dish/repository/repository_put_dish_relation_spec.rb spec/graphql/mutation/dish/source
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/models/dish_source.rb spec/domain/business/dish/dish/repository/repository_put_dish_relation_spec.rb
```

DishSourceは`45074dc^`、旧Repository specは`852718f^`とbyte一致した。TypeChangePolicyとそのspec、GraphQLのtype_change_boundaries_spec.rbは除去されている。これにより関連済み出典の種別変更を許す既存specも復元された。git diff --check成功、利用者変更3fileの保存hash一致と管理基底WIPの608ed3dとのbyte一致を確認した。

失敗はない。これは種別変更拒否の追加を取り消した検証であり、出典詳細保持を新たに保証する結果ではない。実装・tasklist・finding・applicationを変更していない。実DB/AWS/Webhook操作は行っていない。
