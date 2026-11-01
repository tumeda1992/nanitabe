# FR-024: 辞書更新と全料理への再反映が一体で保存されない

- 優先度: P2
- 採否: 採用
- 対応状況: 完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [backend/app/domain/business/food/dish/word/usecase/add_command.rb](../../../../../backend/app/domain/business/food/dish/word/usecase/add_command.rb)
- [backend/app/domain/business/food/dish/word/usecase/update_command.rb](../../../../../backend/app/domain/business/food/dish/word/usecase/update_command.rb)
- [backend/app/domain/business/food/dish/word/usecase/remove_command.rb](../../../../../backend/app/domain/business/food/dish/word/usecase/remove_command.rb)
- [backend/app/domain/business/food/dish/word/usecase/reflect_latest_normalize_word_command.rb](../../../../../backend/app/domain/business/food/dish/word/usecase/reflect_latest_normalize_word_command.rb)

## 問題と根拠

辞書のcreate/update!/destroy!が先に確定し、その後全料理を順次保存する。外側transactionがない。途中の料理で例外が起きると辞書は変更済み、一部料理・タグのみ新ルール適用済みになる。controllerのエラー画面は未保存に見えるが、再送しても最初の操作を取り消せない。

## 改善案

件数が小さい現段階では辞書変更と反映を同一transactionに含める。非同期化する場合は辞書versionと再実行可能な反映状態を設計し、完了前後の検索契約を定める。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

2件目の反映へ失敗を注入し、辞書・1件目・タグがすべて元に戻ることを検証する。正常系だけでなく削除失敗も含める。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用

## 適用結果（2026-11-01）

辞書の追加・更新・削除と全件再反映をそれぞれ同じtransactionへ含めた。再反映Command単独で呼ばれた場合も全料理・タグをまとめてrollbackする。例外の型・メッセージとCommandの戻値を維持している。

追加4ケースは、2料理と各タグを用意し、2件目の料理永続化で実際に失敗させる。失敗直前に1件目の料理・タグが既に書かれたことも読み取り、失敗後に辞書・2料理・両タグの全属性が元へ戻ることを確認した。反映Command全体を例外stubするだけのテストではない。修正前は全4件が辞書残存/部分反映で失敗。修正後は関連95 examples / 0 failures、変更5ファイルRuboCop違反なし。

- `docker compose -f compose.dev.local.yml exec -T backend bundle exec rspec spec/domain/business/food/dish/word spec/requests/admin/food/dish/word/normalize_words_spec.rb spec/system/admin/food/dish/word/normalize_words_spec.rb`
- 同backendの`bundle exec rubocop app/domain/business/food/dish/word/usecase/add_command.rb app/domain/business/food/dish/word/usecase/update_command.rb app/domain/business/food/dish/word/usecase/remove_command.rb app/domain/business/food/dish/word/usecase/reflect_latest_normalize_word_command.rb spec/domain/business/food/dish/word/usecase/atomic_reflection_spec.rb`

実データへの辞書変更・再反映は行っていない。適用commitはapplication.mdとGit履歴で追跡する。
