# FR-020: Nextの画面遷移で論理URLが更新されず日付がずれる

- 優先度: P2
- 採否: 採用
- 対応状況: 再適用・検証完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [frontend/src/app/logical-history.tsx](../../../../../frontend/src/app/logical-history.tsx)
- [frontend/src/components/calendar/calendarComponents/CalendarHeader/index.tsx](../../../../../frontend/src/components/calendar/calendarComponents/CalendarHeader/index.tsx)
- [frontend/src/app/calendar/month/[date]/page.tsx](../../../../../frontend/src/app/calendar/month/[date]/page.tsx)

## 問題と根拠

ProviderはusePathnameを初期stateにしか使わず、以降は独自pushHistoryとpopstateだけで更新する。週/月切替や今週リンクはNext Linkを使い、共通layout内のProviderは維持される。この遷移で論理URLが旧ページのままなら新ページのパーサーが不一致として今日へ戻る。Jestでpathname変更後も古い論理URLが返ることを実測した。実ブラウザのNext遷移は未検証。

## 改善案

Nextのpathname/searchの変更を論理stateへ同期するか、カレンダーの表示日付の正本をrouterへ統一する。独自pushStateと戻る/進むによる二重更新を回帰テストで防ぐ。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

今日以外の週から同じ日を含む月への切替、今週リンク、戻る/進むを検証する。Provider単体の同期欠落は実測済み。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `d8afcf0`

## 適用検証（2026-11-01）

Nextのpathname/search変化を同期childで検知し、effect実行時点のbrowser URLをcontextへ反映する。古いNext snapshotを値として再利用せず、直前の独自push/popを巻き戻さない。同期は履歴を追加しない。独自pushはhashをブラウザ履歴へ保持し、path+queryだけをcontextへ返す。useSearchParamsの同期childだけをSuspenseへ含める。Next contextがない場合のnullも許容する。

テストのwindow.location共通mockがhrefしか持たないため、履歴specは実JSDOM Locationを復元して検証した。その後のredは4件中3件（Next経路・query変更・hash除外）が失敗し、popstateは成功。修正後は関連19 tests、古いsnapshotとの競合追加後5 tests、型検査・変更2ファイルlintが成功した。全画面共通Providerの影響確認でfrontend全体46 suites / 256 testsも成功。

- `docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand --silent logical-history CalendarHeader Calendar/index.spec useRefreshCalendarData`
- 同frontendの`yarn test --runInBand --silent logical-history.spec`
- 同frontendの`yarn tsc --noEmit --incremental false`
- 同frontendの`yarn lint src/app/logical-history.tsx src/app/logical-history.spec.tsx`
- 同frontendの`yarn test --runInBand --silent`

ブラウザ確認requestはrequests/fr020-visual.json。実DBへ変更を送らない全GraphQL mockで確認する。本番buildは常駐devと別の一時source copyで検証中。最初のbuildはnode_modulesへのsymlinkがTurbopackのroot外で環境エラーになり、アプリのcompile結果は得られなかった。依存全量copyは負荷が高く中止し、一時copy側だけrootを調整した。元のNext設定・devの停止/再起動は行っていない。常駐watcherがある状態でTailwindも初回に二重実行してしまったため、以後のbuildは生成済みCSSを使いNextのみで行う。

最終確認: visual-inspectorは16状態、back15回/forward15回でURL・全日付カード・期間labelの一致と履歴の重複追加なしを実測した。8画像目視済み、mutation/未知operation0。結果はrequests/fr020-visual-result.json。実backendデータ取得はmockのため未確認。

同じ開発用frontend containerの`/tmp/nanitabe-fr020-build.66mdS7`で、生成済みCSSを使い`env NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 yarn next build`も成功。compile43秒、TypeScript50秒、静的19ページ生成と最適化が完了した。一時copyだけに`turbopack.root = "/"`を設定して既存node_modules symlinkを解決可能にした。repositoryのconfigは変更していない。適用commitはapplication.mdとGit履歴で追跡する。

## 適用取消と旧挙動の復元（2026-11-05）

Next pathname/search同期とpushHistoryのURL正規化追加をd8afcf0親版へ戻し、専用specを除いた。
[復元結果](../evidence/scope-repair/fr020-attempt-1/result.md)はconsumer Jest16 tests、Provider lintと型検査、
旧byte一致・純抽出と利用者変更保持・diff checkが成功した。
consumer mock検証を実ルーティング検証と混同しない。旧popstate/push/初期化は旧版全量照合で確認した。
元のNext遷移時の同期漏れと過去の実測は保存し、解消済みとは数えない。

## 再適用（2026-11-06）

Next遷移と表示日付の同期を復帰。Jest 20 tests、型検査・lint成功。人工fixtureの画面で週/月、前後、今週、browser戻る/進む8状態のURLと表示一致を確認。内部snapshot競合はunitで検証し実DB未操作。
