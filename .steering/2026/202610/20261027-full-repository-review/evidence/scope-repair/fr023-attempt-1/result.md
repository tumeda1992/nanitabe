# FR-023 復元検証

- request_id: `scope-repair-fr023-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeのbackend/test環境で新旧辞書関連RSpecは61 examples / 0 failures。復元Normalizer 2 filesのRuboCopは0 offensesだった。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T -e RAILS_ENV=test backend bundle exec rspec spec/domain/business/food/dish/word spec/domain/business/dish/word
docker compose -f compose.dev.local.yml exec -T backend bundle exec rubocop app/domain/business/dish/word/normalize/command/normalize_command.rb app/domain/business/food/dish/word/usecase/normalizer.rb
```

新旧Normalizerの2 production fileは`73b8797^`とbyte一致し、literal_normalization_spec.rbは除去されている。先行RV-014のNormalizeWordAttributesはd58c473とbyte一致、FR-024で戻した4Commandも9b1df0a^との一致を保っている。利用者変更3fileの保存hashとgit diff --checkも成功した。

失敗はない。これは旧SQL候補取得と正規表現置換への復元確認であり、正規表現/backreferenceの既知問題を解消した結果ではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作や新service起動も行っていない。
