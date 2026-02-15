# GraphQL Mutations

## 概要
このディレクトリはGraphQL mutationの実装を管理します。各mutationはUsecaseを呼び出し、データの変更操作を提供します。

**非責務:**
- ビジネスロジックの実装（それはUsecaseが担う）
- 直接的なDB操作（Usecaseを経由する）

## クイックマップ

### 入口
- **新しいmutationを作る**: 既存の `dish/source/add_source.rb` を参考にする
- **ベースクラス**: `base_mutation.rb`
- **登録場所**: `types/mutation_type.rb`

### ディレクトリ構造
```
mutations/
  [domain]/          # 例: dish, meal
    [subdomain]/     # 例: source, word
      [action].rb    # 例: add_source.rb, add_word.rb
```

**MUST:** Usecaseの階層と対応させる
- Usecase: `Business::Food::Dish::Word::Usecase::AddCommand`
- Mutation: `mutations/dish/word/add_word.rb`

### grep用キーワード
- `BaseMutation` - すべてのmutationが継承
- `resolve` - 実装メソッド
- `MutationType` - mutation登録場所

## 不変条件・契約

### MUST
- **`BaseMutation` を継承すること**
- **`resolve` メソッドで実装すること**
- **トランザクション内でUsecaseを実行すること** (`ActiveRecord::Base.transaction`)
- **`Types::MutationType` に登録すること**（登録しないとGraphQLから呼べない）

### SHOULD
- **作成したレコードのIDを返すこと** (例: `dish_source_id`, `normalize_word_id`)
- **命名規則に従うこと**:
  - クラス名: `[Action][Resource]` (例: `AddSource`, `AddWord`)
  - MutationTypeフィールド名: `[action]_[resource]` (例: `add_dish_source`, `add_dish_word`)

## 変更ガイド

### 新しいmutationを追加する
1. **ディレクトリ作成** (なければ): `mutations/[domain]/[subdomain]/`
2. **mutationクラス作成**: `[action]_[resource].rb`
   - `BaseMutation` を継承
   - `argument` で引数定義
   - `field` で返り値定義
   - `resolve` でトランザクション + Usecase実行
3. **`MutationType` に登録**: `types/mutation_type.rb`
4. **テスト作成**: `spec/graphql/mutation/[domain]/[subdomain]/[action]_spec.rb`

### Input Typeの作成（必須）
- **MUST: すべてのmutationでInput Typeを作成すること**
  - Relay形式では引数の数に関わらずInput Typeが必要
  - 直接 `argument` で定義するとGraphQLエラーになる
- Input Typeの配置: `types/input/[domain]/[subdomain]/[name]_for_[action].rb`
- 例: `Types::Input::Dish::Word::WordForCreate`

### 実装例
```ruby
# Input Type
module Types::Input::Dish::Word
  class WordForCreate < ::Types::BaseInputObject
    argument :source, String, required: true
    argument :destination, String, required: false
  end
end

# Mutation
module Mutations::Dish::Word
  class AddWord < ::Mutations::BaseMutation
    argument :word, ::Types::Input::Dish::Word::WordForCreate, required: true

    field :normalize_word_id, Int, null: false

    def resolve(word:)
      ActiveRecord::Base.transaction do
        created = ::Business::Food::Dish::Word::Usecase::AddCommand.call(
          source: word[:source],
          destination: word[:destination],
        )

        { normalize_word_id: created.id }
      end
    end
  end
end
```

## 参照
- 開発ガイドライン: `backend/docs/ai_guideline/development_standard/`
- テストガイド: `backend/spec/graphql/mutation/README.md`
