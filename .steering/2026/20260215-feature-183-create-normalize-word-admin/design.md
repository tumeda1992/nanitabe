# 要件ドキュメント

## はじめに
NormalizeWord（料理名の正規化ワード）を管理する管理画面を backend の erb で作成する。デザインはシンプル、認可は不要、URL は `/admin/normalize_words` 配下とする。

## 元の依頼内容
```
正規化ワードのNormalizeWordについての管理画面をbackendディレクトリ配下にerbで作りたい。
デザインは凝らない感じで。

管理画面とかいうけど、ユーザも管理者も自分で、自分しか使わないから、認可とか不要で。
一応、URLにadminっていうディレクトリは掘ってもらいたいけど

リスティングは ActiveRecordの NormalizeWord を全件取得
更新系はビジネスロジックを呼ぶ
- 追加 backend/app/domain/business/food/dish/word/usecase/add_command.rb
- 更新 backend/app/domain/business/food/dish/word/usecase/update_command.rb
- 削除 backend/app/domain/business/food/dish/word/usecase/remove_command.rb
```

## 要件

### 要件1: NormalizeWord一覧表示
**ユーザーストーリー:** 登録済みの正規化ワードを一覧で確認できる

#### 受け入れ基準
1. WHEN `/admin/normalize_words` にアクセス THEN 全NormalizeWordが表示される
2. WHEN 一覧が表示される THEN `entered_source`, `entered_destination`, `source`, `destination` が表示される
3. WHEN 一覧が表示される THEN 各レコードに「編集」「削除」リンクが表示される
4. WHEN 一覧が表示される THEN 「新規作成」リンクが表示される

### 要件2: NormalizeWord新規作成
**ユーザーストーリー:** 新しい正規化ワードを追加できる

#### 受け入れ基準
1. WHEN 新規作成フォームで `source` を入力 THEN `AddCommand` が呼ばれてレコードが作成される
2. WHEN `destination` が未入力 THEN `destination` は自動的に `source` と同じになる（AddCommandの仕様）
3. WHEN 作成成功 THEN 一覧画面にリダイレクトされる
4. WHEN バリデーションエラー THEN エラーメッセージが表示される

### 要件3: NormalizeWord編集
**ユーザーストーリー:** 既存の正規化ワードを修正できる

#### 受け入れ基準
1. WHEN 編集フォームで `source`, `destination` を変更 THEN `UpdateCommand` が呼ばれて更新される
2. WHEN 更新成功 THEN 一覧画面にリダイレクトされる
3. WHEN バリデーションエラー THEN エラーメッセージが表示される

### 要件4: NormalizeWord削除
**ユーザーストーリー:** 不要な正規化ワードを削除できる

#### 受け入れ基準
1. WHEN 削除リンクをクリック THEN `RemoveCommand` が呼ばれてレコードが削除される
2. WHEN 削除成功 THEN 一覧画面にリダイレクトされる

### 非目標
- 凝ったデザイン（Bootstrapの基本コンポーネントのみ使用）
- 認証・認可機能
- ページネーション（全件表示で問題なし）

---

# 設計ドキュメント

## TL;DR
- Rails標準のRESTfulコントローラ `Admin::NormalizeWordsController` を作成
- 7アクション（index, new, create, edit, update, destroy, show）のうち、index/new/create/edit/update/destroyを実装（showは不要）
- erbビューは最小限のHTML（table, form）
- create/update/destroyでは既存のusecaseを呼び出す

## 変更点サマリ

### 新規作成ファイル
1. **コントローラ**: `backend/app/controllers/admin/food/dish/word/normalize_words_controller.rb`
   - 6アクション: index, new, create, edit, update, destroy
   - リスティング: `@normalize_words = NormalizeWord.all`
   - 更新系: usecaseを呼び出し

2. **ビュー**:
   - `backend/app/views/admin/food/dish/word/normalize_words/index.html.erb`: 一覧（table + Bootstrap）
   - `backend/app/views/admin/food/dish/word/normalize_words/new.html.erb`: 新規作成フォーム（Bootstrap）
   - `backend/app/views/admin/food/dish/word/normalize_words/edit.html.erb`: 編集フォーム（Bootstrap）
   - `backend/app/views/admin/food/dish/word/normalize_words/_form.html.erb`: 共通フォーム（partial）

3. **ルーティング**: `backend/config/routes.rb`
   ```ruby
   namespace :admin do
     namespace :food do
       namespace :dish do
         namespace :word do
           resources :normalize_words, except: [:show]
         end
       end
     end
   end
   ```

## 設計選択と理由

### 1. Rails標準のRESTful設計
- **理由**: 既存のRailsプロジェクトに馴染む、テストしやすい、拡張しやすい
- **既存パターン適合**: ApplicationControllerを継承、GraphQLとは別レイヤー

