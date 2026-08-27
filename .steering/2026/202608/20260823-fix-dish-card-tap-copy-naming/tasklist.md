# タスクリスト

## 設計参照

- `./design.md`

## 🚨 タスク完全完了の原則

**このfileの全taskが完了するまで作業を継続すること**

### 必須rule

- **すべてのtaskを`[x]`にすること**
- 「時間の都合により別taskとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- host・tool・外部環境が動かないことを理由に完了扱いにすることは禁止
- 未完了task（`[ ]`）を残したまま`completed`を返さない

### taskの取消完了が許可される唯一のcase

合意済みplanの変更によって元taskが不要または別実装へ置換された場合だけ取消完了にできる。取消時は合意と具体的理由を必ず記録する。

```markdown
- [x] ~~task名~~（合意済みplan変更により不要: 具体的な理由）
```

時間不足、難しさ、host停止、tool制限、外部環境未準備は取消理由にしない。これらの場合は`[ ]`を維持し、停止・再開状態を返す。

### tasklistの更新timing（必須）

- **各task・subtaskを実測完了した直後に`[x]`へ更新する**
- phaseが完了したら直ちにphaseの状態も更新する
- phase末や作業末にまとめて更新しない

---

## 実行環境

- test: `docker compose exec frontend yarn test`（ホスト実行は禁止）
- lint: `docker compose exec frontend yarn lint`
- 実機確認: pluginの`visual-inspector` skillを使う。`npx playwright`やPlaywright toolを直接呼ばない
- frontendコンテナは起動済みであること。落ちている場合は`docker compose up -d frontend backend`で起こす

`spike.repro.spec.tsx`は原因確定のための技術検証実装である。Phase 1で内容を回帰テストへ移した後に削除する。

---

## Phase 1: 評価モーダルで★を1回タップするとスコアが変わる

### DoD（完了条件）

- 評価モーダルを開いて★4の右半分を1回タップすると、塗られた星が 3 → 4 へ変わる。
- 同じタップで背後のカードのアクション展開エリアが開かない。
- 実機（390x844）で、モーダルを閉じた後にアクション展開エリアが開いていない。

### Tasks

- [x] 回帰テストを`index.spec.tsx`へ追加する
  - [x] 「★4右半分を1回タップすると塗られた星が4になる」テストを追加する
  - [x] 「同じタップでアクション展開エリアが開かない」テストを追加する
  - [x] テストを実行し、修正前に失敗すること（RED）を確認する
- [x] `DishCard/index.tsx`のモーダル3つをroot `<div>`の外へ出す
  - [x] テストを実行しgreenを確認する
- [x] `visual-inspector`で実機確認する
  > 確認日時: 2026-08-23
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260823-fix-dish-card-tap-copy-naming/phase-1/result.md
  >
  > 項目1: ★4右半分1回タップでスコアが3→4に変わる ✅
  >   期待値: 1回目のタップで塗られた星が4になる
  >   結果: filledCount:4, hasHalf:false（score 4相当）へ即時変化
  >
  > 項目2: 同じタップでアクション展開エリアが開かない ✅
  >   期待値: モーダルが開いたままの時点で背後のアクション展開エリアが開いていない
  >   結果: モーダル表示中、アクション展開エリア非表示を確認
  >
  > 項目3: モーダルを閉じた後もアクション展開エリアが開いていない ✅
  >   期待値: モーダルを閉じてもアクション展開エリアが開いたままにならない
  >   結果: ×ボタンで閉じた後、カードはコンパクト表示のまま

### 各task詳細

#### 回帰テストを`index.spec.tsx`へ追加する

対象file: `frontend/src/components/calendar/calendarComponents/DishCard/index.spec.tsx`

`spike.repro.spec.tsx`の1件目のケースを土台にする。判定は次の2つで行う。

- 塗られた星の数: `document.querySelectorAll('i.fa-star.fas').length`
- アクション展開の有無: `screen.queryByText('名前コピー')` の有無

