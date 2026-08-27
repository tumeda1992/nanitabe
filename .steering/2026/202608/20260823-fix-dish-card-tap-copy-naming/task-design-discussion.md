# 議論記録

## 論点1: 評価モーダル二度タップの修正範囲

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0: 引き金と機構のどちらを、どこで断つか

#### 提案0

引き金（bubbling）と機構（remount）の両方を断つ。変更は2ファイルで、**呼び出し側5箇所の書き換えは発生しない**。

##### 変更1: `DishCard/index.tsx` — モーダルをクリック領域の外へ出す

3つのモーダルを root `<div>` の子から、Fragment の兄弟へ移す。モーダルは `position: fixed` なので見た目は変わらない。

```diff
   return (
-    <div
-      className={`rounded-lg overflow-hidden border ${cfg.bg} mb-1 cursor-pointer`}
-      data-testid={`dishCard-${meal.id}`}
-      onClick={() => setActionsOpen(true)}
-    >
-      <div className="flex w-full">
-        ...カード本体...
-      </div>
-
-      {/* フルスクリーンモーダル（常時レンダリング、表示制御は内部） */}
-      <EditMealModal.FullScreenModal title="食事修正">...</EditMealModal.FullScreenModal>
-      <EvaluateDishModal.FullScreenModal title="食事評価">...</EvaluateDishModal.FullScreenModal>
-      <EditDishModal.FullScreenModal title="料理修正">...</EditDishModal.FullScreenModal>
-
-      {actionsOpen && (
-        ...アクション展開エリア...
-      )}
-    </div>
+    <>
+      <div
+        className={`rounded-lg overflow-hidden border ${cfg.bg} mb-1 cursor-pointer`}
+        data-testid={`dishCard-${meal.id}`}
+        onClick={() => setActionsOpen(true)}
+      >
+        <div className="flex w-full">
+          ...カード本体...
+        </div>
+
+        {actionsOpen && (
+          ...アクション展開エリア...
+        )}
+      </div>
+
+      {/* クリック領域の外へ置く。モーダル内の操作がカードのonClickへ到達しない */}
+      <EditMealModal.FullScreenModal title="食事修正">...</EditMealModal.FullScreenModal>
+      <EvaluateDishModal.FullScreenModal title="食事評価">...</EvaluateDishModal.FullScreenModal>
+      <EditDishModal.FullScreenModal title="料理修正">...</EditDishModal.FullScreenModal>
+    </>
   );
```

`data-testid` は root `<div>` に付いたまま維持する。

##### 変更2: `useModalTool.ts` — callbackのidentityを安定させる

`onClose` を ref へ退避し、返す関数群を `useCallback([])` にする。

- `onCloseRef` を `useRef` で持ち、毎render `onCloseRef.current = onClose` を代入する
- `openModal` / `closeModal` / `toggleModal` を `useCallback(..., [])` にする。`closeModal` は `onCloseRef.current?.()` を呼ぶ
- `openModalOnClick` / `closeModalOnClick` / `toggleModalOnClick` も `useCallback(..., [])` にする

`onClose` を deps へ入れない。呼び出し側は inline arrow を渡すため毎render identity が変わり、deps に入れると安定化しない。ref 経由で常に最新を読む。

##### 変更3: `useFullScreenModal/index.tsx` — componentのidentityを安定させる

```diff
-  const FullScreenModal = ({ title, children }: {...}) => (
+  const FullScreenModal = React.useCallback(({ title, children }: {...}) => (
     <>
       {modalVisible && (
         ...
       )}
     </>
-  );
+  ), [modalVisible, closeModalOnClick]);
```

`closeModalOnClick` は変更2で安定するため、実質の依存は `modalVisible` だけになる。identity が変わるのは開閉の瞬間だけで、そのときの remount は内容が新規なので無害である。

`FullScreenModalOpener` も同様に `useCallback(..., [toggleModalOnClick])` とする。

##### 変更しないもの

| 対象 | 理由 |
| --- | --- |
| `useFullScreenModal` の公開形 | `{ FullScreenModal, openModal, closeModal, ... }` を返す形は維持する。`useCallback` で包んでも呼び出し側の書き方は変わらないため、`DateCard` / `FrameCard` / `MealIcon/AddMealIcon` / `app/dishes/page.client.tsx` の4箇所は無変更で済む |
| portal 化 | 採らない。理由は提案背景に置く |
| `EvaluateDish` の state 管理 | 変更しない。remount さえ起きなければローカル state のままで正しく動く |

##### 期待する検証結果

| 検証 | 期待 |
| --- | --- |
| jsdom: `actionsOpen=false` から★4を1回タップ | 塗られた星が 3 → 4。アクション展開は `false` のまま |
| jsdom: 親の無関係な再render | 開いているモーダルの選択が保持される |
| 実機（390x844） | 1回目タップでスコアが変わり、閉じた後にアクション展開が開いていない |
| 既存の `index.spec.tsx` / `DateCard.spec.tsx` | green のまま |
| 4つの他の呼び出し元 | 無変更で既存 spec が green のまま |

