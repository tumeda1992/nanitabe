# CR-003: 出典の種別変更が関連料理の詳細情報を不整合にする

- 優先度: P2
- 対象スナップショット: `eb0ab2cd68ee3c3c9882b816cb707c70b7226ea1`
- 対象: `backend/app/domain/business/food/dish/source/usecase/update_command.rb:29`
- 観点: データ整合性
- 由来: 全体レビュー・既存。既存未対応指摘とは原因・修正を分離。
- 採否: 採用（全review指摘反映の後続指示）
- 対応状況: 適用・関連自動検証完了
- 適用枠: 挙動変更が必要
- 依存する指摘: なし

## 問題と根拠

ページ42を持つ料理の出典を本からWebへ変更すると、出典typeだけが更新され、関連テーブルのrecipe_book_pageは42のまま残る。Dish.build_existing_root_from_idは新typeに従いrecipe_website_urlを読むため詳細がnilになる。その料理を後から保存すると新type用set_valueが旧ページ列を消す。出典の編集操作が既存料理の詳細の不可視化・消失につながるP2。既存の所有者指摘とは独立。

## 改善案

関連料理がある種別変更を拒否するか、詳細の移行・破棄を明示合意する操作として設計し、関連料理を同一transactionで整合させる。暗黙の破棄を避ける。

## 振る舞いへの影響

記載した不具合時の検索結果・保存値・拒否条件が変わる。修正の適用は今回のレビュー依頼に含めない。

## 検証方法・証拠

SOURCE_LOCATOR=nil; STORED_PAGE=42をDocker内で実測。変更前後の詳細、料理の再保存、種別を戻す場合、複数料理のrollbackを確認する。

実測3件の共通再現コードは[probes.rb](../evidence/probes.rb)、出力は[probes.log](../evidence/probes.log)。

## 合意・適用記録

- 合意した指示と対象範囲: レビューのみ。新規指摘の適用は未合意。
- 修正内容・判断理由: 未適用
- 実行した検証と結果: 上記参照。問題再現であり修正成功ではない。
- 適用コミット: 未適用

## 適用結果（2026-11-02）

純粋なTypeChangePolicyへ同種/関連なしの許可判定を置き、DishSource更新validationを共通の保存境界にした。関連料理が存在する異種変更はtypeエラー付きRecordInvalidで拒否する。GraphQLは旧Commandで先に保存するため、food Commandだけの検査では迂回されることを現物確認し、二重呼出を残したまま両方を覆った。

model・legacy・現行・実HTTP GraphQLで同じ5シナリオを検証した。ページ42/64を持つ複数料理でtypeと同時rename/commentの全不変、拒否後の元type更新/再取得/料理再保存、同種rename、未関連type変更、YouTube→Web拒否を含む。修正前20件中12件red。修正後は純粋Policy5件と既存の出典/認可を含む158 examples / 0 failures、変更4ファイルRuboCop成功。実GraphQLの拒否は既存のHTTP 422応答として確認した。

本検証は既に関連料理が存在する場合の保存契約を対象とする。並行して新しい関連を追加する操作との競合や、古いLocatorを保持する外部callerまでの完全保証は行っていない。commitはapplication.mdとGit履歴で追跡する。

### 全体回帰での旧spec契約更新

最初のbackend全体936件で、旧Repository specの「関連済み出典を別typeへ変えてから詳細を上書きする」成功期待が1件だけ失敗した。この操作は合意済みCR-003の拒否対象なので、拒否とsource/関連全属性不変を確認するspecへ更新した。既存Repositoryの詳細列更新能力は、最初からYouTube型のsourceへ紐づく旧データの古いbook列をURLへ置き換える別ケースで保持した。validationを迂回して元の成功期待を通す変更はしていない。両者と4経路の関連26 examples / 0 failures、変更specのRuboCop成功。補完commitはapplication.mdとGit履歴で追跡する。
