# Design: フェーズ1 MealFrame として成立する

## TL;DR

食事の「枠」（MealFrame）を管理するための CRUD とカレンダーへの枠エントリ登録を実装する。MealFrame はユーザーが「パスタ」「魚料理」などを定義するマスタ、MealFrameEntry はカレンダー上の特定日時に枠を置いたエントリ（Meal ドメイン内の概念）。フェーズ1では「枠が作れてカレンダーに表示できる」状態を目標とし、食事（Dish）との紐付けはフェーズ2に持ち越す。

---

## 元の依頼内容

フェーズ1: MealFrame として成立する

### DoD（完了条件）
- ユーザーが MealFrame を作成・更新・削除できる（GraphQL + フロントエンド管理UI）
- カレンダーの `+` ボタンから枠をカレンダーに登録できる
- カレンダーに枠カード（FrameCard）が表示される

### タスク概要
- DB: `meal_frames` / `meal_frame_entries` テーブル追加
- バックエンド: `MealFrame` / `MealFrameEntry` ドメインモデル
- GraphQL: `mealFrames` query / `addMealFrame` / `updateMealFrame` / `deleteMealFrame` mutation
- GraphQL: `addMealFrameEntry` mutation / `mealsForCalendar` に `frameEntries` 追加
- フロントエンド: MealFrame 管理UI（一覧・作成・編集・削除）
- フロントエンド: `+` ボタン → タイプセレクタ → 枠登録フォーム（`AddMealFrame.tsx`）
- フロントエンド: `FrameCard.tsx` / `DateCard.tsx` 拡張

---

## 要件

### MUST

- ユーザーが MealFrame（枠マスタ）を作成・更新・削除できる
  - WHEN ユーザーが枠名を入力して作成すると THEN 新しい MealFrame が保存される
  - WHEN ユーザーが枠名を変更すると THEN MealFrame の名前が更新される
  - WHEN ユーザーが枠を削除すると THEN MealFrame が削除される
    - MealFrameEntry が存在する場合は削除ブロック（削除不可）
- カレンダーの `+` ボタンから枠をカレンダーに登録できる
  - WHEN `+` をクリックすると THEN 食事登録フォームがデフォルトで開く
  - WHEN モーダル内のタイプセレクタで「枠」を選ぶと THEN 枠登録フォームに切り替わる
  - WHEN 枠を選択して登録すると THEN MealFrameEntry が作成され、カレンダーに FrameCard が表示される
- カレンダーに枠カード（FrameCard）が表示される
  - WHEN その日付に MealFrameEntry が存在すると THEN 枠名を表示した FrameCard が DishCard と並んで表示される
  - WHEN FrameCard の削除操作をすると THEN MealFrameEntry が削除される（FrameCard が消える）

### SHOULD

- MealFrame 管理 UI に専用ページを設ける（`/mealframes`）
- 既存ナビゲーションから管理ページへ遷移できる

### MAY

- FrameCard にカテゴリアイコン（DishCard のような装飾）を持たせる

### 非目標（フェーズ1スコープ外）

- FrameCard から Dish を割り当てる（`fillMealFrameEntry` mutation）→ フェーズ2
- 週・月単位での枠一括登録 → フェーズ3

---

## Design

### 変更点サマリ

| レイヤ | 追加・変更 |
|---|---|
| DB | `meal_frames` テーブル新設、`meal_frame_entries` テーブル新設 |
| ActiveRecord | `MealFrame` モデル、`MealFrameEntry` モデル |
| Domain | `Business::Food::Meal::Frame::Root`、`Business::Food::Meal::FrameEntry::Root` |
| Usecase | `Meal::Frame::Usecase::AddCommand/UpdateCommand/RemoveCommand/IndexFinder` |
| Usecase | `Meal::FrameEntry::Usecase::AddCommand/RemoveCommand` |
| Usecase | `Meal::Usecase::DateMealsFinder` 拡張（frameEntries 追加） |
| GraphQL Mutation | `addMealFrame`, `updateMealFrame`, `deleteMealFrame`, `addMealFrameEntry`, `removeMealFrameEntry` |
| GraphQL Query | `mealFrames`, `mealsForCalender`（`frameEntries` フィールド追加） |
| Frontend feature | `features/mealFrame/` 新設（CRUD mutation/query hooks） |
| Frontend component | `components/mealFrame/` 新設（管理UI） |
| Frontend component | `components/calendar/calendarComponents/FrameCard/` 新設 |
| Frontend component | `AddMealIcon.tsx` → タイプセレクタ追加（食事デフォルト） |
| Frontend component | `DateCard.tsx` → frameEntries の FrameCard レンダリング追加 |
| Frontend page | `app/mealframes/` 新設（一覧・新規・編集） |

