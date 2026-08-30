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

時間不足、難しさ、host停止、tool制限、外部環境未準備は取消理由にしない。

### tasklistの更新timing（必須）

- **各task・subtaskを実測完了した直後に`[x]`へ更新する**
- phase末や作業末にまとめて更新しない

---

## Phase 1: `postponed_meals` テーブルが存在する

### DoD（完了条件）

- `docker compose exec backend bundle exec rails db:migrate` が成功し、`db/schema.rb` に `postponed_meals` が
  `user_id` / `dish_id` / `meal_type` すべて `null: false` で現れる。一意制約は無い。

### Tasks

- [x] `postponed_meals` のmigrationを作成して適用する
  - [x] migration fileを作成する
  - [x] migrationを実行する
  - [x] `db/schema.rb` の差分を確認する
- [x] **ここで作業を停止し、migration結果をユーザーに確認する。次phaseへは進まない**

### 各task詳細

#### `postponed_meals` のmigrationを作成して適用する

対象: `backend/db/migrate/`、`backend/db/schema.rb`

`design.md` の「データモデル」に従い次を作る。

| column | 型 | 制約 |
| --- | --- | --- |
| `user_id` | bigint | `null: false`、index |
| `dish_id` | bigint | `null: false`、index |
| `meal_type` | integer | `null: false` |
| `created_at` / `updated_at` | datetime | `null: false` |

一意制約は張らない（同じ料理を重複して延期できるため）。FK制約は既存テーブル（`meal_frame_entries` 等）の
記述に合わせる。

実行: `docker compose exec backend bundle exec rails db:migrate`

---

## Phase 2: 食事カードから食事を延期できる

### DoD（完了条件）

- カレンダーの食事カードで「延期」をタップし確認ダイアログでOKすると、その食事がカレンダーから消え、
  `postponed_meals` に `dish_id` / `meal_type` を引き継いだ行が1件増える。
- 枠に紐付いていた食事を延期した場合、枠はその日に残り未割り当て表示になる。

### Tasks

- [x] `Meal::Postponed` 集約と永続化を作る
  - [x] `root.rb` / `factory.rb` を作る
  - [x] `app/models/postponed_meal.rb` を作る
  - [x] `usecase/add_command.rb` を作る
  - [x] RSpecを作成する（集約とmodelの往復、AddCommand）
  - [x] `docker compose exec backend bundle exec rspec` でgreenを確認する
- [x] `postponeMeal` mutationを作る
  - [x] Input Type と mutation classを作る
  - [x] `Types::MutationType` へ登録する
  - [x] RSpecを作成する（`meals` 削除と `postponed_meals` 作成が1トランザクション、枠エントリの `meal_id` が `NULL` へ）
  - [x] green確認する
- [x] 食事カードへ「延期」アクションを追加する
  - [x] `features/meal/postponed/postponeMealMutation.ts` と `usePostponedMeal.ts` を作る
  - [x] `MealCard` のアクション展開エリアへ「延期」を「削除」の直前に追加する
  - [x] 確認ダイアログを実装する
  - [x] Jestを作成する（「延期」の表示、キャンセル時にmutationが呼ばれないこと）
  - [x] `docker compose exec frontend yarn test` でgreenを確認する
  - [x] `visual-inspector` でアクション展開エリアのscreenshotを撮り、3行目の見え方を確認する
    > 確認日時: 2026-08-29
    > 総合結果: ✅ 全項目正常
    > ログ: frontend/inspect/visual/tmp/20260829-add-pending-dish-pool/phase-2/result.md
    >
    > 項目1: 枠に紐付かない食事カードでの「延期」配置 ✅
    >   期待値: 「延期」が「削除」の直前に配置され、レイアウトが崩れない
    >   結果: 9項目（3行目に「削除」単独）。「延期」は2行目末尾、3行目に「削除」のみ。design.mdが許容する「3行目が埋まらない」ケースとして正常
    >
    > 項目2: 枠に紐付いた食事カードでの「延期」配置（10項目・3行目に2つ並ぶケース） ✅
    >   期待値: 「枠解除」ボタンがある食事カードで、3行目に「延期」「削除」が1・2列目に並ぶ
    >   結果: MealFrameEntryで検証用データを作成し確認。1行目[食事編集/評価/料理編集/名前コピー]、2行目[他の日へ/日付交換/食事複製(disabled)/枠解除]、3行目[延期/削除]。design.mdのモックアップどおりの配置、レイアウト崩れなし。確認後、検証用のMealFrameEntryとMealFrameは削除済み

