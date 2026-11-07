# 内部検討記録: 論点3 — 旧枠エントリdomainを削除する

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点3

## 開始context

利用者はPR指摘への回答として「1:ok。2:いらない方消して。3:直して」と実行を指示した。
親Solの説明との対応は、1が評価Commandの認可guard維持、2が旧枠エントリdomain削除、3が辞書反映spec整理である。
これは引継いだ指示・調査と本担当の照合を事後記録したもの。baselineは`94623f6`。

<a id="iteration-1"></a>

## イテレーション1: 旧互換専用contractと現行の有効coverageを分ける

<a id="iteration-1-record-1"></a>

### 判断: 削除許可に従い現行domainだけへ集約する

旧production4fileと旧5spec、現行4spec、現行Root/Add/Removeを通読した。
appの完全修飾旧domain参照は旧4file自身のみ。GraphQL/ActiveRecordのFrameEntry名は別の公開名である。
旧Add4例/Fill2例/Remove3例は現行と重複し、旧pathのUnassign3例は既に現行Commandをdescribeしている。
Unassignを現行pathへ移し、require_relativeの深さを1つ増やす。
compatibility specの旧class identityとunassign非公開だけをRETIREし、Root属性/型変換/必須4属性/assign/set_id、
Addの単一保存/保存属性/private constructor、Removeの他人拒否を現行へMOVE/KEEPする。
現行ownership5例は保持する。この分類はTerra retained_auditの独立した全文照合でも一致した。
旧sourceと全contractの対応は実装編集前に既存FR-034台帳へ新時点として残し、過去の互換維持を上書きしない。
外部script不存在は未確認だが、今回は利用者が削除を明示したことを採否根拠にし、追加確認gateにしない。
本担当はapplication/testを変更せず、検証はexecutorへ渡す。
