# 要件ドキュメント

## はじめに

食事のプレースホルダー（枠）機能を追加する。
1週間の食事計画を立てるとき、最初から具体的な料理を決めるのはハードルが高い。
まず「パスタ」「魚料理」などの枠で日程を埋め、後から具体的な料理を当てはめる、という2段階の計画を実現する。

## 元の依頼内容

食事のプレースホルダー作りたい
どういうことかって言うと、パスタみたいに枠を用意するってこと。

その日、何を食べるかを最初に決めるのは結構ハードルが高い。
だから、まずは枠で1週間を埋めて、その後で枠に当てはまる食事を考える方がハードルが低い。

プレースホルダーはその枠に相当するもの。
名前はプレースホルダーでなくても良い。今イメージとして語っている。

パスタとか白米のおかずとか魚料理とかが枠に当てはまるかな。

枠一覧は別で登録した前提で、
枠（例: パスタ）はカレンダー上から登録できて、2026/1/30「パスタ」みたいに表示される。
多分デザインは .steering/2026/20260307-feature-201-apply-v0-calendar-design/nanitabe_v0_design にあるかな。
枠を登録した後は、その枠に対して、料理をあてがって、食事とする。
2026/1/30 ミートソース、みたいに。元々の「パスタ」って枠で登録したってこともカレンダーで表示されている

で、「枠一覧は別で登録した前提」って言ったけど、その登録方法。
これはやっぱりカレンダーから登録かな。既存があればその枠を使って、なければ新規で作ってって感じで。
ただ、その柔軟性を作ろうとすると、カレンダーの日付のところにある+ボタンを押した時、食事か枠のどちらを作るか選ぶことになるけど、
デフォルトは食事を登録させたいから、ただ単に選ばせる行為は体験を悪くすることになる。
だから+ボタン押した時は、食事登録に最初いかせて、枠登録したいときに枠登録に切り替えられるようにしたいな。
リンクで飛ばさせるというより、この後、食事、枠と並列にイベントも登録させようと思ってるから、ラジオボタンみたいな感じで1つ選んだら、それを登録させるUIを表示させるとかがいいのかなあ。

## 要件

### 要件1: 枠（MealFrame）マスタの管理
**ユーザーストーリー:** ユーザーが「パスタ」「魚料理」などの枠を登録・管理できる

#### 受け入れ基準
1. WHEN カレンダーから枠を登録しようとする THEN 既存の枠一覧から選択できる
2. WHEN 枠一覧にない名前で枠を使いたい THEN 新規作成できる

### 要件2: カレンダーへの枠登録
**ユーザーストーリー:** ユーザーがカレンダーの特定日に枠を登録できる

#### 受け入れ基準
1. WHEN + ボタンを押す THEN デフォルトで食事登録フォームが開く（既存挙動を維持）
2. WHEN + ボタンから開いたモーダル内で「枠」を選択する THEN 枠登録フォームに切り替わる
3. WHEN 枠登録フォームで枠と食事種別（朝/昼/夜）を選んで登録する THEN その日のカレンダーに枠が表示される

### 要件3: カレンダーでの枠表示
**ユーザーストーリー:** ユーザーが枠のみ登録された日を視覚的に確認できる

#### 受け入れ基準
1. WHEN 枠だけ登録されている日 THEN 枠名が破線ボーダーのカードで表示される
2. WHEN 枠に料理が割り当てられている THEN DishCard に枠名がラベルとして表示される
3. WHEN 枠カードをクリックする THEN 食事登録フォームが開く（料理を当てはめるフロー）

### 要件4: 枠への料理割り当て
**ユーザーストーリー:** ユーザーが枠に具体的な料理を当てはめて食事として確定できる

#### 受け入れ基準
1. WHEN 枠カードから食事登録する THEN 通常の AddMeal フローで料理を登録できる
2. WHEN 枠から料理を登録した後 THEN DishCard に変わり、枠名ラベルが残る
3. WHEN 枠に料理を登録した後 THEN 元の枠エントリとの紐付きが保持される

---

# 設計ドキュメント

## TL;DR

