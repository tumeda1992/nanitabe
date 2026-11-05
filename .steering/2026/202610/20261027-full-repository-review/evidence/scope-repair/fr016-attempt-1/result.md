# FR-016 復元検証

- request_id: `scope-repair-fr016-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeのfrontendで料理検索パネルの既存Jestは1 suite / 4 tests成功。復元したindex.tsxのlintも成功した。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand src/components/dish/DishSearchPanel/index.spec.tsx
docker compose -f compose.dev.local.yml exec -T frontend yarn lint src/components/dish/DishSearchPanel/index.tsx
```

index.tsxは`5319fbd^`とbyte一致し、FR-016専用debounce.spec.tsxは除去されている。module共有timerとunmount cleanupなしの旧契約に戻った。FR-032/033の純抽出6 production fileと利用者変更3fileの保存hashも一致し、git diff --checkは成功した。

JestにはApollo fixtureの不足fieldに関するconsole警告が出たが、assertion失敗はない。大量のconsole原文は成果物へ含めていない。

これはper-instance timer/cleanup追加を取り消した結果であり、複数panel間の干渉を解消したものではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作、新service起動、依存取得も行っていない。
