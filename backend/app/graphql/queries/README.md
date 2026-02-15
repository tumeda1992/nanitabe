# GraphQL Queries

## 概要
このディレクトリはGraphQL queryの実装を管理します。各queryはデータの読み取り操作を提供します。

**非責務:**
- データの変更操作（それはMutationが担う）
- ビジネスロジックの実装（それはUsecaseやFinderが担う）
- 直接的なDB操作（ActiveRecordまたはUsecaseを経由する）

## クイックマップ

### 入口
- **新しいqueryを作る**: 既存の `dish/source/dish_sources.rb` を参考にする
- **ベースクラス**: `base_query.rb`
- **登録場所**: `types/query_type.rb`

### ディレクトリ構造
```
queries/
  [domain]/          # 例: dish, meal
    [subdomain]/     # 例: source, word
      [resource].rb  # 例: dish_sources.rb, normalize_words.rb
```

**MUST:** 対応するMutationの階層と合わせる
- Mutation: `mutations/dish/word/add_word.rb`
- Query: `queries/dish/word/normalize_words.rb`

### grep用キーワード
- `BaseQuery` - すべてのqueryが継承
- `resolve` - 実装メソッド
- `QueryType` - query登録場所

## 不変条件・契約

### MUST
- **`BaseQuery` を継承すること**
- **`type` で返り値の型を定義すること**
- **`resolve` メソッドで実装すること**
- **`Types::QueryType` に登録すること**（登録しないとGraphQLから呼べない）

### SHOULD
- **リスト取得の場合は複数形の命名** (例: `dishSources`, `normalizeWords`)
- **Output Typeを作成すること** (例: `Types::Output::Dish::Source::DishSource`)

## 変更ガイド

### 新しいqueryを追加する
1. **Output Type作成** (なければ): `types/output/[domain]/[subdomain]/[resource].rb`
2. **queryクラス作成**: `[resources].rb`
   - `BaseQuery` を継承
   - `type` で返り値の型を定義
   - `resolve` で実装
3. **`QueryType` に登録**: `types/query_type.rb`

### リスト取得Queryの型定義
- **配列を返す場合**: `type [OutputType, { null: false }], null: false`
- **単一オブジェクトを返す場合**: `type OutputType, null: false`

### 実装例

#### Output Type
```ruby
module Types::Output::Dish::Word
  class NormalizeWord < ::Types::BaseObject
    field :id, Int, null: false
    field :entered_source, String, null: false
    field :entered_destination, String, null: false
    field :source, String, null: false
    field :destination, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
```

#### Query（リスト取得）
```ruby
module Queries::Dish::Word
  class NormalizeWords < ::Queries::BaseQuery
    type [::Types::Output::Dish::Word::NormalizeWord, { null: false }], null: false

    def resolve
      ::NormalizeWord.all
    end
  end
end
```

#### Query（単一取得）
```ruby
module Queries::Dish
  class Dish < ::Queries::BaseQuery
    type ::Types::Output::Dish::Dish, null: false

    argument :id, Int, required: true

    def resolve(id:)
      ::Dish.find(id)
    end
  end
end
```

## 参照
- 開発ガイドライン: `backend/docs/ai_guideline/development_standard/`
- Mutationガイド: `backend/app/graphql/mutations/README.md`
