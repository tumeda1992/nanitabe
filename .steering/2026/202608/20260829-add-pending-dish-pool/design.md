# Design: 食事の延期（食べられなかった食事を日付未定で取っておき、後で日付を決めて食べる）

## 元の依頼内容

```text
保留枠を作りたい。
1度食事登録したんだけど、突然の予定とかでその料理が食べられなかったときに保留しておいて、将来的に食事に割り当てるというためのプール。
保存の意味もあるし、assign-dishみたいに、保存したのを後で吐き出すというのも含める。

一旦は1つの箱でいいんだけど、将来的にはAmazonの欲しいものリストみたいにフォルダというか複数の箱があり、
「蒲田で行きたい場所」など、キュレーションされた保留群にしてもいい（キュレーションという言葉はニュアンスで言ってるからユビキタス言語として扱ってほしくない）
その箱は、保留群から外れても、明示的に解除されなかったら解除しないというのもあり。でもそれは保留群とは別に扱ってもいいかもな
```

---

## 1. TL;DR

予定変更で食べられなかった料理は、現状「削除する」か「別の日へ移す」しか選択肢がなく、
**再訪の意思はあるが日付を決められない料理**の置き場所がない。削除すると再訪の意思ごと失われ、
別の日へ移すと決められない日付を無理に決めることになる。この2択の隙間を埋める。

そこで「この料理を、この時間帯に、いつか食べたい」という意思を表す**延期された食事**を、`Meal` とは別のエンティティ
`Business::Food::Meal::Postponed::Root`（テーブル `postponed_meals`）として新設する。
食事を延期する操作と、延期された食事に日付を与えて食事登録する操作を用意する。
終了時には、食べられなかった食事をカレンダーから外しつつ、その料理をその時間帯に食べたいという意思は失わずに保持でき、
後から任意の日へ戻せる状態が成立している。

---

## 前提とする既存仕様

<!-- 確認元: backend/app/domain/business/food/README.md, meal/README.md, 各root.rb, db/schema.rb,
     frontend/src/components/calendar/calendarComponents/ 配下 -->

- `Business::Food::Meal::Root`（`meals`テーブル）: 「ある日に、ある料理を食べた記録」。
  `user_id` / `date` / `meal_type` / `dish_id` がすべて `null: false`。`comment` のみ任意。
  **`dish_id` を nullable にすることは README で明示的に禁止**されている（料理未決定は別モデルで表現する、という設計判断）。
- `Business::Food::Meal::Frame::Root`（`meal_frames`テーブル）: **「枠」= 再利用可能な枠マスタ**（「パスタ」「魚料理」など）。
  ユーザー別に一元管理され、同じ枠を複数日に使い回す。
- `Business::Food::Meal::Frame::Entry::Root`（`meal_frame_entries`テーブル）: カレンダー上の枠エントリ。
  `date` / `meal_type` / `meal_frame_id` が必須、`meal_id` が nullable。
  `meal_id` が入ると「枠に食事が割り当てられた」状態。`assign_meal` / `unassign_meal` を持つ。
- **「日付は決まっているが料理が未決定」は `Meal` に nullable カラムを足さず、`MealFrameEntry` という別モデルで表現された**
  という前例がある（`food/README.md` の「Meal と MealFrameEntry の違い」）。
- `mealsForCalender` クエリは `meals`（`mealFrameEntryId` 付き）と `frameEntries`（`meal_id IS NULL` のみ）を返す。
- 既存の「assign-dish」UI flow: カレンダーが `AssigningDishMode` に入り、
  ① `ChooseDish`（`DishSearchPanel` で料理を選ぶ + 時間帯選択 + 連続登録チェック）
  → ② `AssignChosenDishForDate`（日付をタップして確定）の2段階。`useAssignDishMode` が状態を持つ。
- `MealCard` のアクション展開エリアに「食事編集 / 評価 / 料理編集 / 名前コピー / 他の日へ / 日付交換 / 食事複製(disabled) / 枠解除 / 削除」が並ぶ。
- `Business::Food::Dish::Usecase::RemoveCommand` は、その料理を参照する `meals` が1件でもあれば
  `raise "この料理は登録されている食事があるので削除できません。"` で削除を拒否する。
  コード上のコメントは「ユースケースがはっきり定まっていないので、定まるまで安全に倒す」であり、
  意図的に保守側へ倒した判断である。`Dish` は `has_many :meals`（`dependent` 指定なし）を持つ。
