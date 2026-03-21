# ロードマップ: 食事の枠（MealFrame）機能

## 概要

食事のプレースホルダー（枠）機能を段階的に追加する。

MealFrame は「パスタ」「魚料理」のようなユーザーが定義する枠のマスタであり、ユーザーごとに作成・更新・削除される一人前のビジネスオブジェクトとして扱う。

まず MealFrame 自体が成立する状態（CRUD + カレンダーへの枠表示）を作り、その後に食事との関連付けを追加する2段階構成にする。将来的には週・月単位の一括登録ページも追加する。

このロードマップは大ブロック一覧。各フェーズは独立して別途 steering を作り実装する。
各フェーズ完了時点でアプリが正常動作する状態を保つこと。

---

## フェーズ1: MealFrame として成立する

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

子 steering: TBD（着手時に作成）
ステータス: 未着手

---

## フェーズ2: 食事への割り当て

### DoD（完了条件）
- FrameCard をクリックして料理を登録すると DishCard に変わり、枠名ラベルが残る
- `addMeal` 系 mutation に `frame_entry_id` を渡せる

### タスク概要
- バックエンド: `AddMealCommand` に `frame_entry_id`(optional) 追加
- GraphQL: `addMeal` / `addMealWithNewDish` / `addMealWithNewDishAndNewSource` に `frame_entry_id` 追加
- フロントエンド: FrameCard クリック → `frame_entry_id` 付きで AddMeal フォームを開く
- フロントエンド: DishCard に枠名ラベル表示

子 steering: TBD（フェーズ1完了後に作成）
ステータス: 未着手

---

## フェーズ3: 週・月単位の枠一括登録ページ（将来）

### DoD（完了条件）
- TBD

### タスク概要
- 1週間分・1ヶ月分の枠をまとめて登録できるフロントエンドページ
- 詳細はフェーズ2完了後に設計する

子 steering: TBD
ステータス: 未着手

---

## 振り返り

### 全フェーズ完了日
TBD

### 計画と実績の差分
-
