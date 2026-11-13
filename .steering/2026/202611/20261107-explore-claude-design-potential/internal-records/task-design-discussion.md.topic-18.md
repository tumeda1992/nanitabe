# 内部検討記録: 論点18 — 別のセッションから Design System をどう辿らせるか

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点18

## 開始context

本人から、今回作った Design System などの artifact が、別のセッションで `/design` を使った時に自然と参照されるかを問われた。
私は、一覧には出るが既定の印がなく、`ui_design_management.md` に題名で探すと書いた、と答えた。
これに本人から、作りっぱなしでは困るため、デザインのナレッジのところに URL などを書くべきだと指摘された。

開始時の既決条件は次のとおりである。

- 論点15: 管理方針は `ui_design_management.md` に置き、`development_standard/README.md` から `@` で参照する。提案0では「artifact の URL は public な repository へ書かず、題名で示す」とした。
- 論点13: Design System には、公開できない実データの料理名を入れない。
- `design.md`: 既定の Design System への設定は本人が行う。
- この repository は public である。

決める範囲は、別のセッションが Design System へ辿り着く入口を、repository の文書にどう置くかである。

<a id="iteration-0"></a>

## イテレーション0: 入口の不足と、URL を書いてよいか

<a id="iteration-0-record-1"></a>

### 診断: 今の文書では Design System が使われない

#### 期待との差と原因候補

期待は、別のセッションが Claude Design で画面を作る時に、この Design System を使うことである。
今の `ui_design_management.md` の該当行は「Design System に何を置くかは、その README に従う。claude.ai 上で「なにたべ Design System」という題名で探す。URL は public なこのリポジトリへ書かない。」である。

#### 原因

- 使う場面が書かれていない。この行は、Design System に何を置くかと、どう探すかだけを述べている。読んでも、Claude Design で画面を作る時にこれを使えとは読めない。
- 題名だけでは一意に決まらない。題名は変えられ、同じ題名の artifact も作れる。人がこの文書から開くこともできない。

どちらも今回の文書だけの不足である。

#### 文書が読まれる範囲

`frontend/CLAUDE.md` → `docs/ai_guideline/README.md` → `development_standard/README.md` → `ui_design_management.md` と `@` で辿られることを、この session の読み込み内容で確かめた。
Claude Code は、下位の directory の `CLAUDE.md` を、その directory のファイルを読んだ時に読み込む。
repository の root で始めたセッションでは、frontend のファイルを読むまでこの文書は読み込まれない。
`/design` が Design System を選ぶ時点で読み込まれているとは限らない。

論点14で読んだ Design type の資料では、既定の Design System は必ず使い、既定がなければ使うかを本人へ聞く。
`/design` で確実に使わせる手段は、claude.ai での既定の設定である。
前回 `list_artifacts` で確かめた時点では、既定の印はなかった。

<a id="iteration-0-record-2"></a>

### 判断: Design System の URL を public な repository へ書いてよいか

#### 判断対象・必須条件・根拠

書いてよいと判断した。決め手は、URL を読んだ人が新しくできるようになることが実質ないことである。

必須条件は `confidentiality.md` の判定を通ることである。
論点15の提案0で URL を書かないとしたのは、artifact の URL を識別子として一律に扱ったためであり、第1段（公開された時に、読んだ人が何をできるようになるか）を当てていなかった。
今回、第1段から当て直した。
根拠は `get_artifact` の結果（`read` が `owner`、URL の形）と、論点13の決定である。

#### 当てた結果

- この artifact は private（`read: owner`）であり、開けるのは本人だけである。URL を読んだ人は開けない。
- URL は `https://claude.ai/artifact/` と artifact ごとの ID から成り、本人を示す情報を含まない。
- 本人が後で、リンクを知る人へ共有を広げると、誰でも開けるようになる。その場合も中身は、`globals.css` から写したトークン、public な README から写した画面の意図、Design System 自身の説明である。このリポジトリで既に公開されているものの写しであり、新しく知られることは実質ない。
- この前提は、公開できないものを Design System へ置かないことに依る。論点13の決定で、実データの料理名は「入れない」に既にある。

第1段で落ちるため、第2段（識別子の実値を書かない）へは進まない。

キャンバスの URL は対象にしない。
キャンバスは議論ごとの作業場であり、次のセッションが辿る必要がないためである。
中身も Design System より広く、同じ判定を当てていない。

#### 案への影響

`ui_design_management.md` の該当行を、使う場面と URL を持つ行へ置き換える。
`design.md` の「リスクと対策」で、記録へ書かない識別子を「Design System 以外の artifact の URL」へ狭める。
URL の実値は、合意の前には議論ファイルにも書かない。

<a id="iteration-0-record-3"></a>

### 判断: 決定の反映後に、repository の文書へ残す知識があるか

#### 判断対象・必須条件・根拠

本人の受諾（「ok」）を受け、`ui_design_management.md` の該当行と `design.md` の「リスクと対策」へ反映した後、doc-enricher の提案 mode の手順と Gate A〜G を当てた。
doc-enricher の skill は改めて起動しておらず、この session で読んだ手順を私が当てた。

候補は、URL を書かないとした誤りの原因である「`confidentiality.md` の第1段を当てずに、識別子として一律に扱った」を、同標準の失敗例として足すことである。

#### 当てた結果

候補なしとした。

- Gate G（既存文書との非重複）で落ちる。`confidentiality.md` は「第 2 段だけを先に当てると、第 1 段で落ちるはずの識別子まで変数化することになる」と、同じ失敗を既に書いている。今回の誤りは標準の不足ではなく、標準の順序を守らなかったことである。
- 足す先が plugin の標準であり、このリポジトリからは直接編集しない。同じ種類の例を一つ増やす価値は、その手続きに見合わない。

#### 反映と同時に見つけたこと

反映の確認のため Design System の `project/README.md` を読んだ。
URL を書かない指示は含まれておらず、直す必要はない。

一方で、リポジトリ名を `tumeda1992/nanitabe` と誤記していた。
`git remote -v` の origin は `setsumaru1992/nanitabe` である。
Phase 7 の README 更新の task へ、修正を足した。
