# 要件ドキュメント

## はじめに
料理に「手間」フィールドを追加する。ユーザーが分数を直接入力するのではなく、分数とラベルをセットにした専用テーブル（`dish_effort_levels`）を作り、料理はそのレコードに紐付ける形で管理する。mealPosition によって選択肢が変わる。

## 元の依頼内容
料理に「手間」のフィールドを加えたい。

「ぱぱっとできる」重いとか「1日かかる」ほど簡単かとかがわかりたい

非連続な値での管理ではなく、目安分数による連続値で管理したい。ラベルのソートや、必要なときは料理自体のソートにもその連続値を使う
ただ、ユーザに分数を入力させたくないから、分数とラベルのセットのテーブルがあり、料理とはそのテーブルのレコードを紐付ける形にしたい。

体感としては20分かかるのがメインディッシュとしては普通の感覚で、
10分だとぱぱっとできて簡単で、
1時間弱かかるとかは少し手間で
2,3時間かかると、結構手間で、
1日かかるとかは地獄。
体感を伝えたのは、選択肢を切る単位を示したかっただけで、ラベルに「地獄」とかは今のところ入れなくていいかな

副菜とかだと、また変わるから、 mealPosition によって変わるかな。
副菜は5分でできるなら簡単で
10分くらいかかる印象で、
30分とかかかるなら少し手間で
1時間かかるなら結構手間
基本的に、主食・メインディッシュ・副菜あたりに設定できればよく、主食はメインディッシュと同じようなラインナップ。でも同じ値を使うにしても別レコードで管理したほうがいいかな。

料理としては、このフィールドはnullでokで、わざわざこれを設定したいときにことさら値を入れる感じかな。
料理のソートで使うときにはnullの場合には mealPosition ごとのデフォルト値をソースコードにハードコーディングして、その値で埋めてソートしてもらう感じになるかな。まだ料理でのソートは考えてないけど。
まだデザイン考えてないけど、料理にはデフォルト値じゃない場合「目安料理時間」的なもので表示したいな。こんな野暮ったいラベルじゃないけど。思いつきだけど「{時計マーク} 10分」とかかな


## 要件

### MUST
- `dish_effort_levels` テーブルを作り、`minutes`（目安分数）と `label`（表示用ラベル）と `meal_position` を持つ
- 料理（dishes）は `dish_effort_level_id` を nullable FK で持つ（設定しない料理がある）
- 料理フォームで手間を選択できる。選択肢は料理の mealPosition に応じて切り替わる
- デフォルト値でない場合（= effort が設定されている場合）のみ、料理カードに表示する
  - 表示イメージ: 「🕐 10分」（時計アイコン + minutes）

### 非目標
- 汁物・デザート・その他（meal_position 4, 5, 50）への手間設定は今回対象外。初期データを用意せず、フォームに選択肢も出さない
- 料理一覧のソート機能（ソート用のデフォルト値ハードコーディングは設計に含めるが、実際のソート実装は今回対象外）
- ユーザーごとに異なる選択肢（全ユーザー共通の固定テーブル）

### 受け入れ基準
1. WHEN mealPosition が「主食」「メインディッシュ」「副菜」の料理を作成・編集する THEN 手間の選択肢が表示される
2. WHEN 手間を選ばずに料理を登録する THEN `dish_effort_level_id` が null で保存される
3. WHEN 手間を設定した料理のカードを表示する THEN 「🕐 XX分」が表示される
4. WHEN 手間を設定していない料理のカードを表示する THEN 手間の表示がない
5. WHEN mealPosition を変更する THEN 手間の選択肢がその mealPosition のものに切り替わる（選択済みの値はリセット）

---

# 設計ドキュメント

## TL;DR
`dish_effort_levels` テーブルを新設し、meal_position ごとに「分数 + ラベル」のマスタデータを持つ。料理は nullable FK でこのテーブルと紐付く。バックエンドは GraphQL で levels 一覧クエリと料理更新 mutation を提供。フロントはフォームに選択 UI を追加し、カードに分数表示を追加する。

## 変更点サマリ

### バックエンド
| ファイル | 変更内容 |
|---|---|
| マイグレーション（新規） | `dish_effort_levels` テーブル作成 |
| マイグレーション（新規） | `dishes.dish_effort_level_id` カラム追加 |
| シードデータ | 主食・メインディッシュ・副菜の初期 effort levels 投入 |
| `app/models/dish_effort_level.rb`（新規） | AR モデル |
| `app/models/dish.rb` | `belongs_to :dish_effort_level, optional: true` 追加 |
| `app/graphql/queries/dish/effort_level/dish_effort_levels.rb`（新規） | meal_position を受け取り effort levels 一覧を返すクエリ |
| `app/graphql/types/output/dish/effort_level/dish_effort_level.rb`（新規） | GraphQL 出力型 |
| `app/graphql/types/input/dish/dish_for_create.rb` | `dish_effort_level_id` 引数を追加（nullable） |
| `app/graphql/types/input/dish/dish_for_update.rb`（または同等） | 同上 |
| `app/domain/business/food/dish/root.rb` | `effort_level_id` 属性を追加 |
| `app/controllers/admin/food/dish/effort_level/dish_effort_levels_controller.rb`（新規） | 管理画面 CRUD コントローラー（`normalize_words_controller` と同パターン） |
| `app/views/admin/food/dish/effort_level/dish_effort_levels/`（新規） | 管理画面 views（index/new/edit） |
| `config/routes.rb` | `admin/food/dish/effort_level` リソースを追加 |

