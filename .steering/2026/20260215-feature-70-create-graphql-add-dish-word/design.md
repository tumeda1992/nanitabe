# 要件ドキュメント

## はじめに
料理名の正規化ワードを追加するためのGraphQL mutationエンドポイントを作成する。既存の `Business::Food::Dish::Word::Usecase::AddCommand` をGraphQL経由で実行可能にする。

## 要件

### 要件1: GraphQL Mutationエンドポイントの追加
**ユーザーストーリー:** 管理者が料理名の正規化ワード（例: "ぎょうざ" → "餃子"）をGraphQL経由で登録できるようにする。

#### 受け入れ基準
1. WHEN GraphQL mutation `addDishWord` を実行 THEN 正規化ワード (NormalizeWord) が作成される
2. WHEN `source` のみ指定 THEN 正規化後の `destination` は正規化後の `source` と同じ値になり、`entered_destination` は空文字列になる
3. WHEN `source` と `destination` を指定 THEN 両方とも正規化されてDBに保存される
4. WHEN バリデーションエラー THEN GraphQLエラーが返される

#### MUST (必須)
- `source` (必須): 正規化元の文字列
- `destination` (任意): 正規化先の文字列。省略時は正規化後の `source` と同じ値が `destination` カラムに設定され、`entered_destination` は空文字列
- 既存の `Business::Food::Dish::Word::Usecase::AddCommand` を使用
- トランザクション内で実行
- 作成した NormalizeWord の ID を返す

#### SHOULD (推奨)
- 既存のGraphQL Mutation命名規則に従う (`addDishWord`)
- 既存のディレクトリ構造に従う (`mutations/dish/word/`)
- 引数は直接mutationクラスに定義（Input Type不要）

#### MUST (必須 - テスト)
- テストファーストに従い、テストを先に作成
- 新しい構造 (`Business::Food::Dish::Word`) を前提にしたテスト
- テストディレクトリ: `backend/spec/graphql/mutation/dish/word/`

#### 非目標
- Usecase自体のロジック変更
- NormalizeWordモデルの変更
- 認証・認可の追加（現時点では対象外）

---

# 設計ドキュメント

## TL;DR
既存の `AddCommand` Usecaseを呼び出すGraphQL mutationを追加する。既存のパターン（AddSource等）に従い、`Mutations::Dish::Word::AddWord` クラスを作成（Input Typeは不要）し、`MutationType` に登録する。テストファーストで進め、新しい構造 (`Business::Food`) を前提にしたテストを書く。

## 変更点サマリ

### 新規作成ファイル
1. **`backend/spec/graphql/mutation/dish/word/add_word_spec.rb`**
   - テストファースト: まずテストを作成
   - `Business::Food::Dish::Word::Usecase::AddCommand` を使用
   - 正常系・異常系をカバー

2. **`backend/app/graphql/mutations/dish/word/add_word.rb`**
   - GraphQL mutationクラス
   - `source`, `destination` を引数として直接定義
   - `AddCommand.call` を実行
   - `normalize_word_id` を返す

### 修正ファイル
1. **`backend/app/graphql/types/mutation_type.rb`**
   - `field :add_dish_word, mutation: ::Mutations::Dish::Word::AddWord` を追加

## 設計選択と理由

### 1. ディレクトリ構造: `mutations/dish/word/`
**理由:** 既存の構造に合わせる
- 既存: `mutations/dish/source/add_source.rb`
- 今回: `mutations/dish/word/add_word.rb`
- Usecaseの階層 (`Business::Food::Dish::Word::Usecase`) と対応

### 2. Mutation名: `addDishWord`
**理由:** 既存の命名規則に従う
- 既存: `addDishSource`, `addDish`, `addMeal`
- 今回: `addDishWord`
- snake_caseで動詞+名詞の形式

### 3. Input Typeは作らず、引数を直接定義
**理由:** シンプルさ優先
- 引数が2つのみで単純
- Input Typeを作るまでもない
- 既存の例: 簡単なmutationは直接引数定義している

### 4. 返り値: `normalize_word_id`
**理由:** 作成されたレコードのIDを返すのが標準パターン
- 既存: `dish_source_id`, `dish_id` など
- 今回: `normalize_word_id`

### 5. トランザクション
**理由:** データ整合性の保証
- 既存パターンに従う
- `AddCommand` 内で `ReflectLatestNormalizeWordCommand` も実行されるため

## 代替案

### 代替案1: Input Typeを作成
```ruby
class WordForCreate < Types::BaseInputObject
  argument :source, String, required: true
  argument :destination, String, required: false
end
```
**棄却理由:** 引数が2つだけで単純なため、Input Typeを作るのは過剰設計。直接引数定義で十分。

### 代替案3: MutationTypeに追加せず、別のスキーマを作る
**棄却理由:** 既存のすべてのmutationは `MutationType` に登録されており、一貫性を保つべき。

## リスクと対策

### リスク1: `AddCommand` が user_id を必要とする可能性
**対策:** コードレビューで確認。AddSource は `user_id` を渡しているが、AddCommand のコードには user_id が見当たらない。不要であればそのまま進める。

### リスク2: 認証・認可がない
**対策:** 現時点では非目標とする。必要になった場合は別タスクで対応。

### リスク3: 既存テストは古い構造 (business/dish) を使用
**対策:** 新しく作るテストは新構造 (business/food) を前提にする。既存のテストパターンは参考にするが、usecaseのパスは新しいものを使う。

## テスト方針

### 自動テスト（必須）
テストファーストに従い、以下のテストを作成:

1. **正常系:**
   - `source` のみ指定 → 正規化後の `destination` が正規化後の `source` と同じ値、`entered_destination` は空文字列
   - `source` と `destination` を指定 → 両方とも正規化されてDB保存

2. **異常系:**
   - `source` を省略 → バリデーションエラー
   - 空文字列を指定 → バリデーションエラー

### テストの構造
- パス: `backend/spec/graphql/mutation/dish/word/add_word_spec.rb`
- 既存のパターン (`add_source.rb`) を参考にする
- **重要:** `Business::Food::Dish::Word::Usecase::AddCommand` を使用（新構造）

### テストコード例
```ruby
require "rails_helper"
require_relative "../../../graphql_auth_helper"

module Mutations::Dish::Word
  RSpec.describe AddWord, type: :request do
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
      it "creates normalize_word with normalized destination equals to normalized source" do
        variables = { source: "ぎょうざ" }
        result = fetch_mutation_with_auth(build_mutation, variables, user.id)

        expect(result["addDishWord"]["normalizeWordId"]).to be_present
        word = NormalizeWord.find(result["addDishWord"]["normalizeWordId"])
        expect(word.entered_source).to eq("ぎょうざ")
        expect(word.entered_destination).to eq("")
        expect(word.destination).to eq(word.source) # 正規化後の値は同じ
      end
    end

    context "when source and destination" do
      it "creates normalize_word" do
        variables = { source: "ぎょうざ", destination: "餃子" }
        result = fetch_mutation_with_auth(build_mutation, variables, user.id)

        word = NormalizeWord.find(result["addDishWord"]["normalizeWordId"])
        expect(word.entered_source).to eq("ぎょうざ")
        expect(word.entered_destination).to eq("餃子")
      end
    end
  end
end
```

## 実装の流れ（テストファースト）
1. **テスト作成** (`add_word_spec.rb`) - Red
2. **Mutation作成** (`add_word.rb`) - Green
3. **MutationType登録** - Green
4. **テスト実行** - 全テストグリーン確認
5. **手動確認**（任意）
6. 完了
