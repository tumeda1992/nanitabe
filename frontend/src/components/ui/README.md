# UI コンポーネント（shadcn/ui ベース）

## 概要

shadcn/ui スタイルの共通コンポーネント。Tailwind CSS v4 + CSS変数ベースで実装。

## 利用可能なコンポーネント

- `button.tsx` — variant: default/destructive/outline/secondary/ghost/link、size: default/sm/lg/icon/icon-sm/icon-lg
- `input.tsx` — shadcn/ui スタイルの `<input>` ラッパー。`Form.Control` の代替
- `dropdown-menu.tsx` — `@radix-ui/react-dropdown-menu` ラッパー
- `drawer.tsx` — `@radix-ui/react-dialog` ベースのドロワー

## 不変条件

- MUST: 新規コンポーネント追加時は使用するカラートークン（`--color-xxx`）が `src/app/globals.css` の `@theme inline` に定義済みか確認する
- MUST: Bootstrap は削除済み。`ghost` variant に `bg-transparent border-0` は不要（追加しない）
- MUST: button のブラウザデフォルト枠線は `globals.css` の `@layer base { button { border: none; } }` でリセット済み。shadcn Button コンポーネントを使う限り個別指定不要
