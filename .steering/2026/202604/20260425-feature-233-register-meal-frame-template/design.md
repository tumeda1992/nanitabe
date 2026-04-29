# Design: 食事枠パターン登録・適用機能

## 元の依頼内容

食事枠を1週間分とか、5日分とかまとめたテンプレートとかをfrontendから登録できるようにしたい。

例えば糖質オフ週とかだったら
月: 鶏むね肉料理
火: スープ料理
水: （食事枠空。）
木: サラダ中心
金: 魚料理ん
土: チートデイ
日: 鶏むね肉料理

そもそも食事枠っていうのは、1日ずつ登録するなら、直に食事登録したほうが早い。
まとめて登録できたり、ある一定の型を適用できることで真価を発揮する。1週間分全部決めることは大変だけど、枠が決まっていればあとは枠に当てはめれば終わりっていう思考になる。

1週間とは限らず、3日とかもあるかもしれない。

もちろんこれはユーザごとに違うから、backendでの管理画面ではなく、frontendでユーザがテンプレートを登録する。
フロントエンド側のUIの一例は以下みたいな感じになるかな。フィックスでなくて意図を伝えるために書いているから吟味して再考してほしい。
---
1日目: [肉料理][副菜]
2日目:
3日目: [魚料理]
+
---

---

## 1. TL;DR

ユーザーが複数日分の食事枠パターンを「パターン」として登録・管理し、カレンダーの `+` ボタンから指定日に一括適用できる機能を追加する。新テーブル `meal_frame_patterns`（パターンマスタ）と `meal_frame_pattern_entries`（パターン内の枠定義）を追加する。適用時は resolver が `Frame::Entry::Usecase::AddCommand` を繰り返し呼んで `meal_frame_entries` を一括生成する。パターン自体は「道具」であり、適用済みの `meal_frame_entries` はパターンと独立して存在する。

---

## 前提とする既存仕様

- `meal_frames`: ユーザー別の枠マスタ（パスタ・魚料理など）。`user_id` + `name` を持つ。再利用可能。
- `meal_frame_entries`: カレンダー上の1件の枠エントリ（`user_id`, `date`, `meal_type`, `meal_frame_id`, `meal_id`）。`meal_id` があれば料理割り当て済み。
- `Meal::Frame::Entry::Usecase::AddCommand`: 1件の `MealFrameEntry` を作成する。`date`, `meal_type`, `meal_frame_id`, `user_id` を受け取る。
- `deleteMealFrame` mutation: `MealFrameEntry` が存在する場合は削除をブロックする。
- カレンダーの `+` ボタン: `AddMealIcon.tsx` が「食事 / 枠」2択のタイプセレクタを持つ。「食事」がデフォルト。
- `mealsForCalender` GraphQL query: 日付範囲の `meals` と `frame_entries` を返す。フロントエンドがカレンダーの再取得に使う。

---

## 2. 要件（Requirements）

### MUST（必達）
- ユーザーがパターンを作成・更新・削除できる（名前のみ管理）
- パターンに「何日目の何の食事タイプにどの枠を使うか」（`day_offset`, `meal_type`, `meal_frame_id`）のエントリを追加・削除できる
- パターンをカレンダーの `+` ボタンから適用できる（開始日 = クリックした日がデフォルト）
- パターンはユーザー別に管理される（他ユーザーのパターンは参照・適用不可）
- パターンが参照している `meal_frame` を削除しようとした場合、削除がブロックされる

### SHOULD（できれば）
- パターン一覧ページからも適用できる（補完的 UX。カレンダーの文脈なしで開始日を手入力する形になる）

### 非目標
- パターン適用時の既存エントリとの競合チェック（重複していても追加するだけ）
- パターンの中間日の削除・並べ替え（末尾追加・末尾削除のみ）
- 末尾が空の日を明示的に保持する（末尾が空なら、その日はパターンに含めない）
- 適用履歴（どのパターンから `meal_frame_entries` が生成されたか）の管理

### 受け入れ基準
- パターン CRUD がフロントエンドから完結する
- パターンを適用するとカレンダーに FrameCard が表示される
- カレンダーの `+` ボタン → 「枠パターン適用」タブ → パターン選択 + 開始日 → 適用 → FrameCard 表示 の一連の流れが動く

