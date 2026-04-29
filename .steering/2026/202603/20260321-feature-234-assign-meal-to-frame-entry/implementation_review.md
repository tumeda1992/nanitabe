# Implementation Review: feature-234 実装後レビュー

---

## 1. フィードバック収集（言われた通り転記）

- **FB-1:** カレンダー上での枠作成について、既存で希望のものがなかったら新しく作る機能がない
- **FB-2:** 枠の新規追加時の食事タイプはラジオボタンが良いな。固定長をセレクトボックスだとクリックして開かなきゃいけないのが億劫だし、食事登録みたいにデフォルトが選ばれていてほしい
- **FB-3:** 2026/3/23月にチャーハン枠でチャーハンの食事をあてがったのに、3/22に登録されたんだけど
- **FB-4:** 枠を経由して食事登録されたときのデザインが .steering/2026/20260307-feature-201-apply-v0-calendar-design/nanitabe_v0_design と違う
- **FB-5:** 食事未登録時のカレンダーの破線、あの中の要素をクリックしたら、食事登録が出てほしい。v0にお願いしてたんだけど、いつの間にか消えてたんだよね。破線ブロックの中心に+って文言も欲しい
- **FB-6:** カレンダーの食事のアコーディオンが開くのが、メニューボタンを押さないと開かないのが億劫。食事のカードを押したら開閉してほしい。もちろんアクションボタン押したときには開閉せずにアクションだけ起こってほしいし、開いたアコーディオンをクリックしても閉じないでほしいけど
- **FB-7:** 手間が未入力だと食事登録できないのは意図と違う。バックエンドではnullableかもだけど、フロントエンドで必須にしちゃってるかも
- **FB-8:** 枠から選んだ食事を削除したら、エラーになった
- **FB-9:** カレンダーから枠を割り当てるとき、新規登録できるけど、登録後に食事枠の選択肢では登録前の結果しか見えないから、新規で追加したやつ選べない

---

## 2. 認識合わせ

### 論点1: カレンダーから新規枠作成するときの UX（FB-1）

**提起の背景:** AddMealFrame は既存枠の `<select>` のみ実装されており、一覧にない枠を使いたい場合 `/mealframes/new` ページへの事前登録が必要になっている

**議論の変遷:**
- [前提] feature-64 設計 要件1 受け入れ基準2: 「WHEN 枠一覧にない名前で枠を使いたい THEN 新規作成できる」と決まっている
- [決定] UI の形: 既存 `<select>` に「新規作成...」オプションを追加してその場でテキスト入力させるインライン形式

**決定:** `<select>` に「新規作成...」を追加 → 選択するとテキスト入力欄がインラインで表示される

**決定理由:** モーダルを開く手間なく、枠選択フォームの中で完結できる

---

### 論点2: AddMealFrame の食事タイプ UI（FB-2）

**提起の背景:** 現状 `<select>` で朝食/昼食/夕食を選ばせているが、固定3択なのにクリックして開く操作が必要で億劫

**議論の変遷:**
- [前提] 選択肢は朝食/昼食/夕食の3択で固定
- [フィードバック] ラジオボタンにしてほしい、食事登録（AddMeal）と同様にデフォルト選択ありにしてほしい
- [未決定] デフォルト値: 夕食か、それとも別の値か。AddMeal のデフォルトに合わせるか

**決定:** ラジオボタン化・デフォルト = 夕食

**決定理由:** 固定3択に select は操作コストが高い。AddMeal と同様にデフォルト選択ありにする。デフォルトは夕食

---

### 論点3: FrameCard 経由の食事登録で日付が1日ずれる（FB-3）

**提起の背景:** 2026/3/23 のチャーハン枠をクリックして食事登録したら 3/22 に登録された（フォームを開いた時点で 3/22 が選ばれていた）

**議論の変遷:**
- [前提] FrameCard は AddMeal に `frameEntryId` のみ渡しており `defaultDate` を渡していない → AddMeal は `new Date()`（今日）をデフォルトにする
- [根本原因1] `FrameEntryForCalender` 型に `date` フィールドが存在しない。日付は親の `MealsOfDate.date`（DateCard が持つ）にしかない
- [根本原因2] 仮に `date` を文字列で渡した場合も `new Date("2026-03-23")` は UTC 0:00 解釈 → JST では 3/22 23:00 になるタイムゾーン問題が潜在する
- [修正方針] `DateCard` → `FrameCard` に `date: string` prop を追加し、AddMeal に `defaultDate={parseISO(date)}` で渡す（`parseISO` はローカル解釈なのでタイムゾーン問題を回避できる）

**決定:** 修正方針確定

---

