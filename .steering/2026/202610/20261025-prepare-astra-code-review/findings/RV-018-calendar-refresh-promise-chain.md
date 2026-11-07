# RV-018: 延期確定で必要なキャッシュ初期化待ちが呼び出し元で失われる

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 採用（後続の全件反映指示）
- 対応状況: 完了（FR-015で追跡）
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

- ユーザーの判断: 後続の全件反映指示により採用（FR-015）
- 初回確認: コードと記載した関連specの静的確認。後続の検証結果は以下のFR記録を参照。
- 適用コミット: `c05d21d`

## 後続の反映（2026-11-02）

本fileの「今回の適用対象」は初回の挙動維持枠を指す。後続の全件反映指示による現行状態・検証は[FR-015](../../20261027-full-repository-review/findings/FR-015-refresh-promise.md)へ集約する。適用commitは`c05d21d`。
