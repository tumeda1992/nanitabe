# FR-021: 日付URLが形式だけの検査で無効日付を画面へ渡す

- 優先度: P2
- 採否: 今回は見送り（挙動維持の制約により適用取消）
- 対応状況: 適用取消・旧挙動の復元検証完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [frontend/src/features/calendar/calendarDateFromPath.ts](../../../../../frontend/src/features/calendar/calendarDateFromPath.ts)
- [frontend/src/features/utils/dateUtils.ts](../../../../../frontend/src/features/utils/dateUtils.ts)
- [frontend/src/components/calendar/MonthCalendar/index.tsx](../../../../../frontend/src/components/calendar/MonthCalendar/index.tsx)

## 問題と根拠

yyyy-MM-ddの形式だけでnew Dateへ渡すため、2026-13-40のようなURLでInvalid Dateが下流のformat/eachDayOfIntervalへ届き例外になる。存在しない2月の日が翌月へ繰り上がる入力もある。URL末尾のqueryも日付文字列へ混ぜるため有効日付にqueryを付けるだけで今日へfallbackする。共通化は旧挙動を維持したが、全体レビューとしては残存不具合である。

## 改善案

URLからpathnameの該当segmentだけを取得し、parse後に年月日が一致することまで検証する。無効URLを404とするか今日へ戻すか決める。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

無効月日・閏年・query/hash付きURL・週/月で同一日付をテストする。既存の形式のみ検査を固定したspecは、新契約に合わせて変更する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `c240b94`

## 適用検証（2026-11-01）

合意済みdesignに従い、query/hashを除いたpathnameを完全なcalendar prefixと日付1segmentで照合する。ISO形式に加え、生成したDateの年/月/日が入力と一致する場合だけ採用し、存在しない日付は今日09:00へfallbackする。year0〜99のconstructor補正を避ける既存の文字列Date生成を維持した。

不具合を固定していた旧specの期待値を新契約へ直し、21件中11件のredを確認。修正後は関連3 suites / 35 tests、型検査、変更2ファイルlintが成功した。

- `docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand --silent calendarDateFromPath logical-history CalendarHeader`
- 同frontendの`yarn tsc --noEmit --incremental false`
- 同frontendの`yarn lint src/features/calendar/calendarDateFromPath.ts src/features/calendar/calendarDateFromPath.spec.ts`

ブラウザ確認はrequests/fr021-visual.jsonを使用し、全GraphQLをmockする。

visual-inspectorも2ケース成功。うるう日のquery/hash付きURLは対象日を含む週を保持し、存在しない2月30日はbrowser当日を含む月へfallbackした。全dateカードとlabelを照合し2画像目視済み。例外・mutation・未知operation0。結果はrequests/fr021-visual-result.json。実backend取得はmockのため未確認。適用commitはapplication.mdとGit履歴で追跡する。

## 適用取消と旧挙動の復元（2026-11-05）

URL日付の実在日・query/hash境界の追加検証をc240b94親版へ戻した。
[復元結果](../evidence/scope-repair/fr021-attempt-1/result.md)はJest8 tests、2fileのlintと型検査、
helper/spec旧byte一致、先行共通化・FR-020残部・純抽出と利用者変更保持、diff checkが成功した。
元の無効日付の問題と過去の検証は保存し、解消済みとは数えない。