#### 提案背景

##### 引き金と機構の両方を断つ理由

実測により、二つの独立した欠陥が確認されている。

| 欠陥 | 実測 | 片方だけ直した場合に残るもの |
| --- | --- | --- |
| bubbling（引き金） | 実測2。モーダルが開いたままの時点で背後のアクション展開が開く | 機構だけ直すと、スコアは保持されるがモーダル操作のたびに背後が開き続ける。ユーザーに見える誤動作が残る |
| remount（機構） | 実測3。カードと無関係な親の再renderだけでモーダル内容が消える | 引き金だけ直すと、今回の症状は消えるが、`useFullScreenModal` を使う全5箇所で親の再renderによる入力消失が残る |

実測3を取る前は、remount の被害は bubbling 経路に限られる可能性があり、機構側の修正は投機的だった。実測3により、隣接ボタンの state 変化だけで `FrameCard` の `AddMeal` フォームや `EditMeal` / `EditDish` フォームの入力が消えることが確定した。モーダルは開いたままなので、ユーザーには理由なく入力が失われたように見える。

##### 呼び出し側5箇所を変えずに済む理由

当初、機構側の修正は hook の公開形を変える必要があると想定していた。component を hook 本体の外へ出すと、`modalVisible` を props で渡す形になり、呼び出し側5箇所の書き換えが必要になるためである。

`useCallback` で identity を安定させる形なら、返り値の形が変わらないため呼び出し側は無変更で済む。この差が、機構側の修正コストを大きく下げる。

`onClose` を ref へ退避する必要があるのは、呼び出し側が inline arrow で渡すためである。`DishCard` の3つのモーダルはいずれも `onClose: () => { setActionsOpen(false); }` を毎render新しい関数として渡している。これを deps に入れると `useCallback` が毎render新しい identity を返し、安定化しない。

##### portal 化を採らない理由

`createPortal(..., document.body)` は DOM 上も overlay を独立させるため、bubbling を構造的に断てる。採らないのは次の理由による。

- 変更1で bubbling は断てており、portal 化が追加で解決する問題は実測されていない
- Next.js の SSR では `document` が存在しないため、mount 後にのみ portal を作る分岐が必要になる。実測された利益のない箇所へ、実行環境に依存する分岐を持ち込む
- `modal__background` は `position: fixed` であり、祖先に `transform` / `filter` / `will-change` がなければ `overflow: hidden` の祖先があってもクリップされない。現状の `DishCard` root は `overflow-hidden` を持つが、この条件に当たらない

将来 `transform` を持つ祖先が現れた場合はクリップされうるため、その時点で portal 化を再検討する余地は残る。

##### 「微修正」という枠付けとの関係

依頼原文は「微修正をお願いしたい」である。変更2・変更3は依頼の文面から見ると範囲外に見える。それでも含めるのは、実測3が示す被害が今回の症状と同じ機構から出ており、引き金だけを断つと同じ機構が他の4箇所へ残るためである。変更2・変更3の実際の差分は `useCallback` の追加と ref 一つであり、公開形も呼び出し側も変わらない。

##### 提案0が満たす必要のある条件

1. 実測1・実測2で確認した症状が消える
2. 実測3で確認した被害が消える
3. 呼び出し側4箇所を変更しない
4. 実測されていない問題のために実行環境依存の分岐を持ち込まない

変更1が条件1、変更2・変更3が条件2、`useCallback` で公開形を維持することが条件3、portal 化を採らないことが条件4を満たす。

#### 提案0へのフィードバック

**結果:** 受諾。提案0の3変更をそのまま採用する。

> ok

### 決定

引き金（bubbling）と機構（remount）の両方を断つ。変更は2ファイル3箇所で、`useFullScreenModal`の公開形は維持するため呼び出し側4箇所（`DateCard`、`FrameCard`、`MealIcon/AddMealIcon`、`app/dishes/page.client.tsx`）は無変更とする。

1. `DishCard/index.tsx`: 3つのモーダルを root `<div>` の子から Fragment の兄弟へ移す。`data-testid` は root `<div>` に付いたまま維持する。
2. `useModalTool.ts`: `onClose` を ref へ退避し、`openModal` / `closeModal` / `toggleModal` と `*OnClick` の各版を `useCallback(..., [])` にする。`onClose` を deps へ入れない。呼び出し側が inline arrow を渡すため、deps に入れると安定化しないためである。
3. `useFullScreenModal/index.tsx`: `FullScreenModal` と `FullScreenModalOpener` を `useCallback` で包む。`FullScreenModal` の実質の依存は `modalVisible` だけになり、identity が変わるのは開閉の瞬間だけになる。そのときの remount は内容が新規なので無害である。

