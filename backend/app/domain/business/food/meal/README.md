# Business::Food::Meal

食事（Meal）ドメインのルートモジュール。

## 不変条件・契約（Invariants / Contracts）

### Meal = 日付 + 料理（dish_id は常に必須）

- MUST: `Meal::Root.dish_id` は `presence: true` であり、nullable にしてはならない
- 理由: `Meal` は「ある日に、ある料理を食べた記録」として定義されている。料理が未決定の「枠」は `MealFrameEntry` という別モデルで表現する
- 破ると何が起きるか: `DishCard` は `meal.dish` が常に存在することを前提に書かれており、nullable にすると既存フロントエンドコード全体に null ハンドリングが波及する

### Meal::Frame::* モジュール階層（枠・枠エントリ・パターン）

枠に関する概念はすべて `Meal::Frame::` 傘下に集約されている。

| モジュール | テーブル | 役割 |
|---|---|---|
| `Meal::Frame::Root` | `meal_frames` | 枠マスタ（「パスタ」「魚料理」など）。ユーザー別・再利用可能 |
| `Meal::Frame::Entry::Root` | `meal_frame_entries` | カレンダー上の枠エントリ。`meal_frame_id` で枠を参照し、`meal_id` に料理が割り当てられたら確定済み |
| `Meal::Frame::Pattern::Root` | `meal_frame_patterns` | 複数日分の枠配置パターン。ユーザーが登録・管理する |
| `Meal::Frame::Pattern::Entry::Root` | `meal_frame_pattern_entries` | パターン内の1日1枠定義（`day_offset` + `meal_type` + `meal_frame_id`） |

ディレクトリ対応:
```
meal/frame/
  root.rb        ← Meal::Frame::Root
  entry/         ← Meal::Frame::Entry::Root
  pattern/
    root.rb      ← Meal::Frame::Pattern::Root
    entry/       ← Meal::Frame::Pattern::Entry::Root
```

- MUST: 枠マスタは `meal_frames` で一元管理し、同じ枠を複数日に使い回せる設計を維持する（毎回新規作成しない）
- パターンは「道具」。適用によって生成された `meal_frame_entries` はパターンと独立して存在する（パターン削除で消えない）
- 食事を削除すると `meal_frame_entries.meal_id` は `NULL` へ戻り、**枠はその日に残って未割り当てになる**（`Meal` の `has_one :meal_frame_entry, dependent: :nullify`）。枠は日付と時間帯に対する計画であり、そこへ入る食事とは独立しているため、枠エントリごと消さない

## カレンダークエリの返却構造（`mealsForCalender`）

`mealsForCalender` は2種類のデータを返す。この構造はカレンダーコンポーネントの設計前提になっている。

| フィールド | 内容 | 補足 |
|---|---|---|
| `meals` | 食事データ（LEFT JOIN で `mealFrameEntryId` を付与） | `mealFrameEntryId` が non-null なら枠割り当て済み |
| `frameEntries` | **`meal_id IS NULL` の枠エントリのみ** | 割り当て済み枠はここに含まれない |

- MUST: `frameEntries` から割り当て済み枠エントリを取ることはできない（設計上の契約）
- 「同日の未割り当て食事リスト」を作るには `meals.filter(m => !m.mealFrameEntryId)` でクライアント側フィルタが正しいアプローチ（新クエリは不要）
- やってしまいがちな失敗: `frameEntries` に全枠エントリが含まれると思って実装する → 割り当て済み枠が見えなくなる

### 延期された食事（PostponedMeal）

`Meal::Postponed::Root`（`postponed_meals`）は「この料理を、この時間帯に、いつか食べたい」という意思を表す。日付だけが未決である点で `MealFrameEntry`（料理が未決）と対称的。

- `PostponedMeal` は単体で削除する操作を持たない。一覧から取り除く手段は日付を与えて確定させることだけである
- あるべき姿は延期単体の削除アクションを用意すること。エッジケースであるため見送っている
- この制約により、延期された食事がある料理は `Dish::Usecase::RemoveCommand` で削除を拒否される

## 変更ガイド

### Meal::Root に属性を追加する

以下の3箇所を連動して変更すること:

- `factory.rb` — `Factory.build` のキーワード引数と `Root.new` への渡し方
- `app/models/meal.rb` — `build_existing_root_from_id` でのマッピング（DB → Root）
- `app/models/meal.rb` — `persist_from_food_meal_root` での保存（Root → DB）

## 参照

- `Business::Food::Dish::README.md` — 同様の集約ルートパターン（Dish 側）
- `backend/app/domain/business/food/README.md` — food モジュール全体の役割とアーキテクチャ
