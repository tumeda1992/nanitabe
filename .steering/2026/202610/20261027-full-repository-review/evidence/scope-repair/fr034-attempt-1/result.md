# FR-034 復元検証

- request_id: `scope-repair-fr034-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-04

既存開発Composeのbackend/test環境で関連RSpecは74 examples / 0 failures。旧Root/Add/RemoveのRuboCopは3 files / 0 offenses。指定runnerはeager_load!後の旧Root/Add/Removeの独立した継承を検証し、legacy_inheritance_restoredを出力して成功した。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/domain/business/food/meal/frame spec/graphql/mutation/meal/frame_entry
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/domain/business/food/meal/frame_entry/root.rb app/domain/business/food/meal/frame_entry/usecase/add_command.rb app/domain/business/food/meal/frame_entry/usecase/remove_command.rb
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rails runner -e test "Rails.application.eager_load!; raise unless Business::Food::Meal::FrameEntry::Root.superclass == Business::Base::Entity; raise unless Business::Food::Meal::FrameEntry::Usecase::AddCommand.superclass == Business::Base::Command; raise unless Business::Food::Meal::FrameEntry::Usecase::RemoveCommand.superclass == Business::Base::Command; puts :legacy_inheritance_restored"
```

旧Root/Add/Removeとfood READMEは`fcac860^`とbyte一致した。FR-034専用compatibility_spec.rbは除去され、旧Fillは608ed3dとbyte一致してFR-008由来変更をこの項目では保持している。利用者変更3fileの保存hashも一致し、git diff --checkは成功した。指定既存RSpecがFR-005/008/019の現時点の契約を含めて成功した。

失敗はない。旧RootはBusiness::Base::Entity、旧Add/RemoveはBusiness::Base::Commandを継承する元の関係に戻っている。この結果は旧namespaceの共通化を維持した結果ではない。実装・tasklist・finding・applicationは変更していない。実MySQL/実DB/AWS/Webhook操作は行っていない。
