# 保留メモ: design の合意依頼に「議論していない帰結」を添えない

## 保留時の内容

**提案:** plugin の `task-design/SKILL.md` の「Step 4. design合意判定」の確認項目に、次を追加する。

```markdown
- **議論していない帰結を残さない**: design の要点を示すとき、「議論では明示していなかった帰結」
  「特に見てほしい点」として示したくなる事項は、未解消の設計判断である。示す前に Step 3 へ戻り、
  提案として議論する。
    - やってしまいがちな失敗: 決定から導いた帰結を design に書き、合意依頼の文面で注意点として添える
    - 判断基準: その帰結について、利用者の言葉で合意を引用できるか
```

**具体例:** 適用経路を「prod と review の apply は CI だけ」とする原則を合意した後、その帰結として「review 環境の定義を agent が試すにも main への merge が要る」ことを design に書き、合意依頼の文面で「特に見てほしい点（議論では明示していなかった帰結）」として添えた。利用者から「帰結があるなら議論は尽くせていない。提案して」と指摘され、議論の結果、review だけ作業 branch から手動起動で apply できる経路を持つ形に設計が変わった。

**根拠:** 決定から導いた帰結は、決定の時点で相手が見ていなかった判断を含む。合意依頼に添える形にすると、design 全体への「ok」に紛れて、その帰結への合意が引用できないまま確定する。Step 4 の既存の確認（TBD の解消、新たな論点が生まれない）は、帰結が design 本文に確定事項として書かれていると通過してしまう。

**出典:**

- 発生元の議論: [task-design-discussion.md 論点11](../task-design-discussion.md#論点11-review-環境の-terraform-を、agent-が-main-への-merge-を経ずに適用できるようにするか)。利用者の原文「いや、「 特に見てほしい点(議論では明示していなかった帰結)」があるなら、まだ議論は尽くせてないやろ。そこも提案して」
- 修正案への合意と保留指示: steering の Step 4 で修正案と「plugin repository は別の作業中なので、前回と同じく保留メモにする」を提示した後の会話上の応答「ok」

**対象:** この改善提案一件。

**再開条件:** plugin repository の進行中の作業（branch `20261018-escalate-pending-plugin-improvements` とその未 commit の変更）が片付き、新しい branch を切れる状態になったこと。親 steering の保留メモ `../../20261024-host-production-on-aws-amplify/pending-escalations/001-compare-staging-before-splitting-scope.md` と同じ条件である。

## 追跡

状態: 保留。再開条件の成立証拠は未取得、引渡しは未実施。転送先は未作成。
