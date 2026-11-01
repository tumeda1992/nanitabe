# FR-013: 料理編集で既存の手間レベルを消してしまう

- 優先度: P1
- 採否: 採用
- 対応状況: 完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-011（現行コードで再確認）。

## 対象

- [frontend/src/components/dish/DishForm/DishForm/DishFormOfOnlyDishFields.tsx](../../../../../frontend/src/components/dish/DishForm/DishForm/DishFormOfOnlyDishFields.tsx)
- [frontend/src/features/dish/fetchDishQuery.ts](../../../../../frontend/src/features/dish/fetchDishQuery.ts)
- [frontend/src/features/meal/fetchMealQuery.ts](../../../../../frontend/src/features/meal/fetchMealQuery.ts)
- [backend/app/domain/business/food/dish/usecase/update_command.rb](../../../../../backend/app/domain/business/food/dish/usecase/update_command.rb)

## 問題と根拠

初回mountでもmealPositionのeffectがdish.dishEffortLevelIdへnullを設定する。編集用クエリも既存IDを取得せず、SelectEffortLevelへ復元値が渡らない。料理名だけを変更して保存しても、backendのassign_effort_levelがnullを保存する。正常操作で既存情報が消える。

## 改善案

クエリへ既存IDを含め、フォームdefaultValuesへ復元する。初回初期化とユーザーによる位置づけ変更を区別し、後者だけ適合しない手間をリセットする。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

手間設定済み料理について、名前のみ変更・無変更保存でID維持、位置づけ変更と明示解除で意図した値になることを画面からmutationまで検証する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 既存レビューの全件反映と指摘単位コミットの合意により採用
- 適用コミット: 本記録を含むFR-013コミット（SHAはapplication.mdへ追記）

## 適用結果（2026-11-01）

backendの共通料理出力へnullableな`dishEffortLevelId`を追加し、料理詳細・カレンダーqueryと生成物に反映した。フォームの既存手間IDを初期値へ復元し、初回effectでは消さず、ユーザーが位置づけを変更した時だけ解除する。選択肢の遅延取得後も現在のフォーム値を表示する。

修正前のfrontend追加5件は3 failuresで表示欠落・無変更/名前変更のnull送信を再現した。backend追加2件は未定義出力fieldを再現した。修正後はfrontendの料理/食事フォーム10 suites / 52 tests成功、backendの料理詳細/カレンダー7 examples成功、TypeScript noEmit・frontend変更6ファイルlint・backend変更2ファイルRuboCop成功。ブラウザ確認は`requests/fr013-visual.json`と同名のresult JSONにより4項目成功を確認した。人工fixtureで表示・送信値を検証し、実DBへの保存は行っていない。

ブラウザでは既存ID 17の初期表示、名前変更時の17送信、明示解除と位置づけ変更のnull送信を確認し、1920px幅の4画像を目視した。390px幅でも機能4項目は成功したが、入力フォーカス時の横はみ出しを観測した。変更前との比較がなくFR-013の回帰とは判定していない。画像と実行scriptはgitignore済みの`frontend/inspect/visual/tmp/fr013-effort-retention/`にある。
