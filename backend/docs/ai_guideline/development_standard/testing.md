# テスト（Rails）

## MUST（必須）
- **テストファースト**：テストを先に書き、グリーンになってから次へ進む。
- **実行環境の統一**：テストは**必ず Docker コンテナ内で実行**する（ホスト実行は禁止）。
- **独立・再現性**：各テストは他に依存せず、何度でも同じ結果になること。
- **DB分離**：テスト用DBを本番/開発と分離し、各テストで**トランザクション/リセット**を徹底する。

## PROHIBITED（禁止）
- テスト未実行のまま次タスクへ進むこと。
- 失敗したテストを残したまま別ブランチ/別タスクへ進むこと。
- ホストで `bundle exec rspec` 等を実行すること（**コンテナ外実行の禁止**）。


## 実装サイクル（Red → Green → Refactor）
1. **テスト作成**：修正意図に沿った失敗するテストを書く（具体シナリオ、独立実行可能）。
2. **実装**：テストを通すための**最小限**の変更のみ。
3. **実行**：テストを実行し、失敗なら原因分析→実装修正→再実行。
4. **反復**：全テストがグリーンになるまで繰り返す。必要ならリファクタ。

### ⚠️ 絶対順序
① テスト作成
② 実装
③ 必ずテスト実行
④ 失敗→修正→再実行
⑤ 全緑を確認してから次タスク

## 実行コマンド（Docker内）
> サービス名を `web` と仮定。適宜プロジェクトの compose に合わせて変更。

```bash
# すべてのRSpecを実行
docker compose exec web bundle exec rspec

# 特定ファイル/行の実行
docker compose exec web bundle exec rspec spec/models/user_spec.rb:12

# Minitest（rails test）利用時
docker compose exec web bin/rails test

# 並列実行（DBを自動で分割）
docker compose exec web bin/rails parallel:test

# DB 初期化/マイグレーション（テスト用）
docker compose exec web bin/rails db:test:prepare
docker compose exec web bin/rails db:migrate RAILS_ENV=test
RSpec 基本セットアップ（例）
Gemfile（test/development）
```


## 良い/悪いテスト例（Rails）
### 良い例（モデル）

```ruby
RSpec.describe Room, type: :model do
  it 'valid with required attributes' do
    room = Room.new(name: 'test-room', max_players: 4, host_id: 1)
    expect(room).to be_valid
  end

  it 'invalid with empty name' do
    room = Room.new(name: '', max_players: 4, host_id: 1)
    expect(room).to be_invalid
    expect(room.errors[:name]).to include("can't be blank")
  end
end
```

### 悪い例（意図不明・無アサーション）

```ruby
RSpec.describe Room, type: :model do
  it 'works' do
    Room.create!
  end
end
```

## バリエーション網羅
- 基本: ifの分岐はできるだけカバーし、意味的・運用的に重要なケースがあったらそれもカバーする
- テストするメソッド内で、更にメソッドやオブジェクトを利用している場合
  - 細かなバリエーションは利用先メソッドで担保する
  - 呼び出し元では、主要なパターンを1つずつ確認するのみでよく、細かなパターンは不要
    - 呼び出し元で、そのメソッドの返り値による分岐がある場合は、その分岐をカバーする程度


## トラブルシューティング（Docker）
```bash
# 状態確認
docker compose ps
# コンテナ再作成
docker compose down && docker compose up -d
# キャッシュ無効でビルド
docker compose build --no-cache
# web コンテナに入る
docker compose exec web sh
# ログ
docker compose logs -f web
```

## メタ原則（Claude向け）
禁止：テスト未実行/失敗状態での先送り、コンテナ外実行。

必須：テストファースト、独立性/再現性、DBの厳格な分離。

進め方：常に Red→Green→Refactor。グリーン前に機能追加しない。

## specファイルの記法
禁止
- インスタンス変数を参照して、期待値チェックを行うこと
