# 要件ドキュメント

## はじめに
複数の料理に対して、一括で同じタグを付けるバックエンドAPIを追加する。
GraphQL mutation として `bulkAddTagToDishes` を追加し、ユースケース層にバルク追加コマンドを実装する。

## 元の依頼内容
複数の料理に対して、一括で同じタグを付けられるようにしたい。
まずはバックエンドにその体制をつくりたい。つまりGraphQLとビジネスロジック。

graphqlは、meal_idの配列とtagの文字列を受け取る形かな

## 要件
### 要件1: 複数料理への一括タグ付け
**ユーザーストーリー:** 複数の料理を選択して同じタグをまとめて付けられるようにしたい。

#### 受け入れ基準
1. WHEN `dish_ids: [1, 2, 3]` と `tag: "おすすめ"` を渡すと THEN 各料理にそのタグが追加される
2. WHEN 既に同じタグ（正規化後一致）が付いている料理がある THEN 重複して追加しない（idempotent）
3. WHEN 存在しない dish_id が含まれている THEN エラーを返す
4. WHEN `dish_ids` が空配列 THEN エラーを返す
5. WHEN `tag` が空文字 THEN エラーを返す

--

# 設計ドキュメント

## TL;DR
既存の「タグを全置換する」(`replace_tags`) とは別に、「指定タグを追加する」操作を新設する。
ユースケース層に `BulkAddTagToDishesCommand` を追加し、GraphQL mutation `bulkAddTagToDishes` でそれを呼ぶ。

## ⚠️ 確認事項：`dish_ids` vs `meal_ids`

依頼では「**meal_id** の配列」とあったが、タグは料理 (Dish) に付くものであり、
「複数の**料理**に一括タグ付け」という文脈からすると `dish_ids` の方が自然。

| 案 | 引数 | 内部処理 |
|----|------|---------|
| A: dish_ids | `dish_ids: [Int!]!` | そのまま Dish を検索してタグ追加 |
| B: meal_ids | `meal_ids: [Int!]!` | Meal → Dish の解決後にタグ追加 |

**推奨: 案A（dish_ids）**
- タグはDishに付くため、Meal経由は不要な間接参照
- フロント側でDishを選択するUIになるはず（料理検索ページが既にある）
- Meal経由が必要な場合は別途Queryで dish_id を解決してから呼ぶ方が明確

→ **design.md 作成後にユーザーに確認する**

## 変更点サマリ

### バックエンド
| ファイル | 追加/変更 |
|---------|---------|
| `app/domain/business/food/dish/tag/usecase/bulk_add_tag_to_dishes_command.rb` | **新規** ユースケースコマンド |
| `app/graphql/mutations/dish/tag/bulk_add_tag_to_dishes.rb` | **新規** GraphQL mutation |
| `app/graphql/types/mutation_type.rb` | **変更** mutation 登録 |
| `spec/domain/business/food/dish/tag/usecase/bulk_add_tag_to_dishes_command_spec.rb` | **新規** コマンドのspec |
| `spec/graphql/mutation/dish/tag/bulk_add_tag_to_dishes_spec.rb` | **新規** GraphQL specアーキテクチャ疎通確認 |

## 設計詳細

### コマンドの責務分担

- `BulkAddTagToDishesCommand` → **オーケストレーションのみ**。各dishへの処理は `AddTagToDishCommand` に委譲。
- `AddTagToDishCommand` → 単一Dishにタグを追加する。ビジネスルール（重複チェック等）はドメイン層に委ねる。
- `Dish::Root#add_tag` → 重複チェックを含むビジネスロジックを担う。

### ユースケースコマンド: BulkAddTagToDishesCommand（オーケストレーター）

```ruby
module Business::Food::Dish::Tag::Usecase
  class BulkAddTagToDishesCommand < ::Business::Base::Command
    attribute :user_id, :integer
    attribute :dish_ids, :any  # Array<Integer>
    attribute :tag_content, :string

    validates :user_id, presence: true
    validates :dish_ids, presence: true
    validates :tag_content, presence: true

    def call
      ActiveRecord::Base.transaction do
        dish_ids.each do |dish_id|
          AddTagToDishCommand.call(
            user_id: user_id,
            dish_id: dish_id,
            tag_content: tag_content,
          )
        end
      end
    end
  end
end
```

### ユースケースコマンド: AddTagToDishCommand（単体処理）

```ruby
module Business::Food::Dish::Tag::Usecase
  class AddTagToDishCommand < ::Business::Base::Command
    attribute :user_id, :integer
    attribute :dish_id, :integer
    attribute :tag_content, :string

    validates :user_id, presence: true
    validates :dish_id, presence: true
    validates :tag_content, presence: true

    def call
      dish_root = Business::Food::Dish::Factory.build_existing_from_id(dish_id)
      raise "指定した料理(id=#{dish_id})は存在しません。" if dish_root.blank?

      new_tag = Tag::Root.new(
        user_id: user_id,
        content: Tag::Content.initialize_and_normalize(tag_content),
      )
      dish_root.add_tag(new_tag)  # 重複チェックはadd_tagが担う
      ::Dish.persist_from_food_dish_root(dish_root)
    end
  end
end
```

### Dish::Root への `add_tag` メソッド追加（重複チェックを内包）

既存の `replace_tags` は全置換。今回は1タグを追加するメソッドを追加。
**重複チェックのビジネスロジックをここに持つ**:

```ruby
def add_tag(tag)
  raise "タグの型が不正です。" unless tag.is_a?(Business::Food::Dish::Tag::Root)
  tag.validate!
  # 正規化後の内容で重複チェック（エンティティが自身の不変条件を担う）
  return if tags.any? { |existing| existing.content.normalized == tag.content.normalized }

  self.tags = tags + [tag]
end
```

### GraphQL Mutation

```ruby
module Mutations::Dish::Tag
  class BulkAddTagToDishes < ::Mutations::BaseMutation
    argument :dish_ids, [Int], required: true
    argument :tag, String, required: true

    field :dish_ids, [Int], null: false

    def resolve(dish_ids:, tag:)
      ::Business::Food::Dish::Tag::Usecase::BulkAddTagToDishesCommand.call(
        user_id: context[:current_user_id],
        dish_ids:,
        tag_content: tag,
      )

      { dish_ids: }
    end
  end
end
```

## 代替案

### 代替案1: GraphQL input を `meal_ids` にする
- Meal から Dish に解決する処理が増える
- 同一Dishが複数Mealに紐づく場合、重複処理が必要
- 棄却理由: 不要な間接参照、`dish_ids` の方がシンプル

### 代替案2: UpdateDish を複数回呼ぶ（バルクAPIなし）
- フロント側でN回APIを叩く
- 棄却理由: N+1問題、一括性がないためトランザクション保証が難しい

### 代替案3: `replace_tags` を拡張する（全置換に追加タグを渡す）
- 既存のUpdateDishに `dish_ids` 配列を持たせる
- 棄却理由: UpdateDishは単一Dish更新の責務であり、責務の混在が起きる

## リスクと対策
- **存在しないdish_idのエラー処理**: トランザクション内でraiseし、全件ロールバック
- **重複タグの防止**: 正規化後の content で比較してskip

## テスト方針
- RSpec (コンテナ内実行)
- テストファースト（Red → Green）
- コマンドspec:
  - 正常系: 複数Dishにタグ追加
  - 同じタグが既にある場合は重複しない
  - 存在しないdish_idはエラー
  - dish_ids空はエラー
  - tag_content空はエラー
- GraphQL spec: アーキテクチャ疎通確認（1ケースのみ）