### フロントエンド
| ファイル | 変更内容 |
|---|---|
| `src/features/dish/fetchDishQuery.ts` | `dishEffortLevels` クエリ追加 |
| `src/features/dish/` | effort levels 取得用 hook 追加 |
| `src/components/dish/DishForm/DishForm/SelectEffortLevel.tsx`（新規） | 手間選択 UI |
| `src/components/dish/DishForm/DishForm/index.tsx` | フォームに SelectEffortLevel を組み込み |
| `src/components/dish/DishSearchCard/index.tsx` | `effortLevelMinutes` props 追加・表示追加 |
| `src/features/dish/fetchDishQuery.ts` | `existingDishesForRegisteringWithMeal` クエリに effort 情報を追加 |

## 初期データ案

| meal_position | minutes | label |
|---|---|---|
| 主食 (1) | 10 | ぱぱっとできる |
| 主食 (1) | 20 | 普通 |
| 主食 (1) | 50 | 少し手間 |
| 主食 (1) | 150 | 結構手間 |
| 主食 (1) | 480 | かなり手間 |
| メインディッシュ (2) | 10 | ぱぱっとできる |
| メインディッシュ (2) | 20 | 普通 |
| メインディッシュ (2) | 50 | 少し手間 |
| メインディッシュ (2) | 150 | 結構手間 |
| メインディッシュ (2) | 480 | かなり手間 |
| 副菜 (3) | 5 | ぱぱっとできる |
| 副菜 (3) | 10 | 普通 |
| 副菜 (3) | 30 | 少し手間 |
| 副菜 (3) | 60 | 結構手間 |

## ソート用デフォルト値（ハードコーディング）

今回ソート機能は実装しないが、将来対応したときのためにソースコードに定義だけ置く:

```ruby
# app/models/dish.rb または定数ファイル
EFFORT_DEFAULT_MINUTES_BY_MEAL_POSITION = {
  1 => 20,  # 主食
  2 => 20,  # メインディッシュ
  3 => 10,  # 副菜
}.freeze
```

## 設計選択と理由

### 1. `dish_effort_levels` を独立テーブルにする
- ユーザー指定の要件そのまま
- 分数とラベルの組み合わせは将来変更・追加が起きうるため、テーブルで管理が適切
- `DishEvaluation`（1対1関連テーブル）ではなく、マスタテーブルに FK を持つ形（meals に近い）

### 2. `dish_effort_levels` は全ユーザー共通（user_id を持たない）
- 評価（DishEvaluation）は「ユーザーが料理に付ける評価」なので user_id を持つ
- effort levels は「この料理が一般的に何分かかるか」のマスタ情報なのでユーザー依存しない

### 3. フォームの選択肢切り替え（mealPosition 連動）
- `SelectEffortLevel` コンポーネントが `mealPosition` prop を受け取り、対応する levels を GraphQL で取得
- mealPosition 変更時は選択済みの effort level をリセット（別 mealPosition のレコードに紐付いたままになるのを防ぐ）

### 4. カード表示は minutes を表示（label ではない）
- ユーザーの例示「🕐 10分」が minutes を使っている
- label（「少し手間」など）は選択時の判断材料として使い、カードでは直感的な分数表示にする
- フォームの選択肢は「10分 - ぱぱっとできる」のように時間とラベルを両方示す
- 分数の表示変換（フロントのヘルパー）: 60分未満 → 「XX分」、60分以上 → 「1時間」「2時間30分」等

---

## Dish ビジネスロジックの変更詳細

### 1. `Business::Food::Dish::Root` に `effort_level_id` を追加

```ruby
# app/domain/business/food/dish/root.rb
attribute :effort_level_id, :integer
validates :effort_level_id, presence: false  # nullable

def assign_effort_level(new_effort_level_id)
  self.effort_level_id = new_effort_level_id  # nil も許容（手間設定を外す）
end
```

### 2. `Usecase::Params::Dish` に `effort_level_id` を追加

```ruby
# app/domain/business/food/dish/usecase/params/dish.rb
attribute :effort_level_id, :integer
# バリデーションなし（nullable）
```

### 3. `AddCommand` の変更

`Factory.build` に `effort_level_id` を渡す。

```ruby
# app/domain/business/food/dish/usecase/add_command.rb
dish_root = Business::Food::Dish::Factory.build(
  user_id,
  dish_params.name,
  dish_params.meal_position,
  comment: dish_params.comment,
  effort_level_id: dish_params.effort_level_id,  # 追加
  source:,
  source_locator:,
  tags: dish_tags.map { |tag| tag.to_root(user_id) },
)
```