`EvaluateDish` の state 管理は変更しない。remount が起きなければローカル state のままで正しく動く。

portal 化は採らない。変更1で bubbling は断てており、portal が追加で解決する問題は実測されていない。Next.js の SSR で `document` が無いため mount 後分岐が必要になり、実測された利益のない箇所へ実行環境依存を持ち込むことになる。祖先に `transform` 等が現れて `position: fixed` がクリップされる状況になった時点で再検討する。

## 論点2: 改名の範囲

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0: 名前と、識別子をどこまで揃えるか

#### 提案0

##### 新しい名前

`MealCard` とする。ディレクトリ、component、props 型のすべてに適用する。

##### 改名対象

| 現行 | 改名後 | 備考 |
| --- | --- | --- |
| `calendarComponents/DishCard/` | `calendarComponents/MealCard/` | `git mv` で履歴を保つ |
| `DishCard`（component） | `MealCard` | default export |
| `DishCardProps`（型） | `MealCardProps` | |
| `DateCard.tsx` の import と JSX | `MealCard` | 2行 |
| `data-testid` の `dishCard-*` 8種 | `mealCard-*` | 下表 |
| `calendar/README.md` の `DishCard` 記述 | `MealCard` | 2行 |

`data-testid` の内訳。

| 現行 | 改名後 | 追跡対象の参照元 |
| --- | --- | --- |
| `dishCard-{mealId}` | `mealCard-{mealId}` | `index.tsx`、`index.spec.tsx` |
| `dishCard-frameName-{mealId}` | `mealCard-frameName-{mealId}` | 同上 |
| `dishCard-evaluation-{mealId}` | `mealCard-evaluation-{mealId}` | 同上 |
| `dishCard-source-{mealId}` | `mealCard-source-{mealId}` | 同上 |
| `dishCard-moreBtn-{mealId}` | `mealCard-moreBtn-{mealId}` | `index.tsx` のみ |
| `dishCard-moveBtn-{mealId}` | `mealCard-moveBtn-{mealId}` | 同上 |
| `dishCard-swapBtn-{mealId}` | `mealCard-swapBtn-{mealId}` | 同上 |
| `dishCard-deleteBtn-{mealId}` | `mealCard-deleteBtn-{mealId}` | 同上 |

##### 改名しないもの

| 対象 | 理由 |
| --- | --- |
| `canAnythingExceptDisplayDishName` prop | 「料理名の表示以外の操作が可能か」を意味する。主語が料理名であり、`dish` のままで実態に合う |
| `CategoryIcon.tsx` | ディレクトリ移動には従うが、名前は料理の分類アイコンを表しており実態に合う |
| `frontend/inspect/visual/tmp/` 配下の7ファイル | gitignore 対象の使い捨てスクリプト。過去回の記録であり追随させない |
| `EvaluateDish` / `EditDish` 等、`dish` を主語とする既存 component | Meal ではなく Dish を扱っており実態に合う |

##### 実施順序

1. 回帰テストを `index.spec.tsx` へ追加し、`spike.repro.spec.tsx` を削除する
2. 論点1の3変更を適用する
3. `git mv` でディレクトリを改名し、識別子と `data-testid` を置換する
4. `git grep -n "DishCard\|dishCard-"` の残存が gitignore 対象だけであることを確認する

改名を最後に置く。先に改名すると、論点1の変更差分が改名差分に埋もれて読めなくなる。commit も分ける。

#### 提案背景

##### 名前の根拠

この component が受け取るのは `meal: MealForCalender` である。表示・操作する対象は昼夜区分、枠名、食事コメント、食事編集、枠解除、食事削除、食事複製と Meal レベルが中心で、`dish` は `meal.dish` として内包される一属性にすぎない。ユーザーの指摘「dishじゃなくてmealのcardじゃないか？」はこの実態を指している。

##### `data-testid` を改名対象へ含める根拠

改名の影響範囲を実測した。追跡対象の参照元は次だけである。

| file | 状態 |
| --- | --- |
| `DishCard/index.tsx` | 定義元。改名対象そのもの |
| `DishCard/index.spec.tsx` | 参照。ディレクトリ移動に伴い一緒に動く |
| `DishCard/spike.repro.spec.tsx` | 技術検証実装。実施順序1で削除する |

`inspect/visual/tmp/` 配下の7ファイルは gitignore 対象で、過去回の使い捨てスクリプトである。

`dishCard-moreBtn` 等の4種は現状どこからも参照されていない。追随コストは実質 `index.spec.tsx` 1ファイルに収まる。

据え置く案も検討した。差分は最小になるが、`MealCard` の中に `dishCard-` という識別子が残る。将来 `mealCard-` で grep した人が見つけられず、`dishCard-` で grep した人が Dish 由来だと誤解する。コストが1ファイルに収まる以上、揃える側を採る。

