# 要件ドキュメント

## はじめに

v0 デザインの `DishSearchCard`・`DishSearchPanel`・`DishesPage` を本番フロントエンドに実装する。
骨子コンポーネント（`DishSearchCard`・`DishSearchPanel`）は `/dishes` ページだけでなく、
`ExistingDishesForRegisteringWithMeal` と `ChooseDish` でも使い回す設計にする。

## 元の依頼内容

料理検索のコンポーネントとページを作りたい。

デザインはこれを参考にして。
.steering/2026/20260307-feature-201-apply-v0-calendar-design/nanitabe_v0_design

カレンダー画面のデザイン反映はこちらで行った。
.steering/2026/20260307-feature-201-apply-v0-calendar-design

まずやりたいことは、料理検索ページを作ること（/dishes）。
ただ、このページだけで使うコンポーネントではなく、骨子のコンポーネントは以下でも使い回す前提でいてほしい
（元のデザインもその前提になっているはず）
frontend/src/components/meal/MealForm/MealForm/ExistingDishesForRegisteringWithMeal.tsx
frontend/src/components/calendar/calendarComponents/operationComponents/AssignDish/ChooseDish.tsx

## 要件

### 要件1: 骨子コンポーネント実装（DishSearchCard / DishSearchPanel）

**ユーザーストーリー:** 料理検索に関わるあらゆる画面で一貫したデザインの料理カードと検索UIが使われる

#### 受け入れ基準
1. WHEN 料理一覧を表示したとき THEN 料理名・カテゴリアイコン・レシピ元・評価が表示される
2. WHEN 「page」モードのとき THEN カード右端に `...` アクションメニュー（編集/削除）が表示される
3. WHEN 「picker」モードのとき THEN カード右端にチェックマーク（選択/未選択）が表示される
4. WHEN キーワードで検索したとき THEN 結果がリアルタイムでフィルタされる
5. WHEN 料理の位置（mealPosition）でフィルタしたとき THEN 対象料理のみ表示される
6. WHEN 関連食事でフィルタしたとき THEN 対象料理のみ表示される

### 要件2: /dishes ページ実装

**ユーザーストーリー:** ユーザーが `/dishes` にアクセスしたとき、登録済みの全料理を検索・管理できる

#### 受け入れ基準
1. WHEN `/dishes` にアクセスしたとき THEN 料理検索ページが表示される
2. WHEN 料理カードの `...` をタップしたとき THEN 編集・削除ができる
3. WHEN 複数料理を選択したとき THEN 一括削除ボタンが表示される
4. WHEN 新規ボタンを押したとき THEN 既存の料理登録フォーム（/dishes/new）に遷移する

### 要件3: 既存コンポーネントへの組み込み

**ユーザーストーリー:** 食事登録フォームと AssignDish フローで新しい検索UIが使われる

#### 受け入れ基準
1. WHEN 食事登録フォームで料理を選択するとき THEN DishSearchPanel（mode="library"相当）が表示される
2. WHEN AssignDish フローで料理を選択するとき THEN DishSearchPanel（mode="picker"相当）が表示される

---

## 非目標

- 調理回数 (`cookCount`)・最終調理日 (`lastDate`) の実装（バックエンドに未実装、null表示）
- タグ一括付与機能（UI表示は将来実装、今回はdisabledまたは非表示）
- プレースホルダー機能
- `/dishes/new` `/dishes/[id]/edit` の変更（既存のまま）

---

# 設計ドキュメント

## TL;DR

v0 の `DishSearchCard(A)` → `DishSearchCardLibrary(B)` → `DishSearchCardPicker(C)` という
コンポジション構造をそのまま採用し、GraphQL データに差し替える。
`DishSearchPanel` を shared コンポーネントとして `components/dish/` 配下に置き、
`/dishes` ページ・`ExistingDishesForRegisteringWithMeal`・`ChooseDish` の3箇所で使う。

## 変更点サマリ

| 変更先 | 内容 |
|--------|------|
| `components/dish/DishSearchCard/` | 新規作成（A/B/C の3バリアント） |
| `components/dish/DishSearchPanel/` | 新規作成（検索・フィルタ・リスト） |
| `app/dishes/page.tsx` | 新規作成（ページコンポーネント） |
| `ExistingDishesForRegisteringWithMeal.tsx` | DishSearchPanel mode="library" に差し替え |
| `ChooseDish.tsx` | DishSearchPanel mode="picker" に差し替え |
| `components/dish/ExistingDishIcon/` | 既存のまま（削除しない） |

