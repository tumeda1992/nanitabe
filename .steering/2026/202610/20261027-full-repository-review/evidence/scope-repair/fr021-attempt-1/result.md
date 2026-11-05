# FR-021 復元検証

- request_id: `scope-repair-fr021-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeのfrontendで旧日付parserのJestは1 suite / 8 tests成功。parser/spec 2fileのlintも成功した。request記載のchecksに加え、親のdispatch指定にあった同じ既存commandのtsc --noEmitも成功した。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand src/features/calendar/calendarDateFromPath.spec.ts
docker compose -f compose.dev.local.yml exec -T frontend yarn lint src/features/calendar/calendarDateFromPath.ts src/features/calendar/calendarDateFromPath.spec.ts
docker compose -f compose.dev.local.yml exec -T frontend yarn tsc --noEmit
```

calendarDateFromPath helper/specは`c240b94^`とbyte一致した。先行RV-029の週/月共通parser、FR-020の履歴同期production file、FR-032/033の純粋な共通化6 production fileを保持している。利用者変更3fileの保存hashとgit diff --checkも成功した。

失敗はない。これは形式のみの日付検証と旧境界解釈を復元した結果であり、無効な実在日・query/hash境界の既知問題を解消したものではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作、新service起動、依存取得も行っていない。