---

## 事前設計議論メモ（揮発防止）

### 論点A: `duration_days` フィールドの要否 → 不要

パターン長 = `max(day_offset)` のエントリで暗黙的に管理する。末尾が空の日を保持する要件は現時点では明確でないため、シンプルな設計を優先する。UX 問題が発生したら後で `duration_days` を追加する。

### 論点B: パターン適用のエントリポイント → カレンダー + ボタン

日付はカレンダーを見ながら決めるため、カレンダーの `+` ボタンを主とする。クリックした日が開始日のデフォルト。別ページで日付を確認するのが面倒という UX 上の理由。パターン一覧ページからの適用は補完（SHOULD）。

### 論点C: パターン削除時のエントリ扱い → cascade delete + 適用済みは独立

- `meal_frame_pattern_entries` → パターン削除時に cascade delete（パターンの構成定義であり、パターンと一体）
- 適用済みの `meal_frame_entries` → パターン削除の影響を受けない（パターンは「道具」、`meal_frame_entries` は実態）
- 適用履歴テーブル → 今回スコープ外

### 論点D: コンセプト命名 → 「パターン」（テンプレートを棄却）

「テンプレート」は「それを使ってなにかを作る」という利用法からつけた名前。「パターン」はデータ構造の本質（複数日の枠の配置）を指し、「このパターンを繰り返す」という将来的なサイクル機能とも整合性が高い。ドメインの本質から命名する原則に従い「パターン」を採用する。

### 論点E: UI セレクタラベル → 「枠パターン適用」

カレンダーの `+` ボタンのセレクタ表示名を「枠パターン適用」とする。「枠パターン」だと「食事を登録/枠を登録」という並びの中で「枠パターンを登録（新規作成）」と読めてしまう。「適用」を明示することで「この選択肢はパターンを当てはめる操作」と伝わる。選択後の次画面でも「パターン」という言葉を使うため、用語が一貫する。

---

## 3. 完成後の姿

### 3-1. 操作フロー

**ケース1: パターン作成**

```
① ユーザーが /mealframepatterns/new を開く
② 名前「糖質オフ週」を入力し、「日を追加」を7回押す（7日分のスロット表示）
③ day1 の「+ 枠を追加」→ meal_type=朝・meal_frame=ヨーグルト を選択
④ day1 の「+ 枠を追加」→ meal_type=夜・meal_frame=鶏むね肉料理 を選択（同日2枠の例）
⑤ day2 の「+ 枠を追加」→ meal_type=夜・meal_frame=スープ料理 を選択
⑥ day3 は何も追加しない（空のまま）
⑦ day4〜7 に枠を追加（同じフロー繰り返し）
⑧ 「作成する」を押す
⑨ フロントエンドが addMealFramePattern を1回だけ呼ぶ（名前とエントリを一括で渡す）
   name: "糖質オフ週"
   entries: [
     {day_offset: 1, meal_type: 1(朝), meal_frame_id: 4},
     {day_offset: 1, meal_type: 3(夜), meal_frame_id: 5},
     {day_offset: 2, meal_type: 3(夜), meal_frame_id: 6},
     // day3 はエントリなし（空の日はエントリを送らない）
     {day_offset: 4, meal_type: 3(夜), meal_frame_id: 7},
     ...
   ]
⑩ resolver: 1トランザクションで pattern 作成 + 全エントリ作成
⑪ /mealframepatterns へ遷移
```

**ケース2: パターンをカレンダーから適用**