---

### データモデル

#### テーブル定義

```sql
-- 枠マスタ（ユーザーが定義する枠の種類）
meal_frames:
  id          bigint PK
  user_id     bigint NOT NULL FK → users
  name        string NOT NULL   # 例: "パスタ", "魚料理", "外食"
  created_at  datetime
  updated_at  datetime

-- 枠エントリ（カレンダー上の特定日に枠を配置した記録。中間テーブルとして Meal とも接続）
meal_frame_entries:
  id              bigint PK
  user_id         bigint NOT NULL FK → users
  meal_frame_id   bigint NOT NULL FK → meal_frames
  date            date NOT NULL
  meal_type       integer NOT NULL
  meal_id         bigint NULL FK → meals  # フェーズ1では null。フェーズ2で Meal が割り当てられると埋まる
  created_at      datetime
  updated_at      datetime
```

#### 具体的なデータ例

**典型ケース1: 枠だけ登録（まだ料理は決まっていない）**
```
meal_frames:
  id=1, user_id=1, name="パスタ"
  id=2, user_id=1, name="魚料理"

meal_frame_entries:
  id=1, user_id=1, meal_frame_id=1, date=2026-03-25, meal_type=2(夕食), meal_id=null
  id=2, user_id=1, meal_frame_id=2, date=2026-03-26, meal_type=2(夕食), meal_id=null

meals: (なし、まだ料理は登録していない)
```

→ カレンダー 3/25 に「パスタ」枠カード、3/26 に「魚料理」枠カードが表示される

**典型ケース2: 同じ枠マスタを複数日で使う**
```
meal_frames:
  id=1, user_id=1, name="パスタ"

meal_frame_entries:
  id=1, user_id=1, meal_frame_id=1, date=2026-03-24, meal_type=2, meal_id=null
  id=2, user_id=1, meal_frame_id=1, date=2026-03-27, meal_type=2, meal_id=null
```

→ 同じ「パスタ」枠が 3/24 と 3/27 の両方に表示される（MealFrame は共有できる）

**典型ケース3: 通常の食事（MealFrame なし）**
```
meals:
  id=1, user_id=1, date=2026-03-25, meal_type=1(昼), dish_id=5

meal_frame_entries: (なし)
```

→ カレンダー 3/25 に通常の DishCard が表示される

---

### ドメインモデル設計

#### MealFrame集約

```ruby
# Business::Food::Meal::Frame::Root
class Root < Business::Base::Entity
  attribute :id
  attribute :user_id
  attribute :name

  def rename(new_name)  # 名前を変える
  def set_id(new_id)
end

# Business::Food::Meal::Frame::Usecase::AddCommand
# Business::Food::Meal::Frame::Usecase::UpdateCommand
# Business::Food::Meal::Frame::Usecase::RemoveCommand  # MealFrameEntry が存在する場合はブロック
# Business::Food::Meal::Frame::Usecase::IndexFinder
```

#### MealFrameEntry（Meal ドメイン内）

```ruby
# Business::Food::Meal::FrameEntry::Root
class Root < Business::Base::Entity
  attribute :id
  attribute :user_id
  attribute :meal_frame_id
  attribute :date
  attribute :meal_type

  def set_id(new_id)
end

# Business::Food::Meal::FrameEntry::Usecase::AddCommand
# Business::Food::Meal::FrameEntry::Usecase::RemoveCommand
```

---

### GraphQL 設計

#### mealsForCalender の拡張

`MealsOfDate` 型に `frameEntries` フィールドを追加する。

```ruby
# Types::Output::Meal::CalenderMeal::MealsOfDate 変更後
class MealsOfDate < ::Types::BaseObject
  field :date, GraphQL::Types::ISO8601Date, null: false
  field :meals, [MealForCalender, { null: false }], null: false
  field :frame_entries, [FrameEntryForCalender, { null: false }], null: false  # 追加
end

# Types::Output::Meal::CalenderMeal::FrameEntryForCalender（新設）
class FrameEntryForCalender < ::Types::BaseObject
  field :id, Int, null: false
  field :meal_frame_id, Int, null: false
  field :meal_frame_name, String, null: false
  field :meal_type, Int, null: false
end
```