- アーキテクチャ制約:
  - 異なる集約をまたぐオーケストレーションは**プレゼンテーション層（GraphQL resolver）**が担う。Command は自集約内に限定。
  - 集約ルートと子エントリが不可分なら resolver が1トランザクションで完結させる（複数 mutation 呼び出しは禁止）。
  - ドメインメソッド名は行為・意図を表す動詞にする（`set_xx` / `change_xx` / `update_xx` は禁止）。
  - フィールド追加の判断: 「このエンティティはこのフィールドなしで完結した意味を持つか？」→ Yes なら nullable 追加ではなく別エンティティへ切り出す。
  - FK の向きの判断: 独立して存在できるエンティティに nullable FK を足さない。関連付けの責務は関連付けのために存在するエンティティが担う。
  - ドメインモジュール帰属: 「既存のドメイン概念の文脈を外れても意味を持つか？」→ No なら既存モジュール下に置く。
  - Root に属性を足すときは `factory.rb` / `build_existing_root_from_id` / `persist_from_xxx_root` の3箇所を連動させる。

---

## 2. 要件（Requirements）

### MUST（必達）

- カレンダー上の食事を延期できる。このとき元の `meals` の行は削除され、`postponed_meals` の行が1件作られる。
- 延期された食事は、元の食事から `dish_id` / `meal_type` / `comment` を引き継ぐ。落とすのは `date` だけであり、
  日付が未決であることが延期の定義であるため。退避エンティティは保存を既定とし、落とす項目に理由を要求する。
- 同じ料理を重複して延期できる。延期するたびに1件作られ、片方を戻しても他方は残る。
- 延期された食事の一覧を見られる。
- 延期された食事に**日付を指定するだけで**食事として登録できる。時間帯は延期された食事が持つ値を使い、選択を求めない。
- ユビキタス言語は「延期」「延期された食事」とする。依頼文の「保留枠」は採らない（「枠」が `Meal::Frame` と衝突するため）。
- 延期された食事が1件でも存在する料理は削除できない。
- 枠に紐付いた食事を延期すると、枠はその日に残り未割り当てになる。

### SHOULD（できれば）

- 延期の操作は既存の assign-dish と同じ2段階フローをなぞる。ユーザーの学習コストを増やさないため。

### MAY（あれば嬉しい）

- なし。

### 非目標

- 複数の箱（「蒲田で行きたい場所」等のグループ分け）。今回は扱わない。
- **一度も日付が決まっていない対象を `postponed_meals` へ入れること。** 「延期」はこの用途を括れない。
  これは認識したうえで受け入れた制約である。確定していない用途まで覆う語を選ぶと、現在の実態より広い抽象を先に置くことになり、
  目的の異なるデータが同じテーブルへ混入する余地を作る。この用途を運用するときは、コストを払って移行する。
- 「キュレーション」をユビキタス言語として採用すること（依頼者が明示的に排除）。
- 延期された食事を一覧から削除する操作（「もう食べない」）。あるべき姿はこれを用意することだが、
  料理の削除自体が稀で、そのうち延期リストにだけ存在する料理を消したいケースはさらに稀なエッジケースであるため
  今回は扱わない。この制約は code コメントと `meal/README.md` へ残す。
- 延期された食事の件数をカレンダー上へ表示すること。
- 延期された食事のコメントを、延期中に編集すること。引き継ぎと復元のみを扱う。

### 受け入れ基準

- 食事カードのアクションから延期でき、確認ダイアログなしで `meals` の行が消え `postponed_meals` へ1件増える。
- 食事コメントを書いた食事を延期すると、一覧にそのコメントが表示され、日付を与えて戻すと食事コメントが復元される。
- 枠に紐付いた食事を延期すると、枠がその日に未割り当てとして残る。
- ケバブメニューの「延期した食事」から一覧が開き、`created_at` 降順で料理名と時間帯が並ぶ。
- 一覧から1件選び日付をタップすると、時間帯を訊かれずに食事が登録され、一覧から消える。
- 同じ料理を2回延期すると一覧に2件並び、片方を確定してももう片方が残る。
- 延期された食事がある料理を削除しようとすると拒否される。
- `docker compose exec backend bundle exec rspec` と `docker compose exec frontend yarn test` が通る。

