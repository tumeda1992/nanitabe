# Design: 食事と枠の紐付け解除・既存食事の割り当て・+ボタン挙動統一

## TL;DR

カレンダーの枠（FrameEntry）と食事（Meal）の関係操作として「解除（①）」「既存食事の割り当て（②）」を追加し、日付横の `+` と空エリアの `+` の挙動差（③）を解消する。新規スキーマ変更はなく、既存の `meal_frame_entries.meal_id` カラムと `FillWithMealCommand` を活用して実装する。

---

## 要件（Requirements）

### MUST
- ① 食事に枠が紐ついているとき、DishCard のアクションから枠との紐付けを解除できる
- ② 空の FrameCard クリック時、既存の枠未割り当て食事（同日）を選択して割り当てられる
- ③ 日付横の `+`（AddMealIcon）と空エリアの点線 `+` で開くモーダルが統一される（3タブ: 食事/枠/枠パターン適用）

### 非目標
- 別の日の食事を割り当てる（② は同日の食事のみ対象）
- 食事編集時に枠を付け替える（今回は解除と割り当ての2操作のみ）

---

## 前提とする既存仕様

| 概念 | テーブル | 主なカラム |
|---|---|---|
| 枠エントリ（FrameEntry） | `meal_frame_entries` | `meal_id NULL` = 未割り当て、`meal_id 設定` = 割り当て済み |
| カレンダーデータ | `mealsForCalender` query | `meals`（meal_id あり DishCard）+ `frameEntries`（meal_id=nil の FrameCard のみ） |

- `MealForCalender.mealFrameEntryId` は左結合で取得（meals 側には FK なし）
- `FrameEntryForCalender` は `meal_id IS NULL` の枠エントリのみ返される
- `FillWithMealCommand` は既存で `meal_frame_entry.meal_id = meal_id` をセットして保存する
- 日付横 `+`（AddMealIcon）：食事/枠/枠パターン適用 の3タブモーダル
- 空エリアの点線 `+`（DateCard 独自）：`AddMeal` のみのシンプルモーダル（今回③で統一対象）

---

## 完成後の姿

### 3-1. 操作フロー（動的な視点）

#### フロー①: 枠紐付け解除

```
① ユーザーが DishCard をクリック → アクションパネルが展開される
   （表示条件: meal.mealFrameEntryId が non-null のとき「枠解除」ボタンが表示される）
② 「枠解除」ボタンをクリック → confirm ダイアログ
③ 確認後: unassignMealFromFrameEntry(frameEntryId: meal.mealFrameEntryId) を呼ぶ
④ resolver → Frame::Entry::Usecase::UnassignMealCommand
            → root.unassign_meal() → meal_id = nil
            → persist → meal_frame_entries.meal_id = NULL
⑤ onChanged() → mealsForCalender 再取得
⑥ 結果: DishCard から枠名ラベルが消え、FrameCard が再出現する
```

#### フロー②: 既存食事を枠に割り当て

```
① ユーザーが FrameCard をクリック → ラッパーモーダルが開く（2タブ）
   - Tab 1「新しく食事を登録」（現行と同じ AddMeal）
   - Tab 2「既存の食事を割り当て」
     ※ 食事リストは新規クエリなし。DateCard が mealsForCalender から受け取った
       meals を props 経由で FrameCard に渡す（unlinkedMeals = meals.filter(m => !m.mealFrameEntryId)）
② Tab 2 を選択 → 同日の枠未割り当て食事リストが表示される
   ※ リストが空の場合は「割り当て可能な食事がありません」を表示
③ リストから食事を選択 → fillMealFrameEntry(frameEntryId: frameEntry.id, mealId: selectedMeal.id) を呼ぶ
④ resolver → Frame::Entry::Usecase::FillWithMealCommand（既存）
            → meal_frame_entries.meal_id = selectedMeal.id
⑤ onAddSucceeded() → mealsForCalender 再取得
⑥ 結果: FrameCard が DishCard（枠名ラベル付き）に変わる
```

#### フロー③: 空エリアの `+` から3タブモーダルを開く

```
① ユーザーが「食事がない日の点線エリア」の `+` をクリック
② AddMealIcon の3タブモーダルが開く（現行の日付横 `+` と同じ動作）
③ 「食事 / 枠 / 枠パターン適用」を選択して登録
```

### 3-2. データモデル（静的な視点）

スキーマ変更なし。既存の `meal_frame_entries.meal_id` nullable を利用。

**解除後のデータ例（①）:**

| meal_frame_entries.id | meal_frame_id | date       | meal_type | meal_id |
|----------------------|---------------|------------|-----------|---------|
| 10                   | 3             | 2026-04-26 | 3         | NULL    | ← 解除後（NULL に戻る）

