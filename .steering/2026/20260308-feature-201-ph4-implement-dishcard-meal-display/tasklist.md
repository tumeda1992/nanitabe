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

- [ ] `MealIcon/old/` ディレクトリを作成し、既存ファイルを移動
    - [ ] `MealIcon/index.tsx` → `MealIcon/old/index.tsx`
    - [ ] `MealIcon/Menu.tsx` → `MealIcon/old/Menu.tsx`
    - [ ] `MealIcon/Menu.spec.tsx` → `MealIcon/old/Menu.spec.tsx`
    - [ ] 関連 SCSS モジュール（`index.module.scss`・`Menu.module.scss`）も `old/` に移動

- [ ] インポートパスを修正
    - [ ] `DateCard.tsx`: `CalenderMealIcon` のインポートを `./MealIcon/old` に変更
    - [ ] grep で `MealIcon/index` または `from.*MealIcon'` を参照している箇所を全件確認し修正
    - [ ] `Menu.spec.tsx` 内の `Menu` インポートパスを `./Menu`（old/ 内の相対パス）に確認

- [ ] テスト・ESLint 実行
    - [ ] `docker compose exec frontend yarn test`（全テストグリーン）
    - [ ] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ2: DishCard・CategoryIcon コンポーネント実装

### DoD（完了条件）
- DishCard が単体でレンダリングでき、表示・機能テストが全てグリーン
- MoreHorizontal でアクションパネルが開閉し、全アクションが呼び出せる

### タスク

- [ ] `DishCard/` ディレクトリを作成（`calenderComponents/DishCard/`）

- [ ] `DishCard/CategoryIcon.tsx` を作成
    - [ ] `dish.mealPosition` と `dish.dishSourceRelation.type` を受け取り、対応するアイコンを返す
    - [ ] 既存 `MealIcon/index.tsx` の `mealPositionMark` ロジックを踏襲する
    - [ ] アイコン実装は Font Awesome CSS クラス・または v0 の SVG パス（`category-icon.tsx`）どちらでも可
    - [ ] マッピング・カラー:
        - STAPLE_FOOD → bowl-rice・`text-amber-600`
        - MAIN_DISH → utensils・`text-rose-600`
        - SIDE_DISH → carrot・`text-emerald-600`
        - SOUP → bowl-hot・`text-sky-600`
        - DESSERT → cake・`text-pink-500`
        - RESTAURANT（dishSourceRelation.type）→ store・`text-violet-600`
        - それ以外 → null（何も表示しない）

- [ ] `DishCard/index.tsx` を作成（v0 の `dish-card.tsx` をベースに GraphQL 対応で実装）
    - [ ] Props 定義
        ```
        type DishCardProps = {
          meal: MealForCalender;
          onChanged: () => Promise<void>;
          canAnythingExceptDisplayDishName: boolean;
          calenderModeChangers: any;
          startSwappingMealsMode: (date: Date) => void;
        };
        ```
    - [ ] `globals.css` に朝食の CSS 変数を追加（lunch/dinner と同じパターンで）
        - 既存 SCSS の `$breakfast-blue: #00D4F0` を参考に:
          ```css
          --breakfast: 189 100% 47%;          /* #00D4F0 相当 */
          --breakfast-bg: 189 100% 97%;
          --breakfast-foreground: 189 100% 25%;
          --color-breakfast: hsl(var(--breakfast));
          --color-breakfast-bg: hsl(var(--breakfast-bg));
          --color-breakfast-foreground: hsl(var(--breakfast-foreground));
          ```
