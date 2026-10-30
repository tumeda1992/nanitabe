# RV-018: 延期確定で必要なキャッシュ初期化待ちが呼び出し元で失われる

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: frontend/src/components/calendar/calendarComponents/Calendar/index.tsx: useCalendarModeのonDataChanged; frontend/src/components/calendar/calendarComponents/operationComponents/PostponeMeal/usePostponedMealMode.ts: onCompleted; frontend/src/components/calendar/useRefreshCalendarData.tsx: refreshData
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

延期確定hookはawait onDataChanged()後にrefetchPostponedMealsを呼び、コメントでもclearStoreとの衝突回避を要求する。しかしCalendarが渡すcallbackは{ refreshData(); }でPromiseを返さない。そのためawaitはclearStore完了を待てず、再取得との競合が残る。さらにrefreshData自身も末尾のrefetchMealsForCalendarをawait/returnしない。

## 改善案

CalendarからrefreshDataのPromiseを返し、refreshDataもカレンダー再取得完了まで返す。onDataChangedをPromise<void>契約で型付けする。

## 振る舞いを維持する条件

処理順序・完了タイミング・例外伝播が変わるため対象外。キャッシュ全消去を部分更新に置き換える変更は別検討。

## 検証方法

clearStoreの解決を保留したPromiseで再現し、その間refetchPostponedMealsが呼ばれないことを確認する。resolve後の順序、reject時のモードとエラー処理も検証する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
