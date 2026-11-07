# 内部検討記録: 論点4 — 原子的な辞書反映specを操作ごとに整理する

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点4

## 開始context

利用者の「3:直して」は親Solの辞書反映spec構造改善案への実行指示として引き継いだ。
baseline `94623f6`のatomic_reflection_specと4つのproduction Commandを本担当が通読した。
指示と調査の事後記録であり、test実行結果を記録したものではない。

<a id="iteration-1"></a>

## イテレーション1: 固有操作と共通rollback検証を分ける

<a id="iteration-1-record-1"></a>

### 判断: 共通fixtureを複製せず4操作を独立して読める形にする

現行specはoperation symbolのeach、辞書準備のunless、実行caseを一つのexampleへ集め、
先行料理/タグの実保存観測を配列位置で判定している。4操作の例外type/messageと全attributes rollbackは有効な期待であり保持する。
各Commandの具体describeには辞書の有無/初期値・引数・subjectだけを置く。
本担当の当初案では各describeへ共通fixture/失敗注入も置く記述があったため、親Solが重複を避けるよう訂正した。
採用する完成形は共通shared_contextに2料理/タグ・後半失敗注入・snapshotを一定義とし、shared_examplesへ共通期待をまとめる。
各操作の辞書と共通fixtureを生成した後、実行前snapshotを固定する。
観測値は名前付きhash、rollbackは辞書/料理/タグごとのaggregate_failuresで識別可能にする。
共通側のoperation条件分岐やsubject切替をなくし、操作固有事情をdescribeへ足せば済む形にする。
production4Command/transactionは変更せず、4例の先行実保存確認と後半失敗後rollbackを新sourceで再検証する。