手順は、`screen.getByLabelText('評価')`をクリックしてモーダルを開き、`document.querySelectorAll('.star-floating-half-click-target')`のindex 7（★4の右半分）を1回クリックする。CSS moduleのクラス名は`next/jest`によりキー名へマップされるため、この selector で引ける。

確認方法: 修正前に実行して失敗し、修正後に成功すること。

#### `DishCard/index.tsx`のモーダル3つをroot `<div>`の外へ出す

対象file: `frontend/src/components/calendar/calendarComponents/DishCard/index.tsx`

`return` 全体をFragmentで包み、`EditMealModal.FullScreenModal` / `EvaluateDishModal.FullScreenModal` / `EditDishModal.FullScreenModal` の3つを root `<div>` の子から Fragment の兄弟へ移す。アクション展開エリアは root `<div>` の中に残す。`data-testid` は root `<div>` に付いたまま維持する。

モーダルは`position: fixed`なので見た目は変わらない。

#### `visual-inspector`で実機確認する

`design.md`の実測2と同じ手順を踏む。ビューポートは390x844、`hasTouch: true`。

確認項目は、モーダルを開いて★4右半分を1回タップしたときにスコアが変わること、その時点で背後のアクション展開エリアが開いていないこと、モーダルを閉じた後もアクション展開エリアが開いていないことの3点。

---

## Phase 2: 親の無関係な再render後もモーダルの選択が保持される

### DoD（完了条件）

- カードと無関係な親のstate変化で再renderが起きても、開いている評価モーダルの選択スコアが保持される。
- `useFullScreenModal`を使う他の4箇所（`DateCard`、`FrameCard`、`MealIcon/AddMealIcon`、`app/dishes/page.client.tsx`）を変更せずに、それぞれの既存specがgreenのままである。

### Tasks

- [x] 回帰テストを`index.spec.tsx`へ追加する
  - [x] 「親の無関係な再render後も選択スコアが保持される」テストを追加する
  - [x] テストを実行し、修正前に失敗すること（RED）を確認する
- [x] `useModalTool.ts`のcallback identityを安定させる
- [x] `useFullScreenModal/index.tsx`のcomponent identityを安定させる
  - [x] テストを実行しgreenを確認する
- [x] 他の4呼び出し元の既存specがgreenのままであることを確認する
- [x] `spike.repro.spec.tsx`を削除する
- [x] ~~`visual-inspector`で実機確認する~~（実行不能により取消: 実機のUIから「モーダルを開いたまま親を再renderさせる」操作へ到達できない。`calendar`と`features/meal`にresize・polling・interval等の再render契機が存在しないことを確認済み。この機構の検証はjsdomの回帰テストが所有する。詳細は`implementation_review.md`論点2）

### 各task詳細

#### 回帰テストを`index.spec.tsx`へ追加する

`spike.repro.spec.tsx`の3件目のケースを土台にする。`DishCard`の外側にstateを持つ親componentをテスト内で定義し、そのstateを変えるボタンを置く。

手順は、評価モーダルを開いてスコアを4にし、カードと無関係なボタンをクリックして親を再renderさせ、塗られた星が4のままであることを確認する。

#### `useModalTool.ts`のcallback identityを安定させる

対象file: `frontend/src/components/common/modal/useModalTool.ts`

- `onCloseRef`を`useRef`で持ち、毎render `onCloseRef.current = onClose` を代入する
- `openModal` / `closeModal` / `toggleModal` を `useCallback(..., [])` にする。`closeModal`は`onCloseRef.current?.()`を呼ぶ
- `openModalOnClick` / `closeModalOnClick` / `toggleModalOnClick` も `useCallback(..., [])` にする

`onClose`をdepsへ入れない。呼び出し側はinline arrowを渡すため毎render identityが変わり、depsに入れると安定化しない。

#### `useFullScreenModal/index.tsx`のcomponent identityを安定させる

対象file: `frontend/src/components/common/modal/useFullScreenModal/index.tsx`

