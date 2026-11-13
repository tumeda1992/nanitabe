# 内部検討記録: 論点19 — Design System に何を、どの抽象度で、どこへ置くか

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点19

## 開始context

Phase 7 で「なにたべ Design System」を適用後のコードから写し直し、本人へ結果を見せた。
本人から、overview に具体を書きすぎており、Design System とはそういう存在か、と指摘された。

開始時の既決条件は次のとおりである。

- 論点13: Design System は思考キャッシュであり、トークン、表紙、README を置く。README には存在の説明、置くもの、写した commit と最新化、画面の意図の写し、部品の呼び名を書く。部品のプレビューは置かない。
- 論点14: 正本はリポジトリ。
- 論点17: 全画面や状態ごとの正本の写しを作らない。

決める範囲は、Design System の中のどこへ、どの抽象度で何を置くかである。

<a id="iteration-0"></a>

## イテレーション0: 今の中身の診断と、層の分け方

<a id="iteration-0-record-1"></a>

### 診断: Design System が一画面の仕様の写しになった

#### 期待との差と原因候補

期待は、Design System が画面をまたいで使う層（基礎、部品、原則）を持ち、overview がその入口として抽象的であることである。
実際は、overview にカレンダーの画面の意図の全文、部品の呼び名、カレンダーに限った色の使い方があり、`tokens.json` にカレンダーの部品ごとの寸法（文字14種、間隔9種）がある。

#### 原因

- 元にしたのがカレンダーの一画面だけであり、確定案のボードとコードの値を下から写した。画面をまたぐ層へ上げる段を踏まなかった。
- README とトークンしか作らなかったため、画面ごとの内容も README へ入った。type は `project/` の下の別の `*.md` を section として、`components/<名前>/README.md` を部品の使い方として持てるが、使わなかった。
- type の `SKILL.md` の Checklist は README を、基礎・原則・図像を扱うブランドブックとしている。これを作る時に当てていなかった。
- Phase 7 では、コードと照合する中で部品ごとの寸法をさらに増やした。

部品ごとの寸法の写しは、論点17で作らないと決めた正本の写しと同じ性質を持つ。

論点13は置くものを決めたが、置き場所と抽象度は決めていなかった。
そのため、論点13の再開ではなく、その下位の論点として扱う。

<a id="iteration-0-record-2"></a>

### 判断: 層をどう分けるか

#### 判断対象・必須条件・根拠

overview、トークン、画面ごとの section の三層に分けることを推す。

必須条件は、overview が画面に依存しないこと、トークンが画面をまたいで使える単位であること、論点13の「画面の意図を写す」「部品の呼び名を置く」を保つこと、論点17に反しないことである。
根拠は、type の `SKILL.md` の「What a system holds」と Checklist である。

#### 当てた結果

- overview: これが何か、原則、トークンの使い方、最新化。画面の固有の内容を外す。
- トークン: 色は今も意味の役割で置けており、大きくは変えない。文字、間隔、角丸は、部品ごとの名前をやめ、コードが使う段だけにする。
- 画面ごとの section: カレンダーの部品の呼び名と画面の意図の写し。論点13の決定を保ったまま、overview から外せる。

部品を `components/<名前>/README.md` に置く形も考えた。
プレビューを置かないと決めており（論点13）、プレビューのない部品の項目がページでどう見えるかを確かめていないため、今回は section を推す。

細部（overview に置く原則、段の名前、画面の意図を全文写すか）は、分け方の合意の後に決める。

<a id="iteration-1"></a>

## イテレーション1: 適用と、Design System の範囲

本人は overview とトークンの分け方を受諾して適用を指示し、画面ごとの section は Design System に載せるものかを問うた。

<a id="iteration-1-record-1"></a>

### 判断: 委託された細部をどう決めて適用したか

#### 判断対象・必須条件・根拠

必須条件は、overview が画面に依存しないこと、トークンが画面をまたいで使える単位であること、本人が述べていない原則を一般化して書かないこと、カレンダーの内容を消さないことである。

#### 当てた結果

- overview の原則は「まだない」とし、上げる条件を書いた。
- トークンの使い方には、トークンの意味として画面に依存しないものだけを書いた。
- 文字は Tailwind の段（text-xs、text-sm、text-xl）、間隔は 2・4・6・8px と押せる範囲、角丸は 6px・8px・丸にした。
- カレンダーの内容は `project/calendar.md` へ移し、検討中であることを冒頭に書いた。
- 公開の前に Design System の `design-system.json` を読み直し、`lastChange` だけを変えた。直前の版で、私が公開した `README.md` と `tokens.json` がページに変えられていないことを sha256 と大きさで確かめた。
- キャンバスの `project/ds/nanitabe/tokens.json` を `copy_file` で写し直し、`designSystems` の `version` を `1794577546-ce00` にした。

<a id="iteration-1-record-2"></a>

### 判断: 画面ごとの内容を Design System に置くか

#### 判断対象・必須条件・根拠

置かないことを推す。決め手は、画面ごとの内容は Design System の範囲でなく、このリポジトリでは写しが読まれる経路もないことである。

根拠は次のとおりである。

- キャンバスの type の `SKILL.md`（Creating の手順1）: Design System を使う時は `project/README.md` と `project/tokens.json` を読む。section は手順に含まれない。
- キャンバスは Claude Code から作り、リポジトリを読める。
- 論点17: 写しは作った時点からずれる。

#### 当てた結果

- 画面の意図は写さない。読む手段を `ui_design_management.md` の一行で保つ。
- 部品の呼び名は、この議論で付けた語であり、コードを読んでも分からないため、消さずに画面の README へ移す。
- カレンダーの色の使い方は、コードを読めば分かるため移さない。
- 論点13の決定のうち、画面の意図の写しと部品の呼び名を Design System に置くことを取り消す。

<a id="iteration-1-record-3"></a>

### 判断: 反映の後に、repository の文書へ残す知識がほかにあるか

#### 判断対象・必須条件・根拠

本人の受諾（「ok」）を受け、Design System の README の「置かないもの」を直して `calendar.md` を消し、`frontend/src/components/calendar/README.md` に「部品の呼び名」を足し、`ui_design_management.md` に一行足した。
その後、doc-enricher の提案 mode の手順と Gate A〜G を当てた。doc-enricher の skill は改めて起動していない。

#### 当てた結果

候補なしとした。
Design System の範囲は Design System の README の「何を置くか」と、`ui_design_management.md` の追加した一行が既に持つ（Gate G）。
今回の誤りは、論点13で範囲を決めないまま中身を足したことであり、決めた範囲を書いた今、別の文書へ足すものはない。
