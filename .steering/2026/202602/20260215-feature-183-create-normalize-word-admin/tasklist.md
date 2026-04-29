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

## インクリメンタル開発の方針

各機能を完全に完成させてから次の機能に進む（縦切り）:
1. **準備**: ルーティング、Bootstrap追加
2. **一覧機能**: index（コントローラ → ビュー → テスト → グリーン）
3. **新規作成機能**: new, create（コントローラ → ビュー → テスト → グリーン）
4. **編集機能**: edit, update（コントローラ → ビュー → テスト → グリーン）
5. **削除機能**: destroy（コントローラ → テスト → グリーン）
6. **品質チェック**: 全テスト、Rubocop
7. **ドキュメント**: doc-enricher

---

## フェーズ1: 準備（ルーティングとレイアウト）

### DoD（完了条件）
- ルーティングが設定され、`rails routes` で確認できる
- Bootstrap 5 が application.html.erb に追加され、全ページで利用可能

### タスク

- [x] ルーティング設定
    - [x] `config/routes.rb` に admin/food/dish/word/normalize_words リソースルート追加
    - [x] `docker compose exec backend bundle exec rails routes | grep normalize_words` で確認

- [x] レイアウトに Bootstrap 5 を追加
    - [x] `app/views/layouts/application.html.erb` の `<head>` に Bootstrap CSS 追加
    - [x] `<body>` の最後に Bootstrap JS 追加

---

## フェーズ2: 一覧機能（index）

### DoD（完了条件）
- `/admin/food/dish/word/normalize_words` にアクセスすると、全NormalizeWordが一覧表示される
- コントローラテストとシステムテストが全てグリーン

### タスク

- [x] コントローラテスト作成（index）
    - [x] `spec/controllers/admin/food/dish/word/normalize_words_controller_spec.rb` 作成
    - [x] index アクションのテスト作成（NormalizeWord.all が呼ばれ、index テンプレートがレンダリングされること）
    - [x] テスト実行（Red確認）

- [x] コントローラ実装（index）
    - [x] `app/controllers/admin/food/dish/word/normalize_words_controller.rb` 作成
    - [x] index アクション実装（`@normalize_words = NormalizeWord.all`）
    - [x] テスト実行（Green確認）

- [x] システムテスト作成（index）
    - [x] `spec/system/admin/food/dish/word/normalize_words_spec.rb` 作成
    - [x] 一覧表示のテスト作成（レコードが表示されること、「新規作成」リンクがあること）
    - [x] テスト実行（Red確認）

- [x] ビュー実装（index）
    - [x] `app/views/admin/food/dish/word/normalize_words/index.html.erb` 作成
    - [x] Bootstrap テーブルで一覧表示、「新規作成」リンク追加
    - [x] テスト実行（Green確認）

- [x] フェーズ2完了確認
    - [x] `docker compose exec backend bundle exec rspec spec/controllers/admin/food/dish/word/normalize_words_controller_spec.rb` → グリーン
    - [x] `docker compose exec backend bundle exec rspec spec/system/admin/food/dish/word/normalize_words_spec.rb` → グリーン

---

## フェーズ3: 新規作成機能（new, create）

### DoD（完了条件）
- 新規作成フォームから正規化ワードを作成できる
- バリデーションエラー時にエラーメッセージが表示される
- コントローラテストとシステムテストが全てグリーン

### タスク

- [x] コントローラテスト作成（new）
    - [x] new アクションのテスト作成（new テンプレートがレンダリングされること）
    - [x] テスト実行（Red確認）

- [x] コントローラ実装（new）
    - [x] new アクション実装（`@normalize_word = NormalizeWord.new`）
    - [x] テスト実行（Green確認）

- [x] コントローラテスト作成（create）
    - [x] create アクションのテスト作成
        - 正常系: AddCommand.call が呼ばれ、一覧ページにリダイレクト、フラッシュメッセージ設定
        - 異常系: InvalidAttributeError が raise された場合、new テンプレート再表示、エラーメッセージ設定
    - [x] テスト実行（Red確認）