---

## 3. 完成後の姿

<!-- 採用予定の outcome section:
     interaction-flow.md → screen.md → data.md → caller-contracts.md → code-structure.md
     （catalog.md の代表パターン「dataを更新するAPIを画面へ適用する」に該当）
     未決の設計判断が残るため本文は未着手。骨格合意後に上位の判断から順に埋める。 -->

### 操作フロー

**ケース: 食べられなかった食事を延期する**

1. ユーザーがカレンダー上の食事カードをタップし、アクション展開エリアの「延期」をタップする
2. frontendが `postponeMeal({ mealId })` を1回呼ぶ。確認ダイアログは出さない
3. serverがGraphQL resolverで1トランザクションを開き、`PostponedMeal` の作成と `Meal` の削除を順に行う
4. `postponed_meals` に `user_id` / `dish_id` / `meal_type` / `comment` を引き継いだ行が1件増える
5. `meals` の該当行が削除され、紐付いていた `meal_frame_entries.meal_id` が `NULL` へ戻る
6. カレンダーが再取得され、その日からカードが消える。枠が紐付いていた場合は未割り当ての枠として残る

**ケース: 延期された食事を日付へ戻す**

1. ユーザーがヘッダー右のケバブメニューをタップし、「延期した食事」をタップする
2. frontendが `postponedMeals` を1回呼び、下部パネルへ一覧を表示する
3. ユーザーが一覧から1件をタップする
4. パネルが帯状の確定パネルへ切り替わり、「食事を登録したい日を選んでください」と料理名を表示する
5. ユーザーが日付カードを1回タップする
6. frontendが `resumePostponedMeal({ postponedMealId, date })` を1回呼ぶ
7. serverがGraphQL resolverで1トランザクションを開き、`Meal` の作成と `PostponedMeal` の削除を順に行う
8. `meals` に行が1件増える。`meal_type` と `comment` は延期された食事が持つ値
9. `postponed_meals` の該当行が削除される
10. カレンダーが再取得され、指定日に食事が現れる。パネルは閉じる

**失敗・操作中断・境界case:**

| case | success flowからの分岐 | call・stateへの影響 | actorの観測と次の操作 | 参照 |
| --- | --- | --- | --- | --- |
| コメントなしの食事を延期 | 分岐しない（success flow内） | `postponed_meals.comment` が `NULL` になる | 一覧にコメント行が出ない。行の高さは伸びない | データモデル |
| 延期一覧が空 | step 2 の後 | query呼出済み、data不変 | パネルに空状態が出る。`×` で閉じるしかない | 画面イメージ |
| 戻す対象が他端末で既に戻されていた | step 7 でresolverが対象行を見つけられない | トランザクションがrollbackし、`Meal` も作られない | error表示。一覧を再取得すると当該行が消えている | callerが依存するcontract |
| 枠に紐付いた食事を延期 | 分岐しない（success flow内） | `meal_frame_entries.meal_id` が `NULL` になる | 枠だけがその日に残り、未割り当て表示になる | データモデル |

### 画面イメージと配置意図

実測は `frontend/inspect/visual/tmp/20260829-112118-defer-meal-ui-survey/`（viewport 390×844、モバイル幅）。
以下は実測した現状に対する差分である。

**食事カードのアクション展開エリア（`grid-cols-4`）:**

```text
┌────────────────────────────────────┐
│ 食事編集   評価     料理編集   名前コピー │
│ 他の日へ   日付交換  食事複製   枠解除   │
│                    (disabled) (枠時のみ)│
│ 延期      削除                        │  ← 3行目
└────────────────────────────────────┘
```

配置意図: 「延期」は「削除」の直前へ置く。どちらも食事をカレンダーから消す操作であり、
隣接させることで「消すが意思は残す」と「消して意思も捨てる」の対比が読める。
3行目が埋まらないことは受け入れる。`grid-cols-4` は余ったセルを空けるだけで崩れない。

**延期一覧パネル（下部固定、「食事登録」パネルと同じ型）:**

```text
┌────────────────────────────────────┐
│ 延期した食事                      ×  │  ← ヘッダー（高さ401px = viewport約47%）
├────────────────────────────────────┤
│ 豚の角煮                        夜  │
│   多めに作る                        │  ← コメントがある行だけ2行目が出る
│ レバニラ炒め                     夜  │
│ カオマンガイ                     昼  │
│ 豚の角煮                        夜  │  ← 重複は許されるため同名が並ぶ
└────────────────────────────────────┘
```