#### 新規 Mutation

```
addMealFrame(input: { name: String! }) → meal_frame_id
updateMealFrame(input: { id: Int!, name: String! }) → meal_frame_id
deleteMealFrame(input: { id: Int! }) → meal_frame_id
addMealFrameEntry(input: { meal_frame_id: Int!, date: ISO8601Date!, meal_type: Int! }) → meal_frame_entry_id
removeMealFrameEntry(input: { id: Int! }) → meal_frame_entry_id
```

#### 新規 Query

```
mealFrames → [MealFrame]  # ログインユーザーの全 MealFrame
```

---

### フロントエンド設計

#### `+` ボタンの変更（AddMealIcon.tsx）

現状: `+` クリック → FullScreenModal「食事登録」（AddMeal）

変更後: `+` クリック → FullScreenModal を開く（食事登録フォームがデフォルト表示）
→ モーダル内上部のタイプセレクタで「枠」を選んだ場合のみ枠登録フォームに切り替わる
→ 普段の食事追加操作のクリック数は変わらない

#### DateCard.tsx の変更

`frameEntries` を props に追加し、FrameCard を meals と並べてレンダリング。

```tsx
type DateCardProps = {
  // 既存
  meals: MealForCalender[];
  // 追加
  frameEntries: FrameEntryForCalender[];
  ...
};
```

#### FrameCard.tsx（新設）

```
components/calendar/calendarComponents/FrameCard/index.tsx
```

表示内容: 枠名、削除ボタン（MealFrameEntry の削除）

#### MealFrame 管理 UI（新設）

```
app/mealframes/page.tsx              # 一覧
app/mealframes/new/page.tsx          # 新規作成
app/mealframes/[id]/edit/page.tsx    # 編集
components/mealFrame/                # 管理UIコンポーネント
features/mealFrame/                  # GraphQL hooks
```

---

### 設計選択と理由

**mealsForCalender に frameEntries を追加する**
- 代替案: 別クエリ `frameEntriesForCalender` を追加
- 棄却理由: フロントエンドで2回クエリが必要になり、カレンダー表示ロジックが分散する。`MealsOfDate` 型は「ある日付に何があるか」を表すオブジェクトであり、枠エントリもそこに含むのが自然

**MealFrame・MealFrameEntry を `Business::Food::Meal` モジュール下に配置**
- 代替案: `Business::Food::MealFrame` として Food 直下にトップレベル集約として配置
- 棄却理由: MealFrame は Meal の補助的な概念であり、Meal と独立した存在ではない。「MealFrame と Meal は別のもの？」と聞かれたとき「近い概念だよ」と答えることになるなら、その関係はコードのモジュール構造で表現すべき。暗黙の管理にせず `Business::Food::Meal::Frame` と `Business::Food::Meal::FrameEntry` として Meal モジュール下に揃える

**meal_frame_entries に meal_id（nullable）を持たせる（meals テーブルは変更しない）**
- 代替案: `meals.meal_frame_entry_id` を追加
- 棄却理由: Meal は MealFrameEntry なしで独立して存在できる。関連付けの責務は関連付けのために存在する MealFrameEntry が担うのが自然。meals はコアテーブルであり、枠機能のために nullable カラムを追加するのはモデリングの敗北

---

### リスクと対策

| リスク | 対策 |
|---|---|
| `mealsForCalender` クエリに frameEntries を追加すると DateMealsFinder のクエリが複雑になる | MealFrameEntry の取得は独立した SQL で行い、group_by 後にマージする |
| `+` ボタン変更でタイプセレクタを追加しても既存の食事追加 UX を壊さない | 食事フォームをデフォルト表示とし、既存 AddMeal フローは変えない |

---

### テスト方針

- バックエンド: 各 Command/Finder の RSpec unit test（Dockerコンテナ内）
- GraphQL: 各 Mutation/Query の spec（spec/graphql/）
- フロントエンド: MealFrame管理UIコンポーネントの Jest テスト、FrameCard の Jest テスト

---

## 事前設計議論メモ

設計過程での議論は `discussion.md` を参照。全6論点を記録済み。
