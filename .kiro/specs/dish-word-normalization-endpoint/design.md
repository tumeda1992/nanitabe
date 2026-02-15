# 設計ドキュメント

## 概要

この機能は、料理名の単語正規化ルールを追加するためのGraphQL mutationエンドポイントを実装します。既存の `Business::Food::Dish::Word::Usecase::AddCommand` を呼び出し、単語の正規化マッピングをデータベースに保存します。

## アーキテクチャ

### レイヤー構成

```
GraphQL Layer (Presentation)
  ↓
Mutations::Dish::Word::AddNormalizeWord
  ↓
Business::Food::Dish::Word::Usecase::AddCommand (Application Layer)
  ↓
NormalizeWord Model (Infrastructure Layer)
```

### 処理フロー

1. クライアントがGraphQL mutationを呼び出す
2. GraphQL mutationが入力をバリデーション
3. 認証済みユーザーを確認
4. トランザクション内でCommandを実行
5. Commandが単語を正規化してNormalizeWordレコードを作成
6. 既存の料理に正規化ルールを反映
7. 成功レスポンスを返す

## コンポーネントとインターフェース

### 1. GraphQL Mutation

**ファイル**: `backend/app/graphql/mutations/dish/word/add_normalize_word.rb`

```ruby
module Mutations::Dish::Word
  class AddNormalizeWord < ::Mutations::BaseMutation
    argument :source, String, required: true
    argument :destination, String, required: false

    field :success, Boolean, null: false

    def resolve(source:, destination: nil)
      # 実装詳細は後述
    end
  end
end
```

**責務**:
- 入力パラメータの受け取りとバリデーション
- 認証チェック
- トランザクション管理
- Commandの呼び出し
- レスポンスの構築

### 2. Input Type

**ファイル**: 不要（プリミティブ型のみ使用）

既存のパターンに従い、シンプルなString引数を直接使用します。

### 3. Mutation Type登録

**ファイル**: `backend/app/graphql/types/mutation_type.rb`

既存のMutationTypeに新しいフィールドを追加：

```ruby
field :add_dish_normalize_word, mutation: ::Mutations::Dish::Word::AddNormalizeWord
```

### 4. 既存Commandの利用

**ファイル**: `backend/app/domain/business/food/dish/word/usecase/add_command.rb`

既存のCommandをそのまま使用します。このCommandは：
- sourceとdestinationを受け取る
- 単語を正規化する
- NormalizeWordレコードを作成する
- 既存の料理に正規化を反映する

## データモデル

### NormalizeWord

既存のモデルを使用：

```ruby
# 属性
- entered_source: String (ユーザーが入力した元の単語)
- entered_destination: String (ユーザーが入力した変換先単語)
- source: String (正規化された元の単語)
- destination: String (正規化された変換先単語)
```

## 正確性プロパティ

プロパティとは、システムのすべての有効な実行において真であるべき特性や振る舞いのことです。これは、人間が読める仕様と機械で検証可能な正確性保証の橋渡しとなります。


### プロパティ1: sourceのみの正規化

*任意の*有効なsource文字列に対して、destinationを指定せずにmutationを呼び出すと、作成されるNormalizeWordレコードのsourceとdestinationは同じ正規化された値になる

**検証: 要件 1.1**

### プロパティ2: source+destinationの正規化マッピング

*任意の*有効なsource文字列とdestination文字列のペアに対して、mutationを呼び出すと、作成されるNormalizeWordレコードは正規化されたsourceから正規化されたdestinationへのマッピングを持つ

**検証: 要件 1.2**

### プロパティ3: 空sourceのバリデーションエラー

*任意の*空またはnilのsource値に対して、mutationを呼び出すと、バリデーションエラーが返され、レコードは作成されない

**検証: 要件 1.3, 3.3**

### プロパティ4: 成功時のレスポンス

*任意の*有効なsource（およびオプションのdestination）に対して、mutationが成功すると、レスポンスのsuccessフィールドはtrueになる

**検証: 要件 1.5**

## エラーハンドリング

### 認証エラー

- 未認証ユーザーがmutationを呼び出した場合、GraphQLの認証エラーを返す
- 既存のDevise + JWT認証メカニズムを使用

### バリデーションエラー

- sourceが空またはnilの場合、GraphQLのバリデーションエラーを返す
- Commandのバリデーションエラーをキャッチし、適切なGraphQLエラーに変換

### トランザクションエラー

- データベース操作中にエラーが発生した場合、トランザクションをロールバック
- エラーメッセージをクライアントに返す

## テスト戦略

### ユニットテストとプロパティベーステスト

このプロジェクトでは、ユニットテストとプロパティベーステストの両方を使用します：

- **ユニットテスト**: 特定の例、エッジケース、エラー条件を検証
- **プロパティテスト**: すべての入力にわたる普遍的なプロパティを検証

両方のアプローチは補完的であり、包括的なカバレッジに必要です。

### テストフレームワーク

- **RSpec**: Railsの標準テストフレームワーク
- **プロパティベーステスト**: RSpecのカスタムマッチャーまたはrspec-parameterizedを使用

### テスト構成

各プロパティテストは最低100回の反復を実行する必要があります。各テストには、設計ドキュメントのプロパティを参照するタグを含める必要があります：

```ruby
# Feature: dish-word-normalization-endpoint, Property 1: sourceのみの正規化
```

### テストカバレッジ

#### プロパティベーステスト

1. **プロパティ1**: ランダムなsource文字列を生成し、destinationなしでmutationを呼び出し、source == destinationを確認
2. **プロパティ2**: ランダムなsource/destinationペアを生成し、mutationを呼び出し、正しいマッピングを確認
3. **プロパティ3**: 空/nil/空白文字列のsourceでmutationを呼び出し、エラーを確認
4. **プロパティ4**: 有効な入力でmutationを呼び出し、success: trueを確認

#### ユニットテスト

1. 未認証ユーザーのアクセス拒否
2. 空文字列のdestinationの処理（エッジケース）
3. トランザクションロールバック（エラー発生時）
4. ReflectLatestNormalizeWordCommandの呼び出し確認

### 統合テスト

GraphQL mutation全体を通したエンドツーエンドテスト：
- 認証済みユーザーでmutationを呼び出す
- データベースにレコードが作成されることを確認
- レスポンスが正しい形式であることを確認

## 実装の考慮事項

### 既存パターンの踏襲

このプロジェクトの既存のGraphQL mutationパターンに従います：
- `Mutations::BaseMutation`を継承
- トランザクション内でCommandを呼び出す
- `context[:current_user_id]`で認証を確認

### ディレクトリ構造

```
backend/app/graphql/mutations/dish/word/
└── add_normalize_word.rb
```

既存の`dish`ディレクトリ内に`word`サブディレクトリを作成します。

### 命名規則

- Mutation: `AddNormalizeWord`（既存のパターンに従う）
- GraphQLフィールド: `add_dish_normalize_word`（既存の命名規則に従う）