### 各task詳細

#### `Meal::Postponed` 集約と永続化を作る

対象: `backend/app/domain/business/food/meal/postponed/`、`backend/app/models/postponed_meal.rb`

`design.md` の「codeの責務配置と依存構造」に従う。`Root` は `set_id` 以外の振る舞いを持たない。
`build_existing_root_from_id` と `persist_from_food_meal_postponed_root` の両方を作り、
`user_id` / `dish_id` / `meal_type` が往復で失われないことをRSpecで確認する。

#### `postponeMeal` mutationを作る

対象: `backend/app/graphql/mutations/meal/postponed/postpone_meal.rb`、`types/input/...`、`types/mutation_type.rb`

`ActiveRecord::Base.transaction` 内で `Meal::Postponed::Usecase::AddCommand` → `Meal::Usecase::RemoveCommand`
の順に呼ぶ。2集約をまたぐorchestrationはresolverが担い、Command側へ内包しない。
`Meal` の `has_one :meal_frame_entry, dependent: :nullify` により枠エントリの `meal_id` は自動で `NULL` になる。
これをRSpecで明示的に確認する。

#### 食事カードへ「延期」アクションを追加する

対象: `frontend/src/features/meal/postponed/`、`frontend/src/components/calendar/calendarComponents/MealCard/index.tsx`

確認ダイアログ文言: `この食事を延期しますか？（食事コメントは失われます）`

`design.md` の「画面イメージと配置意図」に従い「延期」は「削除」の直前へ置く。3行目が2個以下になることは
受け入れる。既存の disabled 「食事複製」は変更しない。

---

## Phase 3: 延期した食事を一覧で見られる

### DoD（完了条件）

- ヘッダーのケバブメニューから「延期した食事」をタップすると画面下部にパネルが開き、
  延期した食事が `createdAt` 降順で料理名と時間帯とともに並ぶ。
- 同じ料理を2回延期していれば、同名の行が2件並ぶ。
- 延期した食事が0件なら空状態が表示される。

### Tasks

- [x] `postponedMeals` queryを作る
  - [x] `usecase/postponed_meals_finder.rb` を作る
  - [x] query classと返却Typeを作り `QueryType` へ登録する
  - [x] RSpecを作成する（`createdAt` 降順、他ユーザーのものが混ざらないこと、0件）
  - [x] green確認する
- [x] 延期一覧パネルを作る
  - [x] `features/meal/postponed/postponedMealsQuery.ts` を追加する
  - [x] `operationComponents/PostponeMeal/ChoosePostponedMeal.tsx` と `usePostponedMealMode.ts` を作る
  - [x] `CalendarHeader` のケバブメニューへ「延期した食事」を追加する
  - [x] `useCalendarMode` へ `usePostponedMealMode` を組み込む
  - [x] Jestを作成する（降順、同名の重複表示、空状態）
  - [x] green確認する
  - [x] `visual-inspector` でパネルのscreenshotを撮り、料理名と時間帯の配置を確認する
    > 確認日時: 2026-08-29
    > 総合結果: ✅ 全項目正常
    > ログ: frontend/inspect/visual/tmp/20260829-add-pending-dish-pool/phase-3/result.md
    >
    > 項目1: ケバブメニューから「延期した食事」パネルが開くこと ✅
    >   期待値: メニューを開くと「延期した食事」項目があり、タップでパネルが開く
    >   結果: CalendarClockアイコン付きで表示され、タップでタイトル「延期した食事」+ ×アイコンのパネルが開いた
    >
    > 項目2: createdAt降順、料理名と時間帯の配置、同名重複表示 ✅
    >   期待値: さば味噌(夜)[id=3] → さば味噌(夜)[id=1] → にんじんの酒蒸し(昼)[id=2] の順で、料理名が左・時間帯が右に表示され、同名でも別行として重複表示される
    >   結果: DOMとGraphQLレスポンスの両方で期待順を確認。同名「さば味噌/夜」がid=3とid=1で別行として表示され、名寄せされていないことを確認
    >
    > 項目3: 時間帯ラジオが存在しないこと ✅
    >   期待値: 「食事登録」パネルと異なり時間帯選択UIが無い
    >   結果: パネル表示中のinput[type="radio"]は0件
    >
    > 補足: 初回実行時、クリック直後の待機が短くフェッチ未完了のタイミングで一瞬空状態が描画された（`postponedMeals ?? []`によるloading中の正常な挙動）。待機を確保した再実行では一貫して3件が表示された。code側の不具合ではなく検証スクリプトのタイミング起因と判断し、修正は不要

