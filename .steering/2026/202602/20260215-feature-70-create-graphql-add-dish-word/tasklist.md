# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### 実装可能なタスクのみを計画
- 計画段階で「実装可能なタスク」のみをリストアップ
- 「将来やるかもしれないタスク」は含めない
- 「検討中のタスク」は含めない

### タスクスキップが許可される唯一のケース
以下の技術的理由に該当する場合のみスキップ可能:
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

スキップ時は必ず理由を明記:
```markdown
- [x] ~~タスク名~~（実装方針変更により不要: 具体的な技術的理由）
```

### タスクが大きすぎる場合
- タスクを小さなサブタスクに分割
- 分割したサブタスクをこのファイルに追加
- サブタスクを1つずつ完了させる

---

## フェーズ1: テスト作成（Red）

**DoD（完了条件）**: テストファイルが作成され、実行して失敗（Red）することを確認

- [x] テストディレクトリの作成
    - [x] `backend/spec/graphql/mutation/dish/word/` ディレクトリを作成

- [x] テストファイルの作成
    - [x] `backend/spec/graphql/mutation/dish/word/add_word_spec.rb` を作成
    - [x] 既存のテスト (`add_source.rb`) を参考に基本構造を作成
    - [x] GraphQL mutation クエリを定義 (`build_mutation`)
    - [x] 正常系テスト: `source` のみ指定
    - [x] 正常系テスト: `source` と `destination` を指定
    - [x] 異常系テスト: `source` を省略（バリデーションエラー）

- [x] テスト実行（Red確認）
    - [x] Docker コンテナ内でテスト実行: `docker compose exec backend bundle exec rspec backend/spec/graphql/mutation/dish/word/add_word_spec.rb`
    - [x] すべてのテストが失敗（Red）することを確認

### 各タスク詳細

#### テストファイルの作成

##### テストの構造
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
      it "creates normalize_word with normalized destination equals to normalized source" do
        variables = { source: "ぎょうざ" }
        result = fetch_mutation_with_auth(build_mutation, variables, user.id)

        expect(result["addDishWord"]["normalizeWordId"]).to be_present
        word = NormalizeWord.find(result["addDishWord"]["normalizeWordId"])
        expect(word.entered_source).to eq("ぎょうざ")
        expect(word.entered_destination).to eq("")
        expect(word.destination).to eq(word.source)
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

    context "when source is blank" do
      it "returns validation error" do
        variables = { source: "" }
        expect {
          fetch_mutation_with_auth(build_mutation, variables, user.id)
        }.to raise_error(/presence/)
      end
    end
  end
end
```

---

## フェーズ2: 実装（Green）

**DoD（完了条件）**: すべてのテストが通る（Green）

- [x] Mutation クラスの作成
    - [x] ディレクトリ作成: `backend/app/graphql/mutations/dish/word/`
    - [x] `backend/app/graphql/mutations/dish/word/add_word.rb` を作成
    - [x] `BaseMutation` を継承
    - [x] 引数定義: `source` (required), `destination` (optional)
    - [x] 返り値定義: `normalize_word_id`
    - [x] `resolve` メソッド実装
        - [x] トランザクション内で `Business::Food::Dish::Word::Usecase::AddCommand.call` を実行
        - [x] 作成した NormalizeWord の ID を返す

- [x] MutationType への登録
    - [x] `backend/app/graphql/types/mutation_type.rb` を開く
    - [x] `field :add_dish_word, mutation: ::Mutations::Dish::Word::AddWord` を追加
    - [x] 既存の dish 関連 mutation の近くに配置

- [x] テスト実行（Green確認）
    - [x] Docker コンテナ内でテスト実行: `docker compose exec backend bundle exec rspec backend/spec/graphql/mutation/dish/word/add_word_spec.rb`
    - [x] すべてのテストが成功（Green）することを確認

### 各タスク詳細

#### Mutation クラスの実装

##### 実装例
```ruby
module Mutations::Dish::Word
  class AddWord < ::Mutations::BaseMutation
    argument :source, String, required: true
    argument :destination, String, required: false

    field :normalize_word_id, Int, null: false

    def resolve(source:, destination: nil)
      ActiveRecord::Base.transaction do
        created_word = ::Business::Food::Dish::Word::Usecase::AddCommand.call(
          source: source,
          destination: destination,
        )

        {
          normalize_word_id: created_word.id,
        }
      end
    end
  end
end
```

---

## フェーズ3: 品質チェックと修正

**DoD（完了条件）**: すべての品質チェックが通る

- [x] すべてのテストが通ることを確認
    - [x] Docker コンテナ内で全テスト実行: `docker compose exec backend bundle exec rspec backend/spec/graphql/mutation/dish/word/add_word_spec.rb`

- [x] Rubocop でコードフォーマットを整える
    - [x] `docker compose exec backend bundle exec rubocop backend/app/graphql/mutations/dish/word/add_word.rb`
    - [x] 指摘があれば修正
    - [x] `docker compose exec backend bundle exec rubocop backend/spec/graphql/mutation/dish/word/add_word_spec.rb`
    - [x] 指摘があれば修正

- [x] 手動テスト（任意）
    - [x] GraphQL Playground 等で手動実行して動作確認

---

## フェーズ4: ドキュメント更新

**DoD（完了条件）**: 振り返りを記録

- [x] 実装後の振り返り（このファイルの下部に記録）

---

## 実装後の振り返り

### 実装完了日
（実装完了後に記入）

### 計画と実績の差分

**計画と異なった点**:
（実装完了後に記入）

**新たに必要になったタスク**:
（実装完了後に記入）

**技術的理由でスキップしたタスク**（該当する場合のみ）:
（該当する場合のみ記入）

**⚠️ 注意**: 「時間の都合」「難しい」などの理由でスキップしたタスクはここに記載しないこと。全タスク完了が原則。