```
① ユーザーがカレンダーで月曜(2026-04-28)の + ボタンを押す
② 「食事 / 枠 / 枠パターン適用」タイプセレクタが表示される（食事がデフォルト）
③ 「枠パターン適用」タブを選択
④ パターン一覧から「糖質オフ週」を選択
⑤ 開始日 = 2026-04-28（クリックした日がデフォルト入力済み）で「適用する」ボタンを押す
⑥ フロントエンドが applyMealFramePattern(pattern_id: 1, start_date: "2026-04-28") を呼ぶ
⑦ resolver: pattern の全エントリを取得（day_offset=1,2,4,5,6,7 の7件）
⑧ resolver: 各エントリに対して Frame::Entry::Usecase::AddCommand を呼ぶ
   - day_offset=1 → date=2026-04-28, meal_type=1, meal_frame_id=4(ヨーグルト)
   - day_offset=1 → date=2026-04-28, meal_type=3, meal_frame_id=5(鶏むね肉料理)
   - day_offset=2 → date=2026-04-29, meal_type=3, meal_frame_id=6(スープ料理)
   - （day_offset=3 はエントリなし → 2026-04-30 は何もしない）
   - day_offset=4 → date=2026-05-01, meal_type=3, meal_frame_id=7(サラダ中心)
   - ...
⑨ 合計7件の MealFrameEntry が生成される
⑩ フロントエンドがモーダルを閉じてカレンダーを再取得
⑪ カレンダーの各日に FrameCard が表示される
```

**ケース3: パターンのエントリ編集（枠の追加・削除）**

```
① ユーザーが /mealframepatterns/1/edit を開く
② パターンの既存エントリが日別に表示される
③ day5 の [魚料理 ×] の × を押す → UI から削除（まだ API 呼ばない）
④ day8 の「+ 枠を追加」→ meal_type=朝・meal_frame=鶏むね肉料理 を追加 → UI に追加（まだ API 呼ばない）
⑤ 「更新する」ボタンを押す
⑥ フロントエンドが updateMealFramePattern を1回だけ呼ぶ（名前と現在のエントリ全件を一括で渡す）
   id: 1
   name: "糖質オフ週"
   entries: [現在の UI 上のエントリ全件（削除・追加後の状態）]
⑦ resolver: 1トランザクションで name 更新 + 既存エントリ全削除 + 新規エントリ全件作成
⑧ /mealframepatterns へ遷移
```

### 3-2. データモデル

**meal_frame_patterns（パターンマスタ）**

| id | user_id | name | created_at |
|----|---------|------|------------|
| 1  | 1       | 糖質オフ週 | 2026-04-25 |
| 2  | 1       | 3日魚中心  | 2026-04-25 |

**meal_frame_pattern_entries（パターンエントリ）**

| id | meal_frame_pattern_id | day_offset | meal_type | meal_frame_id |
|----|-----------------------|------------|-----------|---------------|
| 1  | 1                     | 1          | 1(朝)      | 4(ヨーグルト)    |
| 2  | 1                     | 1          | 3(夜)      | 5(鶏むね肉料理)  |
| 3  | 1                     | 2          | 3(夜)      | 6(スープ料理)   |
| 4  | 1                     | 4          | 3(夜)      | 7(サラダ中心)   |
| 5  | 1                     | 5          | 3(夜)      | 8(魚料理)      |
| 6  | 1                     | 6          | 3(夜)      | 9(チートデイ)   |
| 7  | 1                     | 7          | 3(夜)      | 5(鶏むね肉料理)  |

※ id=1,2 が同じ day_offset=1 → 月曜（1日目）に朝・夜の2枠を登録した例。同一 day_offset に meal_type の異なるエントリを複数持てる。
※ day_offset=3（水曜）はエントリなし → 空の日。フロントエンドは max(day_offset)=7 から7日分を表示し、day3 を空スロットで表示する。

**典型ケース:**
- **パターン1（糖質オフ週）**: 7日間で水曜(day3)が空。1日目は朝・夜の2枠。エントリ数=7。適用時に day3 の date には MealFrameEntry が生成されない。
- **パターン2（3日魚中心）**: 3日間で全日に枠あり。エントリ数=3。
- **パターン適用後の meal_frame_entries（参考）**:

| id | user_id | meal_frame_id | date       | meal_type | meal_id |
|----|---------|---------------|------------|-----------|---------|
| 10 | 1       | 4             | 2026-04-28 | 1         | null    |
| 11 | 1       | 5             | 2026-04-28 | 3         | null    |
| 12 | 1       | 6             | 2026-04-29 | 3         | null    |
| （2026-04-30 は何も生成されない） |
| 13 | 1       | 7             | 2026-05-01 | 3         | null    |

