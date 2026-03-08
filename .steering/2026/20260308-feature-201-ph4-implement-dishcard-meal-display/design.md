# 要件ドキュメント

## はじめに

`.steering/2026/20260307-feature-201-apply-v0-calendar-design/tasklist.md` フェーズ4「料理カードの刷新（DishCard）」を実装する。

現在の `MealIcon`（SCSS+FloatModal のアイコン形式）を、v0 デザインに準拠した `DishCard`（左カラーバー + インラインアクションパネル）に置き換える。

## 元の依頼内容

.steering/2026/20260307-feature-201-apply-v0-calendar-design/tasklist.md のフェーズ4を実装したい

## 要件

### 要件1: DishCard の表示

**ユーザーストーリー:** ユーザーがカレンダーで料理を見たとき、左カラーバー付きカードで料理情報（名前・評価・レシピ元・コメント）が見やすく表示される

#### 受け入れ基準

1. WHEN 昼食の料理カードを表示する THEN 左端にオレンジのカラーバーとオレンジ背景が表示される（`bg-lunch`）
2. WHEN 夕食の料理カードを表示する THEN 左端に青のカラーバーと青背景が表示される（`bg-dinner`）
3. WHEN 朝食の料理カードを表示する THEN デフォルト背景で表示される（v0 に朝食定義なし）
4. WHEN 料理カードを表示する THEN 1行目にカテゴリアイコン・料理名・昼夜ラベル・クイックアイコン（UtensilsCrossed / Star / MoreHorizontal）が常時表示される
5. WHEN `dish.evaluationScore` が存在する THEN 2行目に評価（★N）が表示される
6. WHEN `dishSourceRelation` が存在する THEN 2行目にレシピ元が表示される
7. WHEN `dish.comment` が存在する THEN コメントが表示される
8. WHEN `meal.comment` が存在する THEN 食事コメントが表示される

### 要件2: インラインアクションパネルの展開と操作

**ユーザーストーリー:** ユーザーが MoreHorizontal をタップしたとき、カード下部にアクションパネルがインライン展開し、既存の全操作が実行できる

#### 受け入れ基準

1. WHEN MoreHorizontal ボタンをタップする THEN カード下部に `grid-cols-4` のアクションパネルがインライン展開する
2. WHEN もう一度 MoreHorizontal をタップする THEN アクションパネルが閉じる
3. WHEN 「食事編集」（UtensilsCrossed）を選ぶ THEN 既存の EditMeal フルスクリーンモーダルが開く
4. WHEN 「評価」（Star）を選ぶ THEN 既存の EvaluateDish フルスクリーンモーダルが開く
5. WHEN 「料理編集」（Pencil）を選ぶ THEN 既存の EditDish フルスクリーンモーダルが開く
6. WHEN 「名前コピー」（Type）を選ぶ THEN 料理名がクリップボードにコピーされる
7. WHEN 「他の日へ移動」（CalendarArrowUp）を選ぶ THEN 既存の MoveMeal モードが起動する
8. WHEN 「日付交換」（ArrowLeftRight）を選ぶ THEN 既存の SwapMeals モードが起動する
9. WHEN 「食事複製」（CopyPlus）を表示する THEN disabled 状態で表示される（未実装）
10. WHEN 「削除」（Trash2）を選ぶ THEN 確認ダイアログ後に既存の removeMeal mutation が呼ばれる

### 要件3: DateCard との接続・既存機能維持

**ユーザーストーリー:** DishCard 導入後も既存テストが全て動作する

#### 受け入れ基準

1. WHEN DateCard の料理一覧を表示する THEN MealIcon の代わりに DishCard が表示される
2. WHEN 既存テストを実行する THEN 全てグリーン
3. WHEN ESLint を実行する THEN エラーがゼロ

---

# 設計ドキュメント

## TL;DR

v0 の `dish-card.tsx` をほぼそのまま移植し、localStorage（v0）を既存 GraphQL・`useFullScreenModal` に置き換える。
アクションパネルは **カード下部へのインライン展開**（`actionsOpen` state で toggle、`grid-cols-4` グリッド）。Drawer は使わない。
MealIcon を old/ に退避し、DateCard の `CalenderMealIcon` を `DishCard` に差し替える。

## 変更点サマリ