### 各task詳細

#### `postponedMeals` queryを作る

対象: `backend/app/domain/business/food/meal/postponed/usecase/postponed_meals_finder.rb`、`backend/app/graphql/queries/`

返却は `id` / `dishId` / `dishName` / `mealType` / `createdAt`。`createdAt` 降順。
current userのものだけを返す。

#### 延期一覧パネルを作る

対象: `frontend/src/components/calendar/calendarComponents/operationComponents/PostponeMeal/`

パネルは既存の `ChooseDish`（「食事登録」パネル、高さ401px、ヘッダーにタイトル + `×`）と同じ型を使う。
**時間帯ラジオは置かない**（延期した食事が `meal_type` を持つため選択不要。`design.md` の要件）。

---

## Phase 4: 延期した食事に日付を与えて食事に戻せる

### DoD（完了条件）

- 一覧から1件タップして帯状パネルへ切り替わり、カレンダーの日付をタップすると、
  **時間帯を訊かれずに**その日にその料理の食事が登録される。
- 登録された食事の時間帯は延期した食事が持っていた値と一致し、食事コメントは空である。
- 確定した行は一覧から消え、同じ料理の他の行は残る。

### Tasks

- [x] `schedulePostponedMeal` mutationを作る
  - [x] `usecase/remove_command.rb` を作る
  - [x] Input Type と mutation classを作り `MutationType` へ登録する
  - [x] RSpecを作成する（`meal_type` の引き継ぎ、`comment` が `NULL`、対象が存在しない場合のrollback）
  - [x] green確認する
- [x] 確定パネルと日付タップの動線を作る
  - [x] `features/meal/postponed/schedulePostponedMealMutation.ts` を追加する
  - [x] `ScheduleChosenPostponedMealForDate.tsx` を作る
  - [x] `PostponeMeal/index.tsx` で一覧と確定パネルを出し分ける
  - [x] `useCalendarMode.onDateClick` へ分岐を追加する
  - [x] Jestを作成する（確定パネルに時間帯選択UIが無いこと、日付タップでmutationが呼ばれること）
  - [x] green確認する
  - [x] `visual-inspector` で確定パネルのscreenshotを撮る
    > 確認日時: 2026-08-29
    > 総合結果: ✅ 全項目正常（既知のdev環境限定の注記あり）
    > ログ: frontend/inspect/visual/tmp/20260829-add-pending-dish-pool/phase-4/result_recheck.md
    >
    > 項目1: 確定パネルに案内文 + 料理名、^ / × アイコンが表示されること ✅
    >   期待値: 「食事を登録したい日を選んでください」と選択した料理名が読める形で表示され、^ と × が右端にある
    >   結果: 初回確認で案内文と料理名が連結・折返しし読みにくい不具合を検出。ScheduleChosenPostponedMealForDate.tsxとPostponeMeal.module.scssを修正（案内文と料理名を別divへ分離し、white-space: nowrap + text-overflow: ellipsis + 親へmin-width: 0を付与）。再確認でDOM計測により2行が重ならず分離して表示されることを確認。^ / × アイコンも表示されている
    >
    > 項目2: 時間帯選択UIが無いこと ✅
    >   期待値: 確定パネルにラジオボタンが無い
    >   結果: input[type="radio"]は0件
    >
    > 項目3: 帯状パネル（コンパクトな高さ）であること ✅
    >   期待値: 一覧パネルと異なりカレンダーが背後に見える程度の高さ
    >   結果: 固定下部パネルの高さは約49px（viewport 844pxに対し約6%）
    >
    > 注記: 画面左下に浮かぶ円形アイコンが確定パネルのテキストへ重なって見える事象を検出したが、DOM調査により`<nextjs-portal>`要素（Next.jsのdev環境専用インジケータ）と判明。本番buildには含まれないdev環境限定の重なりであり、アプリケーションcodeの不具合ではないため修正不要と判断

