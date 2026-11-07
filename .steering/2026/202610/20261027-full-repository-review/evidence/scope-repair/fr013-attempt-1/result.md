# FR-013 復元検証

- request_id: `scope-repair-fr013-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeで、backend料理GraphQL queryのRSpecは7 examples / 0 failures。frontend料理/食事フォームのJestは9 suites / 47 tests成功。Ruby lintは1 file / 0 offenses、frontendの変更5file lint、tsc --noEmitも成功した。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/graphql/query/dish
docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand src/components/dish/DishForm src/components/meal/MealForm
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/graphql/types/output/dish/essential_dish.rb
docker compose -f compose.dev.local.yml exec -T frontend yarn lint src/components/dish/DishForm/DishForm/DishFormOfOnlyDishFields.tsx src/components/dish/DishForm/DishForm/SelectEffortLevel.tsx src/components/dish/DishForm/DishForm/index.tsx src/features/dish/fetchDishQuery.ts src/features/meal/fetchMealQuery.ts
docker compose -f compose.dev.local.yml exec -T frontend yarn tsc --noEmit
```

restored-paths.jsonの10pathは`fb59312^`とbyte一致または不存在で、実行開始時と結果回収後の双方で照合した。EssentialDishの追加field、query/生成型、defaultValues/選択制御/初回effectの追加変更を旧版へ戻している。先行入力共通化を既存formsテストで確認し、FR-032/033の純抽出6 production fileと利用者変更3fileの保存hashを保持した。git diff --check成功。

全jobに長い経過が記録された。RSpecは読込35分51秒、JestはTime 2219.9秒、frontend lintは2153.88秒、tscは2133.78秒で、失敗や二重実行なしに同じセッションから結果を回収した。原因をコードに帰属させる計測は行っておらず、これらを通常の性能値と扱わない。

失敗はない。これは手間取得・初期値保持の追加を取り消した状態の検証であり、既存編集時の手間レベル消失を解消したものではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作、新service起動、依存取得も行っていない。大量のconsole原文を成果物へ含めていない。
