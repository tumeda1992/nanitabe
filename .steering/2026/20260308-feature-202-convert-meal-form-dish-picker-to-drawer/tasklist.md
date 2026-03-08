# タスクリスト: 食事フォームの料理選択ドロワー化

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### タスクスキップが許可される唯一のケース
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

---

## フェーズ1: ExistingDishesForRegisteringWithMeal をドロワー化

### DoD（完了条件）
- 「料理を選択」ボタンがフォームに表示される
- タップするとドロワーが開き、DishSearchPanel（picker モード）が表示される
- ドロワーフッターの「完了」で料理が選択状態になり、ドロワーが閉じる
- 「新規料理を登録」ボタンがドロワーフッターにあり、押すとドロワーが閉じて新規登録モードに切り替わる
- テスト全グリーン・ESLint エラーゼロ

### タスク

- [x] `ExistingDishesForRegisteringWithMeal.tsx` を修正
    - [x] state 追加: `drawerOpen` (boolean)
    - [x] state 追加: `pendingDishId` (ドロワー内の暫定選択、「完了」でコミット)
    - [x] トリガーボタンを実装
        - 未選択時: 「料理を選択」
        - 選択済み時: 選択した料理名を表示（別途 dish 名を取得するか、選択時に name も state に保持する）
    - [x] `Drawer` / `DrawerContent` / `DrawerHeader` / `DrawerFooter` で包む（`components/ui/drawer.tsx` を使用）
    - [x] `DrawerContent className="max-h-[85vh]"` で高さ制限
    - [x] ドロワー内: `DishSearchPanel mode="picker"` を配置
        - `selectedDishId={pendingDishId}` を渡す
        - `onSelect` で `setPendingDishId(dish.id)` + `setPendingDishName(dish.name)` を呼ぶ
    - [x] フッター実装
        - 「完了」ボタン: `setSelectedDishId(pendingDishId)` → `setValue('dishId', pendingDishId)` → `setDrawerOpen(false)`
        - 「新規料理を登録」ボタン（`displayNewDishIconForSelect` が true のとき表示）: `setDrawerOpen(false)` → `onNewDishIconForSelectClick('')` を呼ぶ
    - [x] ドロワーを開くたびに `pendingDishId` を現在の `selectedDishId` で初期化
    - [x] 既存の `useEffect(() => setValue('dishId', selectedDishId))` は削除し、「完了」時のみ `setValue` を呼ぶよう変更（初期値セット用useEffectは残す）

- [x] テスト修正・追加
    - [x] 既存テスト（`AddMeal.spec.tsx`・`EditMeal.spec.tsx`）が壊れていないか確認
        - ドロワートリガー（`data-testid="dishPickerDrawerTrigger"` 等）のクリックを追加
        - 料理選択後「完了」ボタンクリックを追加
    - [x] `docker compose exec frontend yarn test`（全テストグリーン・90件パス）

- [x] ESLint 実行
    - [x] `docker compose exec frontend yarn lint`（エラーゼロ）

---

## フェーズ2: 品質チェック・スクリーンショット確認

### DoD（完了条件）
- 全テストがグリーン
- ESLint エラーがゼロ
- ドロワーのスクリーンショット目視確認済み

### タスク

- [x] 全テスト実行
    - [x] `docker compose exec frontend yarn test`
    - [x] 全テストグリーン確認（90件パス）

- [x] ESLint 実行（プロジェクト全体）
    - [x] `docker compose exec frontend yarn lint`
    - [x] エラーゼロ確認

- [x] Playwright でスクリーンショット確認
    - [x] ログイン（setsumaru1992@gmail.com / cWWayJpKNA7g39e7cyCN）
    - [x] 食事登録フォームを開く（/meal/new）
    - [x] 「料理を選択」ボタンが表示されることを確認（フォームに「料理を選択」ボタン表示確認済み）
    - [x] ボタンをクリックしてドロワーが開くことを確認（料理フィルタ・検索・完了ボタン・新規料理登録ボタン表示確認済み）
    - [x] スクリーンショットを撮って目視確認（検索パネル・フッターボタンのレイアウト良好）

---

## 実装後の振り返り

### 実装完了日
2026-03-08

### 計画と実績の差分

**計画と異なった点**:
- vaulのDrawerがJSDOMと互換性がないため、`__mocks__/vaul.tsx` でvaulをモックして対応した
- `useEffect(() => setValue('dishId', selectedDishId))` は完全削除ではなく、初期値セット（`dishIdRegisteredWithMeal` がある場合のみ）のために維持した。これはEditMealで既存料理IDが渡される場合の初期フォーム値セットに必要。

**新たに必要になったタスク**:
- `frontend/__mocks__/vaul.tsx` の作成（vaulがJSDOMで動作しないため）
- `spec/jest.setup.ts` にPointer Capture APIのモックとBODYのpointer-events後処理を追加

**技術的理由でスキップしたタスク**（該当する場合のみ）:
- なし