`FullScreenModal`を`React.useCallback(..., [modalVisible, closeModalOnClick])`で包む。`FullScreenModalOpener`も`useCallback(..., [toggleModalOnClick])`で包む。

先行taskで`closeModalOnClick`と`toggleModalOnClick`が安定するため、実質の依存は`modalVisible`だけになる。identityが変わるのは開閉の瞬間だけで、そのときのremountは内容が新規なので無害である。

hookが返すobjectの形は変えない。呼び出し側4箇所は無変更で済む。

#### 他の4呼び出し元の既存specがgreenのままであることを確認する

`DateCard`、`FrameCard`、`MealIcon/AddMealIcon`、`app/dishes/page.client.tsx` に対応する既存specを実行する。公開形を変えていないことの検証にあたる。

#### `visual-inspector`で実機確認する

評価モーダルを開いた状態で、カレンダーの別の操作（別カードのタップ等）により親が再renderする状況を作り、選択が保持されることを確認する。

---

## Phase 3: 名前コピーがレシピ元名を含む

### DoD（完了条件）

- レシピ元名がある料理で「名前コピー」をタップすると、`navigator.clipboard.writeText` へ `{sourceName}の{dish.name}` が渡る。
- レシピ元名がない料理では `{dish.name}` が渡る。

### Tasks

- [x] 回帰テストを`index.spec.tsx`へ追加する
  - [x] レシピ元ありのケースを追加する
  - [x] レシピ元なしのケースを追加する
  - [x] テストを実行し、修正前に失敗すること（RED）を確認する
- [x] `handleCopyName`を修正する
  - [x] テストを実行しgreenを確認する

### 各task詳細

#### 回帰テストを`index.spec.tsx`へ追加する

`navigator.clipboard.writeText`をjest.fnへ差し替え、引数を検証する。検証する具体値は`design.md`の「コピー文字列の具体値」の表に従う。

- `sourceName: 'オレンジページ2024年5月号'`、`dish.name: '肉じゃが'` → `'オレンジページ2024年5月号の肉じゃが'`
- `dishSourceRelation: null`、`dish.name: 'カレー'` → `'カレー'`

#### `handleCopyName`を修正する

対象file: `frontend/src/components/calendar/calendarComponents/DishCard/index.tsx`

`dishSourceRelation?.sourceName` が truthy なら `` `${sourceName}の${dish.name}` ``、それ以外は `dish.name` を`writeText`へ渡す。

`recipeBookPage`は使わない。カード2行目の表示に使う10文字truncateも適用せず、`sourceName`は全文を使う。

このphaseで`visual-inspector`は使わない。変更はクリップボードへ渡す文字列だけで、renderされる内容が変わらないためである。

---

## Phase 4: MealCard へ改名され、旧名の参照が残らない

### DoD（完了条件）

- `git grep -n "DishCard\|dishCard-"` の残存が `frontend/inspect/visual/tmp/` 配下（gitignore対象）だけになる。
- 全specがgreenのままである。
- 実機でカレンダー画面の表示が改名前と変わらない。

### Tasks

- [x] `git mv`でディレクトリを改名する
- [x] 識別子を置換する
  - [x] `DishCard` component と `DishCardProps` 型を `MealCard` / `MealCardProps` へ
  - [x] `DateCard.tsx` の import と JSX を `MealCard` へ
- [x] `data-testid` の `dishCard-*` 8種を `mealCard-*` へ置換する
  - [x] `index.tsx` の定義を置換する
  - [x] `index.spec.tsx` の参照を置換する
  - [x] テストを実行しgreenを確認する
- [x] `calendar/README.md` の `DishCard` 記述2箇所を `MealCard` へ更新する
- [x] 残存確認する
- [x] `visual-inspector`で実機確認する

### 各task詳細

#### `git mv`でディレクトリを改名する

`frontend/src/components/calendar/calendarComponents/DishCard/` を同階層の `MealCard/` へ `git mv` する。`CategoryIcon.tsx` と `index.spec.tsx` も一緒に移動する。`git mv`を使うのは rename 検出を確実にするためである。

