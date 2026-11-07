# FR-011 復元検証

- request_id: `scope-repair-fr011-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-06
- 使用skill: tumeda-dev 8.2.5 test-runner（親model継承）

起動済みのFR-011検証sessionはなかったため、同じrequest_id/attemptで初回実行した。元作業両directoryの暫定指示候補なしという親のmaintenance結果と、従来の安定contextを受領し、現行test-runner/runtime/profileを確認した。

既存開発Composeのbackend/test環境で評価Command/Repository/model/GraphQLの既存RSpecは5 examples / 0 failures。RSpec終了後に評価Command/RepositoryのRuboCopを単独実行し、2 files / 0 offensesだった。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/domain/business/dish/dish/evaluation spec/models/dish_evaluation_spec.rb spec/graphql/mutation/dish/evaluation
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/domain/business/dish/dish/evaluation/command/evaluate_command.rb app/domain/business/dish/dish/evaluation/repository.rb
```

restored-paths.jsonの3pathは`cdb8e27^`とbyte一致または不存在だった。料理ownerの新照合と評価owner修復を戻し、評価record基準の更新認可・force_updateの旧契約を保持している。FR-032/033の純抽出6 production fileと利用者変更3fileの保存hashも一致し、git diff --checkは成功した。

失敗はない。これは旧評価認可・owner保存への復元確認であり、元の評価認可の問題を解消したものではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作、新service起動も行っていない。
