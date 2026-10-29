# FR-015: カレンダー更新完了を待つPromiseが途中で失われる

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-018（現行コードで再確認）。

## 対象

- [frontend/src/components/calendar/calendarComponents/Calendar/index.tsx](../../../../../frontend/src/components/calendar/calendarComponents/Calendar/index.tsx)
- [frontend/src/components/calendar/useRefreshCalendarData.tsx](../../../../../frontend/src/components/calendar/useRefreshCalendarData.tsx)
- [frontend/src/components/calendar/calendarComponents/operationComponents/PostponeMeal/usePostponedMealMode.ts](../../../../../frontend/src/components/calendar/calendarComponents/operationComponents/PostponeMeal/usePostponedMealMode.ts)

## 問題と根拠

延期確定hookはawait onDataChanged()でclearStoreとの競合を避ける意図だが、CalendarのコールバックはrefreshData()をreturnしない。さらにrefreshData内部のrefetchMealsForCalendarもawait/returnされない。再取得・モード終了が先へ進み、画面更新待ちという契約が二段階で崩れる。

## 改善案

onDataChangedへrefreshDataを直接渡し、refreshDataもrefetchのPromiseを返す。失敗時にモード・選択をどう保つかを決め、例外の表示経路を設ける。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

clearStoreとrefetchを個別に保留できるPromiseで差し替え、完了順と失敗時の状態を検証する。即時resolve mockだけで検証しない。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
