# 要件ドキュメント

## はじめに

カレンダーデザイン移行（フェーズ1）として、Tailwind CSS + shadcn/ui を既存の Next.js フロントエンドに導入する。
既存の Bootstrap/SCSS modules との共存が最大の設計課題。

## 元の依頼内容

`.steering/2026/20260307-feature-201-apply-v0-calendar-design/tasklist.md` フェーズ1:
- Tailwind CSS の導入（postcss + tailwind.config）
- shadcn/ui 依存パッケージの追加（lucide-react, clsx, tailwind-merge, radix-ui 等）
- shadcn/ui コンポーネントを `frontend/src/components/ui/` に追加（Button, DropdownMenu, Drawer）
- 既存画面が壊れないこと・既存テストがグリーンであること

## 要件

### 要件1: Tailwind CSS が動作する
**ユーザーストーリー:** 次フェーズ以降でカレンダーコンポーネントに Tailwind ユーティリティクラスを使えるようにする

#### 受け入れ基準
1. WHEN Tailwind ユーティリティクラスをコンポーネントに書く THEN スタイルが適用される
2. WHEN 既存の SCSS modules を使ったコンポーネントを表示する THEN スタイルが壊れない
3. WHEN 既存の base.css（CSS リセット）が適用されている THEN Tailwind preflight と重複しない

### 要件2: shadcn/ui コンポーネントが使える
**ユーザーストーリー:** フェーズ2以降で Button / DropdownMenu / Drawer を import して使える

#### 受け入れ基準
1. WHEN `@/components/ui/button` を import する THEN エラーなく動作する
2. WHEN shadcn/ui コンポーネントをレンダリングする THEN 意図したスタイルが当たる

### 要件3: 既存画面・テストに影響なし
**ユーザーストーリー:** このフェーズ単体でデプロイしてもユーザーに影響なし

#### 受け入れ基準
1. WHEN 既存のカレンダー・食事登録画面を開く THEN 見た目が変わらない
2. WHEN `docker compose exec frontend yarn test` を実行する THEN 全テストグリーン
3. WHEN `docker compose exec frontend yarn lint` を実行する THEN エラーゼロ

---

# 設計ドキュメント

## TL;DR

Tailwind CSS を `postcss.config.js` + `tailwind.config.ts` で追加し、`preflight` を無効化して既存 CSS と共存させる。
`@/` パスエイリアスを tsconfig に追加（現在未設定）。shadcn/ui の Button / DropdownMenu / Drawer を
`src/components/ui/` に手動でコピー（shadcn CLI は使わない）。

## 変更点サマリ

| 変更 | ファイル |
|------|--------|
| 新規作成 | `frontend/postcss.config.mjs` |
| 新規作成 | `frontend/src/app/globals.css`（Tailwind インポート + shadcn/ui CSS 変数） |
| 修正 | `frontend/src/app/layout.tsx`（globals.css import 追加） |
| 修正 | `frontend/tsconfig.json`（`paths: { "@/*": ["./src/*"] }` 追加） |
| yarn add | @tailwindcss/postcss tailwindcss（v4系） |
| yarn add | lucide-react, clsx, tailwind-merge, class-variance-authority |
| yarn add | @radix-ui/react-dropdown-menu, @radix-ui/react-slot, vaul |
| 新規作成 | `frontend/src/components/ui/button.tsx` |
| 新規作成 | `frontend/src/components/ui/dropdown-menu.tsx` |
| 新規作成 | `frontend/src/components/ui/drawer.tsx` |
| 新規作成 | `frontend/src/lib/utils.ts`（`cn` ユーティリティ） |

## 設計選択と理由

### Tailwind v4 を採用（v0 デザインに合わせる）
v0 デザインが `tailwindcss ^4.2.0` + `@tailwindcss/postcss` を使っているため、同バージョンを採用する。
v4 では `tailwind.config.ts` は不要で、CSS ファイルで設定する（`@theme` ブロック）。
postcss plugin も `tailwindcss` ではなく `@tailwindcss/postcss` に変わっている。

### preflight 無効化（v4 の方法）
既存の `base.css`（CSS リセット）と Tailwind の preflight が重複するリスクがある。
v4 では `@import "tailwindcss"` の代わりに、preflight を除いたサブセットをインポートする:
```css
@import "tailwindcss/theme";    /* CSS 変数 (--color-* 等) */
@import "tailwindcss/utilities"; /* ユーティリティクラスのみ */
/* @import "tailwindcss/preflight" は省略 → リセット競合を回避 */
```
shadcn/ui の CSS カスタムプロパティ（`--background`, `--foreground` 等）は `:root` に直接定義する。

### `@/` パスエイリアスの追加
v0 デザインのコンポーネントは `@/components/...` / `@/lib/...` の import を多用している。
tsconfig.json に `"paths": { "@/*": ["./src/*"] }` を追加する。
`next/jest` が tsconfig の paths を自動的に `moduleNameMapper` に変換するため、jest.config.js の変更は不要。

### shadcn CLI を使わない（手動コピー）
shadcn CLI は `components.json` 等の設定ファイルを必要とし、既存プロジェクト構成と干渉しやすい。
必要な 3 コンポーネント（Button / DropdownMenu / Drawer）のみを v0 デザインリポジトリからコピーして調整する。

## 代替案と棄却理由

### 代替案1: Tailwind v3 を採用
shadcn/ui は v3 も v4 も対応しているが、v0 デザインが v4 ベースのため、後フェーズでデザインを移植する際に
CSS 設定の差異でトラブルが起きやすい。v0 と同じ v4 に合わせる方が安全なため棄却。

### 代替案2: shadcn CLI を使う
`npx shadcn@latest init` で初期化する方法。既存の next.config.js / tsconfig への干渉が大きく、
トラブルシュートが複雑になるリスクがある。手動コピーの方が制御しやすいため棄却。

## リスクと対策

| リスク | 対策 |
|--------|------|
| preflight が部分的に適用されて既存 SCSS を上書き | v4 のサブセットインポートで preflight を完全に除外する |
| shadcn/ui コンポーネントの Radix UI バージョン競合 | 追加前に `yarn why` で競合確認。peer deps の警告があれば解消する |
| globals.css import で既存スタイルが変わる | globals.css には Tailwind + CSS 変数のみ。既存 base.css は引き続き各コンポーネントで import |
| v4 の `@tailwindcss/postcss` と既存 postcss 設定の競合 | 既存 postcss 設定がないため新規作成のみで対応できる |

## テスト方針

- テスト追加は不要（新規 UI コンポーネントを追加するだけで、ロジック変更なし）
- 既存テストが全てグリーンであることを確認
- ESLint で新規ファイルのエラーがゼロであることを確認
- 手動確認: 既存のカレンダー画面を開いてスタイル崩れがないことを確認