| meals.id | date       | meal_type | dish_id | ← meal 自体は残る、枠名ラベルなし |
|---------|------------|-----------|---------|
| 7       | 2026-04-26 | 3         | 5       |

**割り当て後のデータ例（②）:**

| meal_frame_entries.id | meal_frame_id | date       | meal_type | meal_id |
|----------------------|---------------|------------|-----------|---------|
| 10                   | 3             | 2026-04-26 | 3         | 7       | ← 割り当て後（meal_id がセット）

### 3-3. クラス・API 設計

#### ① 枠解除

**新規 Domain メソッド（Frame::Entry::Root）:**
```ruby
def unassign_meal
  self.meal_id = nil
end
# 命名根拠: assign_meal の逆操作。「外す」意図が明確。detach より assign との対称性が高い
```

**新規 Usecase Command:**
```ruby
class Frame::Entry::Usecase::UnassignMealCommand
  attribute :user_id
  attribute :meal_frame_entry_id
  def call
    root = MealFrameEntry.build_existing_root_from_id(meal_frame_entry_id)
    root.unassign_meal
    MealFrameEntry.persist_from_food_meal_frame_entry_root(root)
  end
end
```

**新規 GraphQL mutation:**
```graphql
mutation unassignMealFromFrameEntry($frameEntryId: Int!) {
  unassignMealFromFrameEntry(input: { frameEntryId: $frameEntryId }) {
    frameEntryId
  }
}
```

#### ② 既存食事の割り当て

**新規 GraphQL mutation（BE）:**
```graphql
mutation fillMealFrameEntry($frameEntryId: Int!, $mealId: Int!) {
  fillMealFrameEntry(input: { frameEntryId: $frameEntryId, mealId: $mealId }) {
    frameEntryId
  }
}
```
- resolver → 既存 `FillWithMealCommand` を直接呼ぶ（ドメインロジックは再利用）
- 命名根拠: 「枠を食事で埋める（fill）」という操作名。`assignMeal` でもよいが、既存 Command 名に合わせて `fill` を採用

**FE - FrameCard の props 追加:**
```ts
type FrameCardProps = {
  frameEntry: FrameEntryForCalender;
  unlinkedMeals: MealForCalender[];  // 追加: 同日の枠未割り当て食事
  onDeleted: () => void;
  onAddSucceeded?: () => void;
  date?: string;
};
```

**FE - DateCard からの渡し方:**
```tsx
<FrameCard
  frameEntry={frameEntry}
  unlinkedMeals={meals.filter(m => !m.mealFrameEntryId)}  // 追加
  ...
/>
```

#### ③ `+` ボタン挙動統一

3タブのロジック（タブ切り替え state・AddMeal/AddMealFrame/AddMealPattern の出し分け）を `AddMealTabs` として独立コンポーネントに抽出し、AddMealIcon と DateCard の両方から使う。

- AddMealIcon への props 追加なし
- DateCard の点線エリア・`onClick` は変えない
- 3タブロジックは `AddMealTabs` の1箇所のみ

```tsx
// AddMealTabs.tsx（新規）
// タブ切り替え state と子コンポーネントの出し分けを持つ
type AddMealTabsProps = {
  defaultDate: string;
  onAddSucceeded: () => void;
};
const AddMealTabs = ({ defaultDate, onAddSucceeded }: AddMealTabsProps) => {
  const [addType, setAddType] = useState<'meal' | 'frame' | 'pattern'>('meal');
  return (
    <>
      <div className="flex gap-2 mb-4">
        <button onClick={() => setAddType('meal')}>食事</button>
        <button onClick={() => setAddType('frame')}>枠</button>
        <button onClick={() => setAddType('pattern')}>枠パターン適用</button>
      </div>
      {addType === 'meal' && <AddMeal defaultDate={defaultDate} onAddSucceeded={onAddSucceeded} />}
      {addType === 'frame' && <AddMealFrame dateForAdd={defaultDate} onAddSucceeded={onAddSucceeded} />}
      {addType === 'pattern' && <AddMealPattern dateForAdd={defaultDate} onAddSucceeded={onAddSucceeded} />}
    </>
  );
};

// AddMealIcon: 既存の FullScreenModal 内を AddMealTabs に置き換える
<FullScreenModal title="食事登録">
  <AddMealTabs defaultDate={date} onAddSucceeded={onAddSucceeded} />
</FullScreenModal>

// DateCard: FullScreenModal 内を AddMealTabs に置き換える（点線エリアは変えない）
<FullScreenModal title="食事登録">
  <AddMealTabs defaultDate={date} onAddSucceeded={handleEmptyAreaAddSucceeded} />
</FullScreenModal>
```