### 各task詳細

#### `schedulePostponedMeal` mutationを作る

対象: `backend/app/graphql/mutations/meal/postponed/schedule_postponed_meal.rb`

`ActiveRecord::Base.transaction` 内で `Meal::Usecase::AddCommand` → `Meal::Postponed::Usecase::RemoveCommand`
の順に呼ぶ。`meal_type` は延期した食事の値を使い、`comment` は渡さない。
対象が存在しない場合は `raise "指定した延期された食事は存在しません。"` とし、`Meal` も作られないことを確認する。

#### 確定パネルと日付タップの動線を作る

対象: `frontend/src/components/calendar/calendarComponents/operationComponents/PostponeMeal/`、`useCalendarMode.ts`

確定パネルは既存の `AssignChosenDishForDate`（帯状、案内文 + `^` + `×`）と同じ型を使う。
`onDateClick` は既存の `isAssigningSelectedDishMode` / `isMovingMealMode` / `isSwappingMealMode` と
同じ形で分岐を追加する。

---

## Phase 5: 延期した食事がある料理は削除できない

### DoD（完了条件）

- 延期した食事が1件以上ある料理を削除しようとすると
  `この料理は延期された食事があるので削除できません。` で拒否され、`dishes` の行が残る。
- `backend/app/domain/business/food/meal/README.md` に `### 延期された食事（PostponedMeal）` があり、
  削除操作が無いこと・あるべき姿・料理削除が拒否される帰結を、実装を読まずに把握できる。

### Tasks

- [x] 料理削除のガードを追加する
  - [x] `app/models/dish.rb` へ `has_many :postponed_meals` を追加する
  - [x] `Dish::Usecase::RemoveCommand` へガードとコメントを追加する
  - [x] RSpecを作成する（延期した食事がある料理の削除が拒否されること、無ければ削除できること）
  - [x] green確認する
- [x] 延期された食事をREADMEへ記録する
  - [x] `meal/README.md` へ `### 延期された食事（PostponedMeal）` を追加する
  - [x] `food/README.md` のサブモジュール一覧と「Meal と MealFrameEntry の違い」を3モデルの対比へ拡張する

### 各task詳細

#### 料理削除のガードを追加する

対象: `backend/app/models/dish.rb`、`backend/app/domain/business/food/dish/usecase/remove_command.rb`

`dependent` は指定しない（既存の `has_many :meals` と同じ）。既存ガードの直後へ次を置く。

```ruby
# 延期された食事は単体で削除する操作を持たないため、このガードに掛かった料理は
# 「日付を与えて確定 → その食事を削除」という迂回でしか消せない。
# 料理の削除が稀な操作であるため、迂回を許容してガード側を優先している。
raise "この料理は延期された食事があるので削除できません。" if dish_record.postponed_meals.present?
```

#### 延期された食事をREADMEへ記録する

対象: `backend/app/domain/business/food/meal/README.md`

`### 延期された食事（PostponedMeal）` を新設し、次を書く。code側コメントと同じ文を置かない。

- `PostponedMeal` は単体で削除する操作を持たない。一覧から取り除く手段は日付を与えて確定させることだけである
- あるべき姿は延期単体の削除アクションを用意すること。エッジケースであるため見送っている
- この制約により、延期された食事がある料理は `Dish::Usecase::RemoveCommand` で削除を拒否される

このsectionをPhase 1ではなくここへ置くのは、3点目が本phaseの実装が入るまで成立しないためである。
1点目と2点目だけを先に書いて分割すると、一つのsectionが複数phaseへ散る。

あわせて `backend/app/domain/business/food/README.md` を拡張する。同fileは「料理未決 → `MealFrameEntry`」
という片方の未決軸しか説明しておらず、鏡像である「日付未決 → `PostponedMeal`」が欠けている。
サブモジュール一覧へ `Meal::Postponed` を加え、「Meal と MealFrameEntry の違い」を3モデルの対比へ広げる。

| | 決まっているもの | 未決 |
| --- | --- | --- |
| `Meal` | 日付 + 時間帯 + 料理 | なし |
| `MealFrameEntry` | 日付 + 時間帯 + 枠 | 料理 |
| `PostponedMeal` | 料理 + 時間帯 | 日付 |