- [x] コントローラ実装（create）
    - [x] create アクション実装（AddCommand呼び出し + エラーハンドリング）
    - [x] `normalize_word_params` メソッド実装（Strong Parameters）
    - [x] テスト実行（Green確認）

- [x] システムテスト作成（新規作成フロー）
    - [x] 新規作成フローのテスト作成（「新規作成」→ 入力 → 作成 → 一覧に表示）
    - [x] テスト実行（Red確認）

- [x] ビュー実装（new）
    - [x] `app/views/admin/food/dish/word/normalize_words/new.html.erb` 作成
    - [x] `app/views/admin/food/dish/word/normalize_words/_form.html.erb` 作成（共通フォーム partial）
    - [x] Bootstrap フォームで source/destination 入力フィールド、作成ボタン
    - [x] エラーメッセージ表示
    - [x] テスト実行（Green確認）

- [x] index.html.erb に「編集」「削除」リンクを追加（次フェーズの準備）
    - [x] 各レコードに「編集」「削除」リンク追加
    - [x] システムテスト実行（Green確認）

- [x] フェーズ3完了確認
    - [x] `docker compose exec backend bundle exec rspec spec/controllers/admin/food/dish/word/normalize_words_controller_spec.rb` → グリーン
    - [x] `docker compose exec backend bundle exec rspec spec/system/admin/food/dish/word/normalize_words_spec.rb` → グリーン

---

## フェーズ4: 編集機能（edit, update）

### DoD（完了条件）
- 編集フォームから正規化ワードを更新できる
- バリデーションエラー時にエラーメッセージが表示される
- コントローラテストとシステムテストが全てグリーン

### タスク

- [x] コントローラテスト作成（edit）
    - [x] edit アクションのテスト作成（指定IDのレコードが取得され、edit テンプレートがレンダリングされること）
    - [x] テスト実行（Red確認）

- [x] コントローラ実装（edit）
    - [x] edit アクション実装（`@normalize_word = NormalizeWord.find(params[:id])`）
    - [x] テスト実行（Green確認）

- [x] コントローラテスト作成（update）
    - [x] update アクションのテスト作成
        - 正常系: UpdateCommand.call が呼ばれ、一覧ページにリダイレクト、フラッシュメッセージ設定
        - 異常系: InvalidAttributeError が raise された場合、edit テンプレート再表示、エラーメッセージ設定
    - [x] テスト実行（Red確認）

- [x] コントローラ実装（update）
    - [x] update アクション実装（UpdateCommand呼び出し + エラーハンドリング）
    - [x] テスト実行（Green確認）

- [x] システムテスト作成（編集フロー）
    - [x] 編集フローのテスト作成（「編集」→ 変更 → 更新 → 一覧に反映）
    - [x] テスト実行（Red確認）

- [x] ビュー実装（edit）
    - [x] `app/views/admin/food/dish/word/normalize_words/edit.html.erb` 作成
    - [x] _form.html.erb を更新（new/edit 両対応）
    - [x] エラーメッセージ表示
    - [x] テスト実行（Green確認）

- [x] フェーズ4完了確認
    - [x] `docker compose exec backend bundle exec rspec spec/controllers/admin/food/dish/word/normalize_words_controller_spec.rb` → グリーン
    - [x] `docker compose exec backend bundle exec rspec spec/system/admin/food/dish/word/normalize_words_spec.rb` → グリーン

---

## フェーズ5: 削除機能（destroy）

### DoD（完了条件）
- 削除リンクから正規化ワードを削除できる
- コントローラテストとシステムテストが全てグリーン

### タスク

- [x] コントローラテスト作成（destroy）
    - [x] destroy アクションのテスト作成（RemoveCommand.call が呼ばれ、一覧ページにリダイレクト、フラッシュメッセージ設定）
    - [x] テスト実行（Red確認）

