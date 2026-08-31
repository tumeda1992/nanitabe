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
- `@tailwindcss/cli` を `package.json` の `build:css` で独立プロセス実行する方式を採用
- `src/app/tailwind-output.css` は生成物（gitignore済み）。`layout.tsx` で `import './tailwind-output.css'` としてインポート
- カラーユーティリティ（`bg-background`, `text-foreground` 等）を使うには `src/app/globals.css` の `@theme inline { --color-xxx: hsl(var(--xxx)) }` が必須
- `@import "tailwindcss/preflight"` はDocker container内でメモリ超過によりkill（exit 137）されるため使用禁止。`button` 等のブラウザデフォルトスタイルリセットは `globals.css` の `@layer base { button { border: none; background: transparent; } }` で個別対処する
- Tailwind のビルドと watch の特性（`--watch=always` が必要な理由、tree-shake、反映の遅延、再コンパイル時のメモリ膨張）は `docs/troubleshooting/tailwind/build_and_watch.md` を参照
- ローカルの Docker コンテナが壊れたときの症状と復旧手順は `docs/ai_guideline/development_standard/docker.local.md` を参照

#### CSS の処理は Next.js コマンドに随伴させる

`build` は `build:css` を、`dev` は `watch:css` を伴う。新しく Next.js コマンドを叩く script を
追加するときは、そのコマンドが CSS を必要とするかで随伴の要否を決める。呼び出し側に 2 つ叩かせない。

- やってしまいがちな失敗: `build` にだけ CSS を随伴させ、`dev` を `next` のまま据え置く
- それをやると何が起きるか: dev 経路の呼び出し側が watcher の起動を覚えていなければならず、
  「外から両方使わなければならない」状態が片側に残る
- 正しい判断のための問い: 「このコマンドは `tailwind-output.css` を必要とするか？」