配置意図: 料理名を左の判断起点に置き、時間帯を右端へ寄せる。コメントは料理名の下へ小さめのイタリックで置き、
`MealCard` の食事コメントと同じ扱いにする。コメントがない行では2行目を出さず、行の高さを揃える。
引き継いだコメントが見えないと、引き継がれたことをユーザーが確認できない。

実測した「食事登録」パネルの「時間帯」ラジオはここに置かない。延期された食事が時間帯を持つため
選択が不要である。

**今回変わる状態別の見え方:**

| 状態 | 表示 | 操作可否 | 次の操作 |
| --- | --- | --- | --- |
| 一覧に1件以上 | 料理名 + 時間帯の行が `created_at` 降順で並ぶ | 行をタップして選択できる | 選択すると帯状パネルへ遷移 |
| 一覧が空 | 「延期した食事はありません」 | 選択不可。`×` のみ | パネルを閉じる |
| 日付選択中 | 帯状パネルに案内文 + 選択した料理名 | カレンダーの日付カードをタップできる | 日付タップで確定、`^` で選び直し、`×` で中止 |

**inputの供給元:**

| input | 供給元 | 受渡し経路 | 未取得・失敗時 |
| --- | --- | --- | --- |
| 延期された食事の一覧 | `postponedMeals` query | `features/meal/postponed/usePostponedMeal.ts` → 一覧パネル component | 空状態を表示する |
| 選択中の延期された食事 | パネル内のlocal state | `usePostponedMealMode` が保持し、確定パネルへ渡す | 未選択なら確定パネルへ遷移しない |
| 確定する日付 | カレンダーの日付タップ | `useCalendarMode.onDateClick` → `usePostponedMealMode` | タップされるまで確定しない |

### データモデル

`PostponedMeal`（`postponed_meals`）は「この料理を、この時間帯に、いつか食べたい」という意思を表す。未決なのは日付だけである。

```text
postponed_meals
  id
  user_id      NOT NULL
  dish_id      NOT NULL
  meal_type    NOT NULL
  comment      NULL可
  created_at   NOT NULL
  updated_at   NOT NULL
```

一意制約は張らない。同じ料理を重複して延期できる。

`PostponedMeal` は退避エンティティ（新しいデータを作って元データを削除する）であるため、保存を既定とし、
落とす項目に理由を要求する。`meals` の全項目を分類した結果は次のとおりで、未分類はない。

| `meals` の項目 | 扱い | 理由 |
| --- | --- | --- |
| `id` | 引き継がない | 行の識別子であり元データの内容ではない |
| `user_id` / `dish_id` / `meal_type` | 引き継ぐ | — |
| `date` | 落とす | 日付が未決であることが延期の定義そのもの。落とす唯一の項目 |
| `comment` | 引き継ぐ | 落とす理由を書けない |
| `created_at` / `updated_at` | 引き継がない | ライフサイクルmetadataであり元データの内容ではない |

`comment` を NOT NULL にしないのは、コメントなしの食事が存在するためである（`meals.comment` も nullable）。
延期固有のメモと並び順は持たない（`created_at` 降順で足りる）。

既存モデルとの対称性:

| | 決まっているもの | 未決のもの |
| --- | --- | --- |
| `MealFrameEntry` | 日付 + 時間帯 + 枠 | 料理 |
| `PostponedMeal` | 料理 + 時間帯 | 日付 |

`Meal` は3つすべてが決まった状態であり、2つの未決モデルがそれぞれ異なる軸を空けている。

**具体的なrow例:**

| id | user_id | dish_id | meal_type | comment | created_at |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 | 42（豚の角煮） | 3（夕食） | 多めに作る | 2026-08-29 20:10 |
| 2 | 1 | 42（豚の角煮） | 3（夕食） | `NULL` | 2026-08-30 20:05 |
| 3 | 1 | 17（カオマンガイ） | 2（昼食） | `NULL` | 2026-08-30 12:00 |

典型case:
- 同じ料理を2回延期: id 1 と 2。`comment` の有無だけが異なる。両方 `NULL` なら区別は `id` と `created_at` だけ
- コメントなしで延期: id 2・3。`comment` は `NULL`。一覧では2行目を出さない
- 時間帯違い: id 3 は `meal_type` が異なる
- 空: 行なし。一覧は空状態を表示する

