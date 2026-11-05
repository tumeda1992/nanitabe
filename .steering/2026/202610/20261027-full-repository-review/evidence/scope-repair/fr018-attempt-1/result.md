# FR-018 復元検証

- request_id: `scope-repair-fr018-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeのbackend/test環境で、新旧の食事保存・日付交換とGraphQLの関連RSpecは81 examples / 0 failures。保存・交換境界のRuboCopは4 files / 0 offensesだった。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/domain/business/food/meal/usecase spec/domain/business/dish/meal spec/graphql/mutation/meal/swap_meals_between_days_spec.rb spec/graphql/mutation/meal/update_meal_spec.rb
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/domain/business/dish/meal/command/swap_meals_between_days_command.rb app/domain/business/dish/meal/repository.rb app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb app/models/meal.rb
```

restored-paths.jsonの6pathは`25471fd^`とbyte一致または不存在だった。ReleaseFrameOnReschedulePolicy/save_with_frame_release!へのbackend/app内の参照は消え、旧save!と交換の保存境界へ戻っている。FR-002/003の認可を含む当時の親版を保持し、FR-032/033の純抽出6 production fileと利用者変更3fileの保存hashも一致した。git diff --check成功。

失敗はない。これは日付/時間帯変更に伴う元枠解除と交換全体transactionの追加を取り消した結果であり、元の日付不整合・部分保存問題を解消したものではない。FR-019で準備した標準test DBを使用し、新しいschema操作は行っていない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作、新service起動も行っていない。
