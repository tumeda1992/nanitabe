# FR-015: カレンダー更新完了を待つPromiseが途中で失われる

- 優先度: P2
- 採否: 部分採用（Promise伝播）
- 対応状況: 部分再適用・検証完了
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

- ユーザー判断: 既存レビュー反映の合意により採用
- 適用コミット: `c05d21d`

## 適用結果（2026-11-01）

CalendarからrefreshDataのPromiseを直接渡し、refreshDataもcalendar refetchの完了をawaitする。延期確定後はcalendar/list再取得の完了後だけ選択とモードを解除する。再取得失敗はcallback内で捕捉し、選択保持とエラー表示、登録を再送しない再取得操作を追加した。送信中・更新失敗中の日付再クリックも再登録しない。

修正前の追加8 testsは6 failuresで待機の二段階の欠落、更新失敗の未捕捉、表示経路の欠落を再現。修正後は関連7 suites / 25 tests成功、送信中の重複と登録失敗後の状態を追加した最終hook5 testsも成功。型検査と変更7ファイルlintに成功した。ブラウザ確認は`requests/fr015-visual.json`と同名result JSONにより3項目成功。登録後にcalendar再取得を一度失敗させ、選択/エラー保持、日付再クリックで再送しないこと、表示だけの再取得で復帰することを確認した。5画像を目視し、全操作で登録mutationは合計1回。全GraphQLをmockし、実DB保存は確認していない。

## 適用取消と旧挙動の復元（2026-11-05）

refresh待機・失敗時モード保持・retry表示の追加をc05d21d親版の非同期境界と表示へ戻した。
[復元結果](../evidence/scope-repair/fr015-attempt-1/result.md)はJest17 tests、4fileのlint・型検査、
7path旧byte一致/不存在、先行モード型・純抽出と利用者変更保持、diff checkが成功した。
元のPromise欠落・refetch非待機の問題と旧検証は保存し、解消済みとは数えない。

## 部分再適用（2026-11-06）

既存再取得Promiseの2箇所のみ接続し、新retry UI/state machineは保留。Jest 8 tests、型検査とlint成功。人工fixtureの画面確認でcalendar保留中モード継続、解放後一覧再取得と終了を確認。内部失敗伝播はunitで確認し、実DB再保存は未実測。