##### 改名を最後に置く根拠

論点1の変更は挙動を変える。改名は挙動を変えない。同じ commit に混ぜると、後から「どの行が挙動を変えたか」を読み分けられなくなる。ディレクトリ改名は `git mv` でも rename 検出に頼るため、内容変更と同時に行うと diff が壊れやすい。

##### 提案0が満たす必要のある条件

1. component の名前が実態を表す
2. 識別子の主語が component 名と揃う
3. 追随漏れを機械的に検出できる
4. 挙動変更の diff が改名の diff に埋もれない

`MealCard` が条件1、`data-testid` の改名が条件2、実施順序4の `git grep` が条件3、実施順序で改名を最後に置くことが条件4を満たす。

#### 提案0へのフィードバック

**結果:** 受諾。提案0のとおり改名する。

> ok

### 決定

`DishCard` を `MealCard` へ改名する。ディレクトリ、component、props 型、`data-testid` の4層すべてで主語を揃える。

改名対象は `calendarComponents/DishCard/` ディレクトリ（`git mv`）、`DishCard` component と `DishCardProps` 型、`DateCard.tsx` の import と JSX、`data-testid` の `dishCard-*` 8種、`calendar/README.md` の記述2箇所である。

`canAnythingExceptDisplayDishName` prop、`CategoryIcon`、`inspect/visual/tmp/` 配下の使い捨てスクリプト、`EvaluateDish` 等の Dish を主語とする既存 component は改名しない。

`data-testid` を据え置く案は採らない。`MealCard` の中に `dishCard-` が残ると、`mealCard-` で grep した人が見つけられず、`dishCard-` で grep した人が Dish 由来だと誤解する。追随コストが `index.spec.tsx` 1ファイルに収まることを実測で確認したため、揃える側を採る。

実施順序は、回帰テスト追加と `spike.repro.spec.tsx` 削除、論点1の3変更、`git mv` と識別子置換、`git grep` による残存確認とする。改名を最後に置き、commit も分ける。論点1の変更は挙動を変え改名は変えないため、混ぜると後から読み分けられなくなる。

## 論点3: コピー文字列にレシピ本のページ番号を含めるか

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0: ページ番号の扱いを確定する

#### 提案0

含めない。コピー文字列は次の2形だけとする。

| 条件 | コピー文字列 |
| --- | --- |
| `dishSourceRelation.sourceName` が truthy | `{sourceName}の{dish.name}` |
| それ以外（`null` / `undefined` / 空文字 / `dishSourceRelation` 自体が無い） | `{dish.name}` |

`recipeBookPage` は使わない。カード2行目の表示に使う10文字 truncate も適用せず、`sourceName` は全文を使う。

#### 提案背景

##### 依頼原文が形式を指定している

依頼原文は次のとおりである。

> 「名前をコピー」のhandleCopyNameでコピーさせるのはレシピ元がある場合は「dish.name」ではなく、「${dishSourceRelation.sourceName}の${dish.name}」がいいな。。

`sourceName` と `dish.name` だけを含む形が明示されており、ページ番号は含まれていない。ページ番号を含めるかという問いは assistant が後から持ち出したものである。

##### 含めない側の根拠

- `recipeBookPage` はレシピ本以外の source では意味を持たない。含めると `dishSourceRelation.type` による分岐が必要になり、コピー文字列の仕様が source 種別に依存する
- コピーの用途は料理名の検索・共有と考えられる。ページ番号は検索語として機能しない
- 画面上でページを確認する導線はカード2行目に既にある（`{displayName} P{page}`）

##### truncate を適用しない根拠

カード2行目の10文字 truncate は限られた表示幅のための処置である。クリップボードには幅の制約がなく、切り詰めると貼り付け先で情報が欠ける。

##### 提案0が満たす必要のある条件

1. 依頼原文が指定した形式と一致する
2. source 種別による分岐を持ち込まない
3. 表示都合の加工をコピー内容へ持ち込まない

コピー文字列の2形が条件1、`recipeBookPage` を使わないことが条件2、truncate を適用しないことが条件3を満たす。

#### 提案0へのフィードバック

**結果:** 受諾。

> ok

### 決定

コピー文字列にレシピ本のページ番号を含めない。`recipeBookPage` は使わない。カード2行目の表示に使う10文字 truncate も適用せず、`sourceName` は全文を使う。

コピー文字列は `sourceName` が truthy なら `{sourceName}の{dish.name}`、それ以外は `{dish.name}` の2形だけとする。

依頼原文が `${dishSourceRelation.sourceName}の${dish.name}` という形式を明示しており、ページ番号を含めるかという問いは assistant が後から持ち出したものである。含めると `dishSourceRelation.type` による分岐が必要になり、コピー文字列の仕様が source 種別へ依存する。画面上でページを確認する導線はカード2行目に既にある。

