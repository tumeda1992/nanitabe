# frontend
jsのフロントエンド。

## 想定ユーザ
ほぼ自分しか使わない。
毎日の料理だったり、今週分の買い出しのために献立を考える、更には数分で考えることを求められる日常がしんどかったから作った。

## インフラ
本番では、Next.jsを動かすDockerイメージをLambdaで動かし、API Gateway経由でCloudFrontからアクセスさせている

## 主要ライブラリ
Next.js(React) + Apollo + Tailwind CSS(v4) 構成

### Tailwind CSS v4 セットアップ（制約）

- `@tailwindcss/postcss` は使用禁止。Turbopack との組み合わせでコンパイルが2分超になる
- `@tailwindcss/cli` を `entrypoint.sh` の `build_tailwind()` で独立プロセス実行する方式を採用
- `src/app/tailwind-output.css` は生成物（gitignore済み）。`layout.tsx` で `import './tailwind-output.css'` としてインポート
- **Lambda ビルド時も要注意**: `buildOnLambda/Dockerfile` では `yarn build` 前に tailwindcss CLI を明示実行すること
- カラーユーティリティ（`bg-background`, `text-foreground` 等）を使うには `src/app/globals.css` の `@theme inline { --color-xxx: hsl(var(--xxx)) }` が必須
- `@import "tailwindcss/preflight"` はDocker container内でメモリ超過によりkill（exit 137）されるため使用禁止。`button` 等のブラウザデフォルトスタイルリセットは `globals.css` の `@layer base { button { border: none; background: transparent; } }` で個別対処する
- tailwindcss watcherプロセスが死んだ場合（`docker compose exec frontend` で tailwindcss を手動実行するとOOM競合でwatcherが死ぬ）: `docker compose restart frontend` で復旧
