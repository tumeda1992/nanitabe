# FR-023: 正規化辞書の文字列を未エスケープの正規表現として扱う

- 優先度: P2
- 採否: 採用
- 対応状況: 完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-021（現行コードで再確認）。

## 対象

- [backend/app/domain/business/food/dish/word/usecase/normalizer.rb](../../../../../backend/app/domain/business/food/dish/word/usecase/normalizer.rb)

## 問題と根拠

辞書sourceを/#{source}/へ直接補間する。文字列の置換元として「[」を登録するとRegexpErrorになることを実測した。「.」等は想定外の文字に一致し、料理名・タグの正規化結果を壊す。SQL LIKEによる候補抽出とRuby正規表現で意味も一致しない。

## 改善案

辞書が文字列置換ならString#gsubの文字列引数またはRegexp.escapeを用いる。SQL LIKE側の%/_も文字列として扱うよう揃え、正規表現を許す仕様へ暗黙に変更しない。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

[、.、*、バックスラッシュ、%/_を含む置換元・置換先で、登録と再正規化を検証する。今回「[」の例外を実測。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `73b8797`

## 適用検証（2026-11-01）

現行Normalizerと、旧料理・タグCommandが使うBusiness::Dish::Word::Normalize::Command::NormalizeCommandをともに修正した。元の正規化済み入力へsourceが文字列として含まれる規則だけを一度選び、String#gsubの文字列patternとblock戻値で置換する。sourceの正規表現記号もdestinationのbackreferenceも解釈しない。置換出力だけに現れるsourceを新たに候補へ追加しない。

現行の追加11件で8件red、旧経路にも同じ回帰を当て7件redを確認した。最終specは共通10ケースを両経路へ適用し、現行の料理名・タグ再反映も1ケース検証する。関連152 examples / 0 failures。既存の辞書取得1queryの性能specも成功した。

- `docker compose -f compose.dev.local.yml exec -T backend bundle exec rspec spec/domain/business/food/dish/word spec/domain/business/dish/word spec/domain/business/dish/dish spec/requests/admin/food/dish/word/normalize_words_spec.rb spec/system/admin/food/dish/word/normalize_words_spec.rb`

DB検証はtest環境だけで、実データへの再反映は実行していない。

変更3ファイルの`bundle exec rubocop app/domain/business/food/dish/word/usecase/normalizer.rb app/domain/business/dish/word/normalize/command/normalize_command.rb spec/domain/business/food/dish/word/usecase/literal_normalization_spec.rb`も、specの空行整形後に違反なし。適用commitはapplication.mdとGit履歴で追跡する。