## 論点4: doc-enricher が挙げた3件を既存docsへ反映するか

**ステータス:** 分解済み

**種別:** レビュー指摘

<!-- ユーザーが移動中でレビューできないため、適用せず論点として保持している。tasklist の実行とは独立して判断できる。 -->

### イテレーション0: 3件の反映可否を判断する

#### 提案0

##### 提案A: `docs/ai_guideline/development_standard/application_architecture.md` へ新セクションを追加する

```markdown
## hook が component を返すときは identity を安定させる

custom hook が component を返す場合、その関数 identity を `useCallback` 等で安定させること。
hook 本体の内側で component を定義すると、呼び出し側が再 render するたびに新しい関数 identity になる。
React は同じ位置の要素 type が変わったとみなし、subtree を unmount / mount し直す。
その subtree が持つローカル state は、その時点の値ごと失われる。

- やってしまいがちな失敗: hook の中で `const Modal = ({ children }) => (...)` と定義してそのまま返す
- それをやると何が起きるか: 呼び出し側が何らかの理由で再 render するたび、モーダル内の入力・選択が黙って初期値へ戻る。モーダルは開いたままなので、ユーザーには理由なく消えたように見える
- 症状が誤診されやすい: 「クリックが効かない」形で現れるため、z-index や pointer-events を疑う方向へ流れる。実際には子のハンドラは実行されており、直後の remount が結果を捨てている
- 切り分けの問い: 「同じ操作が、親の state を変えない条件でなら効くか？」→ 効くなら remount を疑う
- MUST: hook が返す component の identity を、呼び出し側の再 render で変えない
```

##### 提案B: `docs/ai_guideline/development_standard/testing.md` の `## specファイルの記法` へ追記する

```markdown
### CSS module のクラス名で要素を引く

`jest.config.js` は `next/jest` を使っており、CSS module はキー名へマップされる。
`style['star-floating-half-click-target']` は文字列 `'star-floating-half-click-target'` になるため、
spec から `document.querySelectorAll('.star-floating-half-click-target')` で引ける。

`data-testid` を持たない要素を操作したいとき、testid を足す前にこの方法を検討する。
```

##### 提案C: `docs/ai_guideline/development_standard/application_architecture.md` の components セクション付近へ追記する

```markdown
### component 名は受け取る主データに合わせる

- やってしまいがちな失敗: 内包する一属性を主語にした名前を付ける
  （例: `meal: MealForCalender` を受け取り、昼夜区分・枠名・食事コメント・食事削除を扱う component を `DishCard` と名付ける。`dish` は `meal.dish` として内包される一属性にすぎない）
- それをやると何が起きるか: 読み手が component の責務を取り違える。props の型と名前が食い違うため、変更時に「この component はどのレベルの操作を持つべきか」の判断がぶれる
- 正しい問い: 「この component が受け取る主データの型は何か？ 名前はそれと一致しているか？」
```

#### 提案背景

##### 起点

steering の Ready result 後の必須 gate 4-1 として `doc-enricher` を提案modeで実行した結果である。ユーザーからの応答は次のとおりで、適用せず論点として保持することになった。

> 提案は提案で論点に残しておいて、tasklistは進めちゃって。今出先でちゃんと確認できないから

##### 既存documentの確認結果

いずれも重複しない。

- `application_architecture.md` は「実装コストを理由にユーザー体験を変えてはならない」「共通化の判断基準」「features ディレクトリ構造」「components ディレクトリ構造」を持つ。React の render / hook に関する規則は無い
- `testing.md` はテストファースト、コンテナ内実行、バリエーション網羅、`specファイルの記法` を持つ。CSS module や selector に関する記述は無い

##### 抽象ラダーの止まり位置

提案Aは `useFullScreenModal` 固有 → モーダル全般 → custom hook が component を返す全ケース、まで登った。frontend 全体の設計原則にあたるため上位の architecture document を置き場所とした。

提案Bは `EvaluateDish` 固有 → CSS module を使う全 component → repository の spec 全般における selector 選択、まで登った。test 方針が置き場所になる。

提案Cは `DishCard` 固有 → component 命名一般、まで登った。既存の「components ディレクトリ構造」が配置を扱っており、命名は扱っていないため同じ document の隣接位置とした。

##### DROP した候補

「`position: fixed` の要素でも DOM 上は子孫なのでイベントは祖先へ bubble する」は Gate C（非自明）で落とした。DOM の基本性質であり、1ファイル読めば分かる範囲である。

##### 提案0が満たす必要のある条件

1. 既存 document と重複しない
2. 特定の component 名・hook 名に依存しない一般則になっている
3. 抽象だけでなく、今回の具体例を「やってしまいがちな失敗」として添えている
4. 新規 `docs/` を作らない