新テーブル `meal_frames`（枠マスタ）と `meal_frame_entries`（日付ごとの枠エントリ）を追加する。
既存の `meals` テーブルは変更しない（`dish_id` は引き続き必須）。
カレンダーの取得 GraphQL レスポンスに `frame_entries` を追加し、フロントエンドは Meal と MealFrameEntry の2種類のエントリを表示する。
+ ボタンのモーダル内に「食事 / 枠」セレクタを追加し、食事がデフォルト選択になる。

## Requirements

### MUST
- 枠マスタ（meal_frames）はユーザー別に管理する
- カレンダーの + ボタンは食事登録がデフォルト
- 枠に料理を割り当てた後も、枠との紐付きは失われない
- `meals` テーブルの `dish_id` は nullable にしない（Option B: 別テーブル）

### SHOULD
- 枠カードは食事カードと視覚的に区別できる（破線ボーダー等）

### MAY
- 将来の「イベント」登録に対応できる拡張性をUIに持たせる（食事/枠/イベント のセレクタを前提とした設計）

### 非目標
- 枠の admin CRUD 管理ページは今回スコープ外（カレンダーからの登録のみ）
- 枠の削除・編集 UI は今回スコープ外
- 料理が割り当てられた枠エントリの枠解除は今回スコープ外

## Design

### データモデル

```
meal_frames
  id, user_id, name, created_at, updated_at

meal_frame_entries
  id, user_id, date, meal_type, meal_frame_id(FK->meal_frames), meal_id(nullable FK->meals), created_at, updated_at
```

- `meal_frame_entries.meal_id` = null → 枠のみ（料理未決定）
- `meal_frame_entries.meal_id` = あり → 料理割り当て済み

既存の `meals` テーブルは変更なし。

### データ例（整合性検証）

枠は `meal_frames` マスタとして保持し、**再利用可能**。同じ「パスタ」枠を複数日に使い回せる。

```
meal_frames（枠マスタ・再利用可能）
id | user_id | name
1  | 1       | パスタ
2  | 1       | 魚料理
3  | 1       | 白米のおかず

meal_frame_entries（日付ごとの枠エントリ）
id | user_id | date       | meal_type | meal_frame_id | meal_id
1  | 1       | 2026-03-24 | 2(夜)     | 1(パスタ)      | null   ← 枠のみ・料理未決定
2  | 1       | 2026-03-25 | 2(夜)     | 2(魚料理)      | 5      ← アジの塩焼き割当済み
3  | 1       | 2026-03-26 | 2(夜)     | 1(パスタ)      | null   ← 同じ「パスタ」枠を別日にも使用

meals（変更なし・dish_id は引き続き必須）
id | user_id | dish_id | date       | meal_type | comment
5  | 1       | 10      | 2026-03-25 | 2(夜)     | null      ← アジの塩焼き
6  | 1       | 20      | 2026-03-24 | 1(昼)     | null      ← 枠と無関係な通常の食事
```

カレンダー表示（2026-03-24）:
- `meal_frame_entries.id=1` → meal_id=null → **FrameCard「パスタ」**（破線ボーダー）
- `meals.id=6` → dish_id=20 → **DishCard「ざるそば」**（通常表示）

カレンダー表示（2026-03-25）:
- `meal_frame_entries.id=2` → meal_id=5 → dish_id=10 → **DishCard「アジの塩焼き」** + 枠ラベル「魚料理」

### 変更点サマリ

| 層 | 変更 |
|---|---|
| DB | `meal_frames` テーブル新規追加 |
| DB | `meal_frame_entries` テーブル新規追加 |
| Domain | `Business::Food::MealFrame::Root` 新規 |
| Domain | `Business::Food::MealFrameEntry::Root` 新規 |
| GraphQL query | `mealFrames` 新規（枠一覧取得） |
| GraphQL query | `mealsForCalendar` → `MealsOfDate` に `frameEntries` フィールド追加 |
| GraphQL mutation | `addMealFrameEntry` 新規（枠をカレンダーに登録） |
| GraphQL mutation | `fillMealFrameEntry` 新規（meal_id を MealFrameEntry にセット。Meal 作成後に resolver がオーケストレーション） |
| UseCase | `MealFrameEntry::Usecase::FillWithMealCommand` 新規（meal_id をセット）。`AddMealCommand` は変更しない |
| Frontend | `AddMealIcon.tsx` → 登録タイプセレクタ付きモーダルに変更 |
| Frontend | `AddMealFrame.tsx` 新規（枠登録フォーム） |
| Frontend | `FrameCard.tsx` 新規（カレンダー上の枠カード） |
| Frontend | `DateCard.tsx` → `frameEntries` を受け取り `FrameCard` を表示 |

