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
docker compose exec frontend yarn test
docker compose logs -f frontend
```

### トラブルシューティング
```sh
docker compose ps
docker compose build --no-cache
docker compose exec frontend sh
docker volume ls
docker network ls
```


## 開発フロー
```sh
docker compose up -d
docker compose exec frontend yarn install
docker compose exec frontend yarn test
```

## Tailwind watcher のトラブルシューティング

- MUST: `docker compose exec frontend` で `tailwindcss` を手動実行しない（起動済みの watcher と競合してOOMが発生し、watcher プロセスが死ぬ）
- watcher が死んでいる兆候: `src/app/globals.css` を変更しても `tailwind-output.css` の行数・内容が変わらない
- 復旧: `docker compose restart frontend`（entrypoint.sh が watcher を再起動する）

