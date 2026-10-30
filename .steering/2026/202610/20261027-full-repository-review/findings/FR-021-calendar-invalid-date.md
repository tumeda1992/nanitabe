# FR-021: 日付URLが形式だけの検査で無効日付を画面へ渡す

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
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

- ユーザー判断: 未判断
- 適用コミット: 未適用
