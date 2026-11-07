# CR-004 復元検証

- request_id: `scope-repair-cr004-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-04

指定の既存開発Composeのbackendで、test環境の関連RSpecは25 examples / 0 failuresだった。復元した3 production fileと残存MySQL helperのRuboCopは4 files / 0 offensesだった。

実行したcommand:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/graphql/mutation/meal/postponed spec/domain/business/food/meal/postponed/usecase
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/domain/business/food/meal/postponed/usecase/remove_command.rb app/graphql/mutations/meal/postponed/postpone_meal.rb app/graphql/mutations/meal/postponed/schedule_postponed_meal.rb spec_mysql/mysql_spec_helper.rb
```

静的確認では、RemoveCommandと両GraphQL resolverの3 production fileが`02e2caf^`とbyte一致した。変換専用のconversion_atomicity_spec.rbとmeal_conversion_concurrency_spec.rbは除去され、mysql_spec_helper.rbのSourceDeletionCheckpoint・competing_consumers・prependも除去されている。

FR-019のframe_assignment_spec.rb、MySQL helperのURL/実接続guard、ensure_database!/clean!、RSpecのbefore/after cleanupは残っている。helper差分は変換用checkpoint部分だけだった。git diff --checkも成功した。

失敗はない。これはCR-004の挙動変更を戻した状態の検証であり、並行一回消費の保証を検証した結果ではない。実MySQL、実環境migration、AWS、Webhookは実行していない。実装・tasklist・finding・applicationは変更していない。
