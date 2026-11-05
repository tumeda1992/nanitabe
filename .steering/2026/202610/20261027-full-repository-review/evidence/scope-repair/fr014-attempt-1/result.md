# FR-014 復元検証

- request_id: `scope-repair-fr014-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeのfrontendで、共通mutation consumer・共有schema・カレンダーモードの既存Jestは3 suites / 22 tests成功。復元したbuilder/caller/specの3file lintとtsc --noEmitも成功した。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand src/features/dish/dishInputConversion.spec.ts src/features/meal/frame/pattern/schema.spec.ts src/components/calendar/calendarComponents/useCalendarMode.spec.ts
docker compose -f compose.dev.local.yml exec -T frontend yarn lint src/features/utils/mutationUtils.ts src/components/calendar/calendarComponents/operationComponents/SwapMeals/useSwapMealsMode.ts src/components/calendar/calendarComponents/useCalendarMode.spec.ts
docker compose -f compose.dev.local.yml exec -T frontend yarn tsc --noEmit
```

restored-paths.jsonの4pathは`601d722^`とbyte一致または不存在だった。Apolloの状態読取り修正、任意callback/公開型の変更、付随swap guardと追加期待を旧版へ戻した。先行入力共通化・モード型とFR-032/033の純抽出6 production fileを保持し、利用者変更3fileの保存hashとgit diff --checkも成功した。

失敗はない。これは旧tuple/引数/callerの復元確認であり、loading/error取得の既知不具合を解消したものではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作、新service起動、依存取得も行っていない。
