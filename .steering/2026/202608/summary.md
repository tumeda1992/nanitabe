# 2026年08月 Steering サマリー

## [20260823-fix-dish-card-tap-copy-naming](./20260823-fix-dish-card-tap-copy-naming/)

**概要:** 評価モーダル内で★をタップすると、そのクリックが星のハンドラとカード全体のハンドラの両方で処理される。カード側の `setActionsOpen(true)` が `DishCard` を再 render させ、`useFullScreenModal` が返す `FullScreenModal` を関数ごと作り直すため、React が subtree を remount して直前に書き込まれた選択スコアを捨てる。二度目のタップは `actionsOpen` が同値で React が再 render を打ち切るため効く。この二重処理を断ち、あわせて「名前コピー」がレシピ元名を含むようにし、実態が Meal のカードである component を改名する。

**ステータス:** 完了

---

## [20260830-consolidate-frontend-build-scripts](./20260830-consolidate-frontend-build-scripts/)

**概要:** `frontend/package.json` の `build` は `next build` だけを行い、Tailwind CSS のコンパイルを含まない。そのため build を呼ぶ側（`frontend/entrypoint.sh`、`frontend/buildOnLambda/Dockerfile`、`.github/workflows/ci-frontend-build-verification.yml`）が全員、`node_modules/.bin/tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css` という同じコマンド詳細を各自で持っている。Tailwind の入出力 path を変えると 4 箇所を追随させる必要がある状態を解消する。

**ステータス:** 未完了

---
