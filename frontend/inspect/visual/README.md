# visual/

Playwright を使ってブラウザのスクリーンショットを撮り、UI の見た目を目視確認するためのツール。

## 用途

- 実装後のレイアウト確認
- コンポーネント追加・スタイル変更後の目視チェック
- Claude による自動スクリーンショット取得

## 構成

```
visual/
  lib/
    base.mjs   # ブラウザ起動・ログイン共通ユーティリティ（git管理）
  tmp/         # 即興スクリプト置き場（gitignore）
  package.json
```

## セットアップ

```bash
cd frontend/inspect/visual
yarn install
npx playwright install chromium
```

## スクリプトの書き方

`tmp/` 配下に `.mjs` を作成して実行する。`lib/base.mjs` の `createLoggedInPage` を使うと
ブラウザ起動・ログインが共通化できる。認証情報は `tmp/` は gitignore されているのでベタ書きで良い。

**⚠️ 実行はリポジトリルートから行う。スクリーンショットのパスもリポジトリルートからの相対パスで書くこと。**

```js
import { createLoggedInPage, BASE_URL } from './frontend/inspect/visual/lib/base.mjs';

const { browser, page } = await createLoggedInPage({
  email: 'setsumaru1992@gmail.com',
  password: '...',
});

await page.goto(`${BASE_URL}/dishes`);
await page.screenshot({ path: 'frontend/inspect/visual/tmp/dishes.png' });

await browser.close();
```

## 実行

**リポジトリルートから実行すること**（`cd frontend/inspect/visual` してから実行すると保存パスがずれる）。

```bash
# リポジトリルートで実行
node frontend/inspect/visual/tmp/your-script.mjs
```