- [x] コントローラ実装（destroy）
    - [x] destroy アクション実装（RemoveCommand呼び出し）
    - [x] テスト実行（Green確認）

- [x] システムテスト作成（削除フロー）
    - [x] 削除フローのテスト作成（「削除」→ 確認 → 一覧から削除）
    - [x] テスト実行（Red確認、既にGreenなら確認のみ）

- [x] フェーズ5完了確認
    - [x] `docker compose exec backend bundle exec rspec spec/controllers/admin/food/dish/word/normalize_words_controller_spec.rb` → グリーン
    - [x] `docker compose exec backend bundle exec rspec spec/system/admin/food/dish/word/normalize_words_spec.rb` → グリーン

---

## フェーズ6: 品質チェックと修正

### DoD（完了条件）
- 全テストがグリーン
- Rubocopエラーがない

### タスク

- [x] 全テスト実行
    - [x] `docker compose exec backend bundle exec rspec spec/controllers/admin/food/dish/word/normalize_words_controller_spec.rb`
    - [x] `docker compose exec backend bundle exec rspec spec/system/admin/food/dish/word/normalize_words_spec.rb`
    - [x] すべてグリーン確認

- [x] Rubocop実行
    - [x] `docker compose exec backend bundle exec rubocop app/controllers/admin/food/dish/word/normalize_words_controller.rb`
    - [x] `docker compose exec backend bundle exec rubocop app/views/admin/food/dish/word/normalize_words/`
    - [x] エラーがあれば修正して再実行
    - [x] エラーゼロ確認

---

## フェーズ7: ドキュメント更新

### DoD（完了条件）
- doc-enricher の提案を確認（必要に応じて適用）
- 実装後の振り返りを記録

### タスク

- [x] doc-enricher による README 更新提案
    - [x] steering スキル終了時に doc-enricher が自動実行される
    - [x] 提案内容を確認し、必要に応じて適用

- [x] 実装後の振り返り
    - [x] このファイルの「実装後の振り返り」セクションに記録
    - [x] 計画と実績の差分を記録
    - [x] 新たに必要になったタスクを記録

---

## 実装詳細（参考）

### ルーティング

**ファイル**: `backend/config/routes.rb`

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

### コントローラの基本構造

**ファイル**: `backend/app/controllers/admin/food/dish/word/normalize_words_controller.rb`

```ruby
module Admin::Food::Dish::Word
  class NormalizeWordsController < ApplicationController
    def index
      @normalize_words = NormalizeWord.all
    end

    def new
      @normalize_word = NormalizeWord.new
    end

    def create
      @normalize_word = Business::Food::Dish::Word::Usecase::AddCommand.call(
        source: normalize_word_params[:source],
        destination: normalize_word_params[:destination]
      )
      redirect_to admin_food_dish_word_normalize_words_path, notice: '正規化ワードを作成しました'
    rescue Business::Base::Values::InvalidAttributeError => e
      @normalize_word = NormalizeWord.new(normalize_word_params)
      flash.now[:alert] = e.message
      render :new
    end

    def edit
      @normalize_word = NormalizeWord.find(params[:id])
    end

    def update
      Business::Food::Dish::Word::Usecase::UpdateCommand.call(
        normalize_word_id: params[:id].to_i,
        source: normalize_word_params[:source],
        destination: normalize_word_params[:destination]
      )
      redirect_to admin_food_dish_word_normalize_words_path, notice: '正規化ワードを更新しました'
    rescue Business::Base::Values::InvalidAttributeError => e
      @normalize_word = NormalizeWord.find(params[:id])
      @normalize_word.assign_attributes(normalize_word_params)
      flash.now[:alert] = e.message
      render :edit
    end

    def destroy
      Business::Food::Dish::Word::Usecase::RemoveCommand.call(
        normalize_word_id: params[:id].to_i
      )
      redirect_to admin_food_dish_word_normalize_words_path, notice: '正規化ワードを削除しました'
    end

    private

    def normalize_word_params
      params.require(:normalize_word).permit(:source, :destination)
    end
  end
end
```

