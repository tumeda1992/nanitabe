# FR-006: パターン更新・削除は操作ユーザーを受け取らない

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-008（現行コードで再確認）。

## 対象

- [backend/app/graphql/mutations/meal/frame/pattern/update_meal_frame_pattern.rb](../../../../../backend/app/graphql/mutations/meal/frame/pattern/update_meal_frame_pattern.rb)
- [backend/app/graphql/mutations/meal/frame/pattern/delete_meal_frame_pattern.rb](../../../../../backend/app/graphql/mutations/meal/frame/pattern/delete_meal_frame_pattern.rb)
- [backend/app/domain/business/food/meal/frame/pattern/usecase/update_command.rb](../../../../../backend/app/domain/business/food/meal/frame/pattern/usecase/update_command.rb)
- [backend/app/domain/business/food/meal/frame/pattern/usecase/remove_command.rb](../../../../../backend/app/domain/business/food/meal/frame/pattern/usecase/remove_command.rb)

## 問題と根拠

mutationからCommandへ渡るのはID等だけで、current_user_idがない。更新はIDだけでrootを復元し、全エントリを削除・再作成する。AがBのパターン全体を上書き・削除できる。applyの所有者確認はupdate/deleteには効かない。

## 改善案

user_idをCommandの必須引数に追加し、ユーザー内でパターンを取得する。子の全置換は認可後のtransactionで行う。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

A/Bのパターンを用意し、BのIDを使う更新・削除で名前・子エントリが不変であることを検証する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
