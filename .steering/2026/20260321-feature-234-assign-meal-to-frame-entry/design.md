# Design: フェーズ2 食事への割り当て（MealFrame × Meal）

## 1. TL;DR

食事登録がメイン、枠はその補助。FrameCard をクリックすると既存の AddMeal フォームが開き（日付・食事タイプ pre-fill 済み）、通常通り食事を登録する。`addMeal` 系 mutation に optional で `frame_entry_id` を追加し、渡した場合は resolver が Meal 作成後に FillWithMealCommand を呼んで紐付けをオーケストレーションする。紐付け後は DishCard（枠名ラベル付き）として表示。

---

## 2. 要件（Requirements）

### MUST

- `addMeal` 系 mutation に optional `frame_entry_id` を追加できる
  - WHEN `frame_entry_id` ありで addMeal を呼ぶと
    THEN Meal 作成 + MealFrameEntry.meal_id へのセットがトランザクション内でアトミックに行われる
  - WHEN `frame_entry_id` なし（通常の食事登録）
    THEN 既存の挙動と変わらない
- FrameCard から食事を登録できる
  - WHEN FrameCard をクリックすると THEN AddMeal フォームが日付・食事タイプ pre-fill で開く
  - フォームは通常の食事登録と同じ（料理選択・新規料理・コメント・レシピ元すべて対応）
  - WHEN 登録すると THEN frame_entry_id 付きで addMeal が呼ばれ、FrameCard が DishCard に変わる
- 紐付け後は DishCard に枠名ラベルが表示される
  - WHEN meal に紐付いた frame_entry があると THEN DishCard に「枠: {枠名}」ラベルが表示される

### SHOULD

- 既存の DishCard のスタイルを崩さず、枠名ラベルだけ追加する

### 非目標（スコープ外）

- `fillMealFrameEntry` として独立した mutation は作らない
  - addMeal 系に frame_entry_id を渡すだけで完結する
- 既存 Meal を後から枠に紐付けるユースケース → 将来
- 紐付けを解除するユースケース → 将来

---

## 3. 完成後の姿

### 3-1. 操作フロー

**ケース1: FrameCard から料理を登録する**
```
① ユーザーが FrameCard（meal_frame_entries: id=1, meal_id=null）をクリック
② AddMeal フォームが開く（date=2026-03-25, meal_type=2 pre-fill 済み）
③ ユーザーが料理を選んで登録ボタンを押す
④ フロントエンドが addMeal(dish_id: 5, meal: { date, meal_type }, frame_entry_id: 1) を1回呼ぶ
⑤ addMeal resolver 内で一括処理（トランザクション内）:
   ├ Meal::Usecase::AddCommand.call(...) → meals: id=10 作成
   └ FrameEntry::Usecase::FillWithMealCommand.call(meal_frame_entry_id: 1, meal_id: 10)
       → root.assign_meal(10) → persist
⑥ meal_frame_entries.id=1 の meal_id が 10 にセットされる
⑦ カレンダー再取得 → DateMealsFinder が meals に LEFT JOIN で frame_entry 情報を付加
   meals: id=10 に meal_frame_entry_id=1, meal_frame_name="パスタ" が乗る
   frame_entries: id=1 は meal_id=10（IS NULL でない）→ 除外される
⑧ カレンダーに DishCard「スパゲティ」＋「枠: パスタ」ラベルが表示される（FrameCard は消える）
```

**ケース2: 通常の食事登録（frame_entry_id なし・既存挙動と変わらない）**
```
① ユーザーが + ボタンから AddMeal フォームを開く
② addMeal(dish_id: 6, meal: { date, meal_type }) を呼ぶ（frame_entry_id なし）
③ resolver: Meal::Usecase::AddCommand.call(...) のみ実行（FillWithMealCommand は呼ばれない）
④ カレンダーに通常の DishCard が表示される（枠ラベルなし）
```

### 3-2. データモデル