### 論点4: 枠経由 DishCard のデザインが v0 と異なる（FB-4）

**提起の背景:** 枠に食事をあてがった後の DishCard の枠ラベル表示が v0 デザインと違う

**議論の変遷:**
- [前提] v0 デザイン（`dish-card.tsx`）の MEAL_PLACEHOLDER 実装:
  - 料理名の**上**（1行目より前）に表示
  - スタイル: `text-[10px] text-muted-foreground/50`（非常に薄いグレー）
  - フォーマット: ラベル名のみ（"パスタ" など。"枠:" プレフィックスなし）
- [現状実装] DishCard の枠ラベル:
  - 表示位置: 2行目エリア（評価・レシピ元と同列）
  - スタイル: `text-[10px] text-violet-600`（バイオレット、明るい）
  - フォーマット: "枠: パスタ" と "枠:" プレフィックスあり
- [差異まとめ] 位置・色・フォーマットの3点が v0 と異なる

**決定:** v0 に合わせる
- 位置: 料理名の上（1行目より前）
- スタイル: `text-[10px] text-muted-foreground/50`
- フォーマット: ラベル名のみ（"枠:" プレフィックスなし）

---

### 論点5: 食事未登録日の破線エリアをクリックしたら食事登録フォームが出てほしい + 中心に「+」表示（FB-5）

**提起の背景:** v0 デザインで実装されていたが、いつの間にか消えている

**議論の変遷:**
- [前提] v0 では破線ブロック内クリックで食事登録フォームが開く + 中央に「+」文言あり
- [現状] DateCard の空エリアはクリックしても何も起きない。「+」表示もない
- [修正方針] DateCard の空エリア（食事・枠ゼロの場合）をクリック可能にし、AddMeal フォームを開く。中央に「+」を表示する

**決定:** 修正方針確定

---

### 論点6: DishCard のアコーディオン開閉をカードクリックで行いたい（FB-6）

**提起の背景:** 現状はアコーディオン（アクションエリア）を開くにはメニューボタン（`MoreHorizontal`）を押す必要があり億劫

**議論の変遷:**
- [前提] 現状は `MoreHorizontal` ボタンのみがアコーディオン開閉のトリガー
- [フィードバック]
  - カード本体をクリックしたら開閉する
  - アクションボタン（食事編集・評価・削除など）を押したときは開閉せずアクションだけ起こる
  - アコーディオンが開いた状態でカードをクリックしても**閉じない**（開いたまま）

**決定:** 修正方針確定。カードクリック → 開く。アクションボタンクリック → 開閉しない。開いた状態でのカードクリック → 何もしない（閉じない）

---

### 論点7: 手間未入力で食事登録できないバグ（FB-7）

**提起の背景:** 手間（dishEffortLevelId）を選ばないと食事登録できない。ユーザーの意図は任意項目

**議論の変遷:**
- [前提] バックエンドの schema: `dishEffortLevelId` は nullable
- [前提] フロントエンドの zod schema: `z.number().nullish()` で nullable
- [根本原因] `SelectEffortLevel` で `register('dish.dishEffortLevelId', { valueAsNumber: true })` を使用。「指定なし」選択時の値 `""` が `valueAsNumber: true` により `NaN` に変換され、`z.number()` が NaN を弾く
- [修正方針] `valueAsNumber: true` を外し、`setValueAs: v => v === '' ? null : Number(v)` で空文字 → null 変換する

**決定:** 修正方針確定

---

### 論点8: 枠に紐付いた食事を削除するとエラーになるバグ（FB-8）

**提起の背景:** 枠から割り当てた食事を削除しようとすると 500 エラーが発生した

**議論の変遷:**
- [前提] `meal_frame_entries.meal_id` は `meals.id` への FK 制約あり
- [前提] `Meal` モデルに `has_one :meal_frame_entry` はあったが `dependent:` オプションなし
- [根本原因] `RemoveCommand` が `meal.destroy!` を呼ぶとき、`meal_frame_entries.meal_id` が当該 meal を参照したままのため DB の FK 制約に違反して ROLLBACK される
- [修正方針] `has_one :meal_frame_entry, dependent: :nullify` を追加。食事削除時に枠エントリの `meal_id` が NULL になり、枠が「未割当」状態に戻る
- [修正実施済み] `app/models/meal.rb` を修正・spec 追加・green 確認済み

**決定:** `dependent: :nullify` で対応済み

**決定理由:** 食事を削除しても枠エントリ自体は残すべき（枠の定義は食事とは独立）。`meal_id = NULL` = 未割当に戻すのがドメイン的に正しい振る舞い

---

### 論点9: 新規枠作成後に枠選択肢が更新されないバグ（FB-9）

