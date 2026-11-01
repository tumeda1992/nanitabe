# FR-006: パターン更新・削除は操作ユーザーを受け取らない

- 優先度: P1
- 採否: 採用
- 対応状況: 完了
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

- ユーザー判断: 2026-11-01の反映指示により採用
- 適用コミット: 本記録を含むFR-006コミット（SHAはapplication.mdへ追記）

## 適用結果（2026-11-01）

更新・削除Commandで`user_id`を必須化し、GraphQL両入口から認証利用者IDを渡す。更新はrename・子エントリ置換前にrootの所有者を確認し、削除は利用者で絞った取得に変更した。既存Command specも明示的に本人IDを渡す。

追加`spec/graphql/mutation/meal/frame/pattern/ownership_spec.rb`で他人ID・不存在IDの更新/削除とユーザー欠落を検証。初回は既存404応答を例外と誤認したためテストをHTTP status検証へ修正し、6 examples / 4 failuresで不正操作と欠落の問題を再現した。修正後はGraphQL pattern directoryとdomain pattern/usecase directoryで24 examples / 0 failures。本人の置換・空entries・cascade削除の既存動作、拒否時の親子全属性の不変を確認した。変更7ファイルのRuboCopは違反なし。既存開発用Compose内で実行。
