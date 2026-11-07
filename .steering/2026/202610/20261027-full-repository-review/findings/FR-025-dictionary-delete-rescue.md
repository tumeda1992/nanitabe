# FR-025: 辞書削除後の反映失敗をrescue自身が別例外で隠す

- 優先度: P2
- 採否: 採用
- 対応状況: 再適用・検証完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [backend/app/controllers/admin/food/dish/word/normalize_words_controller.rb](../../../../../backend/app/controllers/admin/food/dish/word/normalize_words_controller.rb)
- [backend/app/domain/business/food/dish/word/usecase/remove_command.rb](../../../../../backend/app/domain/business/food/dish/word/usecase/remove_command.rb)

## 問題と根拠

destroyのrescueはNormalizeWord.find(params[:id])を呼ぶが、Commandは既に辞書をdestroy!しているためRecordNotFoundになる。さらにDELETEには通常normalize_wordパラメータがなく、normalize_word_paramsのrequireも成立しない。ユーザーへ反映失敗を知らせるつもりの処理が到達できない。

## 改善案

削除処理の原子性を先に修正し、rescueでは削除前に取得した表示用情報を使うか一覧へ失敗通知する。DELETEでフォームpayloadを必須にしない。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

反映Commandに例外を注入してDELETEを行い、二次例外でなく意図した応答・メッセージになることをrequest specで確認する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `4a12564`

## 適用結果（2026-11-01）

削除後の再反映エラーでは、レコードの再検索やDELETEにないnormalize_word paramsを読まず、一覧へalert付きでredirectする。一覧templateにもエラーalertを表示する。FR-024のtransactionによって辞書は元へ戻り、削除成功の通知を出さない。

本文なしDELETEの追加request specで、最初はParameterMissingによる400を再現した。redirectへ直した後の検証で一覧がalertを描画しないことも検出し、templateを修正した。最終的に関連24 examples / 0 failures、変更Ruby2ファイルRuboCop違反なし。requestはredirect後の実HTMLに元の反映エラーが表示され、辞書の全属性が不変であることを確認する。既存system CRUDも成功した。

- `docker compose -f compose.dev.local.yml exec -T backend bundle exec rspec spec/requests/admin/food/dish/word/normalize_words_spec.rb spec/system/admin/food/dish/word/normalize_words_spec.rb spec/domain/business/food/dish/word/usecase/remove_command_spec.rb spec/domain/business/food/dish/word/usecase/atomic_reflection_spec.rb`
- 同backendの`bundle exec rubocop app/controllers/admin/food/dish/word/normalize_words_controller.rb spec/requests/admin/food/dish/word/normalize_words_spec.rb`

実DBや開発serverでの管理操作は行っていない。適用commitはapplication.mdとGit履歴で追跡する。

## 適用取消と旧挙動の復元（2026-11-04）

削除失敗時のredirectとalert表示追加は例外経路を変えるため、controller/view/request specを4a12564親版へ戻した。
[復元結果](../evidence/scope-repair/fr025-attempt-1/result.md)はRSpec9 examples / 0 failures、RuboCop2 files / 0 offenses、
3file旧byte一致、FR-001 WIP/FR-024と利用者変更保持、diff checkが成功した。
元のrescue不具合の指摘と過去の検証は保存し、解消済みとは数えない。

## 再適用（2026-11-06）

本文なしDELETEの反映失敗を元エラーとして一覧へ表示し、FR-024 transactionで全属性を保持する。RSpec 75 examples / 0 failures、指定2 file RuboCop 0 offenses。今回の指定lintには既存FR-001 offenseは出ていない。FR-001 WIPを保持。[結果](../evidence/scope-repair/fr025-retain-attempt-1/result.md)。