**更新・削除後のdata:**

| operation | 操作前 | 操作後 | relation・cascade・保持値 |
| --- | --- | --- | --- |
| 食事を延期する | `meals` に `{date: 2026-08-29, meal_type: 3, dish_id: 42, comment: "多めに作る"}` | `meals` の行は削除。`postponed_meals` に `{dish_id: 42, meal_type: 3, comment: "多めに作る"}` が1件 | `comment` はそのまま引き継がれる。落ちるのは `date` だけ。紐付いていた `meal_frame_entries.meal_id` は `NULL` へ |
| 延期された食事を戻す | `postponed_meals` id=1（`comment: "多めに作る"`） | `postponed_meals` id=1 は削除。`meals` に `{date: 指定日, meal_type: 3, dish_id: 42, comment: "多めに作る"}` が1件 | id=2 は残る。同じ料理の別の意思であるため |
| 料理を削除する | `dishes` id=42、`postponed_meals` に id 1・2 | 削除は拒否され、すべての行が不変 | `Dish::Usecase::RemoveCommand` が `postponed_meals` の存在を検査して `raise` する |

**不変条件:**

- `postponed_meals` の行は必ず `dish_id` と `meal_type` を持つ。日付は持たない
- 延期と復元を1往復しても、`dish_id` / `meal_type` / `comment` は元の食事と一致する。落ちるのは `date` だけ
- 同じ `(user_id, dish_id, meal_type)` の行が複数存在してよい。重複は「複数回食べたい」という意思を表す
- `postponed_meals` の行が増減しても `meals` の他の行、`meal_frames`、`meal_frame_patterns` は変化しない

### callerが依存するcontract

**mutation / query:**

```graphql
postponeMeal(input: { mealId: Int! }): { postponedMealId: Int! }
schedulePostponedMeal(input: { postponedMealId: Int!, date: ISO8601Date! }): { mealId: Int! }
postponedMeals: [PostponedMealForList!]!
```

| contract | caller | input contract | 成功時のresult | 成功時のside effect |
| --- | --- | --- | --- | --- |
| `postponeMeal` | 食事カードのアクション展開エリア | `mealId` は current user の食事 | `postponedMealId` | `meals` の行を削除し `postponed_meals` へ `dish_id` / `meal_type` / `comment` を引き継いで1件作成。紐付く `meal_frame_entries.meal_id` は `NULL` へ戻る |
| `schedulePostponedMeal` | 延期一覧の確定パネル | `postponedMealId` は current user のもの、`date` 必須 | `mealId` | `postponed_meals` の行を削除し `meals` へ1件作成。`meal_type` と `comment` は延期された食事の値 |
| `postponedMeals` | 延期一覧パネル | なし | `id` / `dishId` / `dishName` / `mealType` / `comment` / `createdAt` を `createdAt` 降順で | なし |

命名根拠: 戻す操作を `schedule` としたのは、この操作で起きるのが「日付が未決だった食事に日付を与えて
確定させる」ことだからである。`re` を付けないのは、元の日付へ復すのではなく新しい日付を決めるため。
`restore` は「元へ戻す」と読めて不正確、`resume` は何を再開するのかが曖昧であり、いずれも採らない。

**失敗contract:**

| 条件 | caller-facingなerror | state・side effectの保証 |
| --- | --- | --- |
| `mealId` が存在しない / 他ユーザーのもの | `raise "指定した食事は存在しません。"` | data不変 |
| `postponedMealId` が存在しない（他端末で確定済み等） | `raise "指定した延期された食事は存在しません。"` | トランザクションrollback。`Meal` も作られない |
| 延期された食事がある料理を削除しようとした | `raise "この料理は延期された食事があるので削除できません。"` | `dishes` の行は残る |

既存の `Meal::Usecase::RemoveCommand` 等が同じ形式で `raise` しているため、それに揃える。

### codeの責務配置と依存構造

**配置と責務:**