---

## 設計判断

### 「既存食事リストをクライアント側でフィルタする」理由
- カレンダークエリ（`mealsForCalender`）は既に全 meals を `mealFrameEntryId` 付きで返している
- 新しい query を追加せずとも `mealFrameEntryId == null` でフィルタ可能
- 別 query を追加すると過剰設計（新たな N+1 リスクも生まれる）

### 「`fillMealFrameEntry` を独立 mutation にする」理由
- `addMeal` は meal 作成と frame 紐付けを1つにまとめた mutation
- 「既存 meal を frame entry に紐付けるだけ」は別の意図・引数シグネチャ → 別 mutation が適切
- プレゼンテーション層のオーケストレーション原則に合致（既存 Command を別経路から呼ぶ）

### 「`AddMealTabs` コンポーネントを抽出して AddMealIcon・DateCard 両方から使う」理由
- AddMealIcon と DateCard の両方で「食事/枠/枠パターン適用」の3タブを開く。同一機能が全く同じタイミングで変更される → 抽出して1箇所に持つべき（共通化判断基準: 変更の必然性あり）
- AddMealIcon への props 追加なし。DateCard の点線エリアも変えない。変わるのはモーダル内部のみ
- 採用しなかった代替案1: `openerElement` prop を AddMealIcon に追加する → AddMealIcon のインターフェースが複雑になる
- 採用しなかった代替案2: DateCard に3タブロジックをそのまま inline → 重複コードが生まれ、タブ追加時に2箇所変更が必要になる

---

## リスクと対策

| リスク | 対策 |
|---|---|
| ①で解除後に meal が枠なし DishCard として残り、見た目が変わる | `onChanged()` で再取得するため自動反映される |
| ②の食事リストが空のとき（同日に枠未割り当て食事がない） | 「割り当て可能な食事がありません」メッセージを表示する |
| ③の AddMealTabs が AddMealIcon と DateCard で別インスタンスになる | state は各インスタンスが独立して持つため問題なし |

---

## テスト方針

### バックエンド（RSpec）
- `Frame::Entry::Usecase::UnassignMealCommand` spec
  - 正常: meal_id が nil になる
  - 異常: 存在しない frame_entry_id
- `unassignMealFromFrameEntry` resolver spec
- `Mutations::Meal::FrameEntry::FillMealFrameEntry` resolver spec（② 新規）
  - 正常: meal_id が設定される
  - 異常: 他ユーザーの frame_entry

### フロントエンド（Jest）
- `DishCard` spec
  - `mealFrameEntryId` あり: 「枠解除」ボタンが表示される
  - `mealFrameEntryId` なし: 「枠解除」ボタンが表示されない
- `FrameCard` spec
  - Tab 1（新しく食事を登録）が表示される
  - `unlinkedMeals` ありのとき Tab 2（既存食事を割り当て）が表示される
  - `unlinkedMeals` 空のとき Tab 2 に「割り当て可能な食事がありません」が表示される
- `AddMealTabs` spec（新規）
  - 初期表示: 「食事」タブが選択され AddMeal が表示される
  - 「枠」タブ選択: AddMealFrame が表示される
  - 「枠パターン適用」タブ選択: AddMealPattern が表示される
- `DateCard` spec
  - 空エリアの `+` クリックで3タブモーダルが開く

---

## （付録）変更点一覧

### バックエンド
- `Frame::Entry::Root#unassign_meal` メソッド追加（既存 root.rb 変更）
- `Frame::Entry::Usecase::UnassignMealCommand` 新規作成
- `Mutations::Meal::FrameEntry::UnassignMealFromFrameEntry` 新規作成
- `Mutations::Meal::FrameEntry::FillMealFrameEntry` 新規作成
- `mutation_type.rb` に2つの新 mutation を登録
- spec 各種追加

### フロントエンド
- GraphQL codegen 実行（schema.json / graphql.ts 更新）
- `unassignMealFromFrameEntryMutation.ts` 新規作成
- `fillMealFrameEntryMutation.ts` 新規作成
- `useMealFrame.ts` に2つの mutation を追加
- `DishCard` に「枠解除」ActionBtn 追加（条件付き表示）
- `AddMealTabs` コンポーネント新規作成（3タブ切り替えロジックを集約）
- `AddMealIcon` の FullScreenModal 内部を `AddMealTabs` に差し替え
- `FrameCard` に `unlinkedMeals` prop 追加・モーダルを2タブ化
- `DateCard` の FullScreenModal 内部を `AddMealTabs` に差し替え（点線エリアの見た目・onClick は変えない）
- spec 各種追加・変更