**ケース1: FrameCard を料理で埋めた後**
```
meal_frames:        id=1, user_id=1, name="パスタ"
meal_frame_entries: id=1, meal_frame_id=1, date=2026-03-25, meal_type=2, meal_id=10  ← セット済み
meals:              id=10, date=2026-03-25, meal_type=2, dish_id=5
```
→ DateMealsFinder: meals の id=10 が meal_frame_entry_id=1, meal_frame_name="パスタ" を保持して返る
→ frame_entries: id=1 は meal_id あり → 除外される（IS NULL フィルタ）
→ カレンダー: DishCard「スパゲティ」＋「枠: パスタ」ラベル表示

**ケース2: まだ料理を登録していない枠（フェーズ1 と変わらない）**
```
meal_frame_entries: id=2, meal_frame_id=1, date=2026-03-26, meal_type=2, meal_id=null
```
→ frame_entries に含まれる → FrameCard 表示

**ケース3: 通常の食事（枠なし）**
```
meals: id=11, date=2026-03-27, meal_type=1, dish_id=6
```
→ meal_frame_entry_id = null → DishCard に枠ラベルなし

### 3-3. クラス・API 設計

命名はドメインが何をしているかの宣言。実装前に揃えることで「`set_xx`/`update_xx` 系」が紛れ込むのを防ぐ。

#### ドメイン層

**`FrameEntry::Root` への追加**

```ruby
module Business::Food::Meal::FrameEntry
  class Root < ::Business::Base::Entity
    attribute :meal_id, :integer   # 追加

    def assign_meal(meal_id)       # 枠に食事を割り当てる
      self.meal_id = meal_id
    end
  end
end
```

命名の根拠: 「枠に食事を割り当てる」という行為 → `assign_meal`
（`set_meal_id` / `update_meal_id` 等の汎用変更操作名は禁止）

**`Meal::FrameEntry::Usecase::FillWithMealCommand`（新設）**

```ruby
module Business::Food::Meal::FrameEntry
  class Usecase::FillWithMealCommand < ::Business::Base::Command
    attribute :user_id, :integer
    attribute :meal_frame_entry_id, :integer
    attribute :meal_id, :integer

    def call
      root = ::MealFrameEntry.build_existing_root_from_id(meal_frame_entry_id)
      root.assign_meal(meal_id)
      ::MealFrameEntry.persist_from_food_meal_frame_entry_root(root)
      root
    end
  end
end
```

命名の根拠: 「枠を食事で満たす」という意図 → `FillWithMealCommand`
（`UpdateMealFrameEntryCommand` のような汎用更新名は禁止）

#### GraphQL 層

**`addMeal` / `addMealWithNewDish` / `addMealWithNewDishAndNewSource` の変更（共通パターン）**

```ruby
# 追加する argument（全 mutation 共通）
argument :frame_entry_id, Int, required: false

# resolve の変更（addMeal を例に）
def resolve(dish_id:, meal:, frame_entry_id: nil)
  ActiveRecord::Base.transaction do
    created_meal = ::Business::Food::Meal::Usecase::AddCommand.call(
      user_id: context[:current_user_id],
      meal_params: meal.convert_to_command_param(use_food_module: true, dish_id:),
    )

    if frame_entry_id
      ::Business::Food::Meal::FrameEntry::Usecase::FillWithMealCommand.call(
        user_id: context[:current_user_id],
        meal_frame_entry_id: frame_entry_id,
        meal_id: created_meal.id,
      )
    end

    { meal_id: created_meal.id }
  end
end
```

resolver が「Meal 作成 → FrameEntry への紐付け」という異なる集約のオーケストレーションを担う。
application_architecture.md の「異なる集約をまたぐオーケストレーションはプレゼンテーション層が担う」に合致。

**`MealForCalender` 出力型の拡張**

```ruby
# 追加（枠なし食事では null）
field :meal_frame_entry_id, Integer, null: true
field :meal_frame_name, String, null: true
```

