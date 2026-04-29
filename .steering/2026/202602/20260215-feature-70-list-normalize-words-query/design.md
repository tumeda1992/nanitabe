# 要件ドキュメント

## はじめに
管理画面で現在の正規化ワード（NormalizeWord）をリスティング表示するため、GraphQL Query エンドポイントを作成する。フロントエンドで正規化ワードの一覧を取得・表示できるようにする。

## 要件

### 要件1: 正規化ワードリストを取得するGraphQL Queryエンドポイントの追加
**ユーザーストーリー:** 管理者が管理画面で現在登録されている正規化ワード一覧を確認できる。

#### 受け入れ基準
1. WHEN GraphQL query `normalizeWords` を実行 THEN すべての正規化ワードが返される
2. WHEN 正規化ワードが0件 THEN 空配列が返される
3. WHEN 正規化ワードが複数件 THEN すべて取得できる

#### MUST (必須)
- すべての NormalizeWord レコードを取得
- 以下のフィールドを返す:
  - `id`: レコードID
  - `enteredSource`: 入力されたソース文字列
  - `enteredDestination`: 入力された変換先文字列
  - `source`: 正規化されたソース文字列
  - `destination`: 正規化された変換先文字列
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時

#### SHOULD (推奨)
- 既存のGraphQL Query命名規則に従う (`normalizeWords`)
- 既存のディレクトリ構造に従う (`queries/dish/word/`)
- Output Typeを作成してフィールドを定義

#### MAY (任意)
- ソート順の指定（現時点では不要、将来追加可能）
- ページネーション（現時点では不要、管理画面用で件数が少ない想定）
- フィルタリング（現時点では不要、全件取得でOK）

#### 非目標
- ページネーション機能（将来必要になったら追加）
- 複雑なフィルタリング機能（全件取得で十分）
- 認証・認可の追加（現時点では対象外）

---

# 設計ドキュメント

## TL;DR
NormalizeWordモデルをリスト取得するGraphQL Queryを追加する。既存のパターン（DishSources等）に従い、`Queries::Dish::Word::NormalizeWords` クラスと `Types::Output::Dish::Word::NormalizeWord` Output Typeを作成し、`QueryType` に登録する。

## 変更点サマリ

### 新規作成ファイル
1. **`backend/app/graphql/types/output/dish/word/normalize_word.rb`**
   - GraphQL Output Type
   - NormalizeWordのフィールドを定義

2. **`backend/app/graphql/queries/dish/word/normalize_words.rb`**
   - GraphQL queryクラス
   - すべてのNormalizeWordを取得
   - 配列で返す

### 修正ファイル
1. **`backend/app/graphql/types/query_type.rb`**
   - `field :normalize_words, resolver: ::Queries::Dish::Word::NormalizeWords` を追加

## 設計選択と理由

### 1. ディレクトリ構造: `queries/dish/word/`
**理由:** 既存の構造に合わせる
- 既存: `queries/dish/source/dish_sources.rb`
- 今回: `queries/dish/word/normalize_words.rb`
- Mutationの階層 (`mutations/dish/word/add_word.rb`) と対応

### 2. Query名: `normalizeWords`
**理由:** 既存の命名規則に従う
- 既存: `dishSources`, `dishes`, `meals`
- 今回: `normalizeWords`
- リスト取得なので複数形

### 3. Output Typeを作成
**理由:** GraphQLのベストプラクティス
- フィールドの型定義を明確にする
- 将来フィールドを追加・変更しやすい
- 既存パターンに従う

### 4. 全件取得
**理由:** 管理画面用で件数が少ない想定
- 現時点ではページネーション不要
- シンプルな実装で十分
- 将来必要になったら追加可能

### 5. ユーザーフィルタなし
**理由:** NormalizeWordはグローバルデータ
- すべてのユーザーで共有される正規化ルール
- `context[:current_user_id]` でフィルタする必要なし

## 代替案

### 代替案1: ページネーション機能を追加
**棄却理由:** 現時点では過剰設計。管理画面用で件数が少ない想定。必要になったら後から追加できる。

### 代替案2: ソート機能を追加
**棄却理由:** 現時点では不要。フロントエンド側でソートできる。必要になったら後から追加できる。

### 代替案3: Output Typeなしで直接モデルを返す
**棄却理由:** GraphQLのベストプラクティスに反する。既存パターンから逸脱する。

## リスクと対策

### リスク1: 件数が多い場合のパフォーマンス
**対策:** 現時点では管理画面用で件数が少ない想定。将来的に件数が増えたらページネーションを追加する。

### リスク2: 認証・認可がない
**対策:** 現時点では非目標とする。必要になった場合は別タスクで対応。

### リスク3: Output Typeのフィールド名
**対策:** GraphQLの命名規則（camelCase）に従う。既存のOutput Typeを参考にする。

## テスト方針

### 自動テスト
- 既存のQuery testがあるか確認して、同様のパターンでテストを作成
- テストディレクトリ: `backend/spec/graphql/query/dish/word/`

### テストケース
1. **正常系:**
   - 正規化ワードが0件 → 空配列が返される
   - 正規化ワードが1件 → 1件取得できる
   - 正規化ワードが複数件 → すべて取得できる

2. **フィールド検証:**
   - すべてのフィールドが正しく返される

### テストクエリ例
```graphql
query {
  normalizeWords {
    id
    enteredSource
    enteredDestination
    source
    destination
    createdAt
    updatedAt
  }
}
```

## 実装の流れ（テストファースト）
1. **Output Type作成** (`normalize_word.rb`)
2. **Query作成** (`normalize_words.rb`)
3. **QueryTypeに登録**
4. **テスト作成**（既存パターンがあれば）
5. **テスト実行**
6. 完了