パターンを削除しても、上記 meal_frame_entries は残る（独立）。

### 3-3. クラス・API 設計

**新設クラス（バックエンド）:**

- `Business::Food::Meal::Frame::Pattern::Root`
  - attributes: `id`, `user_id`, `name`
  - `rename(new_name)`: パターン名変更
    - 根拠: 既存 `Frame::Root#rename` と命名規則を合わせる。`set_name` / `update_name` は禁止命名
  - `set_id(new_id)`: DB 採番後 ID 設定（既存 `Frame::Root` / `Frame::Entry::Root` と同パターン）

- `Business::Food::Meal::Frame::Pattern::Entry::Root`
  - attributes: `id`, `meal_frame_pattern_id`, `day_offset`, `meal_type`, `meal_frame_id`
  - `set_id(new_id)`: DB 採番後 ID 設定

**リネーム（既存）:**

- `Business::Food::Meal::FrameEntry::Root` → `Business::Food::Meal::Frame::Entry::Root`
  - ディレクトリ: `meal/frame_entry/` → `meal/frame/entry/`
  - AR モデル・GraphQL resolver・spec の参照も全更新

**新設 Command:**

- `Meal::Frame::Pattern::Usecase::AddCommand`: パターンを作成する
- `Meal::Frame::Pattern::Usecase::UpdateCommand`: パターンを更新する（name + entries 全置換）
- `Meal::Frame::Pattern::Usecase::RemoveCommand`: パターンを削除する（エントリを cascade delete）
- `Meal::Frame::Pattern::Entry::Usecase::AddCommand`: パターンエントリを1件追加する（resolver から呼ばれる。直接 mutation は持たない）
- `Meal::Frame::Pattern::Entry::Usecase::RemoveAllByPatternCommand`: パターンの全エントリを削除する（update 時の置換用）

**新設 GraphQL mutation:**

| mutation | 引数 | 返り値 |
|----------|------|--------|
| `addMealFramePattern` | `meal_frame_pattern: {name: String!, entries: [{day_offset: Int!, meal_type: Int!, meal_frame_id: Int!}]!}` | `{ meal_frame_pattern_id: Int! }` |
| `updateMealFramePattern` | `meal_frame_pattern: {id: Int!, name: String!, entries: [{day_offset: Int!, meal_type: Int!, meal_frame_id: Int!}]!}` | `{ meal_frame_pattern_id: Int! }` |
| `deleteMealFramePattern` | `id: Int!` | `{ meal_frame_pattern_id: Int! }` |
| `applyMealFramePattern` | `pattern_id: Int!, start_date: String!` | `{ applied_meal_frame_pattern_id: Int! }` |

※ `addMealFramePatternEntry` / `removeMealFramePatternEntry` は MVP スコープ外。パターン登録・更新は必ず一括バッチで行う。

**新設 GraphQL query:**

| query | 返り値 |
|-------|--------|
| `mealFramePatterns` | `[{ id, name, entries: [{ id, day_offset, meal_type, meal_frame_id, meal_frame_name }] }]` |

**既存修正:**

- `Meal::Frame::Usecase::RemoveCommand`: `MealFramePatternEntry` への参照が存在する場合も削除をブロックする
- `Meal::Frame::Entry::*`: `Meal::FrameEntry::*` からのリネーム（ディレクトリ移動 + 全参照更新）

**フロントエンド ルート:**

- `/mealframepatterns` - パターン一覧（SHOULD: 各パターンに「適用」ボタン）
- `/mealframepatterns/new` - パターン作成
- `/mealframepatterns/[id]/edit` - パターン編集

**フロントエンド カレンダー変更:**

- `AddMealIcon.tsx`: 「食事 / 枠 / 枠パターン適用」3択セレクタに拡張
- 「枠パターン適用」タブ内コンポーネント: パターン選択 + 開始日入力（default = クリックした日）+ 「適用する」ボタン

---

## 4. なぜこの姿か（設計判断）

### 設計選択と理由

