# 実装計画: dish-word-normalization-endpoint

## 概要

既存の`Business::Food::Dish::Word::Usecase::AddCommand`を呼び出すGraphQL mutationエンドポイントを実装します。

## タスク

- [ ] 1. GraphQL Mutationクラスの作成
  - `backend/app/graphql/mutations/dish/word/add_normalize_word.rb`を作成
  - `Mutations::BaseMutation`を継承
  - `source`（必須）と`destination`（オプション）の引数を定義
  - `success`フィールドを定義
  - トランザクション内で`Business::Food::Dish::Word::Usecase::AddCommand`を呼び出す
  - _要件: 1.1, 1.2, 1.5, 4.1_

- [ ]* 1.1 Mutationのユニットテストを作成
  - `backend/spec/graphql/mutation/dish/word/add_normalize_word_spec.rb`を作成
  - 認証済みユーザーでの正常系テスト
  - 未認証ユーザーでのエラーテスト
  - _要件: 2.1, 2.2_

- [ ]* 1.2 プロパティテスト: sourceのみの正規化
  - **プロパティ1: sourceのみの正規化**
  - **検証: 要件 1.1**

- [ ]* 1.3 プロパティテスト: source+destinationの正規化マッピング
  - **プロパティ2: source+destinationの正規化マッピング**
  - **検証: 要件 1.2**

- [ ]* 1.4 プロパティテスト: 空sourceのバリデーションエラー
  - **プロパティ3: 空sourceのバリデーションエラー**
  - **検証: 要件 1.3, 3.3**

- [ ]* 1.5 プロパティテスト: 成功時のレスポンス
  - **プロパティ4: 成功時のレスポンス**
  - **検証: 要件 1.5**

- [ ] 2. MutationTypeへの登録
  - `backend/app/graphql/types/mutation_type.rb`に`add_dish_normalize_word`フィールドを追加
  - _要件: 1.1_

- [ ] 3. チェックポイント - すべてのテストが通ることを確認
  - すべてのテストが通ることを確認し、質問があればユーザーに尋ねる

- [ ]* 4. エッジケースのユニットテスト
  - 空文字列のdestinationの処理テスト
  - トランザクションロールバックのテスト
  - _要件: 3.2, 4.2_

- [ ]* 5. 統合テスト
  - GraphQL mutation全体のエンドツーエンドテスト
  - データベースへのレコード作成確認
  - ReflectLatestNormalizeWordCommandの呼び出し確認
  - _要件: 1.4_

## 注記

- `*`マークのタスクはオプションで、より速いMVPのためにスキップ可能です
- 各タスクは特定の要件を参照してトレーサビリティを確保します
- チェックポイントで段階的な検証を行います
- プロパティテストは普遍的な正確性プロパティを検証します
- ユニットテストは特定の例とエッジケースを検証します