このphaseを最後に置いている。Phase 1〜3は挙動を変え、改名は変えない。同じcommitへ混ぜると、後から挙動を変えた行を読み分けられなくなる。

#### `data-testid` の `dishCard-*` 8種を `mealCard-*` へ置換する

対象は `dishCard-{mealId}`、`dishCard-frameName-{mealId}`、`dishCard-evaluation-{mealId}`、`dishCard-source-{mealId}`、`dishCard-moreBtn-{mealId}`、`dishCard-moveBtn-{mealId}`、`dishCard-swapBtn-{mealId}`、`dishCard-deleteBtn-{mealId}` の8種。

追跡対象の参照元は `index.tsx`（定義）と `index.spec.tsx` だけである。`DateCard.spec.tsx` は testid を参照していないことを確認済み。

#### 残存確認する

`git grep -n "DishCard\|dishCard-"` を実行し、ヒットが `frontend/inspect/visual/tmp/` 配下だけであることを確認する。同ディレクトリは gitignore 対象の使い捨てスクリプトであり追随させない。

実測結果: 追跡対象のsource配下に残存ゼロ。ヒットは過去のsteering記録（`.steering/2026/202603/` 配下）だけであり、当時の事実の記録なので改名しない。

設計時に把握できていなかった参照元が1件あった。`frontend/src/components/dish/DishSearchCard/index.tsx` が `CategoryIcon` を旧pathからimportしていた。この`git grep`で検出し修正済み。詳細は`implementation_review.md`の論点1にある。

#### `visual-inspector`で実機確認する

改名は表示を変えない変更だが、component の移動と識別子置換を含むため、表示崩れがないことを確認する。カレンダー画面で料理カードが改名前と同じに描画されることを見る。

---

## Phase 5: 品質checkと修正

### DoD（完了条件）

- 全testがgreen
- `docker compose exec frontend yarn lint` にerrorがない
- 最終screenshotで見た目を目視確認済み

> screenshot確認は最後にまとめて行うものではない。Phase 1・2・4のDoDに各phaseの確認を含めてある。このphaseでは全体の最終確認だけを行う。

### Tasks

- [x] 全test実行
  - [x] `docker compose exec frontend yarn test` を実行する
  - [x] すべてgreenであることを確認する
- [x] lint実行
  - [x] `docker compose exec frontend yarn lint` を実行する
  - [x] errorがあれば修正して再実行する
  - [x] error zeroを確認する
- [x] 最終screenshotで見た目を目視確認する
  - [x] pluginの`visual-inspector` skillを使いscreenshotを撮る
  - [x] カレンダー画面と評価モーダルのlayoutが意図どおりか確認する
  - [x] 問題があれば修正して再確認する（問題なし）

---

## Documentation reviewと実装後振り返り

- [x] ~~doc-enricherを提案modeで適用する~~（steeringのgate 4-1で実施済み。提案3件は`task-design-discussion.md`の論点4へ保存し、ユーザーがレビューできる状態になるまで適用しない）
- [ ] 実装中に新たな永続化候補が出た場合だけ、その場でdoc-enricherを提案modeで適用し、論点4へ追記する
  - [ ] 適用はユーザー承認後だけ行う。承認が得られない間は提案のまま保持する
- [ ] 実装、review、validationからfeedbackまたは実装とのずれが生じた場合、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用する
  - [ ] `discussion_directory=<working_dir>`と`discussion_file_name=implementation_review.md`を渡す
  - [ ] 原文、関連する実装・design・plan、原因、採用方針、決定を渡し、修正済みでも記録を省略しない
  - [ ] 「共有されていなかった知識の前提は何か」を確認する
  - [ ] 「codeを読めば分かるか、設計意図か、process不足か」を確認する
  - [ ] 「どこに書けば次回この議論が不要になるか」を確認し、合意後だけ反映する
  - [ ] decisionをcallerへ返し、designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す
  - [ ] review後に実装を自動再開しない

---

## 動作確認

### DoD