**ドメインモジュール配置: `Meal::Frame::Pattern` / `Meal::Frame::Pattern::Entry`**
- `Frame` 傘下に関連する全概念（枠マスタ・カレンダーエントリ・パターン・パターンエントリ）を集約する
- `Frame::Pattern` は `MealFrame` の文脈でのみ意味を持つ（食事の枠のパターン）。独立トップレベルモジュールは不要

**`applyMealFramePattern` の一括生成は resolver が担う**
- `Frame::Pattern` → `Frame::Entry` の作成は異なる集約間のオーケストレーション
- 既存アーキテクチャ指針「異なる集約をまたぐオーケストレーションはプレゼンテーション層が担う」に従う

**パターンエントリは `meal_frame_id` を参照する（名前ではなく）**
- `MealFrameEntry` が `meal_frame_id` を参照するのと一貫性を保つ
- 適用時に `meal_frame_id` を解決する処理が不要になる

**cascade delete（パターン削除時）**
- `meal_frame_pattern_entries` はパターンの構成定義であり、パターンなしに単独で存在する意味がない
- 適用済みの `meal_frame_entries` は独立した実態（パターンは「道具」）

**`addMealFramePattern` / `updateMealFramePattern` はエントリを一括バッチで受け取る**
- フロントエンドが「パターン作成 → N件のエントリ作成」と複数回 API を叩く設計では、パターンだけ作られてエントリが欠ける部分適用が起きる
- mutation をまたいだ `ActiveRecord::Base.transaction` は機能しない
- パターンとそのエントリは「一体として登録される」不変条件を API 設計に反映し、resolver が1トランザクションで完結させる

### 代替案と棄却理由

- **フロントエンドから `addMealFramePattern` → N回 `addMealFramePatternEntry` を呼ぶ**: トランザクション保証がなく途中失敗でデータ不整合が起きる。フロントエンドのオーケストレーション責務になる。棄却。
- **フロントエンドから `addMealFrameEntry` を N 回呼んで適用（applyMealFramePattern の代替）**: N 回のラウンドトリップが発生し、途中失敗時に部分適用が起きるリスクがある。`applyMealFramePattern` 1 mutation で原子性を確保する方が安全。棄却。
- **パターンエントリに `meal_frame_id` でなく `name`（文字列）を持たせる**: 適用時に `name` → `meal_frame_id` の解決処理が必要になり、存在しない枠名が入力できてしまうリスクも生まれる。棄却。

---

## 5. リスクと対策

| リスク | 対策 |
|--------|------|
| パターンが参照する `meal_frame` を削除するとエントリが broken になる | `deleteMealFrame` の `RemoveCommand` に `MealFramePatternEntry` 存在チェックを追加する |
| パターン適用時に同日同食事タイプに既に FrameEntry が存在する | 初期 MVP では未チェック（重複追加を許容）。カレンダー上で重複 FrameCard が並ぶ。将来改善 |
| `PatternEntry` で `day_offset` に不正な値が入る（0 以下、超大値）| `Frame::Pattern::Entry::Root` に `day_offset: numericality: { greater_than: 0 }` バリデーション追加 |
| `applyMealFramePattern` でパターン所有者≠ログインユーザーの場合 | resolver で `pattern.user_id == current_user_id` を確認する（既存パターンに倣う）|

---

## 6. テスト方針

**バックエンド:**
- `Frame::Pattern::Root`: バリデーション（name presence）
- `Frame::Pattern::Usecase::AddCommand`: 正常作成
- `Frame::Pattern::Usecase::UpdateCommand`: 名前変更
- `Frame::Pattern::Usecase::RemoveCommand`: 削除成功 / `PatternEntry` 存在時は cascade delete されること
- `Frame::Pattern::Entry::Usecase::AddCommand`: 正常作成 / day_offset バリデーション
- `Frame::Pattern::Entry::Usecase::RemoveAllByPatternCommand`: パターンID指定で全削除
- `applyMealFramePattern` resolver: 正常ケース（空の日を含む）/ パターン所有者チェック
- `Meal::Frame::Usecase::RemoveCommand`（修正分）: `FramePatternEntry` 存在時の削除ブロック