**提起の背景:** `AddMealFrame` で「新規作成...」から枠を作っても、作成した枠が選択肢に現れない

**議論の変遷:**
- [前提] `AddMealFrame` の枠一覧はコンポーネントマウント時に1回 query で取得
- [根本原因] `addMealFrame` mutation 完了後に枠一覧クエリが refetch されないため、作成した枠がドロップダウンに反映されない
- [修正方針] `addMealFrame` mutation 完了後に枠一覧クエリを refetch する

**決定:** mutation 完了後に refetch で対応

---

## 3. 設計

### 完成後の姿

#### 操作フロー

**ケース1: FrameCard をクリックして食事登録する（FB-3 修正後）**
```
① 3/23 の FrameCard をクリック
② AddMeal フォームが開く → 日付欄に 3/23 が pre-fill されている
③ 料理を選んで登録
④ 3/23 に食事が登録される
```

**ケース2: 枠登録フォームで食事タイプを選ぶ（FB-2 修正後）**
```
① + ボタン → 「枠」を選択してフォームが開く
② 食事タイプがラジオボタンで「朝食 / 昼食 / 夕食」が横並びに表示される
③ 初期状態で「夕食」が選択済み
④ タップ1回で別の食事タイプに切り替えられる
```

**ケース3: 新規枠をその場で作って登録する（FB-1 修正後）**
```
① 枠登録フォームの枠セレクトを開く
② 一覧の末尾に「新規作成...」がある
③ 「新規作成...」を選ぶ → セレクトの下にテキスト入力欄が出現
④ 枠名を入力して確定
⑤ 作成した枠が自動選択され、そのまま登録できる
```

**ケース4: 食事未登録日に食事を追加する（FB-5 修正後）**
```
① 食事も枠もない日付エリアを見ると、破線の中央に「+」が表示されている
② 破線エリアをタップ
③ AddMeal フォームが開く
```

**ケース5: DishCard のアクションを開く（FB-6 修正後）**
```
① DishCard のカード本体をタップ → アクションエリアが開く
② アクションボタン（削除・編集など）をタップ → アクションだけ起こる（開閉しない）
③ アクションエリアが開いた状態でカード本体をタップ → 何も起きない（閉じない）
```

**ケース6: 手間未選択で食事登録する（FB-7 修正後）**
```
① 新規料理で食事登録フォームを開く
② 手間を選ばずそのまま登録ボタンを押す
③ 登録できる（手間 = null で保存）
```

**ケース7: 枠ありの食事が DishCard に表示される（FB-4 修正後）**
```
① 枠経由で登録した食事の DishCard を見る
② 料理名の上に薄いグレーで「パスタ」とだけ表示される（"枠:" プレフィックスなし）
```

---

#### データモデル・クラス設計

FB-3 のみデータフローの変更あり。`FrameEntryForCalender` 型は `date` を持たないため、`MealsOfDate.date` を DateCard から FrameCard へ prop として渡す。

```
MealsOfDate.date（string）
  → DateCard が date を持つ
    → FrameCard に date: string を追加
      → AddMeal に defaultDate={parseISO(date)} を渡す
```

その他の修正はデータモデルの変更なし。UI・バリデーションの変更のみ。

**FB-8（削除エラー）は修正済み。** `Meal` モデルに `dependent: :nullify` を追加し、食事削除時に枠エントリが未割当に戻る。

**FB-9（新規枠作成後に選択肢が更新されない）の修正後フロー:**
```
① AddMealFrame で「新規作成...」を選択
② 枠名を入力して確定ボタン押下
③ addMealFrame mutation が実行される
④ mutation 完了後、枠一覧クエリを refetch
⑤ 作成した枠が選択肢に表示され、自動選択される
⑥ そのまま枠登録を完了できる
```

---

## 4. タスク整理

既存 `tasklist.md` のフェーズ6完了後に以下のフェーズを追記する。

---

### フェーズ7: FB-3 FrameCard 日付バグ修正

**DoD:** FrameCard をクリックして開いた AddMeal フォームの日付が枠の日付と一致する（spec green）

- [ ] `DateCard` → `FrameCard` に `date: string` prop を追加
- [ ] `FrameCard` が `AddMeal` に `defaultDate={parseISO(date)}` を渡すよう修正
- [ ] `FrameCard` spec に「date が AddMeal に渡されること」のテスト追加
- [ ] rspec / yarn test green 確認

---

### フェーズ8: FB-7 手間バリデーション修正

**DoD:** 手間未選択のまま食事登録できる（spec green）

- [ ] `SelectEffortLevel` の `register` オプションを `{ setValueAs: (v) => v === '' ? null : Number(v) }` に変更
- [ ] spec に「手間未選択で submit できること」のテスト追加
- [ ] yarn test green 確認