スマホ相当のビューポートで評価モーダルを操作し、意図どおりであることを確認した。

実施主体はagentである。ユーザー自身の実端末での確認は行っていない。ユーザー確認gateは、報告を受けたユーザーが進行を述べた時点で満たす。

今回の確認が及んでいない範囲を明示する。★タップは`EvaluateDish`のローカルstateだけを変え、永続化は「登録」ボタンのsubmitで起きる。今回の確認は登録を押さずにモーダルを閉じたため、永続化経路を通っていない。今回の変更はクリップボード文字列とcomponent identityだけを変えており、永続化経路には触れていない。

### Tasks

- [x] 動作確認する（agentがpluginの`visual-inspector`で実施。390x844・hasTouch。成果物は`frontend/inspect/visual/tmp/20260827-231935-mealcard-star-copy-verification/`）
  - [x] 評価モーダルで★を1回タップしてスコアが変わる
    - `mealCard-2253`（8/22「山形のだし」、初期3.5）で★4右半分を1回タップ。`{"filledCount":4,"hasHalf":true}` → `{"filledCount":4,"hasHalf":false}`。`02_modal_opened.png`と`03_after_first_tap.png`をagentが目視確認済み
  - [x] モーダルを閉じた後にアクション展開エリアが開いていない
    - 閉じた直後のアクションラベル検出数0件（`{"visibleActionLabels":[]}`）。モーダルを開いている間も背後のカードは折りたたみ表示のままである
  - [x] レシピ元がある料理で「名前コピー」の内容が正しい
    - `navigator.clipboard.readText()`の実測値が`"りゅうじの山形のだし"`。`${sourceName}の${dish.name}`と一致
  - [x] ~~ユーザーへ動作確認を依頼する~~（取消: agentが先に確認して報告する順序のため、依頼という形を取らない。ユーザー確認gate自体は廃止せず、報告を受けたユーザーが進行を述べた時点で満たす。詳細は`implementation_review.md`論点4）
- [x] feedbackがあれば、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用し、decisionをcallerへ返す（4件を論点1〜4として記録し、すべて決定）
  - [x] ~~designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す~~（該当なし: 4件とも記述の訂正とdocsへの一般則反映で完結し、完成後の姿・要件・公開APIは変わらなかった）
  - [x] ~~feedbackがなければ完了扱いにする~~（該当なし: feedbackが4件あった）

---

## 完了後のaction

> ⚠️ 動作確認phaseが完了するまでcommit、push、PRを促したり実行したりしない。急かすことも禁止する。

- [x] commit（phase単位かつ意味単位で分割。7commitへ分割した）
  - MUST: まとめて一commitにしない
  - Phase 1（bubbling修正）、Phase 2（identity安定化）、Phase 3（コピー文字列）、Phase 4（改名）を別commitにする
  - Phase 4の改名commitへ挙動変更を混ぜない
  - 実際の順序: 改名commitをPhase 1〜3の挙動変更より前へ置いた。`data-testid`の改名と、モーダルをroot外へ出す構造変更が同一行に重なっており、Phase順のままでは存在しなかった中間状態を捏造しなければ分割できなかったためである。粒度と内容は合意どおり
  - steering成果物のうち`design.md`と`task-design-discussion.md`は、対応する変更commitより前に置く
  - `tasklist.md`のcheckbox確定は、対応する変更commitより後に置く
  - ユーザーが一部だけ承認した場合は承認範囲だけをcommitし、残りは待つ
  - ユーザーが不要と回答した場合は`[x] ~~commit~~（ユーザーが不要と回答）`の形式で完了扱いにする

- [x] current branchをpushしてPRを作成する（PR #272）
  - [x] commit taskの結果としてlocal commitが実際に一件以上あることを確認する。一件もなければpush・PRを実行しない
  - [ ] current branchが公開可能なnon-default branchであることを確認する
  - [ ] `git push -u origin <current-branch>`を実行する
  - [ ] `tasklist-executor/scripts/github/create_or_get_pr.sh`を使い、既存PRがあれば再利用する