| 対象 | 現状 | 変更後 |
|------|------|--------|
| `MealIcon/index.tsx` | SCSS+FloatModal のアイコン形式 | `MealIcon/old/` に退避 |
| `MealIcon/Menu.tsx` | FloatModal でメニュー表示 | `MealIcon/old/` に退避 |
| `MealIcon/Menu.spec.tsx` | Menu のテスト | `MealIcon/old/` に退避・パス修正で継続 |
| 新 `DishCard/index.tsx` | 存在しない | v0 dish-card.tsx を GraphQL ベースで実装 |
| `DateCard.tsx` | `CalenderMealIcon` を使用 | `DishCard` に差し替え、SwapMeals props を追加 |

## 設計選択と理由

### アクションパネルはインライン展開（v0 準拠）

v0 の `dish-card.tsx` を確認したところ、アクションパネルはボトムシート（Drawer）ではなく、**カード下部へのインライン展開**だった。
- `actionsOpen` state で toggle
- `border-t border-border/30 bg-background/60` のエリアがカード内に展開
- `grid grid-cols-4` のグリッドでアイコン+ラベルの `ActionBtn` が並ぶ
- クイックアイコン（UtensilsCrossed / Star / MoreHorizontal）は1行目に常時表示

### カラーバーの色

`globals.css` に既に定義済みの CSS 変数を使う（フェーズ1で追加済み）:
- 昼食: `bg-lunch-bg`（背景）・`bg-lunch`（左カラーバー）・`text-lunch-foreground`
- 夕食: `bg-dinner-bg`（背景）・`bg-dinner`（左カラーバー）・`text-dinner-foreground`
- 朝食: v0 に定義なし。デフォルト背景で表示する

### 既存操作フローの流用

v0 は localStorage ベースだが、本実装では既存の hooks を使う:
- 削除: `useMeal().removeMeal`
- 食事編集: `useFullScreenModal` + `<EditMeal>`
- 評価: `useFullScreenModal` + `<EvaluateDish>`
- 料理編集: `useFullScreenModal` + `<EditDish>`
- 他の日へ移動: `calenderModeChangers.startMovingDishMode(meal)`
- 日付交換: `startSwappingMealsMode(date)`（DateCard から追加 props として渡す）
- 名前コピー: `navigator.clipboard.writeText(dish.name)`

### SwapMeals props の追加

既存 MealIcon には「日付交換」がなかった。DishCard では `startSwappingMealsMode` を DateCard から props として受け取り追加する。
DateCard の Props 型に `startSwappingMealsMode` を追加し、呼び出し元（Calender/index.tsx）も修正する。

### DishCard のディレクトリ構成

```
calenderComponents/
├── DishCard/
│   ├── index.tsx       ← メインカードコンポーネント
│   └── index.spec.tsx  ← テスト
├── MealIcon/
│   ├── old/            ← 既存 MealIcon を退避
│   │   ├── index.tsx
│   │   ├── Menu.tsx
│   │   └── Menu.spec.tsx
│   └── AddMealIcon.tsx ← 変更なし（+ ボタン用）
```

## 代替案と棄却理由

### 代替案1: ボトムシート（Drawer）をアクションパネルに使う
v0 の実際の実装はインライン展開だった。Drawer に変更すると v0 デザインから乖離するため採用しない。

### 代替案2: FloatModal（既存パターン）をそのまま使う
既存 MealIcon の FloatModal は v0 デザインと異なるため採用しない。

## リスクと対策

| リスク | 対策 |
|--------|------|
| MealIcon/old/ 退避後のインポートパス修正漏れ | 退避直後にテスト・ESLint で検出 |
| SwapMeals props 追加による型変更 | DateCard.tsx・Calender/index.tsx を合わせて修正 |
| フルスクリーンモーダルとアクションパネルの重なり | アクション選択時に `setActionsOpen(false)` してからモーダルを開く（v0 と同様） |
| `bg-lunch` 等のクラスが tailwind-output.css に未収録 | docker compose restart frontend で watcher を再ビルド |

## テスト方針

- `MealIcon/old/` 退避後: `yarn test` で全テストグリーン確認
- `DishCard/index.spec.tsx` を追加:
  - 表示テスト: 昼食カラーバー・夕食カラーバー・料理名・評価・レシピ元の表示
  - 機能テスト: MoreHorizontal タップでアクションパネルが開閉すること
  - 機能テスト: 削除ボタンで `removeMeal` mutation が呼ばれること
  - 機能テスト: 「他の日へ移動」で `startMovingDishMode` が呼ばれること
  - 機能テスト: 「日付交換」で `startSwappingMealsMode` が呼ばれること