- [ ] mealConfig（lunch/dinner/breakfast）
        - LUNCH: `{ bg: 'bg-lunch-bg', bar: 'bg-lunch', text: 'text-lunch-foreground', label: '昼' }`
        - DINNER: `{ bg: 'bg-dinner-bg', bar: 'bg-dinner', text: 'text-dinner-foreground', label: '夜' }`
        - BREAKFAST: `{ bg: 'bg-breakfast-bg', bar: 'bg-breakfast', text: 'text-breakfast-foreground', label: '朝' }`
    - [ ] カードラッパー: `rounded-lg overflow-hidden border` + `cfg.bg`
    - [ ] 左カラーバー: `w-1 shrink-0` + `cfg.bar`
    - [ ] 1行目（常時表示）:
        - [ ] `CategoryIcon`（`dish.mealPosition` / `dishSourceRelation.type`）
        - [ ] 料理名（`font-medium text-sm truncate`）
        - [ ] 昼夜ラベル（`cfg.label`、`cfg.text`）
        - [ ] QuickBtn × 3（UtensilsCrossed / Star / MoreHorizontal）
            - MoreHorizontal: `setActionsOpen(v => !v)` で toggle
    - [ ] 2行目（評価・レシピ元）:
        - [ ] `dish.evaluationScore` があれば `★N`（amber）
        - [ ] `dish.dishSourceRelation.sourceName` があればレシピ元テキスト + ページ番号
    - [ ] コメント行:
        - [ ] `dish.comment` があれば表示
        - [ ] `meal.comment` があれば italic で表示
    - [ ] インラインアクションパネル（`actionsOpen` が true のとき展開）:
        - [ ] `border-t border-border/30 bg-background/60 px-2 py-1.5`
        - [ ] `grid grid-cols-4 gap-0.5` のグリッド
        - [ ] ActionBtn × 9:
            - 食事編集（UtensilsCrossed）→ `useFullScreenModal` + `<EditMeal>` を開く（`canAnythingExceptDisplayDishName` が true のとき有効）
            - 評価（Star）→ `useFullScreenModal` + `<EvaluateDish>` を開く
            - 料理編集（Pencil）→ `useFullScreenModal` + `<EditDish>` を開く
            - 名前コピー（Type）→ `navigator.clipboard.writeText(dish.name)`
            - 他の日へ移動（CalendarArrowUp）→ `calenderModeChangers.startMovingDishMode(meal)`
            - 日付交換（ArrowLeftRight）→ `startSwappingMealsMode(meal.date)`
            - 食事複製（CopyPlus）→ disabled
            - 削除（Trash2）→ `window.confirm` 後 `useMeal().removeMeal`（danger スタイル）
    - [ ] 各アクション選択後に `setActionsOpen(false)` してからモーダル等を起動
    - [ ] `QuickBtn`・`ActionBtn` をファイル内に定義（v0 準拠）

- [ ] `DishCard/index.spec.tsx` を作成
    - [ ] 表示テスト
        - [ ] 昼食の場合 `bg-lunch-bg` クラスが適用されること
        - [ ] 夕食の場合 `bg-dinner-bg` クラスが適用されること
        - [ ] 料理名が表示されること
        - [ ] `dish.evaluationScore` がある場合に評価が表示されること
        - [ ] `dish.dishSourceRelation.sourceName` がある場合にレシピ元が表示されること
        - [ ] `canAnythingExceptDisplayDishName=false` のとき MoreHorizontal が表示されないこと
    - [ ] 機能テスト
        - [ ] MoreHorizontal タップでアクションパネルが表示されること
        - [ ] もう一度タップでアクションパネルが閉じること
        - [ ] 削除ボタンタップで `removeMeal` mutation が呼ばれること
        - [ ] 「他の日へ移動」タップで `startMovingDishMode` が呼ばれること
        - [ ] 「日付交換」タップで `startSwappingMealsMode` が呼ばれること

- [ ] テスト・ESLint 実行
    - [ ] `docker compose exec frontend yarn test`（全テストグリーン）
    - [ ] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ3: DateCard に DishCard を接続

### DoD（完了条件）
- カレンダー上の料理が DishCard 形式で表示される
- 既存テストが全てグリーン・ESLint エラーがゼロ

### タスク

- [ ] `DateCard.tsx` を修正
    - [ ] Props に `startSwappingMealsMode: (date: Date) => void` を追加（DishCard に渡すため）
    - [ ] `CalenderMealIcon`（old/）を `DishCard` に差し替え
    - [ ] DishCard の Props を正しく渡す:
        ```
        <DishCard
          meal={meal}
          onChanged={onChanged}
          canAnythingExceptDisplayDishName={isDisplayCalenderMode}
          calenderModeChangers={calenderModeChangers}
          startSwappingMealsMode={startSwappingMealsMode}
        />
        ```
    - [ ] `CalenderMealIcon` の import を削除

- [ ] `Calender/index.tsx` を修正
    - [ ] `DateCard` に `startSwappingMealsMode` を渡す:
        `startSwappingMealsMode={useSwapMealsModeResult.startSwappingMealsMode}`

- [ ] テスト・ESLint 実行
    - [ ] `docker compose exec frontend yarn test`（全テストグリーン）
    - [ ] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ4: 品質チェック

### DoD（完了条件）
- 全テストがグリーン
- ESLint エラーがゼロ（プロジェクト全体）

### タスク

- [ ] 全テスト実行
    - [ ] `docker compose exec frontend yarn test`
    - [ ] 全テストグリーン確認

- [ ] ESLint 実行（プロジェクト全体）
    - [ ] `docker compose exec frontend yarn lint`
    - [ ] エラーがあれば `yarn lint --fix` で自動修正してから再確認
    - [ ] エラーゼロ確認

---

## 実装後の振り返り

### 実装完了日
{YYYY-MM-DD}

### 計画と実績の差分

**計画と異なった点**:
-

**新たに必要になったタスク**:
-

**技術的理由でスキップしたタスク**（該当する場合のみ）:
-
