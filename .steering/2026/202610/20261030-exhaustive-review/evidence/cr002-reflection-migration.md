# CR-002 辞書反映callerの適応台帳

baselineは`ddfef5a`。既存タグを保存するCR-002修正により、辞書反映が別Rootで保存した最新タグを古いdish_root.tagsで上書きする依存が表面化した。失敗実装を正本にせず、baselineのReflectLatestNormalizeWordCommandを再読した。移行方向は同Commandの別タグRoot/先行保存から、同じ料理Rootのタグを更新してDish集約の保存へ委ねる形。既存の辞書反映結果・原子性・ログ・エラーを維持する適応である。

| baseline sourceの連続範囲 | destination / 分類 |
| --- | --- |
| reflect_latest_normalize_word_command.rb 1–9 | transaction・全料理ID・ループ/初期化をKEEP |
| 同10–14 | 料理Root構築・表示名・開始ログをKEEP |
| 同15–19 | 同じdish_root.tagsを再正規化し、保存をDish.persistへMOVE。別Rootの再取得を集約内Root参照へADAPT |
| 同20–28 | 名前再正規化・集約保存・完了ログ・例外wrapをKEEP |
| 同29–34 | log_prefixとmodule境界をKEEP |

sourceはbackend/app/domain/business/food/dish/word/usecase/基準。consumerはWord Add/Update/Remove、管理CRUD、Normalizer反映・全件atomicityのspec。Dish/Tagの保存境界はCR-002の新しい原子性を担う。

| contract | 分類 / destination |
| --- | --- |
| W01 全料理を元のID順に処理し、1つのtransactionへまとめる | KEEP / 同Command |
| W02 各料理の全タグを最新辞書で再正規化し、ID/原文を保持する | ADAPT / dish_root.tags |
| W03 各料理名を再正規化する | KEEP / 同Command |
| W04 正規化したタグと料理を保存する | MOVE / Dish.persist内のタグ保存 |
| W05 開始/完了ログと番号・件数・ID/料理名を維持する | KEEP / 同Command |
| W06 失敗をReflectLatestNormalizeWordErrorへwrapし全件rollbackする | KEEP / 同Commandと既存transaction |
| W07 既存の5料理処理が60 query未満という性能基準 | KEEP / 追加再読を空タグ時に省く |

適応前に固定した台帳。順逆照合と再検証結果を後に追記する。

## 適応後の照合（2026-11-02）

全5構造範囲を通読し、別タグRootの再取得/先行保存の削除をW02/W04へ逆引きした。dish_root.tagsを再正規化した後、既存の名前再正規化とDish保存を呼ぶ。最新値を持つ同じRootを保存へ渡すため、古いnormalized値を後から上書きしない。再正規化の内容/処理対象/ログ/例外/全件transactionは元ownerに残し、保存だけを集約の新しい原子境界へ移した。

集計: 適合7（KEEP5/ADAPT1/MOVE1） / 合意済み追加0 / 合意済み変更0 / 明示廃止0 / 未監査0 / 未分類削除0 / 未分類追加0。

既存の辞書反映6件とquery数1件が初回CR-002実装で失敗し、この依存を検出した。適応後は新規タグ10件、料理・タグ・GraphQL・辞書を含む204 examples / 0 failures、変更5ファイルRuboCop成功。5料理処理の60 query未満という既存基準も成功した。backend全体回帰も902 examples / 0 failures。

## 再適用（2026-11-06）

FR-024の辞書更新transactionを保持し、同じdish_rootのtagsを再正規化して保存する。旧時点の検証記録は履歴であり、今回の再実測はfull-repository-reviewのscope-repair結果に記録する。
