# RV-014: 正規化辞書の登録・更新が同じ値変換を重複する

- 観点: 保守性・責務・型
- 優先度: 中
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/domain/business/food/dish/word/usecase/add_command.rb: call; update_command.rb: call
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

双方でsourceをDB辞書適用なしで正規化し、destinationがpresentなら同じ変換、blankならnormalized_sourceを使う。またentered_destinationも同じpresenceルールで保存する。この辞書値の規則は登録・更新で共通なのにコピーされている。

## 改善案

入力source/destinationから保存用4属性を作る副作用のない値変換を同Wordモジュールへ抽出する。レコード作成/更新とReflectLatestNormalizeWordCommandの呼び出しは各Commandに残す。

## 振る舞いを維持する条件

Normalizerの呼び出し回数とuse_db_normalize_word: false、blank判定を維持する。Addのcreateをcreate!へ変更することや全件再正規化の非同期化は混ぜない。

## 検証方法

既存add/update specでdestination省略・空文字・空白・指定あり、ひらがなと全角英数字の保存4属性を比較し、再正規化呼び出しも維持する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
