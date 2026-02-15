# GraphQL Mutation Tests

## 概要
このディレクトリはGraphQL mutationのテストを管理します。テストファーストに従い、mutation実装前にテストを作成します。

**非責務:**
- Usecaseのテスト（それは `spec/domain/` が担う）
- 単体テストレベルの詳細（GraphQL統合テストに焦点）

## クイックマップ

### 入口
- **新しいテストを作る**: 既存の `dish/source/add_source.rb` を参考にする
- **ヘルパー**: `graphql_helper.rb`, `graphql_auth_helper.rb`

### ディレクトリ構造
```
mutation/
  [domain]/          # 例: dish, meal
    [subdomain]/     # 例: source, word
      [action]_spec.rb  # 例: add_source_spec.rb, add_word_spec.rb
```

**MUST:** mutationの構造と対応させる
- Mutation: `app/graphql/mutations/dish/word/add_word.rb`
- Test: `spec/graphql/mutation/dish/word/add_word_spec.rb`

### grep用キーワード
- `build_mutation` - GraphQLクエリ定義
- `fetch_mutation_with_auth` - mutation実行ヘルパー
- `type: :request` - リクエストスペックとして実行

## 不変条件・契約

### MUST
- **テストファーストで書くこと** (Red → Green → Refactor)
- **Dockerコンテナ内で実行すること** (`docker compose exec backend bundle exec rspec`)
- **正常系と異常系をカバーすること**
- **`type: :request` を指定すること**

### SHOULD
- **`build_mutation` メソッドでGraphQLクエリを定義すること**
- **`fetch_mutation_with_auth` でmutation実行すること**
- **作成されたレコードをDBから取得して検証すること**

## 変更ガイド

### 新しいテストを追加する
1. **ディレクトリ作成** (なければ): `mutation/[domain]/[subdomain]/`
2. **テストファイル作成**: `[action]_spec.rb`
3. **テスト構造**:
   - `build_mutation` でGraphQLクエリ定義
   - contextで正常系・異常系を分ける
   - `fetch_mutation_with_auth` で実行
   - DBから取得して検証

### テストデータのクリーンアップ
- **MUST: 他のデータに影響を与えるUsecaseを呼ぶ場合、テスト前にクリーンアップする**
  - 例: `ReflectLatestNormalizeWordCommand` が既存Dishを参照する場合
  - `before` ブロックで関連モデルを `delete_all` する
  - 例:
    ```ruby
    before do
      NormalizeWord.delete_all
      Dish.delete_all
    end
    ```
- **理由:** 既存のテストデータがUsecaseの副作用で不正な状態になると、テストが失敗する

### テンプレート
```ruby
require "rails_helper"
require_relative "../../../graphql_auth_helper"

module Mutations::Dish::Word
  RSpec.describe AddWord, type: :request do
    let(:user) { User.create!(email: "test@example.com", password: "password") }

    def build_mutation
      <<~GRAPHQL
        mutation addDishWord($source: String!, $destination: String) {
          addDishWord(input: {source: $source, destination: $destination}) {
            normalizeWordId
          }
        }
      GRAPHQL
    end

    context "when source only" do
      it "creates normalize_word" do
        variables = { source: "ぎょうざ" }
        result = fetch_mutation_with_auth(build_mutation, variables, user.id)

        expect(result["addDishWord"]["normalizeWordId"]).to be_present
        word = NormalizeWord.find(result["addDishWord"]["normalizeWordId"])
        expect(word.entered_source).to eq("ぎょうざ")
      end
    end

    context "when validation error" do
      it "raises error" do
        variables = { source: "" }
        expect {
          fetch_mutation_with_auth(build_mutation, variables, user.id)
        }.to raise_error(/presence/)
      end
    end
  end
end
```

### テスト実行
```bash
# 特定のテストファイル
docker compose exec backend bundle exec rspec spec/graphql/mutation/dish/word/add_word_spec.rb

# ディレクトリ配下すべて
docker compose exec backend bundle exec rspec spec/graphql/mutation/dish/word/
```

## 参照
- テスト方針: `backend/docs/ai_guideline/development_standard/testing.md`
- Docker実行: `backend/docs/ai_guideline/development_standard/docker.md`