---

## Phase 6: 延期しても食事コメントが失われない

> 実装後のユーザー動作確認で判明した仕様追加。経緯は `implementation_review.md` の論点1・論点2。
> `PostponedMeal` は退避エンティティであり、保存を既定として落とす項目に理由を要求する。
> `meals` の全項目を分類した結果、理由をもって落とせるのは `date` だけだった。

### DoD（完了条件）

- 食事コメントを書いた食事を延期すると、一覧にそのコメントが表示される。
- その行に日付を与えて戻すと、登録された食事に元の食事コメントが復元される。
- コメントのない食事を延期した行では、一覧の2行目が出ず行の高さが伸びない。
- 延期時に確認ダイアログが出ない。

### Tasks

- [x] `postponed_meals` へ `comment` を追加する
  - [x] migration fileを作成する
  - [x] migrationを実行し `db/schema.rb` の差分を確認する
  - [x] **ここで作業を停止し、migration結果と commit・push の要否をユーザーに確認する**

- [ ] backend で `comment` を引き継ぎ・復元する
  - [ ] `Meal::Postponed::Root` へ `attribute :comment, :string` と `validates :comment, presence: false` を追加する
  - [ ] `Factory` / `PostponedMeal` model の往復（`build_existing_root_from_id` / `persist_from_...`）へ `comment` を通す
  - [ ] `Usecase::AddCommand` が `comment` を受け取る
  - [ ] `postpone_meal.rb` が元の食事の `comment` を渡す
  - [ ] `schedule_postponed_meal.rb` が `comment` を新しい `Meal` へ渡す
  - [ ] `postponed_meals_finder.rb` と返却Typeへ `comment` を追加する
  - [ ] RSpecを作成・変更する（引き継ぎ、復元、`comment` が `NULL` の場合、**延期と復元の1往復で `dish_id` / `meal_type` / `comment` が一致すること**）
  - [ ] `docker compose exec backend bundle exec rspec` でgreenを確認する

- [ ] frontend で確認ダイアログを廃止し、一覧へコメントを表示する
  - [ ] `MealCard/index.tsx` の `window.confirm` を削除する
  - [ ] `postponedMealsQuery.ts` と生成型へ `comment` を追加する
  - [ ] `ChoosePostponedMeal.tsx` で料理名の下へコメントを表示する（`MealCard` と同じ小さめのイタリック、コメントなしなら2行目を出さない）
  - [ ] Jestを作成・変更する（確認ダイアログなしでmutationが呼ばれること、コメントがある行だけ2行目が出ること）
  - [ ] `docker compose exec frontend yarn test` でgreenを確認する
  - [ ] `visual-inspector` で一覧パネルのscreenshotを撮り、コメント有無で行の高さが変わることを確認する

### 各task詳細

#### `postponed_meals` へ `comment` を追加する

対象: `backend/db/migrate/`、`backend/db/schema.rb`

`t.string :comment`（nullable）。`meals.comment` と同じ型・同じ nullable 性にする。
コメントなしの食事が存在するため NOT NULL にしない。

DB migration であるため、`task-design-discussion.md` の論点10 により、完了時に commit・push の
要否をユーザーへ確認する。開発環境のDBが共有リソースであり、スキーマ変更の記録がローカルにしか
無い状態を避けるためである。

#### backend で `comment` を引き継ぎ・復元する

`Root` へ属性を足すため、`design.md` の「前提とする既存仕様」にある3箇所連動
（`factory.rb` / `build_existing_root_from_id` / `persist_from_...`）を必ず揃える。
片方だけ変更すると取得はできるが保存されない不整合が起きる。

#### frontend で確認ダイアログを廃止し、一覧へコメントを表示する

対象: `MealCard/index.tsx`、`operationComponents/PostponeMeal/ChoosePostponedMeal.tsx`、`features/meal/postponed/`

確認ダイアログを外す根拠は `implementation_review.md` 論点2 にある。`comment` を引き継ぐと
「コメントが黙って消えるのを防ぐ」という設置理由が成立しなくなり、延期で失われるのは
ユーザーが意図的に捨てている `date` だけになる。既存の「他の日へ」も日付を変えるが確認を求めていない。

---

## Phase 7: 品質checkと修正

### DoD（完了条件）

