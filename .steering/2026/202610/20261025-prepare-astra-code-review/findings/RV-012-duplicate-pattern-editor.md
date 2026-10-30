# RV-012: パターン作成・編集フォームの入力操作が二重実装されている

- 観点: 保守性・責務・型
- 優先度: 中
- 採否: 採用
- 対応状況: 完了
- 今回の適用対象: 対象
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: frontend/src/components/meal/frame/pattern/MealFramePatternForm.tsx; MealFramePatternEditForm.tsx
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

日追加・削除、枠追加・削除、入力更新、名前と未選択枠の検証、日番号の再計算、フォームDOMがほぼ同じまま二重に存在する。いずれも同じパターンの編集規則なので、枠の入力仕様が変わるたび両方を同期する必要がある。

## 改善案

共通のパターン入力コンポーネントと入力型を抽出し、初期値・送信callback・送信ラベルをpropsで渡す。作成mutationと更新mutation、既存entriesからDaySlotへの復元は外側の薄いコンポーネントに残す。

## 振る舞いを維持する条件

初期化時期、DOMとtestid、エラー文言と順序、nameをtrimせず送る現状、dayIndex+1での再採番、mutation呼び出し回数を維持する。未選択optionの挙動修正はこの抽出に混ぜない。

## 検証方法

両既存フォームspecを使い、空名・未選択枠・中間日削除・作成/更新payload・成功callbackを比較する。共有化後もidが更新だけに入ることを確認する。

## 採否・対応記録

- 2026-10-26: ユーザーの適用指示により採用・実装済み。
- 検証: MealFramePatternFieldsへ入力・検証・DOMを集約し、作成/編集wrapperにAPI呼出と初期値復元を残した。共通化前の回帰6件と既存Form/Listを実行: 3 suites, 13 tests成功。
- 適用コミット: 本ファイルの完了記録と同じコミット（git logで参照可能）