EssentialMeal には追加しない（「軽量 Meal」コメントに従い、カレンダー専用フィールドは MealForCalender に直接持つ）。

#### フロントエンド層

**`AddMeal` コンポーネントへの変更**

```tsx
type AddMealProps = {
  defaultDate?: Date;
  onAddSucceeded: () => void;
  frameEntryId?: number;   // 追加（省略時は通常の食事登録）
};
```

フォーム内部で `frameEntryId` を mutation の引数として渡すだけ。表示・操作は変わらない。

**`FrameCard` クリックフロー**

```
FrameCard クリック
  → FullScreenModal で AddMeal フォームを開く
      props: defaultDate={frameEntry.date}
             defaultMealType={frameEntry.mealType}
             frameEntryId={frameEntry.id}   ← 追加
  → ユーザーが料理を選択・登録（通常の食事登録と同じ操作）
  → addMeal(dish_id, meal, frame_entry_id) が呼ばれる
  → resolver が Meal 作成 + FillWithMealCommand を実行
  → onAddSucceeded() → モーダルを閉じてカレンダー再取得
```

`onAddSucceeded: () => void` の interface は変更しない。

**`DishCard` への枠名ラベル追加**

```tsx
{meal.mealFrameName && (
  <span className="text-[10px] text-violet-600 shrink-0 truncate">
    枠: {meal.mealFrameName}
  </span>
)}
```

既存の DishCard スタイルを崩さず、2行目エリアに追加する。

---

## 4. なぜこの姿か（設計判断）

### addMeal 系に frame_entry_id を渡す（fillMealFrameEntry 独立 mutation は作らない）

- **棄却案**: fillMealFrameEntry(meal_frame_entry_id, meal_id) を独立 mutation として作り、フロントエンドが addMeal → fillMealFrameEntry の順に2回呼ぶ
- **棄却理由**: フロントエンドが2 mutation を自力で sequencing するとトランザクションが保証できない。「食事登録 + 枠への紐付け」はアトミックに行われるべき
- **採用理由**: addMeal resolver 内でトランザクションを一本化できる。フロントエンドは1回の mutation 呼び出しで完結

### frame_entries は meal_id IS NULL のみ返す

- **棄却案**: frame_entries に紐付き済みも含め、フロントエンドで表示判定
- **棄却理由**: 「未割当枠 = FrameCard」「割当済み = DishCard」の分類はバックエンドが責任を持つべき
- **採用理由**: 「frame_entries = 未割当の枠」「meals = 確定した食事（枠由来も含む）」というセマンティクスが明確になる

### MealForCalender に frame_entry フィールドを直接追加（EssentialMeal には追加しない）

- **理由**: 既存コードコメント「特定のユースケースのためのMealはEssentialMealを拡張せず、別のMealを作成する」に従う

---

## 5. リスクと対策

| リスク | 対策 |
|---|---|
| Meal モデルに `has_one :meal_frame_entry` が未定義 | 実装前に確認・追加する |
| addMeal 系 3 mutation すべてに同じ変更が必要で漏れが起きやすい | テストで frame_entry_id ありのケースを全 mutation 分書く |
| DateMealsFinder の SELECT で meal_frame_entry_id / meal_frame_name カラム名が meal 側のカラムと衝突する可能性 | AS でエイリアスを明示する（すでに設計に含めた） |
| DishCard に枠ラベルを追加してレイアウトが崩れる | スクリーンショット確認で目視チェック |

---

## 6. テスト方針

**バックエンド**
- `spec/domain/business/food/meal/frame_entry/usecase/fill_with_meal_command_spec.rb`（新設）
- `spec/graphql/mutation/meal/add_meal_spec.rb` に frame_entry_id ありのケース追加
- `spec/graphql/mutation/meal/add_meal_with_new_dish_spec.rb` に同様追加
- `spec/graphql/mutation/meal/add_meal_with_new_dish_and_new_source_spec.rb` に同様追加
- `spec/graphql/query/meal/calender/meals_for_calender_spec.rb` に「紐付け後は meals に含まれ frame_entries から除外」ケース追加

