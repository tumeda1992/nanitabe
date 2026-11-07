# FR-020 復元検証

- request_id: `scope-repair-fr020-1`
- attempt: 1
- status: passed
- 実測日: 2026-11-05

既存開発Composeのfrontendで、論理履歴consumerのJestは3 suites / 16 tests成功。旧Provider 1fileのlint、tsc --noEmitも成功した。

実行command:

```text
docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand src/components/calendar/calendarComponents/useCalendarMode.spec.ts src/components/calendar/calendarComponents/Calendar/index.spec.tsx src/components/calendar/calendarComponents/CalendarHeader/index.spec.tsx
docker compose -f compose.dev.local.yml exec -T frontend yarn lint src/app/logical-history.tsx
docker compose -f compose.dev.local.yml exec -T frontend yarn tsc --noEmit
```

logical-history.tsxは`d8afcf0^`とbyte一致し、FR-020専用logical-history.spec.tsxは除去されている。旧版のpopstate/pushHistory/初期化を保持し、pathname同期child、Suspense/searchParams追加、URL正規化追加を取り消している。FR-032/033の純抽出6 production fileと利用者変更3fileの保存hashも一致し、git diff --checkは成功した。

consumer testsはmockされた履歴を使う範囲の確認であり、実ProviderのNextルーティング同期が動くことを証明しない。JestにはMSWの未登録fixture queryの警告が残るが、assertion失敗はなかった。

これは旧Providerへの復元確認であり、Next遷移の既知の同期漏れを解消した結果ではない。実装・tasklist・finding・applicationは変更せず、実DB/AWS/Webhook操作、新service起動、依存取得も行っていない。
