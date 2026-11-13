# 内部検討記録: 論点13 — Claude Design の Design System を作るか

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点13

## 開始context

論点6で、Design System は正本にしないと決め、作るかは別の問いとして残した。
本人はポテンシャルを知るために一気通貫したいと述べ、こだわりのない所へ保守の手間をかけたくないとも述べている。

<a id="iteration-0"></a>

## イテレーション0: 試す価値と手間

<a id="iteration-0-record-1"></a>

### 判断: Design System を作るか

#### 判断対象・必須条件・根拠

根拠は Design System type の instructions と `from-code.md`、`DesignSync` tool の説明である。

- a: コードへの適用の後に一度だけ作って試し、維持はしない。
- b: 今回は作らない。

#### 当てた結果

a を推す。決め手は、作業の目的がポテンシャルを知ることであり、この機能は資料の記述でしか確かめていないことである。

維持をしなければ repository の保守の手間は増えない。
ただしコードと同期しないため、時間が経つと古くなる。
今の `globals.css` のトークンは shadcn/ui の既定と昼夜朝の色が中心で、内容は多くない。
価値は配色より、次のキャンバスへ意図が読まれるかを確かめることにある。

#### 確認していないこと

`from-code.md` の手順は実行していない。
既定に設定した時に次のキャンバスで実際に読まれるかは、資料の記述のみである。

<a id="iteration-1"></a>

## イテレーション1: 作る範囲の段階

本人から「デザインシステムを作るもグラデーションがある」「塩梅による」との指摘を受けた。
提案0は一つの範囲だけを示しており、比較の材料になっていなかった。

<a id="iteration-1-record-1"></a>

### 調査: 段階ごとに何が必要か

#### 問い・探索範囲・方法

Design System type の instructions と `from-code.md` から、作れるものの段階を読み取った。
実際の部品を束ねられるかを、`MealCard/index.tsx`、`DateCard.tsx`、`frontend/src/components/ui/README.md` で確かめた。

#### 見つかった事実

- 資料には、トークンと README だけの小さな system、部品の README と静的なプレビュー、実際の部品を束ねた `components/bundle.js` の三つの形がある。
- `bundle.js` は `window.React` を読む一つの script であり、部品のデータ取得は含められない。
- `MealCard` は `useMeal`、`useMealFrame`、`usePostponedMeal` を内部で呼ぶ。`DateCard` は `AddMealTabs` を持つ。
- `components/ui/` には `button`、`input`、`dropdown-menu`、`drawer` がある。

#### 言える範囲と限界

週カレンダーの部品をそのまま束ねることはできず、表示部分の切り出しが先に要る。
切り出しの規模は見積もっていない。

<a id="iteration-1-record-2"></a>

### 判断: どの段階を推すか

段階1を推す。決め手は、配色と意図の読み込みという効果の大半を、最小の手間で確かめられることである。
段階2は手書きのプレビューが増え、本人の保守の見方に合わない。
段階3は今回の適用を超える改修が要る。

コード側の部品化は別の話であり、この論点へ混ぜない。
本人の「今の部品をすべて部品化」がコード側も指していた可能性はあるが、確かめていない。

<a id="iteration-2"></a>

## イテレーション2: 語の区別

本人から、語の意味、最小と最大、置き場所、保守を問われた。
Claude Design の Design System とコードの共通部品を区別せずに問うていたため、二つへ分けて示した。
新しい調査はなく、イテレーション1の事実を使った。

<a id="iteration-3"></a>

## イテレーション3: 作業場に何を入れるか

論点14で、正本はリポジトリ、Claude Design は作業場と決まった。
本人は「Claudeに何を残すか自体は議論する」と述べた。

<a id="iteration-3-record-1"></a>

### 判断: 作業場の内容

#### 判断対象・必須条件・根拠

基準は、消えても失うものがなく、次のキャンバスの質が上がることである。
根拠は Design System type の instructions（`README.md` は必須、`components/Cover/preview.html` は全ての system に置く）と、論点13のイテレーション1の調査である。

#### 当てた結果

トークン、README（意図の写し、部品の呼び名、注記）、表紙を入れる案を作った。
部品のプレビューと `bundle.js`、経緯、実データ、未決の事項は入れない。

意図を写すか path だけにするかは二重管理の問題であり、本人へ判断を求める点として明示した。
写す案を推すのは、キャンバスを作る場でリポジトリを読めるとは限らないためである。
これは私の見立てであり、本人がどの場でキャンバスを作るかは聞いていない。
