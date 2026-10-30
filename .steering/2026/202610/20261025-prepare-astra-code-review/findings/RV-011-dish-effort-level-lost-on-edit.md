# RV-011: 料理編集で既存の手間レベルが未設定へ戻る

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: frontend/src/components/dish/DishForm/DishForm/DishFormOfOnlyDishFields.tsx: useEffect; frontend/src/features/dish/fetchDishQuery.ts: DISH; backend/app/graphql/types/output/dish/essential_dish.rb; backend/app/domain/business/food/dish/usecase/update_command.rb: update_dish_root
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

出力スキーマEssentialDishにはdish_effort_level_idがなく、編集用queryも取得しない。フォームは初回effectでもdish.dishEffortLevelIdをnullにする。backendは更新時にassign_effort_levelを無条件実行するので、手間が設定済みの料理で名前だけ編集して送信しても手間が失われる。backend specには明示nullで解除するケースがあり、その解除自体は意図された動作。

## 改善案

出力スキーマと編集queryへ現在の手間IDを追加し、初期値へ反映する。位置づけを実際に変更したときだけ手間をリセットし、初回表示と区別する。

## 振る舞いを維持する条件

保存結果が変わるバグ修正であり対象外。明示的な「指定なし」による解除と、位置変更時のリセットは維持する。

## 検証方法

手間付き料理の名前のみ変更後に手間IDが維持される往復テスト、明示解除、位置づけ変更の3ケースを追加する。カレンダー内と単独編集画面の両入口を確認する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
