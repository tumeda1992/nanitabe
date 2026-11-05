# FR-015 復元検証

- request_id: `scope-repair-fr015-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeのfrontendでカレンダー/モード/延期操作の既存Jestは4 suites / 17 tests成功。復元4fileのlintとtsc --noEmitも成功した。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand src/components/calendar/calendarComponents/Calendar/index.spec.tsx src/components/calendar/calendarComponents/useCalendarMode.spec.ts src/components/calendar/calendarComponents/operationComponents/PostponeMeal
docker compose -f compose.dev.local.yml exec -T frontend yarn lint src/components/calendar/calendarComponents/Calendar/index.tsx src/components/calendar/calendarComponents/operationComponents/PostponeMeal/ScheduleChosenPostponedMealForDate.tsx src/components/calendar/calendarComponents/operationComponents/PostponeMeal/usePostponedMealMode.ts src/components/calendar/useRefreshCalendarData.tsx
docker compose -f compose.dev.local.yml exec -T frontend yarn tsc --noEmit
```

restored-paths.jsonの7pathは`c05d21d^`とbyte一致または不存在だった。Calendar wrapperの旧Promise境界、非await refetch、旧延期hook/表示を保持し、refresh待機・失敗時状態保持・retry表示の追加を除去している。先行カレンダーモード型を含む親版、FR-032/033の純抽出6 production file、利用者変更3fileの保存hashを保持し、git diff --checkも成功した。

失敗はない。console原文は大量に出力せず、テスト集計を記録した。この結果は旧待機境界への復元確認であり、元のPromise欠落を解消したものではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作、新service起動、依存取得も行っていない。
