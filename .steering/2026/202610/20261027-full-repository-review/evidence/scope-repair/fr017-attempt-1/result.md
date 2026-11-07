# FR-017 復元検証

- request_id: `scope-repair-fr017-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeのfrontendで旧フォームと共有schemaのJestは2 suites / 19 tests成功。復元Fields/Editor specの2file lintとtsc --noEmitも成功した。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand src/components/meal/frame/pattern/MealFramePatternEditor.spec.tsx src/features/meal/frame/pattern/schema.spec.ts
docker compose -f compose.dev.local.yml exec -T frontend yarn lint src/components/meal/frame/pattern/MealFramePatternFields.tsx src/components/meal/frame/pattern/MealFramePatternEditor.spec.tsx
docker compose -f compose.dev.local.yml exec -T frontend yarn tsc --noEmit
```

加えて[request](../../../requests/scope-repair-fr017-1.json)第二checkのCJS比較commandをそのまま実行し、d58c473 schema comparisons: 120 passedを得た。比較に埋め込まれたadd/update schema blockはbaseline-schema-blocks.jsonと一致し、双方ともd58c473の元Mutation fileに存在するblockそのものだった。

各schemaについて、undefined/null/空object、nameやentriesの欠落、NaN/Infinity/-Infinity、0/負数/整数/少数、文字列、unknown key、複数entryを含む120ケースで、success/dataまたは全issuesのpath/code/message/orderが元schemaと一致した。静的にもshared schemaは元のnumber契約を保持し、追加の整数/正数条件はない。

MealFramePatternFieldsとEditor specは`62359ad^`とbyte一致した。FR-032/033の6 production fileは608ed3dとbyte一致しており、shared schemaを今回書き換えていない。利用者変更3fileの保存hashとgit diff --checkも成功した。

失敗はない。これは未選択枠のnull化と追加拒否を旧フォーム契約へ戻した状態の検証であり、placeholder再選択時の旧問題を解消したものではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作、新service起動、依存取得も行っていない。
