# Design: codegen実行確認と元レビューの記録更新

## 元の依頼内容

> 元リポジトリのメモもコミットしておきたいし、その前に、今の元リポジトリのカレンダー画面への修正ってテスト通ったけど動いてる？動作確認環境に反映してくれない? 本番でAPIがエラー吐いててAPIが正常レスポンスが返っていない「[GraphQL error]: Message: Field 'dishEffortLevelId' doesn't exist on type 'Dish', Location: [object Object], Path: query mealsForCalender,mealsForCalender,meals,dish,dishEffortLevelId」

後続の利用者訂正（2026-11-14）:

> 聞きたいのはテスト通ったけど、graphql変えた後にyarn codegen 実行したかってこと

今回の確定範囲を定めた利用者発話（2026-11-14）:

> 確かに大丈夫だったわ。本番でAPIのサーバ立ち上げ直したら問題なくなってた。元リポジトリのメモもコミットどうする？あと、今回の調査でもpython3 << EOF の書き方、無駄に承認を求めるから、git管理しないところに勝手にスクリプト立ててそれを実行するようにして承認なくてもできるようにAGENTS.local.mdに書いておいて

## TL;DR

通常schemaからのcodegen実行と再生成一致の既存記録を確認し、利用者へ回答した。
利用者がAPI server再起動後の解消を確認したため、今回のreview反映は行わず、元レビューの3メモを実装・導入済みの現状態へ更新する。
`AGENTS.local.md` には、許可済みの複数行PythonをGit管理外の一時fileへ保存して実行する手順と、承認対象を迂回しない境界を追加する。

## 完成後の姿

### codegenの実行を根拠から判断できる

前回レビューの [FR-022記録](../../202610/20261027-full-repository-review/findings/FR-022-new-dish-without-source.md) は、HTTPでのschema取得がmigration検知により止まった後、通常の `BackendSchema.to_json` をoffline出力し、schemaの参照先だけを差し替えた一時configでcodegenしたことを記録している。
[再適用時の検証結果](../../202610/20261027-full-repository-review/evidence/scope-repair/fr022-retain-attempt-1/result.md) は、同方法で再生成したTypeScriptとintrospection JSONが、当時の生成物とそれぞれ完全一致したことを記録している。
これは生成実行の根拠であり、本番backendの配備完了の証明とは区別する。
APIエラー解消は今回の利用者報告として扱い、agentが本番再起動や復旧検証を行ったとは記録しない。

### 元レビューのメモが現在の完了状態を示す

主な読者は、前回レビューの保留改善を追跡する利用者と後続agentである。
3メモの「追跡」に現在状態と引渡し時の履歴を分けて置き、固定された「保留時の内容」、原発言、保留解除指示を保持する。

