# Docker環境（Rails）

## コマンド実行環境の原則
- Rails タスク、DB マイグレーションなどは 必ずコンテナ内で実行。
  - 環境差異を防ぐため、ホスト直接実行は避ける。
- `docker-compose` コマンドは非推奨です。代わりに `docker compose` を使用してください。

## 基本ルール
- マルチステージビルドを使用。
- キャッシュを活用。
- セキュリティを考慮。
- イメージサイズを最適化。

## 運用ルール
### 基本的なコンテナ操作
```sh
docker compose up -d
docker compose stop
docker compose down
docker compose exec backend bundle exec rspec
docker compose logs -f backend
```

### トラブルシューティング
```sh
docker compose ps
docker compose build --no-cache
docker compose exec backend sh
docker volume ls
docker network ls
```


## 開発フロー（Rails）
```sh
docker compose up -d
docker compose exec backend bundle install
docker compose exec backend rails db:create db:migrate
docker compose exec backend bundle exec rspec {specファイルパス}
```

