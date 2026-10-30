# FR-025: 辞書削除後の反映失敗をrescue自身が別例外で隠す

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
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

- ユーザー判断: 未判断
- 適用コミット: 未適用