既存確認結果が条件1、抽象ラダーの止まり位置が条件2、各提案の失敗例が条件3、既存2 document への追記に限ることが条件4を満たす。

#### 提案0へのフィードバック

**結果:** 提案の中身ではなく、提示の粒度への指摘。3件を一度に問うたことが誤りである。

> 1個ずつ聞いて

提案A・B・Cは互いに依存せず、片方だけを採ることができる。一つの論点へ束ねたことで、一つの合意で三つのdecisionが同時に動く形になっていた。

### 決定

3件を独立decisionへ分解する。以後は子論点が各件の採否を所有する。

- 論点5: 提案A（hookが返すcomponentのidentity）
- 論点6: 提案B（CSS moduleのクラス名でspecから引く）
- 論点7: 提案C（component名は受け取る主データに合わせる）

提案0に書いた各追記案の本文は、対応する子論点が引き継ぐ。本論点では追記を適用しない。

---

## 論点5: 提案A（hookが返すcomponentのidentityを安定させる）を反映するか

**ステータス:** 決定

**種別:** レビュー指摘

**親論点:** 論点4

### イテレーション0: 提案Aの採否を判断する

#### 提案0

`frontend/docs/ai_guideline/development_standard/application_architecture.md` へ新セクションを追加する。

```markdown
## hook が component を返すときは identity を安定させる

custom hook が component を返す場合、その関数 identity を `useCallback` 等で安定させること。
hook 本体の内側で component を定義すると、呼び出し側が再 render するたびに新しい関数 identity になる。
React は同じ位置の要素 type が変わったとみなし、subtree を unmount / mount し直す。
その subtree が持つローカル state は、その時点の値ごと失われる。

- やってしまいがちな失敗: hook の中で `const Modal = ({ children }) => (...)` と定義してそのまま返す
- それをやると何が起きるか: 呼び出し側が何らかの理由で再 render するたび、モーダル内の入力・選択が黙って初期値へ戻る。モーダルは開いたままなので、ユーザーには理由なく消えたように見える
- 症状が誤診されやすい: 「クリックが効かない」形で現れるため、z-index や pointer-events を疑う方向へ流れる。実際には子のハンドラは実行されており、直後の remount が結果を捨てている
- 切り分けの問い: 「同じ操作が、親の state を変えない条件でなら効くか？」→ 効くなら remount を疑う
- MUST: hook が返す component の identity を、呼び出し側の再 render で変えない
```

#### 提案背景

##### 起点

steeringのReady result後の必須gate 4-1で`doc-enricher`を提案modeで実行した結果である。論点4で3件を独立decisionへ分解したため、提案Aの採否を本論点が所有する。

##### 既存documentとの非重複

`application_architecture.md` は「実装コストを理由にユーザー体験を変えてはならない」「共通化の判断基準」「features ディレクトリ構造」「components ディレクトリ構造」を持つ。Reactのrender・hookに関する規則は無い。

##### 抽象ラダーの止まり位置

`useFullScreenModal`固有 → モーダル全般 → custom hookがcomponentを返す全ケース、まで登った。frontend全体の設計原則にあたるため上位のarchitecture documentを置き場所とした。

##### codeを読んでも分からない知識である根拠

修正後のcodeを読めば`useCallback`が付いていることは分かるが、なぜ必要かは分からない。外すと壊れることも読み取れない。

今回の実測では、カードと無関係な親のstate変化だけで、開いているモーダルの選択が消えた。この因果はcodeに現れない。

##### 症状の誤診が実際に起きた

本steeringでも当初、bubblingだけを原因と見てCSSのz-indexとpointer-eventsを疑う方向へ寄った。jsdomの対照実験で、子のハンドラは常に実行されており直後のremountが結果を捨てていると確定した。この誤診の経路を記録に含める。

##### 提案0が満たす必要のある条件

1. 次に同じ症状へ当たった者が、remountを疑う経路へ辿り着ける
2. `useCallback`を外す変更が将来提案されたときに、外せない理由が読める
3. 既存documentと重複しない

`症状が誤診されやすい`と`切り分けの問い`が条件1、機構の説明とMUSTが条件2、Reactのrender規則が既存に無いことが条件3を満たす。

#### 提案0へのフィードバック

**結果:** 受諾。

> ok

### 決定

`frontend/docs/ai_guideline/development_standard/application_architecture.md` へ `## hook が component を返すときは identity を安定させる` を追加する。内容は提案0のとおりとする。

配置は設計判断の規則群の末尾、`## features ディレクトリ構造` の直前とする。同documentの前半2章が設計判断の規則、後半2章がディレクトリ構造であり、本節は前者に属する。

**適用済み。**

---

## 論点6: 提案B（CSS moduleのクラス名でspecから要素を引く）を反映するか

**ステータス:** 決定

**種別:** レビュー指摘

**親論点:** 論点4

### イテレーション0: 提案Bの採否を判断する

