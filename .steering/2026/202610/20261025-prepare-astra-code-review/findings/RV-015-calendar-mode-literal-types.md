# RV-015: カレンダーモードの型がstringとanyへ広がっている

- 観点: 保守性・責務・型
- 優先度: 中
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: frontend/src/components/calendar/calendarComponents/useCalendarMode.ts; operationComponents/MoveMeal/useMoveMealMode.ts; operationComponents/PostponeMeal/usePostponedMealMode.ts; operationComponents/AssignDish/useAssignDishMode.ts; operationComponents/SwapMeals/useSwapMealsMode.ts
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

モード定数オブジェクトにas constがなく、値から作るMode型はstringに広がる。calendarModeとupdateCalendarModeはanyで受けるため、宣言されたCalendarModeの列挙にない文字列も型検査を通る。複数hookに分かれた状態遷移を追加・変更する際に誤記を検出できない。

## 改善案

定数をas constにし、共通のモード型とsetter型を定義する。useState<CalendarMode>と各hook引数へ適用し、実際の文字列と遷移処理は維持する。共有型はhookの循環importを増やさないファイルへ置く。

## 振る舞いを維持する条件

型だけの変更とし、状態をdiscriminated unionオブジェクトへ変更したり、callbackのawaitを追加したりしない。RV-018の非同期修正は独立。

## 検証方法

型チェックと既存モード切替specで選択・実行・Escapeを確認する。未定義のモード文字列が型エラーになることも確認する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
