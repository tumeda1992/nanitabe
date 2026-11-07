# CR-001: 複数タグに分かれた検索語をAND検索すると該当料理が消える

- 優先度: P2
- 対象スナップショット: `eb0ab2cd68ee3c3c9882b816cb707c70b7226ea1`
- 対象: `backend/app/domain/business/food/dish/usecase/dish_searcher.rb:32`
- 観点: 検索の正確性
- 由来: 全体レビュー・既存。既存未対応指摘とは原因・修正を分離。
- 採否: 採用
- 対応状況: 再適用・検証完了
- 適用枠: 挙動変更が必要
- 依存する指摘: なし

## 問題と根拠

料理名・出典に検索語がなく、タグalphaとbetaを別々に持つ料理を「alpha beta」で検索すると結果に含まれない。単一のdish_tags JOIN行へ各語の条件をANDで追加するため、一行で両語を満たすことを要求してしまう。通常の複数語検索で正しい候補が欠落するためP2。FR-007の所有者制御、FR-016のdebounceとは独立。

## 改善案

語ごとに料理へ相関したタグのEXISTSを作り、各語が料理名・出典名・いずれかのタグに一致する条件をANDで結ぶ。

## 振る舞いへの影響

記載した不具合時の検索結果・保存値・拒否条件が変わる。修正の適用は今回のレビュー依頼に含めない。

## 検証方法・証拠

SEARCH_BOTH_TAGS=false。Docker内のRails runnerで実測。異なるタグ、同一タグ、料理名とタグに分散した語を回帰テストへ追加する。

実測3件の共通再現コードは[probes.rb](../evidence/probes.rb)、出力は[probes.log](../evidence/probes.log)。

## 旧適用記録（現在の合意として扱わない）

- 合意した指示と対象範囲: 初回レビュー後の全review指摘反映・継続指示により本指摘を採用。
- 修正内容・判断理由: 後述の適用結果とdesign.mdを参照。
- 実行した検証と結果: 初回の問題再現は上記、今回の修正検証は後述の適用結果を参照。
- 適用コミット: `ddfef5a`

## 適用結果（2026-11-02）

語ごとのタグ条件を料理へ相関するEXISTSへ変更した。1語内は料理名/出典/任意タグのOR、語間はANDとし、bind変数、検索前正規化、本人scope、先頭固定、位置づけ/食事有無、distinct/並び順を保持する。別料理のタグを組み合わせて一致させない。

別タグ・同タグ・料理名/出典とタグの分散、一語不足、別料理分散、他人の一致を7件追加した。日本語の未正規化fixtureを切り分けた最終再現では、別タグの1件だけred。修正後は検索34件とGraphQL2件の36 examples / 0 failures、変更2ファイルRuboCop・diff check成功。commitはapplication.mdとGit履歴で追跡する。

## 適用取消と旧挙動の復元（2026-11-04）

全指摘反映が挙動維持制約を解除したという旧記録はassistantの誤判断である。
別タグにまたがる単語検索の結果を変える相関EXISTSを元に戻し、追加した検索期待も除いた。
[復元結果](../../20261027-full-repository-review/evidence/scope-repair/cr001-attempt-1/result.md)は
RSpec36 examples / 0 failures、RuboCop2 files / 0 offenses、ddfef5a親版とのbyte一致、FR-007残部と利用者変更保持、diff checkが成功した。
元の検索不具合の指摘と過去の実測は保存する。今回の復元は検索不具合の解消を意味しない。

## 再適用（2026-11-06）

料理単位で複数タグにまたがるAND検索を行う。別料理・他人のタグを組み合わせずFR-007を保持。RSpec 43 examples / 0 failures、2 file RuboCop 0 offenses。検証はfull-repository-reviewの `evidence/scope-repair/cr001-retain-attempt-1/result.md` に記録。
