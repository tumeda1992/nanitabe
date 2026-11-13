# 内部検討記録: 論点14 — Claude Design がある中で、デザインをどう管理するか

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点14

## 開始context

論点13で Design System を作る段階を問うたところ、本人から、これは運用方針の問いであるとの指摘を受けた。
本人は、Claude で継続的に保守しない場合でも他のデザイン管理の仕組みで通用する管理をしたいと述べた。
Design System が Claude の作業場という意味なら、そこへ残すことは任せるとも述べた。

この論点で決めるのは、デザインの正本と Claude Design の関係である。

<a id="iteration-0"></a>

## イテレーション0: Design System の運用の実態

<a id="iteration-0-record-1"></a>

### 調査: Design System は Claude の作業でどう使われるか

#### 問い・探索範囲・方法

既に読んだ Design type の instructions（Creating の step 1、4）、Design System type の instructions、`from-code.md`、`DesignSync` tool の説明を見直した。

#### 見つかった事実

- Design type の Creating の step 1: 既定の system は依頼の内容にかかわらず使う。既定がなく候補があれば本人へ聞く。空ならキャンバス独自の見た目にする。
- 使う時は `project/README.md` と `project/tokens.json` を読む。
- Creating の step 4: `tokens.json` をキャンバスの `project/ds/<folder>/` へ写し、`designSystems` へ記録する。
- Design System type: `tokens.json` は一覧の形でなければならず、DTCG / W3C の名前と値の map 形式はページで読めない。
- `from-code.md`: CSS custom properties や Tailwind v4 の `@theme` から `tokens.json` を作る。再同期は既存の内容と統合し、ページ上の編集を残す。
- `DesignSync` の説明: 単独の Claude Design は 2026-12-14 までに閉じ、Claude の中へ移る。

#### 範囲内で見つからなかったこと

読んだ資料の範囲に、コードを変える通常の作業で Design System を読む手順はなかった。
これは Design type の手順に書かれていないという意味であり、Claude が読めないという意味ではない。

#### 言える範囲と限界

資料の記述であり、実際に Design System を作って動きを確かめてはいない。
他のツールの形式への変換の手間は調べていない。

<a id="iteration-0-record-2"></a>

### 判断: 管理の方針

#### 判断対象・必須条件・根拠

必須条件は本人の言葉から取った。

- Claude で継続的に保守しなくても通用すること
- 他のデザイン管理の仕組みへ載せられること
- こだわりのない所へ保守の手間をかけないこと（論点8）

検討した案は二つである。

- a: 正本はリポジトリの CSS 変数、コード、Markdown。Claude Design は作業場。
- b: W3C 形式のトークンのファイルを正本にして、CSS と Claude Design の形式へ変換する。

#### 当てた結果

a を推す。決め手は、既にある形のままで必須条件を満たし、新しい保守が要らないことである。

b は移行の手間を前払いする形であり、移る予定がない今は変換の仕組みの保守だけが残る。
これは今の条件での判断であり、他のツールへ移ることが決まった時に、変換の仕方を改めて検討する。

Claude Design を正本にする案は、本人の必須条件に反するため候補にしていない。