#### 提案0

`frontend/docs/ai_guideline/development_standard/testing.md` の `## specファイルの記法` へ追記する。

```markdown
### CSS module のクラス名で要素を引く

`jest.config.js` は `next/jest` を使っており、CSS module はキー名へマップされる。
`style['star-floating-half-click-target']` は文字列 `'star-floating-half-click-target'` になるため、
spec から `document.querySelectorAll('.star-floating-half-click-target')` で引ける。

`data-testid` を持たない要素を操作したいとき、testid を足す前にこの方法を検討する。
```

#### 提案背景

##### 起点

steeringのReady result後の必須gate 4-1で`doc-enricher`を提案modeで実行した結果である。論点4で3件を独立decisionへ分解したため、提案Bの採否を本論点が所有する。

##### 既存documentとの非重複

`testing.md` はテストファースト、コンテナ内実行、独立・再現性、バリエーション網羅、実行コマンド、`## specファイルの記法`、`## UI変更の動作確認` を持つ。CSS moduleやselectorに関する記述は無い。

##### 実際に判断を変えた場面

今回`EvaluateDish`の星の半分クリック領域には`data-testid`が無い。この事実を知らなければ、spec を書くために本番codeへ`data-testid`を足す変更を検討することになった。実際には spec 側だけで完結した。

##### 他の2件との性質の違い

提案Aと提案Cは設計意図であり、codeを読んでも「なぜそうするか」が分からない類である。提案Bは道具の挙動であり、性質が異なる。

`next/jest`のCSS module変換はframeworkの挙動であり、`jest.config.js`を読むだけでは分からない。知らなければ本番codeへtestid を足す方向へ流れるため、`doc-enricher`のGate C（非自明）は通ると判断する。ただし3件の中では最も弱い。

##### 提案0が満たす必要のある条件

1. `data-testid`を持たない要素をspecから操作する場面で、本番codeへtestidを足す前に別手段があると分かる
2. なぜクラス名で引けるのかというframework側の根拠が読める
3. 既存documentと重複しない

`testid を足す前にこの方法を検討する`が条件1、`next/jest`がキー名へマップするという説明が条件2、既存にselector記述が無いことが条件3を満たす。

#### 提案0へのフィードバック

**結果:** 受諾。

> ok

### 決定

`frontend/docs/ai_guideline/development_standard/testing.md` の `## specファイルの記法` へ `### CSS module のクラス名で要素を引く` を追記する。内容は提案0のとおりとする。

**適用済み。**

---

## 論点7: 提案C（component名は受け取る主データに合わせる）を反映するか

**ステータス:** 決定

**種別:** レビュー指摘

**親論点:** 論点4

### イテレーション0: 提案Cの採否を判断する

#### 提案0

`frontend/docs/ai_guideline/development_standard/application_architecture.md` の `## components ディレクトリ構造` へ追記する。

```markdown
### component 名は受け取る主データに合わせる

- やってしまいがちな失敗: 内包する一属性を主語にした名前を付ける
  （例: `meal: MealForCalender` を受け取り、昼夜区分・枠名・食事コメント・食事削除を扱う component を `DishCard` と名付ける。`dish` は `meal.dish` として内包される一属性にすぎない）
- それをやると何が起きるか: 読み手が component の責務を取り違える。props の型と名前が食い違うため、変更時に「この component はどのレベルの操作を持つべきか」の判断がぶれる
- 正しい問い: 「この component が受け取る主データの型は何か？ 名前はそれと一致しているか？」
```

#### 提案背景

##### 起点

steeringのReady result後の必須gate 4-1で`doc-enricher`を提案modeで実行した結果である。論点4で3件を独立decisionへ分解したため、提案Cの採否を本論点が所有する。

##### 失敗例の事実確認

`MealCardProps`は`meal: MealForCalender`を主propsとして受け取り、`dish`は`meal.dish`から導出している。旧名`DishCard`は内包される一属性を主語にしていた。今回の改名はこの不一致を解消したものである。

##### 既存documentとの非重複

`## components ディレクトリ構造` は配置だけを扱い、命名を扱っていない。同じ章の隣接位置へ命名の観点を置く。

##### 抽象ラダーの止まり位置

`DishCard`固有 → component命名一般、まで登った。frontend全体の命名判断にあたるため、配置を扱う既存章と同じdocumentへ置く。

##### 提案0が満たす必要のある条件

1. 特定のcomponent名に依存しない一般則になっている
2. 今回の具体例を失敗例として添えている
3. 配置を扱う既存章と重複しない

`正しい問い`が条件1、`DishCard`の例が条件2、命名という観点が既存に無いことが条件3を満たす。

#### 提案0へのフィードバック

**結果:** 却下。結果としての改名は正しいが、規則が短絡的である。