**フロントエンド**
- `FrameCard/index.spec.tsx`: クリックでモーダルが開くこと、登録後にカレンダー更新が呼ばれること
- `DishCard/index.spec.tsx`: `mealFrameName` があるとき枠ラベルが表示されること
- `AddMeal` 系: `frameEntryId` を渡したとき mutation 引数に含まれること

---

## （付録）変更点一覧

| レイヤ | 追加・変更 |
|---|---|
| Domain: FrameEntry::Root | `meal_id` attribute 追加 + `assign_meal(meal_id)` ドメインメソッド追加 |
| Domain: Usecase | `Meal::FrameEntry::Usecase::FillWithMealCommand` 新設 |
| GraphQL Mutation | `addMeal` / `addMealWithNewDish` / `addMealWithNewDishAndNewSource` に optional `frame_entry_id: Int` 追加 |
| Usecase: DateMealsFinder | meals に LEFT JOIN で frame_entry_id / meal_frame_name を追加。frame_entries は `meal_id IS NULL` のみ返す |
| GraphQL Output | `MealForCalender` に `meal_frame_entry_id`(nullable Int)・`meal_frame_name`(nullable String) 追加 |
| Frontend feature | `addMealMutation.ts` 等 addMeal 系 mutation に `frameEntryId` 引数追加 |
| Frontend component | `AddMeal` コンポーネントに optional `frameEntryId` prop 追加 |
| Frontend component | `FrameCard/index.tsx` にクリック → AddMeal モーダル追加 |
| Frontend feature | `fetchMealQuery.ts` の MEALS_FOR_CALENDER に frame_entry フィールド追加 |
| Frontend component | `DishCard/index.tsx` に枠名ラベル表示追加 |

---

## 事前設計議論メモ（揮発防止）

### 論点1: fillMealFrameEntry を独立 mutation として作るか

**提起の背景:** ロードマップに「fillMealFrameEntry mutation 追加」と記載があり、独立 mutation として設計を始めた。

**議論の変遷:**
- [前提] resolver がオーケストレーション = fillMealFrameEntry resolver 内で Meal 作成 + 紐付け
- [疑問] addMealWithNewDish 等の全バリアントを fillMealFrameEntry に重複実装するのは現実的か？
- [ユーザー指摘] AddMeal 系の引数に frame_entry_id を渡すのでは？
- [変化点] 「フロントエンドで addMeal → fillMealFrameEntry を2回呼ぶ」ではなく「addMeal 系に frame_entry_id を渡し、resolver が FillWithMealCommand を呼ぶ」が正しい設計
- [ユーザー確認] fillMealFrameEntry 独立 mutation は不要（a を選択）

**決定:** fillMealFrameEntry 独立 mutation は作らない。addMeal 系に frame_entry_id を optional で追加する。

**決定理由:** トランザクションの一本化、既存 addMeal バリアントをそのまま活かせる、フロントエンドの変更が最小限。

### 論点2: FrameCard クリック時の UI

**提起の背景:** FrameCard から料理を登録する際、専用の料理選択 UI を作るか既存 AddMeal を流用するかが設計の分岐点。

**議論の変遷:**
- [前提] 「料理割り当て」という枠側の文脈から、専用コンポーネント（料理選択のみ）を考えていた
- [ユーザー指摘] 食事の登録がメイン、枠はその補助。コメントも入力するし料理がなかったら登録もする
- [変化点] 「割り当て」ではなく「食事登録（枠 pre-fill 付き）」というメンタルモデルに転換

**決定:** 既存の AddMeal フォームを流用。`frameEntryId` を optional prop として追加するだけ。

**決定理由:** UX 的に正しい（食事登録の全機能が使える）、フロントエンドの変更最小限、onAddSucceeded の interface 変更不要。