### 設計選択と理由（Option B 採用理由）

`meals.dish_id` を nullable にする Option A と比較して Option B（別テーブル）を選んだ理由:

- **エンティティの不変条件を守れる**: `Meal = 日付 + 料理` という定義が崩れない。枠エントリは性質が異なる（料理が決まる前の仮の計画）
- **DishCard の null ハンドリング不要**: フロントエンドの `meal.dish` が常に存在すると仮定できる（既存コードへの影響が最小）
- **カレンダーに2種類のエントリが並ぶことを明示的に表現できる**

トレードオフ: カレンダー取得クエリで2種類のエントリを結合する必要があり、GraphQL 型設計が複雑になる。

### 代替案と棄却理由

**Option A: meals.dish_id を nullable にする**
- 棄却理由: `DishCard` が `meal.dish` は常に存在するという前提で書かれており、nullable にすると既存コードへの影響が広範囲になる。また Meal ドメインエンティティの `dish_id: presence: true` というバリデーションを崩すことになる。

### 主要な実装イメージ

#### GraphQL: MealsOfDate に frameEntries 追加
```ruby
# types/output/meal/calender_meal/meals_of_date.rb
field :frame_entries, [::Types::Output::MealFrameEntry::MealFrameEntryForCalendar], null: false
```

#### Frontend: AddMealIcon → 登録タイプセレクタ
```tsx
// AddCalendarEntryModal（既存 AddMealIcon を拡張）
// 上部に 食事 | 枠 ラジオ（将来 | イベント も追加予定）
// デフォルト: 食事
```

#### Frontend: FrameCard（枠のみ）
```tsx
// 破線ボーダー、枠名表示、クリックで AddMeal フローに移行
// DishCard と同様のカラーバー（薄め）
```

### リスクと対策

| リスク | 対策 |
|---|---|
| カレンダー取得クエリの複雑化 | `mealsForCalendar` の返却型 `MealsOfDate` に `frameEntries` を追加するだけでシンプルに保てる |
| 枠 → 料理割り当て時の競合（同日同食事種別にすでに Meal がある場合）| `AddMealCommand` 内でバリデーション |
| フロントエンドの型（`MealForCalender` / `MealFrameEntryForCalendar`）管理 | codegen で型を生成するため整合性は自動保証 |

### テスト方針

- バックエンド: `MealFrame` モデルバリデーション / `MealFrameEntry` モデルバリデーション / `AddMealCommand`（`frame_entry_id` あり）ユースケース
- フロントエンド: `FrameCard` 表示 / AddCalendarEntryModal のタイプセレクタ挙動 / DateCard での frameEntries 表示

---

## 事前設計議論メモ（揮発防止）

### 問: meals.dish_id を nullable にするか？ → Option B（別テーブル）採用

**議論の論点:**
- Option A（meals.dish_id nullable）: 実装シンプル、だが `Meal = 日付 + 料理` という不変条件を崩す。DishCard の null ハンドリング対応が広範囲
- Option B（meal_frame_entries 別テーブル）: Meal エンティティの不変条件を守れる。カレンダーは2種類のエントリを扱う設計になる

**決定**: Option B。食事と枠は関連はあるが全然違うものなので別テーブルで持つ。

### 問: 枠は毎回新規作成？それとも再利用できる？

**論点:** 「パスタ」という枠を毎回入力するのか、一度作ったら使い回せるのか

**決定:** `meal_frames` はマスタテーブルとして持ち、再利用可能。カレンダーから枠を登録するときは「既存枠から選ぶ / 新規作成」のどちらかを選ぶ。

→ データ例参照（meal_frame_entries.id=1 と id=3 が同じ meal_frame_id=1 を参照）

### 問: +ボタン後のUI → モーダル内タブ/ラジオで型選択

**議論の論点:**
- デフォルト食事の体験を損なわないよう、食事をデフォルト選択で表示
- 将来イベントも並ぶ可能性を考慮し、拡張しやすいラジオ型のセレクタを採用

**決定**: モーダル上部に「食事 / 枠」ラジオ（デフォルト: 食事）。将来 イベント を追加しやすい構造。