> 具体として、結果だけは今回合ってるし、再発してほしくはないとはいえ、命名提案が短絡的すぎない？ 命名についての観点で厳しく自己レビューして

自己レビューで次の5点を確認した。

1. **過剰一般化。** 本repositoryの命名は「受け取る主データ」に揃っていない。`EvaluateDish`は`dishId: number`と`score`を受け取り主データは数値、`EditMeal`・`AddMeal`は操作、`CategoryIcon`・`Star`は描画するもの、`Button`・`FullScreenModal`は汎用UIの役割で名付けられている。提案0を字義どおり適用すると`EvaluateDish`が改名対象になるが、現状の名前のほうが良い。規則が誤っている。
2. **処方が一択。** 名前とpropsの食い違いには複数の正解がある。`meal`を受け取って`meal.dish.name`だけを描画するcomponentなら、直すべきは名前ではなくpropsである。提案0は改名のみを指示する。
3. **「主データ」が未定義。** `MealCard`はpropsを5つ受け取る。どれが主かを規則が答えていない。
4. **発火点が無い。** 静的な命名公式は名付ける瞬間にしか効かない。
5. **今回の原因を捉えていない。** 症状は書いているが、なぜそう名付けたかと、なぜ誰も気づかなかったかを捉えていない。

##### 履歴による事実確認

提案0を書いた時点では「責務が育って名前が取り残された」という筋書きを想定していた。履歴はこれを否定した。

| commit | propsの主データ |
| --- | --- |
| `756d41e`（作成時） | `meal: MealForCalender` |
| `14bd136` | `meal: MealForCalender` |
| `2c2d3da` | `meal: MealForCalender` |

作成時点から`meal`であり、drift は起きていない。表示上の主役である料理名に引きずられて名付けられ、3つのfeature commitを跨いでも見直されなかった。

### イテレーション1: 名前の主語と責務の主語という観点へ組み替える

#### 提案1

`frontend/docs/ai_guideline/development_standard/application_architecture.md` へ、設計判断の規則として独立した章を追加する。`## components ディレクトリ構造` の下位には置かない。

```markdown
## 名前の主語と、責務の主語を一致させる

component 名は、それが担う操作の主語を表す。表示上の主役とは限らない。

- 判断の問い: 「この component が持つ操作の主語は何か？ 名前の主語と同じか？」
- 操作を追加するときにも同じ問いを立てる。追加する操作の主語が名前の主語と違うなら、名前を変える・その操作を主語の一致する場所へ移す・component を分ける、のいずれかを選ぶ
- やってしまいがちな失敗: 表示上の主役に引きずられて名付ける
  （例: カレンダーのカードは料理名が最も目立つため `DishCard` と名付けられた。しかし props は作成時点から `meal: MealForCalender` で、昼夜区分・枠名・食事コメント・食事削除・食事複製・日付交換という食事レベルの操作を持っていた。表示の主役は料理、責務の主語は食事だった）
- 名前と props の型が食い違うことは手がかりであって、それ自体が誤りではない。一属性だけを描画する component が広い型を受け取っているなら、直すのは名前ではなく props である
```

#### 提案背景

##### 直前のfeedbackから今回満たす必要が生じた条件

1. 本repositoryの既存命名（操作・描画対象・汎用役割）と矛盾しない
2. 名前とpropsの食い違いに対して、改名以外の処方も選べる
3. 名付ける瞬間だけでなく、操作を追加する瞬間にも発火する
4. 表示上の主役に引きずられるという、今回実際に起きた誤りの機序を含む

`名前の主語＝責務の主語`という定式が条件1を満たす。`EvaluateDish`の責務の主語は料理、`EditMeal`は食事であり、どちらも規則へ適合し改名を要求しない。三つの処方を並べたことが条件2、`操作を追加するときにも同じ問いを立てる`が条件3、`表示上の主役に引きずられて名付ける`という失敗例が条件4を満たす。

##### 提案0から維持した部分と置換した部分

維持: `DishCard`を失敗例として使うこと、置き場所を`application_architecture.md`とすること、判断の問いを添えること。

置換: 規則の定式を「受け取る主データ」から「責務の主語」へ変えた。章の位置を`components ディレクトリ構造`の下位から、設計判断の規則群へ移した。命名は配置の一種ではなく設計判断であるためである。

追加: 誤りの機序（表示上の主役）と、propsの食い違いに対する処方の分岐。

#### 提案1へのフィードバック

**結果:** 受諾。

> ok

### 決定

`frontend/docs/ai_guideline/development_standard/application_architecture.md` へ `## 名前の主語と、責務の主語を一致させる` を、設計判断の規則群の末尾（`## features ディレクトリ構造` の直前）へ追加する。内容は提案1のとおりとする。

提案0の「component名は受け取る主データに合わせる」という定式は採らない。本repositoryの既存命名と矛盾し、処方を改名一択に固定するためである。

**適用済み。**