---

### フェーズ9: FB-2 食事タイプ ラジオボタン化

**DoD:** AddMealFrame で食事タイプがラジオボタンで表示され、夕食がデフォルト選択されている（スクリーンショット確認）

- [ ] `AddMealFrame/index.tsx` の `mealTypeSelect` をラジオボタン3択に変更（デフォルト: 夕食）
- [ ] spec 更新（select → radio、デフォルト夕食）
- [ ] yarn test green 確認
- [ ] visual-inspector でスクリーンショット確認

---

### フェーズ10: FB-4 DishCard 枠ラベル v0 合わせ

**DoD:** 枠ありの DishCard で枠ラベルが料理名の上に薄グレーで表示される（スクリーンショット確認）

- [ ] `DishCard/index.tsx` の枠ラベルを v0 仕様に修正（位置・スタイル・フォーマット）
- [ ] spec 更新（表示位置・スタイルの変更に合わせて）
- [ ] yarn test green 確認
- [ ] visual-inspector でスクリーンショット確認

---

### フェーズ11: FB-5 食事未登録日の破線エリア

**DoD:** 食事・枠ゼロの日付エリアに「+」が表示され、クリックで食事登録フォームが開く（スクリーンショット確認）

- [ ] `DateCard.tsx` の空エリアに「+」表示を追加
- [ ] 空エリアクリックで AddMeal モーダルを開く実装
- [ ] spec 追加（空エリアクリックでモーダルが開くこと）
- [ ] yarn test green 確認
- [ ] visual-inspector でスクリーンショット確認

---

### フェーズ12: FB-6 DishCard アコーディオン開閉

**DoD:** DishCard 本体クリックでアクションエリアが開き、アクションボタンクリックでは開閉しない（スクリーンショット確認）

- [ ] `DishCard/index.tsx` のカード本体に `onClick` 追加（`actionsOpen = true` のみ、閉じない）
- [ ] spec 追加（カードクリック→開く、アクションボタンクリック→開閉しない）
- [ ] yarn test green 確認
- [ ] visual-inspector でスクリーンショット確認

---

### フェーズ13: FB-1 AddMealFrame 新規枠作成インライン

**DoD:** 枠一覧に「新規作成...」が表示され、選択するとテキスト入力欄が現れ、登録後に作成した枠が自動選択される（spec green + スクリーンショット確認）

- [ ] `AddMealFrame/index.tsx` に「新規作成...」オプション追加
- [ ] 選択時にテキスト入力欄をインライン表示
- [ ] 入力確定で `addMealFrame` mutation を呼び、作成した枠を自動選択
- [ ] spec 追加（新規作成フロー）
- [ ] yarn test green 確認
- [ ] visual-inspector でスクリーンショット確認

---

### フェーズ14: 品質チェック

**DoD:** 全テスト green・lint clean・最終スクリーンショット確認

- [ ] `docker compose exec backend bundle exec rspec` 全 green
- [ ] `docker compose exec frontend yarn test` 全 green
- [ ] `docker compose exec backend bundle exec rubocop`（エラーあれば `-a`）
- [ ] `docker compose exec frontend yarn lint`（エラーあれば `--fix`）
- [ ] visual-inspector で最終スクリーンショット確認

---

### フェーズ15: FB-8 枠に紐付いた食事削除エラー修正（修正済み）

**DoD:** 修正・spec 追加・green 確認済み

- [x] `Meal` モデルに `has_one :meal_frame_entry, dependent: :nullify` を追加
- [x] `meal_spec.rb` に「枠に紐付いた食事を削除すると meal_frame_entry.meal_id が nil になること」のテスト追加
- [x] rspec green 確認

---

### フェーズ16: FB-9 新規枠作成後に選択肢が更新されないバグ修正

**DoD:** 「新規作成...」で枠を作成した直後、作成した枠が選択肢に表示されて選択できる（spec green + スクリーンショット確認）

- [ ] `AddMealFrame/index.tsx` で `addMealFrame` mutation 完了後に枠一覧クエリを refetch
- [ ] spec 追加（新規作成後に選択肢が更新されること）
- [ ] yarn test green 確認
- [ ] visual-inspector でスクリーンショット確認

---

### フェーズ17: 品質チェック

**DoD:** 全テスト green・lint clean

- [ ] `docker compose exec backend bundle exec rspec` 全 green
- [ ] `docker compose exec frontend yarn test` 全 green
- [ ] `docker compose exec backend bundle exec rubocop`（エラーあれば `-a`）
- [ ] `docker compose exec frontend yarn lint`（エラーあれば `--fix`）

