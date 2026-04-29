# タスクリスト: フェーズ4 料理カードの刷新（DishCard）

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### タスクスキップが許可される唯一のケース
以下の技術的理由に該当する場合のみスキップ可能:
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

---

## フェーズ1: 既存 MealIcon を old/ に退避

### DoD（完了条件）
- `MealIcon/old/` に index.tsx・Menu.tsx・Menu.spec.tsx が移動している
- DateCard.tsx のインポートパスが `old/` を指して動作している
- 全テストがグリーン・ESLint エラーがゼロ

### タスク

- [x] `MealIcon/old/` ディレクトリを作成し、既存ファイルを移動
    - [x] `MealIcon/index.tsx` → `MealIcon/old/index.tsx`
    - [x] `MealIcon/Menu.tsx` → `MealIcon/old/Menu.tsx`
    - [x] `MealIcon/Menu.spec.tsx` → `MealIcon/old/Menu.spec.tsx`
    - [x] 関連 SCSS モジュール（`index.module.scss`・`Menu.module.scss`）も `old/` に移動

- [x] インポートパスを修正
    - [x] `DateCard.tsx`: `CalenderMealIcon` のインポートを `./MealIcon/old` に変更
    - [x] grep で `MealIcon/index` または `from.*MealIcon'` を参照している箇所を全件確認し修正
    - [x] `Menu.spec.tsx` 内の `Menu` インポートパスを `./Menu`（old/ 内の相対パス）に確認

- [x] テスト・ESLint 実行
    - [x] `docker compose exec frontend yarn test`（全テストグリーン）
    - [x] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ2: DishCard・CategoryIcon コンポーネント実装

### DoD（完了条件）
- DishCard が単体でレンダリングでき、表示・機能テストが全てグリーン
- MoreHorizontal でアクションパネルが開閉し、全アクションが呼び出せる

### タスク

- [x] `DishCard/` ディレクトリを作成（`calenderComponents/DishCard/`）

- [x] `DishCard/CategoryIcon.tsx` を作成
    - [x] `dish.mealPosition` と `dish.dishSourceRelation.type` を受け取り、対応するアイコンを返す
    - [x] 既存 `MealIcon/index.tsx` の `mealPositionMark` ロジックを踏襲する
    - [x] アイコン実装は Font Awesome CSS クラス・または v0 の SVG パス（`category-icon.tsx`）どちらでも可
    - [x] マッピング・カラー:
        - STAPLE_FOOD → bowl-rice・`text-amber-600`
        - MAIN_DISH → utensils・`text-rose-600`
        - SIDE_DISH → carrot・`text-emerald-600`
        - SOUP → bowl-hot・`text-sky-600`
        - DESSERT → cake・`text-pink-500`
        - RESTAURANT（dishSourceRelation.type）→ store・`text-violet-600`
        - それ以外 → null（何も表示しない）

- [x] `DishCard/index.tsx` を作成（v0 の `dish-card.tsx` をベースに GraphQL 対応で実装）
    - [x] Props 定義
    - [x] `globals.css` に朝食の CSS 変数を追加（lunch/dinner と同じパターンで）
- [x] mealConfig（lunch/dinner/breakfast）
    - [x] カードラッパー: `rounded-lg overflow-hidden border` + `cfg.bg`
    - [x] 左カラーバー: `w-1 shrink-0` + `cfg.bar`
    - [x] 1行目（常時表示）
    - [x] 2行目（評価・レシピ元）
    - [x] コメント行
    - [x] インラインアクションパネル（`actionsOpen` が true のとき展開）
    - [x] 各アクション選択後に `setActionsOpen(false)` してからモーダル等を起動
    - [x] `QuickBtn`・`ActionBtn` をファイル内に定義（v0 準拠）

- [x] `DishCard/index.spec.tsx` を作成
    - [x] 表示テスト
        - [x] 昼食の場合 `bg-lunch-bg` クラスが適用されること
        - [x] 夕食の場合 `bg-dinner-bg` クラスが適用されること
        - [x] 料理名が表示されること
        - [x] `dish.evaluationScore` がある場合に評価が表示されること
        - [x] `dish.dishSourceRelation.sourceName` がある場合にレシピ元が表示されること
        - [x] `canAnythingExceptDisplayDishName=false` のとき MoreHorizontal が表示されないこと
    - [x] 機能テスト
        - [x] MoreHorizontal タップでアクションパネルが表示されること
        - [x] もう一度タップでアクションパネルが閉じること
        - [x] 削除ボタンタップで `removeMeal` mutation が呼ばれること
        - [x] 「他の日へ移動」タップで `startMovingDishMode` が呼ばれること
        - [x] 「日付交換」タップで `startSwappingMealsMode` が呼ばれること

- [x] テスト・ESLint 実行
    - [x] `docker compose exec frontend yarn test`（全テストグリーン）
    - [x] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ3: DateCard に DishCard を接続

### DoD（完了条件）
- カレンダー上の料理が DishCard 形式で表示される
- 既存テストが全てグリーン・ESLint エラーがゼロ

### タスク

- [x] `DateCard.tsx` を修正
    - [x] Props に `startSwappingMealsMode: (date: Date) => void` を追加（既に実装済みだった）
    - [x] `CalenderMealIcon`（old/）を `DishCard` に差し替え
    - [x] DishCard の Props を正しく渡す
    - [x] `CalenderMealIcon` の import を削除

- [x] `Calender/index.tsx` を修正
    - [x] `DateCard` に `startSwappingMealsMode` を渡す（既に実装済みだった）

- [x] テスト・ESLint 実行
    - [x] `docker compose exec frontend yarn test`（全テストグリーン）
    - [x] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ4: 品質チェック

### DoD（完了条件）
- 全テストがグリーン
- ESLint エラーがゼロ（プロジェクト全体）

### タスク

- [x] 全テスト実行
    - [x] `docker compose exec frontend yarn test`
    - [x] 全テストグリーン確認（83 tests passed）

- [x] ESLint 実行（プロジェクト全体）
    - [x] `docker compose exec frontend yarn lint`
    - [x] エラーゼロ確認

---

## 実装後の振り返り

### 実装完了日
2026-03-08

### 計画と実績の差分

**計画と異なった点**:
-

**新たに必要になったタスク**:
-

**技術的理由でスキップしたタスク**（該当する場合のみ）:
-