### 2. usecaseの呼び出し方
コントローラからusecaseを呼ぶパターン:
```ruby
# createアクション
begin
  @normalize_word = Business::Food::Dish::Word::Usecase::AddCommand.call(
    source: params[:normalize_word][:source],
    destination: params[:normalize_word][:destination]
  )
  redirect_to admin_food_dish_word_normalize_words_path, notice: '正規化ワードを作成しました'
rescue Business::Base::Values::InvalidAttributeError => e
  @normalize_word = NormalizeWord.new(params.require(:normalize_word).permit(:source, :destination))
  flash.now[:alert] = e.message
  render :new
end
```

- **理由**: ビジネスロジックをusecaseに閉じ込め、コントローラはプレゼンテーション層の責務に専念
- **既存パターン適合**:
  - DDDレイヤードアーキテクチャに従う（プレゼンテーション層→ユースケース層）
  - GraphQLのMutationと同じパターン（`Command.call` を直接呼ぶ、例: `backend/app/graphql/mutations/dish/source/add_source.rb`）
  - `Command` クラスは `initialize` 時に自動バリデーション→失敗時は `InvalidAttributeError` を raise

### 3. CSRFトークン
- ApplicationControllerで `protect_from_forgery with: :null_session` が設定済み
- 既存の設定をそのまま利用（変更不要）

### 4. デザイン
- Bootstrap 5 を使用（CDN経由で読み込み）
- シンプルなレイアウト（table, form, button等の基本コンポーネント）
- **理由**: ユーザー要求（「デザインは凝らない」が、Bootstrapは使ってOK）

## 代替案と棄却理由

### 代替案1: GraphQL Mutationで実装
- **棄却理由**: ユーザーが「erbで作りたい」と明示、HTMLフォームの方が実装が早い

### 代替案2: コントローラから直接ActiveRecordを呼ぶ
- **棄却理由**: ユーザーが「更新系はビジネスロジックを呼ぶ」と明示、usecaseが既に存在しており一貫性を保つため

### 代替案3: showアクションも実装
- **棄却理由**: 一覧で十分情報が見えるため不要、編集で詳細も見れる

## リスクと対策

### リスク1: usecaseのバリデーションエラーハンドリング
- **確認済み**:
  - `Command` は `Business::Base::Values` を継承（`ActiveModel::Model` を include）
  - `initialize` 時に自動的に `valid?` をチェック
  - バリデーション失敗時は `Business::Base::Values::InvalidAttributeError` を raise
- **対策**: `begin...rescue InvalidAttributeError` でエラーハンドリング、フラッシュメッセージで表示

### リスク2: CSRF無効化による脆弱性
- **現状**: ApplicationControllerで `protect_from_forgery with: :null_session` が設定されている（暫定）
- **影響**: 管理画面でもCSRF保護が無効
- **判断**: ユーザーが「自分しか使わない」と明示しており、現時点では問題なし
- **将来対応**: 必要に応じてCSRFトークンを有効化

### リスク3: 認可なしによるセキュリティ
- **現状**: 認可機能なし
- **判断**: ユーザーが「認可とか不要」と明示、開発環境or内部ツールと推測
- **将来対応**: 必要に応じてBasic認証やdevise導入

## テスト方針

### コントローラテスト（RSpec）
- **ファイル**: `backend/spec/controllers/admin/food/dish/word/normalize_words_controller_spec.rb`
- **カバレッジ**:
  - index: 全件取得できること
  - new: フォームが表示されること
  - create:
    - 正常系: AddCommandが呼ばれ、リダイレクトすること
    - 異常系: バリデーションエラー時にnewテンプレートが再表示されること
  - edit: 既存レコードが取得されること
  - update:
    - 正常系: UpdateCommandが呼ばれ、リダイレクトすること
    - 異常系: バリデーションエラー時にeditテンプレートが再表示されること
  - destroy: RemoveCommandが呼ばれ、リダイレクトすること

### システムテスト（RSpec + Capybara）
- **ファイル**: `backend/spec/system/admin/food/dish/word/normalize_words_spec.rb`
- **シナリオ**:
  - 一覧→新規作成→作成完了→一覧に戻る
  - 一覧→編集→更新→一覧に戻る
  - 一覧→削除→一覧に戻る（レコードが消えている）

### テスト実行環境
- **Docker内で実行**: `docker compose exec backend bundle exec rspec`
- **テストファースト**: テスト作成→実装→グリーン確認

## 実装の優先順位
1. ルーティング + コントローラ（index, new, create）
2. ビュー（index, new, _form）
3. テスト（index, new, create）
4. コントローラ（edit, update, destroy）
5. ビュー（edit）
6. テスト（edit, update, destroy）
