# Design: 料理カードの評価モーダル二度タップ解消・名前コピー仕様変更・MealCard へのリネーム

## 元の依頼内容

frontend/src/components/calendar/calendarComponents/DishCard/index.tsx について微修正をお願いしたい。
EvaluateDishModal で開かれたものについて、スマホで★4とかをタップすると、一回反応しないで、モーダル裏がタップされたことになり、もう一回クリックしてやっと反応するのを直したい。
ついでに、「名前をコピー」のhandleCopyNameでコピーさせるのはレシピ元がある場合は「dish.name」ではなく、「${dishSourceRelation.sourceName}の${dish.name}」がいいな。。
あと frontend/src/components/calendar/calendarComponents/DishCard ってdishじゃなくてmealのcardじゃないか？

---

## 1. TL;DR

評価モーダル内で★をタップすると、そのクリックが星のハンドラとカード全体のハンドラの両方で処理される。カード側の `setActionsOpen(true)` が `DishCard` を再 render させ、`useFullScreenModal` が返す `FullScreenModal` を関数ごと作り直すため、React が subtree を remount して直前に書き込まれた選択スコアを捨てる。二度目のタップは `actionsOpen` が同値で React が再 render を打ち切るため効く。この二重処理を断ち、あわせて「名前コピー」がレシピ元名を含むようにし、実態が Meal のカードである component を改名する。

---

## 前提とする既存仕様

- `frontend/src/components/calendar/calendarComponents/DishCard/index.tsx`: `meal: MealForCalender` を1件受け取り、料理名・昼夜ラベル・評価・レシピ元・コメントを表示する。root の `<div>` に `onClick={() => setActionsOpen(true)}` を持ち、タップでアクション展開エリア（食事編集・評価・料理編集・名前コピー・他の日へ・日付交換・食事複製・枠解除・削除）を開く。`EditMealModal` / `EvaluateDishModal` / `EditDishModal` の3つのモーダルを、この root `<div>` の子として常時レンダリングしている。
- `frontend/src/components/common/modal/useFullScreenModal/index.tsx`: hook 本体の内側で `FullScreenModal` component を定義して返す。呼び出し側 component が再 render するたびに新しい関数 identity になる。`modal__background` は `position: fixed` だが、DOM 上は呼び出し側の JSX 位置に描画される。
- `frontend/src/components/dish/EvaluateDish/index.tsx`: 選択中スコアを `useState(registeredDishScore || 3)` でローカル保持する。`登録` ボタン押下で初めて `evaluateDish` mutation を呼ぶ。
- `frontend/src/components/dish/EvaluateDish/index.module.scss`: `.star-floating-container` は `position: absolute`、親 `.star-container` は `position: relative`。幅 60px・高さ 35px で星（`font-size: 35px` + 左右 `padding: 10px`）を覆う。`.star-floating-half-click-target` は幅 50%・高さ 100% が2つ。positioned 要素であるため非 positioned な `<i class="fa-star">` より上に描画される。`:hover` 依存はない。
- `frontend/src/components/common/modal/useModalTool.ts`: `useModalRef` が document の `mousedown` で外側クリックを監視するが、`modalOpenerRef.current` が null のとき常に早期 return するため、`FullScreenModalOpener` を使わない今回の呼び出し方では外側クリック close は発火しない。
- `frontend/src/components/calendar/calendarComponents/FrameCard/index.tsx`: 同種のカード。`handleCardClick` で `e.target.closest('[data-testid="frameCard-deleteBtn-..."]')` を見て、特定要素のクリックではカード click を発火させない自衛をしている。
- `frontend/src/components/calendar/calendarComponents/DateCard.tsx`: `MealCard` componentの呼び出し元。
- `frontend/src/components/dish/DishSearchCard/index.tsx`: `MealCard/CategoryIcon` を再利用している。component本体ではなく配下のfileへの依存であり、ディレクトリ改名の影響を受ける。
- `frontend/src/components/calendar/README.md`: 「Calender → DateCard → DishCard と props で伝搬させる」と記載。本文は "calender" 表記統一を MUST としているが、実際のディレクトリ・ファイルは既に `calendar` 表記へ移行済みで、README が実態から乖離している。
- `frontend/inspect/visual/.gitignore`: `tmp/*` を ignore。`frontend/inspect/visual/tmp/` 配下の Playwright スクリプトと成果物は追跡対象外。
- `frontend/docs/ai_guideline/development_standard/testing.md`: テストファースト必須、ホストでの `yarn test` 禁止（`docker compose exec frontend yarn test`）。

---

## 調査で確定した原因

