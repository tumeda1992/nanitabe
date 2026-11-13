# 内部検討記録: 論点6 — デザイン意図の正本をどこに置くか

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点6

## 開始context

論点1から論点4で、週カレンダーのデザイン意図が揃った。
本人は残し方についても検討を求め、「今までうまく表現できてたら既存通りでいいけど」と述べた。

この論点で決めるのは、意図の正本の置き場所と書く内容である。
Claude Design の Design System を作るかは決めない。

<a id="iteration-0"></a>

## イテレーション0: 既存の残し方はうまくいっているか

<a id="iteration-0-record-1"></a>

### 調査: 画面やデザインの知識は、これまでどこにどう残されてきたか

#### 問い・探索範囲・方法

既存の型で足りるなら新しい場所を作らない。
`git ls-files` で `frontend` の README と backend の domain の README を列挙し、次を読んだ。

- `frontend/src/components/calendar/README.md` の全文
- `frontend/src/components/ui/README.md` の全文
- `frontend/src/components/dish/DishSearchCard/README.md`、`AssignDish/README.md` の冒頭
- `frontend/README.md` の見出し
- `frontend/docs/ai_guideline/` の README と development_standard（前の調査で読了）
- `.kiro/steering/product.md`（前の調査で読了）

#### 見つかった事実

- 画面に関する判断は module の README に置かれている。`calendar/README.md` の「変更ガイド」は、操作モードの UI を底部固定バーにする方針を理由付きで持つ。
- 書き方は MUST、SHOULD、理由、やってしまいがちな失敗で揃っている。
- `docs/ai_guideline` は開発の標準であり、画面の意図はない。
- 土曜始まりの理由、レシピ元の役割、操作欄の由来は、読んだ範囲のどの文書にもない。
- `calendar/README.md` は名前が古い。見出しが `components/calender` で、「MUST: ディレクトリ名・コンポーネント名は "calender"（スペルミス）で統一する」とあるが、実際のディレクトリは `calendar` である。`MealIcon/index.tsx` や `FloatModal` の記述も、現状のコードと合っているかは確かめていない。

#### 言える範囲

型は機能しており、欠けているのは中身である。
一方で README の鮮度は保たれておらず、更新の機会を作らないと同じように古くなる。

<a id="iteration-0-record-2"></a>

### 判断: 置き場所と書く内容

#### 判断対象・必須条件・根拠

必須条件は、カレンダーを変える人が変更前に読むこと、コード変更と一緒に更新できること、この repository が public であることへの適合である。
根拠は上の調査と、`doc-enricher` の基準である。

検討した案は三つである。

- a: `calendar/README.md` へ節を足す。
- b: Design System artifact の README を正本にする。
- c: `frontend/docs/` へ新しい文書を作る。

#### 当てた結果

a を推す。決め手は、既存の型と読者の導線をそのまま使えることである。

抽象度を上げられるかを問うと、原則そのものは他の画面にも当てはまりそうだが、本人の発言は全てカレンダーの場面についてである。
他の画面で成り立つ根拠がないため、カレンダーで止めた。

b は正本にしないが、`from-code.md` の手順は repository の docs から README を作るため、a と両立する。
作るかどうかは別の問いとして残した。

#### 書く内容の絞り込み

`doc-enricher` の Gate A から G へ当てた。

- 残す: 原則、場面の表、MUST と SHOULD、やってしまいがちな失敗。いずれも半年後も正しい見込みが高く、コードからは読めない。
- 落とす: 濃い枠線などの「意図ではないもの」。適用後は見えなくなり、Gate A を満たさない。
- 落とす: `…` の大きさなどの実装の値。コードを読めば分かり、Gate C を満たさない。
- 落とす: A/B/C の比較の経緯。この steering が持つ。

SHOULD にした自動スクロールは、論点4の暫定の判断であるため、見直す条件を文に残した。

#### 確認していないこと

README の他の記述の正しさは通読していない。
節を足した時に、同じ README の「変更ガイド」と矛盾しないかは、反映の時に確かめる。
