# 要件ドキュメント

## はじめに

食事登録フォームの料理選択UIを、インライン表示からドロワーに変更する。
検索結果が多くても「登録」ボタンまでスクロールせずに済むよう、
ドロワー内に検索パネルを閉じ込め、フッターに「完了」ボタンを固定する。

## 元の依頼内容

mealFormについてはv0のデザインの通りドロワーにしたい。

というのも、この後、料理のヒット件数減らすつもりでいるんだけど、それでも多いから、
検索結果を最後までスクロールさせずに、ドロワーでもなんでも、検索結果の上に「登録」とかネクストアクションのボタンを置きたかったんだよね

## 要件

### 要件1: 料理選択をドロワー化

**ユーザーストーリー:** 食事登録フォームで料理を選択するとき、ドロワーを開いて料理を選び「完了」を押すだけで、スクロール操作なしに登録ボタンまで戻れる

#### 受け入れ基準
1. WHEN フォームを開いたとき THEN 「料理を選択」ボタン（または選択済み料理名）が表示される
2. WHEN 「料理を選択」ボタンを押したとき THEN ドロワーが開き DishSearchPanel（picker モード）が表示される
3. WHEN ドロワー内で料理を選択し「完了」を押したとき THEN ドロワーが閉じ、選択した料理がフォームに反映される
4. WHEN ドロワーのフッターが常時表示されること THEN スクロール量に関わらず「新規料理を登録」「完了」ボタンが見える
5. WHEN 「新規料理を登録」ボタンを押したとき THEN 既存の `onNewDishIconForSelectClick` コールバックが呼ばれる

---

## 非目標
- ChooseDish（AssignDish フロー）の変更（今回スコープ外）
- ドロワー内デザインの大幅変更（v0 の DishPickerDrawer 踏襲）

---

# 設計ドキュメント

## TL;DR

`ExistingDishesForRegisteringWithMeal` を「トリガーボタン + ドロワー」パターンに変更する。
既存の `Drawer` コンポーネント（`components/ui/drawer.tsx`）が使える。
ドロワー内は `DishSearchPanel mode="picker"`（チェックマーク付き）を使う。
`setValue('dishId', ...)` の呼び出し方は変わらない（ドロワーの「完了」で発火）。

## 変更点サマリ

| 変更前 | 変更後 |
|--------|--------|
| `ExistingDishesForRegisteringWithMeal` がインラインで `DishSearchPanel mode="library"` を表示 | トリガーボタン（選択済み料理名 or 「料理を選択」）を表示 → タップでドロワーが開く |
| 検索結果がフォームの一部として縦に伸び、スクロールが必要 | ドロワー内（`max-h-[85vh]`）に収まり、フッターの「完了」ボタンが常時表示 |
| DishSearchPanel mode="library" | DishSearchPanel mode="picker"（チェックマーク表示に変更） |

## コンポーネント設計

### ExistingDishesForRegisteringWithMeal の変更

```
// 変更前: インライン表示
<DishSearchPanel mode="library" ... />

// 変更後: トリガー + ドロワー
<button onClick={() => setDrawerOpen(true)}>
  {selectedDish?.name ?? "料理を選択"}
</button>

<Drawer open={drawerOpen} onOpenChange={setDrawerOpen}>
  <DrawerContent className="max-h-[85vh]">
    <DrawerHeader>料理を選択</DrawerHeader>
    <div className="flex-1 overflow-y-auto px-4 pb-4 min-h-0">
      <DishSearchPanel
        mode="picker"
        selectedDishId={selectedDishId}
        onSelect={(dish) => setSelectedDishId(dish.id)}
      />
    </div>
    <DrawerFooter className="flex-row gap-2">
      {displayNewDishIconForSelect && (
        <Button variant="outline" onClick={onNewDishIconForSelectClick}>
          新規料理を登録
        </Button>
      )}
      <Button onClick={handleDone}>完了</Button>
    </DrawerFooter>
  </DrawerContent>
</Drawer>
```

### 「完了」ボタンの挙動
- `setValue('dishId', selectedDishId)` を呼ぶ
- ドロワーを閉じる
- 既存の `useEffect` による `setValue` は削除し、「完了」時にのみ `setValue` を呼ぶよう変更

### DishSearchPanel の mode 変更
- `library` → `picker`（チェックマーク表示）
- `onSelect` の代わりに `onSelect` を渡して即選択（完了ボタン押下時にコミット）
- ドロワー内で暫定的な選択状態を管理し、「完了」で確定

## 設計選択と理由

### mode を picker に変更する理由
library モードは「アクションメニュー（編集/削除）付き」のカードで、選択の文脈に合わない。
picker モードはチェックマーク付きで「選んで完了」の UX に最適。

### useEffect での setValue を削除して「完了」でコミット
ドロワー内での選択は暫定状態とし、「完了」ボタンで初めてフォームに反映する。
これにより、ドロワーを閉じずに何度でも料理を選び直せる。

## 代替案と棄却理由

### 代替案1: Sheet（サイドシート）を使う
shadcn の Sheet はサイドから出るが、モバイルでは操作しづらい。
Drawer（下から出る）の方がモバイル用途に合う。

### 代替案2: インライン表示のまま、検索結果に height 制限を設けてスクロール
検索結果ボックスを `overflow-y-auto max-h-[40vh]` にする方法。
実装は簡単だが、「スクロール in スクロール」になりUXが悪い。棄却。

## リスクと対策

| リスク | 対策 |
|--------|------|
| 既存の AddMeal.spec.tsx / EditMeal.spec.tsx が壊れる | テスト実行を必須とし、ドロワーのトリガーと「完了」ボタンの testid を追加 |
| `setValue` のタイミング変更で既存テストが壊れる | useEffect 削除を慎重に行い、テストを先に確認 |

## テスト方針
- 既存テスト（AddMeal.spec.tsx, EditMeal.spec.tsx）がグリーンであることを確認
- ドロワーを開く → 料理選択 → 完了 → dishId がセットされる、の流れをテスト
- `docker compose exec frontend yarn test` + `yarn lint`
- Playwright でドロワーのスクリーンショット確認