推論ではなく実測で確定した。証跡は jsdom による判別実験と、スマホ相当ビューポートでの実機再現の二つである。

### 実測1: jsdom（`spike.repro.spec.tsx`、コンテナ内 Jest）

jsdomの実測は、機構が再現することを示す。実機のUI操作から到達できる経路があることは別に確認する必要がある。本repositoryで実機から到達できるのは実測2のbubbling経路であり、親の再render経路については、`calendar`と`features/meal`にresize・polling・interval等の自動再render契機が存在しないことを確認した。

`actionsOpen` の初期状態だけを変えた対照実験を行った。

| 条件 | ★4右半分を1回タップした結果 |
| --- | --- |
| `actionsOpen` が `false` の状態から開始 | 塗られた星 3 のまま変化しない。かつアクション展開が `true` になる |
| `actionsOpen` を先に `true` にしてから開始 | 塗られた星が 3 → 4 へ変化する |

同じ1回のタップが、`actionsOpen` の初期値によって効いたり効かなかったりする。星のクリックハンドラには常に到達している。

### 実測2: 実機（390x844、`hasTouch: true`）

| 段階 | DOM 実測値 |
| --- | --- |
| モーダル初期表示 | `filledCount: 4, hasHalf: true`（登録済みスコア 3.5 と一致） |
| ★4右半分 1回目タップ直後 | `filledCount: 4, hasHalf: true` で変化なし。**モーダルが開いたままの時点で、既に背後カードのアクション展開エリアが開いている** |
| 同 2回目タップ直後 | `hasHalf: false` へ変化（スコア 4 相当） |
| モーダルを閉じた後 | アクション展開エリアが開いたまま |

証跡: `frontend/inspect/visual/tmp/20260823-dishcard-star-tap-bug/`（スクリーンショット5点、`inspect.mjs`、`result.md`）。

### 確定した因果連鎖

1. モーダルはカード root `<div onClick={() => setActionsOpen(true)}>` の DOM 子孫である。`position: fixed` は描画位置だけを変え、イベントの伝播経路は DOM 木に従う。
2. 星をタップすると、星のハンドラが `updateScore(4)` を実行し、同じイベントがカード root へも到達して `setActionsOpen(true)` を実行する。両方が処理される。
3. `actionsOpen` が `false` から `true` へ変わるため `DishCard` が再 render する。`useFullScreenModal()` が呼び直され、`FullScreenModal` が新しい関数 identity になる。
4. React は同じ位置の要素 type が変わったとみなし、subtree を unmount して mount し直す。`EvaluateDish` の `currentScore` は component ローカル state なので、直前に書き込まれた値ごと失われる。
5. 二度目のタップでは `setActionsOpen(true)` が同値であり、React が再 render を打ち切る。remount が起きないため選択が残る。

**bubbling が引き金、`FullScreenModal` の再生成による remount が機構である。** クリックターゲットの位置ズレ、重なり、`pointer-events` は原因ではない。実測1の対照実験と、CSS が positioned 要素として星の上に載っている事実の両方がこれを示す。

---

## 2. 要件（Requirements）

### MUST（必達）

- 評価モーダルを開いた状態で★をタップしたとき、1回目のタップで選択スコアが変わる。
- 評価モーダル内の操作で、背後のカードのアクション展開エリアが開かない。
- 「名前コピー」でクリップボードへ入る文字列が、レシピ元名がある場合に `{sourceName}の{dish.name}`、ない場合に `{dish.name}` になる。
- `DishCard` を `MealCard` へ改名する。ディレクトリ、component、props 型、`data-testid` の4層すべてで主語を揃える。

### SHOULD（できれば）

- 上記の回帰を Jest で検出できるテストが残る。実測1の対照実験は、そのまま回帰テストの土台になる。

### MAY（あれば嬉しい）

- なし。

### 非目標

- 評価モーダル以外のモーダル（`EditMeal` / `EditDish`）の UI・機能変更。
- レシピ元の表示（2行目の `sourceText`）の仕様変更。10文字 truncate と `P{ページ}` 付与は現状維持。
- `frontend/src/components/calendar/README.md` の "calender" 表記乖離そのものの是正。
- `canAnythingExceptDisplayDishName` prop 名の変更。「料理名の表示以外の操作が可能か」を意味しており、`dish` のままで実態に合う。
- `frontend/inspect/visual/tmp/` 配下の過去スクリプトの追随。gitignore 対象の使い捨てである。
- `frontend/src/components/meal/frame/pattern/` の2ファイルへの変更。アプリ起動を阻む型エラーを本 steering の前に別途修正済みであり、本 steering の対象ではない。

