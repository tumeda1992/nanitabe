# FR-019 復元検証

- request_id: `scope-repair-fr019-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

第一checkのguard commandをrequestのJSONからdecodeした文字列どおり実行した。実改行25、literal backslash-n/backslash-quote各0を実行前に確認し、commandの意味やquoteを変換していない。環境test、adapter sqlite3、設定の標準test fileとPRAGMAの実接続fileの二重guardが成功した。

標準test SQLiteには旧検証時のmeal_id unique indexが残っていたため、このguard済みtest DBだけにschema loadを行った。その後、接続をtestとして再確立して同じguardを再確認し、unique meal assignment index不在を確認してexit0になった。実行guardの正本は[request](../../../requests/scope-repair-fr019-1.json)の第一checkである。

guardとschema準備の完了後に関連RSpecを起動し、70 examples / 0 failuresだった。同一mealを複数枠へ置く旧unassign fixtureも含む。Fill/既存unassign specのRuboCopは2 files / 0 offensesだった。

関連実行command:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/domain/business/food/meal/frame spec/graphql/mutation/meal/frame_entry
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb spec/graphql/mutation/meal/frame_entry/unassign_meal_from_frame_entry_spec.rb
```

restored-paths.jsonの9pathは`01e5394^`とbyte一致または不存在だった。schema versionとmeal_id非unique indexは旧版で、AssignMealPolicy、追加migration、cardinality/migration spec、MySQL補完spec/helper残部は除去されている。FR-008のowner検証は親版のFillに保持される。FR-032/033の純抽出6 production file、利用者変更3fileの保存hashも一致し、git diff --checkは成功した。

失敗はない。これは一食一枠の追加制約を取り消した結果であり、元の重複割当問題を解消したものではない。許可されたguard済みtest DBのschema load以外のDB操作、開発/実DBへのmigration/down、MySQL service起動、AWS/Webhook操作は行っていない。実装・tasklist・finding・applicationは変更していない。