**フロントエンド:**
- `MealFramePatternForm`: 日の追加・削除、枠の追加・削除のインタラクション
- `MealFramePatternList`: 一覧表示
- `AddMealIcon`: 枠パターン適用タブ追加後の 3 択セレクタ切り替え
- パターン適用フォームコンポーネント: パターン選択 + 開始日入力

---

## （付録）変更点一覧

### バックエンド

| 対象 | 変更内容 |
|------|----------|
| **【リネーム】** `app/domain/business/food/meal/frame_entry/` | `meal/frame/entry/` へ移動。`Business::Food::Meal::FrameEntry::*` → `Meal::Frame::Entry::*` に全リネーム |
| **【リネーム】** AR モデル・GraphQL resolver・spec の `FrameEntry` 参照 | `Frame::Entry` に全更新 |
| DB migration | `meal_frame_patterns` テーブル新規追加（id, user_id, name） |
| DB migration | `meal_frame_pattern_entries` テーブル新規追加（id, meal_frame_pattern_id, day_offset, meal_type, meal_frame_id） |
| `app/models/meal_frame_pattern.rb` | 新規 AR モデル（`belongs_to :user`, `has_many :meal_frame_pattern_entries, dependent: :destroy`） |
| `app/models/meal_frame_pattern_entry.rb` | 新規 AR モデル（`belongs_to :meal_frame_pattern`, `belongs_to :meal_frame`） |
| `app/domain/business/food/meal/frame/pattern/root.rb` | 新規ドメインモデル（`Meal::Frame::Pattern::Root`） |
| `app/domain/business/food/meal/frame/pattern/entry/root.rb` | 新規ドメインモデル（`Meal::Frame::Pattern::Entry::Root`） |
| `Meal::Frame::Pattern::Usecase::AddCommand` | 新規 |
| `Meal::Frame::Pattern::Usecase::UpdateCommand` | 新規 |
| `Meal::Frame::Pattern::Usecase::RemoveCommand` | 新規 |
| `Meal::Frame::Pattern::Entry::Usecase::AddCommand` | 新規（resolver から呼ばれる。直接 mutation は持たない） |
| `Meal::Frame::Pattern::Entry::Usecase::RemoveAllByPatternCommand` | 新規（update 時の全置換用） |
| GraphQL Input 型 | `MealFramePatternForCreate`（name + entries[]）, `MealFramePatternForUpdate`（id + name + entries[]）, `MealFramePatternEntryInput` 新規 |
| GraphQL Output 型 | `MealFramePatternForList`（entries 含む）新規 |
| GraphQL Mutation (4種) | `addMealFramePattern`, `updateMealFramePattern`, `deleteMealFramePattern`, `applyMealFramePattern` 新規 |
| GraphQL Query | `mealFramePatterns` 新規 |
| `Meal::Frame::Usecase::RemoveCommand` | `MealFramePatternEntry` 存在チェック追加 |

### フロントエンド

| 対象 | 変更内容 |
|------|----------|
| **【リネーム】** `src/features/mealFrame/` | `src/features/meal/frame/` へ移動。全インポートパスを更新 |
| `src/features/meal/frame/pattern/` | 新規 feature ディレクトリ（mutations/query/hook） |
| `src/app/mealframepatterns/page.tsx` | パターン一覧ページ 新規 |
| `src/app/mealframepatterns/new/page.tsx` | パターン作成ページ 新規 |
| `src/app/mealframepatterns/[id]/edit/page.tsx` | パターン編集ページ 新規 |
| `src/components/mealFramePattern/MealFramePatternForm.tsx` | 作成・編集フォーム（日スロット管理・枠追加・削除 UI）新規 |
| `src/components/mealFramePattern/MealFramePatternList.tsx` | 一覧表示コンポーネント 新規 |
| `src/components/calendar/calendarComponents/MealIcon/AddMealPattern/index.tsx` | パターン適用フォームコンポーネント 新規 |
| `src/components/calendar/calendarComponents/MealIcon/AddMealIcon.tsx` | タイプセレクタを「食事 / 枠 / 枠パターン適用」3択に拡張 |
| ナビゲーション | `/mealframepatterns` リンク追加 |