```text
backend/app/domain/business/food/meal/postponed/  ← 延期された食事の集約
  root.rb                        set_id 以外の振る舞いを持たない
  factory.rb                     モジュール外からのroot生成
  usecase/add_command.rb         延期された食事を1件作る
  usecase/remove_command.rb      延期された食事を1件消す
  usecase/postponed_meals_finder.rb  created_at 降順で返す
backend/app/models/postponed_meal.rb              ← 永続化
backend/app/graphql/mutations/meal/postponed/     ← 2集約をまたぐorchestration
  postpone_meal.rb / schedule_postponed_meal.rb
frontend/src/features/meal/postponed/             ← query/mutationのfacade
frontend/src/components/calendar/calendarComponents/operationComponents/PostponeMeal/
```

**境界のrule:**

- `Meal::Postponed::Usecase::*` は自集約の内部だけを扱い、`Meal` を知らない
- 2集約をまたぐorchestrationは **GraphQL resolver** が1トランザクションで担う
  （architecture doc「異なる集約をまたぐオーケストレーションはプレゼンテーション層」）
- 既存の `Meal::Usecase::AddCommand` / `RemoveCommand` をそのまま再利用し、`Meal` 側へ新しいCommandを足さない
- `Meal::Postponed::Root` に振る舞いを置かない。延期された食事は生成後に変化せず、日付を与える操作は
  `Meal` の生成であってこの集約の状態変更ではない
- `Meal::Root` に `postpone` 等を足さない。延期は `Meal` の状態変化ではなく削除である
- `frontend/src/features/` は backend のドメイン階層を反映する（frontend architecture doc）。
  操作モードのcomponentは既存の `AssignDish` / `MoveMeal` / `SwapMeals` と同じ `operationComponents/` へ並べる

**制約の記録先:**

延期された食事は単体で削除する操作を持たない。この制約を2箇所へ、内容を分けて残す。

| 置き場所 | 持つ内容 | 読者 |
| --- | --- | --- |
| `Dish::Usecase::RemoveCommand` のガード直上コメント | なぜこのガードがこの形なのか。迂回が必要でもガードを優先する理由 | 削除が拒否される理由を追う人 |
| `business/food/meal/README.md` の `### 延期された食事（PostponedMeal）` | 削除操作が無いこと、あるべき姿は延期単体の削除アクションであること、その帰結として料理削除が拒否されること | 延期機能の設計を変える人 |

同じ文を両方へ置かない。ガードで弾かれた人はREADMEを読まず、延期機能を設計する人は `Dish` のCommandを
読まないため、一箇所へ寄せるとどちらかへ届かない。

**全体のcall関係:**

```text
postponeMeal          -> Meal::Postponed::Usecase::AddCommand -> Meal::Usecase::RemoveCommand
schedulePostponedMeal -> Meal::Usecase::AddCommand -> Meal::Postponed::Usecase::RemoveCommand
postponedMeals        -> Meal::Postponed::Usecase::PostponedMealsFinder
removeDish（既存）    -> Dish::Usecase::RemoveCommand（postponed_meals の存在チェックを追加）
```

---

## 4. リスクと対策

| リスク | 対策 |
| --- | --- |
| `PostponedMeal` はドメインpath平坦化の語順から反転する唯一のARモデルになり、次の実装者が規則を誤解する | `Meal::README.md` へ逸脱と理由を記録する（doc-enricher で扱う） |
| 「蒲田で行きたい場所」用途が来たとき `postponed_meals` へ流用され、目的の異なるデータが混入する | 非目標として design に明記済み。流用ではなく移行で対応する |
| 延期リストにだけ存在する料理を削除したいとき、確定してから食事を消す迂回が必要になる | 認識したうえで受け入れた帰結。料理の削除は稀で重い操作のため頻度は低い。延期を取り消す操作が必要になった時点で解消する |
| 2集約をまたぐorchestrationをCommandへ内包してしまい、ドメイン境界が崩れる | resolver が1トランザクションで担うことを code-structure の境界ruleへ明記済み |

---

## 5. テスト方針

backend / frontend とも test-first、container 内実行（`backend/docs/ai_guideline/development_standard/testing.md`、
`frontend/.../testing.md`）。

**backend（RSpec、`docker compose exec backend bundle exec rspec`）**

- `Meal::Postponed::Usecase::AddCommand` / `RemoveCommand` / `PostponedMealsFinder`: 自集約の単体
- `PostponedMeal` model: `build_existing_root_from_id` と `persist_from_...` の往復で属性が失われないこと
- `mutations/meal/postponed/postpone_meal`: `meals` の削除と `postponed_meals` の作成が1トランザクションで
  起きること、紐付く `meal_frame_entries.meal_id` が `NULL` になること
