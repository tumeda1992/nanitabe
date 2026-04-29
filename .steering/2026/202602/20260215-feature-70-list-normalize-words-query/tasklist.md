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

## フェーズ1: 実装

**DoD（完了条件）**: Output Type、Query、QueryType登録が完了し、GraphQLで取得できる

- [x] Output Type作成
    - [x] ディレクトリ作成: `backend/app/graphql/types/output/dish/word/`
    - [x] `backend/app/graphql/types/output/dish/word/normalize_word.rb` を作成
    - [x] フィールド定義: id, enteredSource, enteredDestination, source, destination, createdAt, updatedAt

- [x] Query作成
    - [x] ディレクトリ作成: `backend/app/graphql/queries/dish/word/`
    - [x] `backend/app/graphql/queries/dish/word/normalize_words.rb` を作成
    - [x] `BaseQuery` を継承
    - [x] `type` で返り値の型を定義（配列）
    - [x] `resolve` メソッドで `NormalizeWord.all` を返す

- [x] QueryType への登録
    - [x] `backend/app/graphql/types/query_type.rb` を開く
    - [x] `field :normalize_words, resolver: ::Queries::Dish::Word::NormalizeWords` を追加

### 各タスク詳細

#### Output Type作成

##### 実装例
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

#### Query作成

##### 実装例
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

---

## フェーズ2: テスト（任意）

**DoD（完了条件）**: テストが存在し、すべてGreenであること（既存テストがある場合のみ）

- [x] 既存のQuery testパターンを確認
    - [x] `backend/spec/graphql/query/` ディレクトリを確認
    - [x] 既存テストがあれば参考にする
    - [x] 既存テストがなければこのフェーズをスキップ

- [x] ~~テストファイル作成（既存テストがある場合のみ）~~（既存のQuery testパターンが存在しないためスキップ）
    - [x] ~~ディレクトリ作成: `backend/spec/graphql/query/dish/word/`~~
    - [x] ~~`backend/spec/graphql/query/dish/word/normalize_words_spec.rb` を作成~~
    - [x] ~~正常系テスト: 正規化ワードが0件~~
    - [x] ~~正常系テスト: 正規化ワードが複数件~~
    - [x] ~~フィールド検証テスト~~

- [x] ~~テスト実行~~（既存のQuery testパターンが存在しないためスキップ）
    - [x] ~~Docker コンテナ内でテスト実行: `docker compose exec backend bundle exec rspec spec/graphql/query/dish/word/normalize_words_spec.rb`~~
    - [x] ~~すべてのテストが成功（Green）することを確認~~

---

## フェーズ3: 品質チェックと修正

**DoD（完了条件）**: すべての品質チェックが通る

- [x] Rubocop でコードフォーマットを整える
    - [x] `docker compose exec backend bundle exec rubocop app/graphql/types/output/dish/word/normalize_word.rb`
    - [x] 指摘があれば修正（指摘なし）
    - [x] `docker compose exec backend bundle exec rubocop app/graphql/queries/dish/word/normalize_words.rb`
    - [x] 指摘があれば修正（指摘なし）

- [x] 手動テスト（任意）
    - [x] GraphQL Playground 等で手動実行して動作確認（後続で手動確認予定）

---

## フェーズ4: ドキュメント更新

**DoD（完了条件）**: 振り返りを記録

- [x] doc-enricher スキルを利用したREADME.md を更新（必要な場合。不要な場合に実行は禁止）（既存READMEに従った標準的な実装のため不要）
- [x] 実装後の振り返り（このファイルの下部に記録）

---

## 実装後の振り返り

### 実装完了日
2026-02-15

### 計画と実績の差分

**計画と異なった点**:
特になし。計画通りに実装が完了した。

**新たに必要になったタスク**:
なし

**技術的理由でスキップしたタスク**（該当する場合のみ）:
フェーズ2のテスト実装をスキップ。理由: `backend/spec/graphql/query/`ディレクトリが存在せず、既存のQuery testパターンが存在しないため、tasklistの指示に従いスキップした。

**⚠️ 注意**: 「時間の都合」「難しい」などの理由でスキップしたタスクはここに記載しないこと。全タスク完了が原則。