現在状態の根拠は [plugin PR #14](https://github.com/tumeda1992/ai_agent_dev_skill_plugin/pull/14) のmerge、source commit `b6bae67dabb8d518e8b17131121f80b0a1f1d0cb`、version `8.3.1` の導入確認である。
一時的な完了記録と同commitのsource本文を照合し、PRのmergeも親担当がGitHub上で再確認している。
将来の追跡では、履歴を書き換えず確認日とsourceを新しい状態へ添える。

| メモ | 現在状態から判断できること |
| --- | --- |
| `001-review-behavior-preservation.md` | 正常な認可ユーザーの操作と業務仕様を守り、根拠を示した内部認可・transaction修正を許すことが実装済み |
| `002-model-division.md` | SolとTerraの役割分担は `exhaustive-review` 限定、host非限定であり、全skillへの指定ではない |
| `003-work-without-new-approval.md` | `unattended-execution` は既存の必須承認を維持し、既承認の独立作業だけを自走する |

元メモの更新は同じ前回レビューの追跡情報であるため、既存fileの「追跡」へ統合する。
plugin規則の正本を変更したり、新たな規則を元メモ側で制定したりしない。

### ローカルで複数行Pythonを実行する

`AGENTS.local.md` の既存本文を保持し、「複数行Pythonの実行」を末尾へ追加する。
読者はこのマシンで調査するagentであり、heredocの代わりに `/tmp/` の作業専用directoryへ `.py` fileを作り、絶対pathで実行できる。
例は `python3 /tmp/<作業専用directory>/<目的>.py` とし、別作業のfileを上書きしない。

scriptの内容が既存scope・許可・上位指示・実行環境の権限内かを実行前に判断する。
許可済み処理のfile化に毎回の利用者確認は追加しない。
新規承認が必要な処理や拒否された同等操作は、script化、別tool、別path、保存prefixを使って通さない。
必要な操作とその依存先を保留し、独立した許可済み作業を継続する。上位指示に従う承認要求は維持する。

この方針は既存のマシン専用指示へ配置し、Git管理外の扱いを維持する。
権限や上位指示が変わった時には、その変更に合わせて実行方針も確認する。

## 要件（Requirements）

### MUST（必達）

- 3メモを実装・merge・導入確認済みへ更新し、元の発話と引渡し時の状態を履歴として保持する。
- `002` の適用範囲と `003` の既存必須承認の維持を明記する。
- `AGENTS.local.md` の既存本文とignore状態を保持する。
- script化を承認の迂回に使わず、承認不要の保証も記載しない。
- 公開文書へ秘密、実domain、既存環境の非公開構成を転記しない。
- 元checkoutの利用者変更を保全する。

### 非目標

- 今回は利用者による解消報告を受けて記録保存へ範囲を絞ったため、reviewへの反映と本番操作を行わない。再び反映が依頼された時点で、その時の対象revisionと環境状態から判断する。
- この設計担当は文書反映とvalidationまでを所有する。Git commitは親担当が元checkoutの `feature-287` で行い、3メモと今回作成した月次サマリー・設計記録を保存する。別worktreeでの保存後も元checkoutに差分が残ったという利用者の指摘を受け、保存先を元のブランチへ改めた。`AGENTS.local.md` はコミット対象へ加えない。

### 受け入れ基準

- 3メモからPR、commit、versionと各改善の適用範囲を辿れ、保留時の原文が残る。
- `AGENTS.local.md` に一時file化、絶対path実行、権限照合、迂回禁止、独立作業継続の判断がある。
- `AGENTS.local.md` はignore対象のままで、3メモ以外の追跡fileへ今回の変更がない。
- document-reviewで作成時・更新時の観点を適用し、差分の空白検査に問題がない。

## リスクと対策

| リスク | 対策 |
| --- | --- |
| 引渡し時の未完了記述が現在状態と混同される | 日付付きの現在状態と過去履歴を分ける |
| model役割分担を全skillへ広げる | `exhaustive-review` 限定・host非限定を明記する |
| 一時scriptを承認回避の手段と解釈する | 内容による権限判断と迂回禁止を一緒に記載する |
| ローカル構成が公開記録へ混入する | `AGENTS.local.md` の既存内容を公開成果物へ複製しない |

## テスト方針

applicationコードとruntimeを変更しないため、application testは追加しない。
3メモをsourceと照合し、固定本文保持、ignore、Git差分とdocument-reviewで検証する。

## （付録）前提とする既存仕様

- `escalate-plugin-skill-fix/pending-escalations.md`: 保留時本文は固定し、後発証拠と現在状態を追跡へ記録する。引渡し済みの改善を二重起動しない。
- `unattended-execution`: 必須指示・承認を保持し、広いprefixや別tool・pathによる同等操作の迂回を禁じる。
- `AGENTS.local.md`: マシン専用指示であり、既存の `*.local.md` ignore対象である。
- task-designとdocument-reviewの実行版は `8.3.2`。この作業directoryに有効な暫定指示はない。

## （付録）変更の実行区分

### task-design内で対象成果物へ適用済み

| 対象 | 反映内容 | validation結果 | 参照するdesign section |
| --- | --- | --- | --- |
| 元レビューの3メモ | 現在状態、PR・commit・version、適用範囲を追加し履歴保持 | source照合、固定本文保持、document-review、差分検査成功 | 元レビューのメモが現在の完了状態を示す |
| `AGENTS.local.md` | 許可済みPythonの一時file実行と承認境界を追記 | 既存本文保持、ignore確認、document-review成功 | ローカルで複数行Pythonを実行する |

### task-design内の対象成果物反映待ち

なし。

### execution plan対象

なし。今回担当する文書反映は、利用者の具体指示とsourceから一意に実行でき、一つの連続した反映・validationで完了する。
Git commitは親担当が所有する既承認の後続処理であり、新しいtasklistは作らない。