- `mutations/meal/postponed/schedule_postponed_meal`: `meal_type` と `comment` が引き継がれること、
  対象が存在しない場合にrollbackして `Meal` が作られないこと
- 延期と復元の1往復で `dish_id` / `meal_type` / `comment` が元の食事と一致すること（退避の全量保存の回帰）
- `Dish::Usecase::RemoveCommand`: 延期された食事がある料理の削除が拒否されること

**frontend（Jest、`docker compose exec frontend yarn test`）**

- 一覧パネル: `created_at` 降順で並ぶこと、同名の行が重複して並べること、空状態
- 確定パネル: 時間帯の選択UIが存在しないこと（論点2の決定が守られていることの回帰）
- 食事カード: 「延期」が表示され、タップすると確認ダイアログなしで mutation が呼ばれること
- 一覧パネル: コメントがある行だけ2行目が出ること

**UI動作確認**

自動テストとは別に、`visual-inspector` で実際の画面を撮影して確認する。`frontend/.../testing.md` の
「UI変更の動作確認」に従い、agent が確認・報告したうえでユーザーが必要と判断したときだけ触る。
commit / push / PR はユーザーが報告を受けて進めてよいと述べた時点で可能になる。

---

## （付録）変更の実行区分

### task-design内で対象成果物へ適用済み

| 対象 | 反映内容 | validation結果 | 参照するdesign section |
| --- | --- | --- | --- |
| `backend/app/domain/business/food/meal/README.md` | `Meal::Frame::*` sectionへ「食事を削除すると枠エントリの `meal_id` は `NULL` へ戻り、枠はその日に残って未割り当てになる」と、その設計意図を追加 | 既存の `has_one :meal_frame_entry, dependent: :nullify` から導かれる挙動であることを `app/models/meal.rb` で確認 | [操作フロー](#操作フロー) |
| `backend/docs/ai_guideline/development_standard/README.md` / `frontend/docs/ai_guideline/development_standard/README.md` | `## リポジトリ非依存の共通標準` を同一文で追加。plugin docs入口への導線、置き場所の判断の問い、直接編集禁止と `escalate-plugin-skill-fix` 経由の明記 | 2 fileへ適用し内容が一致することを確認 | 本sectionの下記「導線を置いた理由」 |

**導線を置いた理由:** 命名とエンティティ設計の標準は、今回のsteeringで plugin 正本
（`plugins/tumeda-dev/docs/development_standards/`）へ置いた。利用先にその導線がないと、
次に標準を書こうとする者が置き場所を毎回判断することになる。判断の問いを添えて導線だけを置き、
収録fileは列挙しない。列挙するとplugin側の増減で利用先が腐るため。

### task-design内の対象成果物反映待ち

なし

### execution plan対象

| 対象 | 掲載理由 | 参照するdesign section |
| --- | --- | --- |
| `postponed_meals` の migration | 本番application coding（schema変更） | [データモデル](#データモデル) |
| `Meal::Postponed` 集約（`root.rb` / `factory.rb` / `usecase/` 3件）と `models/postponed_meal.rb` | 本番application coding。RSpecで正しさを確認する | [codeの責務配置と依存構造](#codeの責務配置と依存構造) |
| `mutations/meal/postponed/` 2件、`postponedMeals` query、`MutationType` / `QueryType` 登録 | 本番application coding | [callerが依存するcontract](#callerが依存するcontract) |
| `Dish::Usecase::RemoveCommand` と `models/dish.rb` への `postponed_meals` 追加 | 本番application coding（既存挙動の変更） | [callerが依存するcontract](#callerが依存するcontract) |
| `features/meal/postponed/` 4件 | 本番application coding | [codeの責務配置と依存構造](#codeの責務配置と依存構造) |
| `operationComponents/PostponeMeal/` 4件、`useCalendarMode` / `CalendarHeader` / `MealCard` の変更 | 本番application coding。Jestで正しさを確認する | [画面イメージと配置意図](#画面イメージと配置意図) |
| `business/food/meal/README.md` への `### 延期された食事（PostponedMeal）` 追加 | 記述内容が実装の存在を前提とするため、実装と同じ実行単位で反映する必要がある | [codeの責務配置と依存構造](#codeの責務配置と依存構造) の「制約の記録先」 |
</content>