## コンポーネント設計

### DishSearchCard の3バリアント（v0踏襲）

```
DishSearchCard (A) ← ベース表示のみ。trailing スロット注入で拡張
  ↑ 使用
DishSearchCardLibrary (B) ← page/library 用。`...` アクションメニュー + チェックボックス
DishSearchCardPicker  (C) ← picker 用。チェックマーク内包
```

### DishSearchPanel の mode

| mode | 使用箇所 | カード種別 |
|------|----------|-----------|
| `page` | /dishes ページ | B（アクションメニュー + チェックボックス） |
| `library` | ExistingDishesForRegisteringWithMeal | B（アクションメニューのみ、チェックボックスなし） |
| `picker` | ChooseDish | C（チェックマーク） |

### データ構造の差異と対処

v0 の `Dish` 型は localStorage ベースのモック。本番では `existingDishesForRegisteringWithMeal` GraphQL クエリを使う。

| v0 フィールド | 本番対応 |
|--------------|----------|
| `name` | `dish.name` ✓ |
| `category` | `dish.mealPosition`（数値）→ CategoryIcon に渡す ✓ |
| `rating` | `dish.evaluationScore` ✓ |
| `sourceId` → `DishSource` | `dish.dishSourceName`（文字列）を使用 |
| `lastDate` | バックエンド未実装 → null 表示 |
| `cookCount` | バックエンド未実装 → null 表示（または非表示） |
| `tags` | クエリに含まれていない → 非表示 |
| `memo` | `dish.comment` ✓ |

**CategoryIcon の再利用**: `DishCard/CategoryIcon.tsx` がすでに `mealPosition` → アイコンのマッピングを実装済み。
`DishSearchCard` でもこれを使い回す。

### ディレクトリ構成

```
frontend/src/components/dish/
  DishSearchCard/
    index.tsx              ← DishSearchCard (A) ベースカード
    Library.tsx            ← DishSearchCardLibrary (B)
    Picker.tsx             ← DishSearchCardPicker (C)
    index.spec.tsx         ← 表示テスト
  DishSearchPanel/
    index.tsx              ← DishSearchPanel（mode: "page" | "library" | "picker"）
    index.spec.tsx         ← フィルタ・検索テスト

frontend/src/app/dishes/
  page.tsx                 ← /dishes ページ（新規）
  page.client.tsx          ← クライアントコンポーネント（新規）
```

## 設計選択と理由

### components/dish/ 配下に置く
v0 では `components/calendar/` に置かれているが、本番では dish ドメインに属するコンポーネントなので
`components/dish/` に置く。カレンダー依存を外すことで `ExistingDishesForRegisteringWithMeal` からも自然に使える。

### ExistingDishIcon は残す
`ExistingDishIconForSelect` は既存のフォーム UI で使われており、
今回の差し替えは段階的（DishSearchPanel に移行後も参照が残る可能性がある）。
削除は別タスクとする。

### /dishes ページでの削除は既存 removeDish mutation を使う
v0 は localStorage dispatch だが、本番では `useDish()` の `removeDish` を使う。

### タグ一括付与はスコープ外
バックエンド未実装のため、一括タグボタンは非表示にするか `disabled` にする。

## 代替案と棄却理由

### 代替案1: ExistingDishIcon を DishSearchCard に置き換えない
既存 UI との分断が残り、デザイン統一が達成されない。今回のスコープに含めて棄却。

### 代替案2: DishSearchPanel を `components/calendar/` に置く
v0 と同じ場所だが、MealForm や dishes ページからの参照が不自然になるため棄却。

## リスクと対策

| リスク | 対策 |
|--------|------|
| GraphQL クエリのフィールド不足 | `existingDishesForRegisteringWithMeal` クエリに必要フィールドを追加（dishSourceName, evaluationScore はすでに含まれている） |
| ExistingDishesForRegisteringWithMeal の差し替えで既存テストが壊れる | 差し替え前後でテスト実行を必須とする |
| ChooseDish の差し替えで既存フローが壊れる | assignDish.spec.tsx で動作確認する |

## テスト方針

- `DishSearchCard/index.spec.tsx`: 表示テスト（料理名・カテゴリアイコン・評価・レシピ元の表示確認）
- `DishSearchPanel/index.spec.tsx`: フィルタ・検索テスト
- 各フェーズ完了後: `docker compose exec frontend yarn test` + `yarn lint`
- /dishes ページ完了後: Playwright でスクリーンショット確認
