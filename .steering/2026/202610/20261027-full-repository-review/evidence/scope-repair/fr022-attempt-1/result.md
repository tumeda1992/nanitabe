# FR-022 復元検証

- request_id: `scope-repair-fr022-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeで、backend食事更新関連RSpecは3 examples / 0 failures、frontend Jestは2 suites / 16 tests成功。Ruby lintは1 file / 0 offenses、frontendの変更4fileのlintとtsc --noEmitも成功した。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/graphql/mutation/meal/update_meal_spec.rb spec/graphql/mutation/meal/update_meal_with_new_dish_spec.rb spec/graphql/mutation/meal/update_meal_with_new_dish_and_new_source_spec.rb
docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand src/components/meal/MealForm/EditMeal.spec.tsx src/features/dish/dishInputConversion.spec.ts
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/graphql/mutations/meal/update_meal_with_new_dish.rb
docker compose -f compose.dev.local.yml exec -T frontend yarn lint src/components/meal/MealForm/EditMeal.spec.tsx src/features/dish/dishInputConversion.spec.ts src/features/dish/normalizeFunctions.ts src/features/meal/updateMealMutation.ts
docker compose -f compose.dev.local.yml exec -T frontend yarn tsc --noEmit
```

restored-paths.jsonの8pathは`5b54e45^`とbyte一致または親版どおり不存在だった。出典なし許容specを除去し、backend input・frontend operation・生成型のrequired契約を旧版へ戻している。FR-013の手間取得が含まれる当時の生成物を保持し、先行RV-001の共通変換も既存の16 testsで検証した。FR-032/033のproduction 6fileは608ed3dとのbyte一致を保つ。利用者変更3fileの保存hashとgit diff --checkも成功した。

JestはApollo fixtureの不足fieldに関するconsole警告を出したが、assertion失敗はない。大量のconsole原文を成果物へ含めず、結果の集計だけ記録した。

これは出典なし新規料理の追加許容を取り消した状態の検証であり、出典なし編集の既知不具合を解消した結果ではない。実装・tasklist・finding・applicationは変更していない。実DB/AWS/Webhook操作、新service起動、依存取得も行っていない。