※ `Factory.build` でも `effort_level_id:` を受け取るよう変更が必要。

### 4. `UpdateCommand` の変更

`update_dish_root` で effort_level_id を更新する。`nil` を渡した場合は「手間設定なし」に変更する意図なのか、「変更しない」意図なのか区別が必要。ここでは **`dish_params` に `effort_level_id` キーが含まれていれば（nil も含め）更新する** 方針とする（Rails の `unless dish_params.effort_level_id.nil?` ではなく `unless dish_params.to_hash.key?(:effort_level_id)` で判定）。

ただし `CommandParams` の属性がデフォルト nil のため、「キーを持つかどうか」の判定方法は実装時に確認が必要。現状の他フィールドのパターン（`dish_params.name.present?` で更新判定）に合わせ、今回は送信された値で無条件に更新する形とする。

```ruby
# app/domain/business/food/dish/usecase/update_command.rb
def update_dish_root(dish_root, dish_params, ...)
  dish_root.rename(dish_params.name) if dish_params.name.present?
  dish_root.reposition_in_meal(dish_params.meal_position) if dish_params.meal_position.present?
  dish_root.revise_comment(dish_params.comment) unless dish_params.comment.nil?
  dish_root.assign_effort_level(dish_params.effort_level_id)  # 追加（nil も更新）
  # ...
end
```

### 5. `Dish` AR モデルの変更

#### `build_existing_root_from_id` に `effort_level_id` を追加

```ruby
# app/models/dish.rb
def self.build_existing_root_from_id(id)
  dish_record = find_by(id: id)
  return if dish_record.blank?
  # ...
  ::Business::Food::Dish::Root.new(
    id: dish_record.id,
    # ...
    effort_level_id: dish_record.dish_effort_level_id,  # 追加
  )
end
```

#### `persist_from_food_dish_root` に `effort_level_id` を追加

```ruby
# app/models/dish.rb
def persist_from_food_dish_root(food_dish_root)
  self.name = food_dish_root.name.value
  # ...
  self.dish_effort_level_id = food_dish_root.effort_level_id  # 追加
  save!
  # ...
end
```

#### `with_search_relations` と `search_output` の変更

カード表示用に `effort_level_minutes` を取得するため:

```ruby
# with_search_relations に LEFT JOIN を追加
scope :with_search_relations, -> {
  # 既存のサブクエリ...
  joins("LEFT JOIN (#{meals_count_subquery.to_sql}) AS meal_counts ON ...")
    .left_joins(:dish_source, :dish_source_relation, :dish_evaluation, :dish_tags,
                :dish_effort_level)  # 追加
    .preload(:dish_source, :dish_source_relation, :dish_evaluation, :dish_tags,
             :dish_effort_level)  # 追加
}

# search_output の select に追加
select_clauses.push("dish_effort_levels.minutes AS effort_level_minutes")
```

#### `to_searched_values` の変更

`effort_level_minutes` は `search_output` の select で `attributes` に自動的に入るため `to_searched_values` の変更は不要。

### 6. GraphQL 型の変更

```ruby
# app/graphql/queries/dish/existing_dishes_for_registering_with_meal.rb
class ExistingDishForRegisteringWithMeal < ::Types::BaseObject
  implements ::Types::Output::Dish::DishFields
  field :dish_source_name, String, null: true
  field :effort_level_minutes, Int, null: true  # 追加
end
```

## 代替案と棄却理由

**案: `dishes` テーブルに `effort_minutes` を直接追加し、フロントでラベルを管理**
- ユーザーが「分数とラベルのセットのテーブルがあり」と明示しているため却下
- labels をコードに持つと、mealPosition ごとの差異や将来の変更に対応しにくい

**案: `dish_effort_levels` に `is_default` フラグを持ち、ソートデフォルトをDBで管理**
- ソート機能は今回実装しないので不要。ハードコーディングで十分
- テーブルに状態を持たせると変更時にデータ操作が必要になり保守コストが上がる

## リスクと対策
- `dish_effort_levels` は全ユーザー共通なので、将来的にラベルを変更すると全料理の表示が変わる。今回は初期データを慎重に決めること
- mealPosition を変更したとき既存の effort_level_id が別 mealPosition のレコードを指す可能性がある → フロントで mealPosition 変更時に effort_level_id をリセットする

## テスト方針
- バックエンド: `DishEffortLevel` モデルのバリデーション、`dishEffortLevels` クエリが meal_position で正しく絞り込めること
- バックエンド: 料理作成・更新時に `effort_level_id` が正しく保存・変更されること
- フロントエンド: `SelectEffortLevel` が mealPosition に応じた選択肢を表示すること、mealPosition 変更時にリセットされること
- フロントエンド: DishSearchCard に effortLevelMinutes がある場合のみ表示されること
