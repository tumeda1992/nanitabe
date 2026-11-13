# 内部検討記録: 論点16 — 設計で足した見た目を、確定案のボードで確かめる

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点16

## 開始context

`design.md` の review を文章で求めたところ、見た目が分からず判断できないとの指摘を受けた。
Design System がどう残るかも artifact で見えていなかった。

<a id="iteration-0"></a>

## イテレーション0: 確定案と Design System を実物で示す

<a id="iteration-0-record-1"></a>

### 判断: 何を作って見せるか

#### 判断対象・必須条件・根拠

必須条件は、設計で足した七点が画面で見えること、現状と比べられること、Design System の中身が実物で分かることである。

#### 当てた結果

キャンバスに「確定案」の page を足し、現状、週ビュー、操作欄を開いた状態、移動の操作中、月ビューの五つのボードを置いた。
移動の操作中の文言は `MoveMeal/index.tsx` の「移動先の日付を選んでください」に合わせた。

Design System は `create_from_type` で作り、トークン、README、表紙を置いた。
キャンバスの `designSystems` へ記録し、`tokens.json` を `project/ds/nanitabe/` へ写した。

論点13の「適用の後に作る」は、見て判断するために前倒しした。
適用の後に写し直す必要があるため、README に適用前の版であることと、差のある値を注記した。

#### 確認していないこと

ボードと Design System の描画は確認していない。
表紙の見え方も同様である。