### 受け入れ基準

- Jest: 評価モーダルを開き★をクリックする1回の操作で選択状態が変わり、かつアクション展開エリアが表示されないことを検証するテストが green になる。
- Jest: レシピ元あり／なしの2ケースで `navigator.clipboard.writeText` の引数を検証するテストが green になる。
- 既存の `index.spec.tsx` と `DateCard.spec.tsx` が green のままになる。
- `docker compose exec frontend yarn lint` が green になる。
- `visual-inspector` による実機確認で、実測2と同じ手順を踏んで1回目のタップでスコアが変わり、モーダルを閉じた後にアクション展開エリアが開いていない。

---

## 3. 完成後の姿

### 操作フロー

**ケース: 評価モーダルで★4をタップして登録する**

1. ユーザーが料理カードの★クイックアイコンを1回タップする。`QuickBtn` は `e.stopPropagation()` を持つため `actionsOpen` は `false` のままである
2. `EvaluateDishModal.openModal()` により評価モーダルが表示される
3. ユーザーがモーダル内の★4の右半分を1回タップする
4. モーダルはカード root `<div>` の外（Fragment の兄弟）にあるため、このクリックはカード root の `onClick` へ到達せず、`setActionsOpen` は呼ばれない
5. `EvaluateDish` の `currentScore` が `4` になり、★1〜4が塗られた状態が見える。remount が起きないため状態が保持される
6. ユーザーが `登録` を1回タップする
7. `evaluateDish({ dishId, score: 4 })` を1回呼ぶ
8. `onEditSucceeded` で `EvaluateDishModal.closeModal()` と `onChanged()` が走り、カードの2行目の評価表示が `4` になる
9. モーダルを閉じた後、カードのアクション展開エリアは開いていない

**ケース: 名前コピー**

1. ユーザーが料理カードをタップし、アクション展開エリアを開く
2. ユーザーが `名前コピー` を1回タップする
3. `navigator.clipboard.writeText(コピー文字列)` を1回呼ぶ
4. `setActionsOpen(false)` でアクション展開エリアが閉じる

コピー文字列の具体値:

| `dishSourceRelation.sourceName` | `dish.name` | コピーされる文字列 |
| --- | --- | --- |
| `オレンジページ2024年5月号` | `肉じゃが` | `オレンジページ2024年5月号の肉じゃが` |
| `クックパッド` | `鶏の唐揚げ` | `クックパッドの鶏の唐揚げ` |
| `null` / `undefined` / `''` | `カレー` | `カレー` |
| `dishSourceRelation` 自体が無い | `カレー` | `カレー` |

2行目の表示に使う10文字 truncate と `P{ページ}` 付与は、コピー文字列へ適用しない。

`recipeBookPage` はコピー文字列へ含めない。含めると `dishSourceRelation.type` による分岐が必要になり、コピー内容が source 種別へ依存する。画面上でページを確認する導線はカード2行目にある。

**失敗・操作中断・境界case:**

| case | success flowからの分岐 | call・stateへの影響 | actorの観測と次の操作 | 参照するcontract |
| --- | --- | --- | --- | --- |
| 評価モーダル内をタップしてから登録せず閉じる | step 6 の前で中断 | `evaluateDish` 未呼出、dish の評価は不変 | カードの評価表示は変わらず、アクション展開エリアも開いていない | 本section step 9 |
| `sourceName` が空文字 | 名前コピー step 3 の引数が変わる | `writeText('カレー')` を1回呼ぶ | レシピ元名なしの文字列がコピーされる | 本section コピー文字列の具体値 |

### callerが依存するcontract

**変更する component:**

- `MealCard`（`frontend/src/components/calendar/calendarComponents/MealCard/index.tsx` の default export）: カレンダー上で `MealForCalender` 1件を表示し、食事・料理に対する操作の入口を提供する
  - 命名根拠: 受け取るのは `meal: MealForCalender` であり、表示・操作する対象は昼夜区分、枠名、食事コメント、食事編集、枠解除、食事削除、食事複製と Meal レベルが中心である。`dish` は `meal.dish` として内包される一属性であり、カード全体の主語ではない。
  - props（現行から不変）: `meal`、`onChanged`、`canAnythingExceptDisplayDishName`、`calendarModeChangers`、`startSwappingMealsMode`
  - caller: `frontend/src/components/calendar/calendarComponents/DateCard.tsx`

**`data-testid` contract:**