### ビューの実装例

#### index.html.erb

```erb
<div class="container mt-4">
  <h1>正規化ワード管理</h1>

  <% if notice %>
    <div class="alert alert-success" role="alert"><%= notice %></div>
  <% end %>

  <%= link_to '新規作成', new_admin_food_dish_word_normalize_word_path, class: 'btn btn-primary mb-3' %>

  <table class="table table-striped">
    <thead>
      <tr>
        <th>ID</th>
        <th>入力元（source）</th>
        <th>入力先（destination）</th>
        <th>正規化元</th>
        <th>正規化先</th>
        <th>操作</th>
      </tr>
    </thead>
    <tbody>
      <% @normalize_words.each do |word| %>
        <tr>
          <td><%= word.id %></td>
          <td><%= word.entered_source %></td>
          <td><%= word.entered_destination %></td>
          <td><%= word.source %></td>
          <td><%= word.destination %></td>
          <td>
            <%= link_to '編集', edit_admin_food_dish_word_normalize_word_path(word), class: 'btn btn-sm btn-secondary' %>
            <%= button_to '削除', admin_food_dish_word_normalize_word_path(word), method: :delete, data: { confirm: '本当に削除しますか?' }, class: 'btn btn-sm btn-danger' %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

#### new.html.erb

```erb
<div class="container mt-4">
  <h1>正規化ワード新規作成</h1>

  <% if flash[:alert] %>
    <div class="alert alert-danger" role="alert"><%= flash[:alert] %></div>
  <% end %>

  <%= render 'form', normalize_word: @normalize_word %>

  <%= link_to '戻る', admin_food_dish_word_normalize_words_path, class: 'btn btn-secondary mt-3' %>
</div>
```

#### edit.html.erb

```erb
<div class="container mt-4">
  <h1>正規化ワード編集</h1>

  <% if flash[:alert] %>
    <div class="alert alert-danger" role="alert"><%= flash[:alert] %></div>
  <% end %>

  <%= render 'form', normalize_word: @normalize_word %>

  <%= link_to '戻る', admin_food_dish_word_normalize_words_path, class: 'btn btn-secondary mt-3' %>
</div>
```

#### _form.html.erb

```erb
<%= form_with(model: normalize_word, url: normalize_word.persisted? ? admin_food_dish_word_normalize_word_path(normalize_word) : admin_food_dish_word_normalize_words_path, local: true) do |form| %>
  <div class="mb-3">
    <%= form.label :source, '元ワード（source）', class: 'form-label' %>
    <%= form.text_field :source, class: 'form-control', placeholder: '例: トマト煮込み' %>
  </div>

  <div class="mb-3">
    <%= form.label :destination, '正規化先（destination）', class: 'form-label' %>
    <%= form.text_field :destination, class: 'form-control', placeholder: '例: トマト煮（空欄可：sourceと同じになります）' %>
    <small class="form-text text-muted">空欄の場合、sourceと同じ値になります</small>
  </div>

  <%= form.submit normalize_word.persisted? ? '更新' : '作成', class: 'btn btn-primary' %>
<% end %>
```

---

## 実装後の振り返り

### 実装完了日
2026-02-15

### 計画と実績の差分

**計画と異なった点**:
- コントローラテストを request spec に変更
  - 理由: Rails 5以降、`assigns` と `render_template` は `rails-controller-testing` gem が必要
  - 対応: controller spec の代わりに request spec を使用（Rails推奨の方法）

**新たに必要になったタスク**:
- なし（計画通り全タスク完了）

**技術的理由でスキップしたタスク**:
- なし（全タスク完了）

**実装の成果**:
- フェーズ1〜7まで全て完了
- 全14テストがグリーン
- Rubocopエラーゼロ
- インクリメンタル開発（機能単位の縦切り）が効果的に機能
