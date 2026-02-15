# 概要

このディレクトリは管理画面用のコントローラを配置する。

## 役割（What）
- 自分専用の管理ツール（認証・認可なし）
- NormalizeWord等の内部データのCRUD操作
- Rails標準のRESTful設計、erbビュー

## 非責務（やらないこと）
- ユーザー向け機能（GraphQL経由で提供）
- 認証・認可（自分しか使わない前提）

---

# クイックマップ

## 読む順・入口
1. `admin/food/dish/word/normalize_words_controller.rb`: 最初の admin 機能（正規化ワード管理）
2. `app/views/admin/food/dish/word/normalize_words/`: 対応するビュー

## grep用キーワード
- `Admin::Food::Dish::Word::NormalizeWordsController`: コントローラ名
- `admin_food_dish_word_normalize_words_path`: ルートヘルパー
- `Business::Base::Values::InvalidAttributeError`: Command呼び出しのエラーハンドリング

---

# 不変条件・契約

## MUST
- **Command呼び出しパターン**: `Business::Food::Dish::Word::Usecase::AddCommand.call(...)` のようにクラスメソッド `call` を直接呼ぶ
  - `new` は `private_class_method` で外部から呼べない
  - GraphQLのMutationと同じパターン（例: `backend/app/graphql/mutations/dish/source/add_source.rb`）
- **エラーハンドリング**: `Business::Base::Values::InvalidAttributeError` を rescue してフラッシュメッセージ表示、フォーム再表示
  - `Command` は `initialize` 時に自動バリデーション→失敗時は例外 raise
- **URL構造**: `/admin/food/dish/word/...` のように、ドメイン構造を反映したネストを維持

## SHOULD
- **ビジネスロジック委譲**: コントローラ内にビジネスロジックを書かず、usecaseを呼び出す
- **RESTful設計**: 標準的な7アクション（index/new/create/edit/update/destroy/show）を基本とする

---

# 変更ガイド

## よくある変更パターン

### 新しい管理画面を追加する
1. コントローラ作成: `admin/[domain]/[entity]_controller.rb`
2. ルーティング追加: `config/routes.rb` の `namespace :admin` 配下
3. ビュー作成: `app/views/admin/[domain]/[entity]/`
4. Command呼び出し: 既存のusecase（AddCommand/UpdateCommand/RemoveCommand）を `call` で呼ぶ
5. エラーハンドリング: `InvalidAttributeError` を rescue

### Command呼び出しを追加する
- **確認すべき場所**:
  - `backend/app/domain/business/base/command.rb`: Command基底クラス
  - `backend/app/domain/business/base/values.rb`: バリデーション・例外の仕組み
  - 既存のGraphQL Mutation: 同じパターンを使用（例: `backend/app/graphql/mutations/dish/source/add_source.rb`）

---

# 参照
- [DDDアーキテクチャ方針](../../docs/ai_guideline/development_standard/application_architecture.md)
- [テストファースト方針](../../docs/ai_guideline/development_standard/testing.md)
- [business/food/README.md](../../domain/business/food/README.md): usecase/Commandの役割