| 改名前 | 改名後 | 追跡対象の参照元 |
| --- | --- | --- |
| `dishCard-{mealId}` | `mealCard-{mealId}` | `index.tsx`、`index.spec.tsx` |
| `dishCard-frameName-{mealId}` | `mealCard-frameName-{mealId}` | 同上 |
| `dishCard-evaluation-{mealId}` | `mealCard-evaluation-{mealId}` | 同上 |
| `dishCard-source-{mealId}` | `mealCard-source-{mealId}` | 同上 |
| `dishCard-moreBtn-{mealId}` | `mealCard-moreBtn-{mealId}` | `index.tsx` のみ |
| `dishCard-moveBtn-{mealId}` | `mealCard-moveBtn-{mealId}` | 同上 |
| `dishCard-swapBtn-{mealId}` | `mealCard-swapBtn-{mealId}` | 同上 |
| `dishCard-deleteBtn-{mealId}` | `mealCard-deleteBtn-{mealId}` | 同上 |

`inspect/visual/tmp/` 配下の7ファイルは gitignore 対象の使い捨てスクリプトであり、追随させない。

**改名の実施順序:**

1. 回帰テストを `index.spec.tsx` へ追加し、`spike.repro.spec.tsx` を削除する
2. 論点1で決めた3変更を適用する
3. `git mv` でディレクトリを改名し、識別子と `data-testid` を置換する
4. `git grep -n "DishCard\|dishCard-"` の残存が gitignore 対象だけであることを確認する

改名を最後に置く。論点1の変更は挙動を変え、改名は変えない。同じ commit へ混ぜると、後から挙動を変えた行を読み分けられなくなる。

---

## 4. リスクと対策

| リスク | 対策 |
| --- | --- |
| 共有 hook の変更が `DateCard` / `FrameCard` / `AddMealIcon` / `dishes/page.client.tsx` の4呼び出し元へ影響する | 公開形を維持する形の修正を採ったため、4箇所は無変更で済む。各箇所の既存 spec が green のままであることを検証に含める |
| `useCallback` の deps に `onClose` を含めると identity が安定せず、修正が効かない | `onClose` を ref へ退避し deps から外す。呼び出し側が inline arrow を渡すため、deps に含めると毎 render 新しい identity になる |
| リネームで import 漏れ・testid 参照漏れが残る | `git grep` で旧名の残存ゼロを確認する |
| リネームとバグ修正を1コミットに混ぜると、後から挙動変更の diff が読めなくなる | コミットを分ける |

---

## 5. テスト方針

- `frontend/src/components/calendar/calendarComponents/{改名後}/index.spec.tsx` にテストファーストで追加する。
  - 評価モーダルを開き★をクリックする1回の操作で、選択状態が変わりアクション展開エリアが開かないこと。実測1の対照実験がそのまま土台になる。
  - 名前コピーが、レシピ元あり／なしの2ケースで期待文字列を `navigator.clipboard.writeText` へ渡すこと。
- 既存の `index.spec.tsx` / `DateCard.spec.tsx` は testid の扱いに追随させ、それ以外のアサーションは変更しない。
- 実行は `docker compose exec frontend yarn test`。ホスト実行は禁止されている。
- 実装後に `visual-inspector` で実測2と同じ手順を踏み、1回目のタップでスコアが変わることと、閉じた後にアクション展開エリアが開いていないことを確認する。
- `spike.repro.spec.tsx` は技術検証実装であり、回帰テストへ内容を移した後に削除する。

---

## （付録）変更の実行区分

### task-design内で対象成果物へ適用済み

なし

### task-design内の対象成果物反映待ち

なし

### execution plan対象

| 対象 | 掲載理由 | 参照するdesign section |
| --- | --- | --- |
| `frontend/src/components/calendar/calendarComponents/DishCard/` 一式 | 本番 frontend の runtime behavior 変更（タップ挙動・コピー文字列）と、それを担保する Jest テスト | [操作フロー](#操作フロー) |
| `frontend/src/components/calendar/calendarComponents/DateCard.tsx` | 改名に伴う import 追随（本番 code） | [callerが依存するcontract](#callerが依存するcontract) |
| `frontend/src/components/calendar/README.md` | 改名に伴う記述追随 | [callerが依存するcontract](#callerが依存するcontract) |
| `frontend/src/components/common/modal/useFullScreenModal/index.tsx` | 本番 frontend の runtime behavior 変更。`FullScreenModal` の identity 安定化 | [調査で確定した原因](#調査で確定した原因) |
| `frontend/src/components/common/modal/useModalTool.ts` | 本番 frontend の runtime behavior 変更。callback の identity 安定化 | [調査で確定した原因](#調査で確定した原因) |
