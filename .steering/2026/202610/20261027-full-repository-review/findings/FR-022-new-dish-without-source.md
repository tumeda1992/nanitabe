# FR-022: 食事編集で出典なしの新規料理を選ぶと送信契約に違反する

- 優先度: P2
- 採否: 採用
- 対応状況: 完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [frontend/src/features/meal/updateMealMutation.ts](../../../../../frontend/src/features/meal/updateMealMutation.ts)
- [frontend/src/features/dish/schema.ts](../../../../../frontend/src/features/dish/schema.ts)
- [frontend/src/features/dish/normalizeFunctions.ts](../../../../../frontend/src/features/dish/normalizeFunctions.ts)
- [backend/app/graphql/mutations/meal/update_meal_with_new_dish.rb](../../../../../backend/app/graphql/mutations/meal/update_meal_with_new_dish.rb)

## 問題と根拠

編集UIは新規料理＋既存出典選択モードで未選択を許し、schemaもselectedDishSourceをoptionalにする。normalizerは未選択をdishSource:nullへ変換する。しかしupdateMealWithNewDishの変数とbackend引数はSourceForRead!であり、その通常入力を拒否する。登録側では出典がoptionalなので、登録と編集で利用可能な操作が食い違う。

## 改善案

出典なし料理を編集時にも作成できるなら、backend引数とGraphQL operationをnullableにし、resolver既定値を揃えてcodegenする。必須という仕様ならUIの選択とschemaを明示的に必須にする。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

既存食事を出典なし新規料理へ差し替える画面操作を、mockだけでなくGraphQL validationまで含めて検証する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用

## 適用検証（2026-11-01）

合意済みdesignの「編集時も出典なし新規料理を許す」契約を適用した。backendのdish_sourceをnullableにしてRuby既定値nilを置き、frontend operation変数もnullableへ揃えた。出典自体の省略にも対応し、共通normalizerがsource/detailをnullへ返す。入力はdeep cloneしたまま変更しない。

修正前は実GraphQLの省略/nullの2ケースが必須引数検証で失敗し、frontendでは省略sourceを読む3呼出元が失敗した。UI mockテスト自体は元から通るため、それだけではGraphQL契約の検証にならないことも確認した。修正後はbackend11 examples、frontend34 tests、型検査、backend2/ frontend4ファイルlintが成功。省略/nullのどちらでも新料理へ差替え、source/relation件数不変を確認した。認可失敗では新料理がrollbackされる。

- `docker compose -f compose.dev.local.yml exec -T backend bundle exec rspec spec/graphql/mutation/meal/update_meal_without_source_spec.rb spec/graphql/mutation/meal/update_meal_with_new_dish_spec.rb spec/graphql/mutation/meal/update_meal_with_new_dish_and_new_source_spec.rb spec/graphql/mutation/meal/ownership_spec.rb`
- 同frontendの`yarn test --runInBand --silent dishInputConversion EditMeal.spec AddMeal.spec AddDish.spec`
- 同frontendの`yarn tsc --noEmit --incremental false`と変更箇所`yarn lint`、同backendの変更箇所`bundle exec rubocop`: 成功。

通常のHTTP codegenはFR-019の新migrationを開発serverが検知しPendingMigrationErrorで停止した。開発DBへ適用せず、同backendの`rails runner 'File.write(Rails.root.join("tmp/fr022-development-schema.json"), BackendSchema.to_json)'`で通常schemaのみをoffline出力した。test環境では認証用schemaが異なるため、その出力は型生成に使っていない。通常schemaをfrontendのgitignore済み作業先へcopyし、schema pathだけを差し替えた一時codegen設定で生成した。生成差分が対象input・変数・operationのnullable化だけであることを確認済み。repositoryのcodegen設定は変更していない。

ブラウザ確認はrequests/fr022-visual.jsonを使用し、全GraphQLを人工fixtureでmockする。実DBへのmigrationやUI保存は実施しない。

visual-inspectorも成功。updateMealWithNewDishを1回だけ送信し、source/detailはnull、既存meal.idを保持するpayloadを確認した。modalが閉じて再取得後に新料理名が表示され、3画像を目視済み。未知operation・browser例外0。結果はrequests/fr022-visual-result.json。実DB保存はmock対象のため未確認であり、保存と認可rollbackはtest DBの実GraphQL requestで検証した。適用commitはapplication.mdとGit履歴で追跡する。
