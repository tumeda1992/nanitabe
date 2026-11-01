# CR-002: 既存タグID付きの内容変更を成功扱いで破棄する

- 優先度: P2
- 対象スナップショット: `eb0ab2cd68ee3c3c9882b816cb707c70b7226ea1`
- 対象: `backend/app/models/dish_tag.rb:40`
- 観点: 保存契約
- 由来: 全体レビュー・既存。既存未対応指摘とは原因・修正を分離。
- 採否: 採用（全review指摘反映の後続指示）
- 対応状況: 適用・関連/全体自動検証完了
- 適用枠: 挙動変更が必要
- 依存する指摘: なし

## 問題と根拠

updateDishのdishTagsはidとcontentを受け取り、Rootも変更後contentを保持する。しかしreplace_tags_of_dishはID配列が同じなら早期returnし、異なる場合も新規タグだけを保存する。既存タグのcontentを変更してもDBは旧値のまま。現行UIは既存タグをhiddenで送るため、通常画面からの編集ではなく公開GraphQL入力と永続化の契約不一致。FR-004の認可とは別のP2。

## 改善案

既存IDの所有と所属を確認したうえで内容と正規化値を更新する。既存内容を不変とする仕様なら、変更入力を明示的に拒否してAPI契約と揃える。

## 振る舞いへの影響

記載した不具合時の検索結果・保存値・拒否条件が変わる。修正の適用は今回のレビュー依頼に含めない。

## 検証方法・証拠

UPDATED_TAG=alpha。変更後Rootを渡しても旧値が残ることをDocker内で実測。API経由の成功応答と再取得値も回帰テストで確認する。

実測3件の共通再現コードは[probes.rb](../evidence/probes.rb)、出力は[probes.log](../evidence/probes.log)。

## 合意・適用記録

- 合意した指示と対象範囲: レビューのみ。新規指摘の適用は未合意。
- 修正内容・判断理由: 未適用
- 実行した検証と結果: 上記参照。問題再現であり修正成功ではない。
- 適用コミット: 未適用

## 適用結果（2026-11-02）

タグID配列一致の早期returnを除去し、既存content/normalized_contentも保存する。全入力の所有・料理所属・必須値を先に確認し、他人/別料理/不在IDは副作用前に拒否する。直接persistもid/dish_id/user_idを限定する。新規IDのRootへの設定と置換後Relation返却を維持した。

タグ置換と料理・出典関連・タグの全保存をtransactionへまとめた。既存の辞書反映が別Rootで保存した最新タグを古い料理Rootで上書きする依存を関連テストが検出したため、料理Root自身のタグを再正規化して一度に保存するよう適応した。ログ/例外/全件原子性は維持する。[移行台帳](../evidence/cr002-reflection-migration.md)を参照。

新規model9件はすべてred。実GraphQL再取得1件も、検索fixtureの既存Bullet条件を揃えた後に旧content保持をred確認した。修正後は新規10件を含む関連204 examples、backend全体902 examplesが全成功。既存の60 query未満の性能基準と変更5ファイルRuboCopも成功。commitはapplication.mdとGit履歴で追跡する。