- 全testがgreen
- repository全体のlintにerrorがない
- 最終screenshotで見た目を目視確認済み

> ⚠️ screenshot確認は最後にまとめて行うものではない。UIへ変更を加えた各phaseのDoDにscreenshot確認を含めている。このphaseでは全体の最終確認だけを行う。

### Tasks

> ⚠️ この phase は一度 Phase 5 完了時点のコードに対して実施し、test 738/188 green・lint error zero を
> 確認済みだった。その後 Phase 6（食事コメントの退避）でコードが変わるため、checkbox を未完了へ戻している。
> Phase 6 完了後に全項目を再実行する。

- [ ] 全test実行
  - [ ] `docker compose exec backend bundle exec rspec` がgreenであることを確認する
  - [ ] `docker compose exec frontend yarn test` がgreenであることを確認する
- [ ] lint実行（新規file）
  - [x] 新規fileに対してlintを実行する
  - [x] errorがあれば修正して再実行する
  - [x] error zeroを確認する
- [x] repository全体のlintを実行する
  - [x] `docker compose exec backend bundle exec rubocop` を実行する
  - [x] `docker compose exec frontend yarn lint` を実行する
  - [x] 新規codeが既存codeへ与えた影響を確認する
  - [x] errorがあれば修正して再実行する
  - [x] error zeroを確認する
- [ ] 最終screenshotで見た目を目視確認する
  - [ ] pluginの`visual-inspector` skillをchildとして使いscreenshotを撮る
  - [ ] 食事カードのアクション、一覧パネル、確定パネルの3画面を確認する
  - [ ] 問題があれば修正して再確認する
  - ⚠️ `npx playwright`またはPlaywright toolを直接呼ばない。必ずpluginの`visual-inspector` skillを使う。

## Documentation reviewと実装後振り返り

- [ ] code readingまたは実装で永続化候補を得た場合、その場でdoc-enricherを提案modeで適用する
  - [ ] 提案がある場合だけユーザー承認後に既存READMEまたは既存docsへ反映する
  - [ ] 提案・承認判断を別taskへ先送りしない
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

ユーザーが実際に機能を使い、意図どおりであることを確認した。

### Tasks

- [ ] agentが`visual-inspector`で動作確認を行い、観測結果とscreenshotを報告する
  - ⚠️ 自分で確認せずにユーザーへ確認を促さない（`frontend/docs/ai_guideline/development_standard/testing.md`）
  - [ ] 確認が及んでいない範囲も明示して報告する
- [ ] ユーザーに動作確認を依頼する
- [ ] feedbackがあれば、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用し、decisionをcallerへ返す
  - [ ] designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す
  - [ ] feedbackがなければ`[x] ~~feedback収集~~（feedbackなし）`の形式で完了扱いにする

---

## 完了後のaction

> ⚠️ 動作確認phaseが完了するまでcommit、push、PRを促したり実行したりしない。急かすことも禁止する。

- [ ] commit（phase単位かつ意味単位で分割）
  - MUST: まとめて一commitにしない
  - phaseごとに別commitにする
  - 同一phase内でも意味的に異なる変更を分割する（DB migration / domain model / GraphQL / frontend）
  - steering成果物のうち`design.md`と`task-design-discussion.md`は実装より前に確定しているため、最初の実装commitより前へ置く
  - `tasklist.md`のcheckbox確定は実装commitより後へ置く
  - ユーザーが一部だけ承認した場合は承認範囲だけをcommitし、残りは待つ
  - ユーザーが不要と回答した場合は`[x] ~~commit~~（ユーザーが不要と回答）`の形式で完了扱いにする

- [ ] current branchをpushしてPRを作成する
  - [ ] commit taskの結果としてlocal commitが実際に一件以上あることを確認する。一件もなければpush・PRを実行しない
  - [ ] current branchが公開可能なnon-default branchであることを確認する
  - [ ] `git push -u origin <current-branch>`を実行する
  - [ ] pluginのskills directory配下にある `tasklist-executor/scripts/github/create_or_get_pr.sh` を実行する
    - pathの起点はpluginのskills directoryである。利用先repositoryからの相対pathではない
    - 同じhead branchのopen PRがあれば新規作成せずそのURLを返す
    - `feature-<issue番号>`契約によりbranch名からissue番号を導いてPR bodyへ`Closes #<番号>`を入れる
