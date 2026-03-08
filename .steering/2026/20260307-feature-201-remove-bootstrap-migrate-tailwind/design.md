# 要件ドキュメント

## はじめに

Bootstrap と Tailwind CSS v4 が共存している状態を解消する。
Bootstrap のデフォルトスタイルが Tailwind utility クラスに干渉しているため（button の border/background など）、
react-bootstrap コンポーネントを native HTML + Tailwind に置き換えて Bootstrap を完全削除する。
あわせて Bootstrap 干渉回避のワークアラウンド（`bg-transparent border-0` など）も除去する。
Lambda ビルド時に Tailwind CSS が生成されない問題も同時に修正する。

## 元の依頼内容

既存bootstrapを消しても大丈夫にするのと
実際に消すのと
tailwindでワークアラウンドな書き方してたのをやめるのやろうか

あと、buildしたものを使って
docker-compose.yml の frontend_next_lambdaコンテナでデバッグできるimage が、本番でlambdaで動いているんだけど
今回の修正した後で動くか不安だな

## 要件

### 要件1: react-bootstrap コンポーネントの Tailwind 対応置き換え

**ユーザーストーリー:** react-bootstrap への依存を除去し、フォーム・ボタン・レイアウトを Tailwind CSS で表現できる

#### 受け入れ基準

1. WHEN Login/Signup ページを開く THEN 見た目が現状と同等以上で動作する
2. WHEN MealForm/DishForm/SourceForm を開く THEN フォームが正しく表示・操作できる
3. WHEN ChooseDish (AssignDish) を開く THEN カレンダーから食事割当てが動作する
4. WHEN FormFieldWrapperWithLabel が使われる THEN ラベル付きフィールドが正しくレイアウトされる

### 要件2: Bootstrap の完全削除

**ユーザーストーリー:** Bootstrap の CSS/JS が読み込まれなくなり、スタイル干渉がなくなる

#### 受け入れ基準

1. WHEN アプリを起動する THEN `bootstrap/dist/css/bootstrap.min.css` が読み込まれない
2. WHEN `package.json` を確認する THEN `bootstrap` と `react-bootstrap` が dependencies に存在しない

### 要件3: Tailwind ワークアラウンドの除去

**ユーザーストーリー:** Bootstrap 干渉回避のために書いた冗長なクラスが不要になり、コードがシンプルになる

#### 受け入れ基準

1. WHEN `button.tsx` を確認する THEN ghost variant に `bg-transparent border-0` が不要になっている
2. WHEN ヘッダーを確認する THEN ghost ボタンがボーダーなし・透明背景で正しく表示される

### 要件4: Lambda ビルドで Tailwind CSS が正しく生成される

**ユーザーストーリー:** Lambda 本番環境でも Tailwind のスタイルが適用される

#### 受け入れ基準

1. WHEN `buildOnLambda/Dockerfile` でビルドする THEN `tailwind-output.css` が生成されてから `yarn build` が実行される
2. WHEN `frontend_next_lambda` コンテナを起動する THEN Tailwind スタイルが適用されたページが表示される

---

# 設計ドキュメント

## TL;DR

react-bootstrap の `Form`, `Button`, `Col`, `Row` を使っている14ファイルを native HTML + Tailwind CSS に置き換える。
置き換え完了後に Bootstrap CSS/パッケージを削除し、workaround コードも除去する。
Lambda Dockerfile に Tailwind CLI 実行ステップを追加して、本番ビルドでも CSS が正しく生成されるようにする。

## 変更点サマリ

| 対象 | 変更内容 |
|------|---------|
| 14ファイルの react-bootstrap import | native HTML + Tailwind CSS クラスに置き換え |
| `apollo_provider.tsx` | `import 'bootstrap/dist/css/bootstrap.min.css'` を削除 |
| `package.json` | `bootstrap`, `react-bootstrap`, `@types/react-bootstrap` を削除 |
| `button.tsx` | ghost variant から `bg-transparent border-0` を削除 |
| `buildOnLambda/Dockerfile` | builder ステージに `RUN node_modules/.bin/tailwindcss ...` を追加 |

## 置き換え方針

### Form コンポーネント

| react-bootstrap | 置き換え先 |
|----------------|-----------|
| `<Form>` | `<form>` |
| `<Form.Group>` | `<div>` |
| `<Form.Label>` | `<label className="text-sm font-medium">` |
| `<Form.Control>` (input) | `<input className="border rounded px-3 py-2 w-full ...">` または shadcn Input |
| `<Form.Control>` (select) | `<select className="...">` または shadcn Select |
| `<Form.Check>` | `<input type="checkbox" className="...">` |
| `<Form.Text>` | `<p className="text-sm text-muted-foreground">` |

### Button コンポーネント

| react-bootstrap | 置き換え先 |
|----------------|-----------|
| `<Button variant="primary">` | `<Button>` (shadcn, default variant) |
| `<Button variant="secondary">` | `<Button variant="secondary">` (shadcn) |
| `<Button variant="link">` | `<Button variant="link">` (shadcn) |

### レイアウト (Col/Row)

| react-bootstrap | 置き換え先 |
|----------------|-----------|
| `<Row>` | `<div className="flex gap-4">` または `<div className="grid ...">` |
| `<Col>` | `<div className="flex-1">` または `<div>` |

### shadcn Input コンポーネントの追加

フォーム入力は shadcn/ui の `Input` コンポーネントを新規作成して使用する。
（既存の `button.tsx`, `dropdown-menu.tsx` と同じスタイルで統一）

## 設計選択と理由

- **shadcn Input を新規作成する**: Button と同様に shadcn/ui スタイルのコンポーネントを揃えることで、Tailwind v4 対応の一貫したデザインシステムを構築できる
- **`FormFieldWrapperWithLabel` を先に置き換える**: 多くのフォームコンポーネントから使われている共通コンポーネントのため、ここを先に置き換えると変更が集約できる
- **Lambda Dockerfile に `tailwindcss` コマンドを追加**: `entrypoint.sh` は Lambda Dockerfile から呼ばれないため、Dockerfile に直接追加が必要

## 代替案

- **Bootstrap を残したまま Tailwind workaround を続ける**: 今後も干渉が発生するたびに `!important` や override を書き続ける必要があり、コードの複雑性が増す。棄却。
- **Bootstrap CSS のみ削除して react-bootstrap は残す**: react-bootstrap コンポーネントが無スタイルで表示されるため、見た目が崩れる。中途半端な状態になる。棄却。
- **shadcn/ui の Form コンポーネント（react-hook-form 連携）に置き換える**: 本格的だが、フォームのバリデーション実装も変更が必要になり scope が大きすぎる。今回は native HTML + Tailwind クラスの最小置き換えにとどめる。

## リスクと対策

| リスク | 対策 |
|--------|------|
| フォームの見た目が崩れる | 各フォームページを Playwright で目視確認しながら進める |
| Lambda ビルドが壊れる | `frontend_next_lambda` コンテナでローカルビルドを確認してから完了とする |
| `tailwind-output.css` が Lambda の COPY に含まれる/されない問題 | Dockerfile 内で明示的に生成するため、ローカルファイルへの依存をなくす |

## テスト方針

- 各フォームページを Playwright でスクリーンショット撮影して視覚的に確認
- `frontend_next_lambda` コンテナのビルドと起動確認
- ESLint (`docker compose exec frontend yarn lint`) で全体チェック
