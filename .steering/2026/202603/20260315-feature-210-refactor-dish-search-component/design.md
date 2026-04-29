# 設計: 料理検索コンポーネントのリファクタリング

## 元の依頼内容

料理検索のコンポーネントについてうまく作れていないように感じるから直したい
（対象コミット: d8393ed34c5085a2ce8812c4b1814bc321578b15）

表出している問題:
- 食事登録時の料理検索で見つからなかったとき、新規料理登録フォームに検索ワードが初期値として入っていない
- 食事割当で連続登録後に検索ワードが保たれない（以前は検索結果が残っていたから使い回せた）
- 食事登録の料理検索で、選んだ後に検索条件を変えると選んだ料理が見えなくなる
- 食事登録時の料理検索でチェックが外せない
- 食事登録の料理検索にメニューボタン（⋮）が表示される
- 料理検索ページのメニューで編集を押したとき、ページ遷移になっている（カレンダーと同じインラインモーダルにしたい）

---

## TL;DR

`DishSearchPanel` の `mode` prop が3つのユースケース（料理検索ページ A・食事登録 B・食事割当 C）の差分を吸収しようとして、個別ロジックが混入している。
`mode` を削除し、カード描画を `renderCard` prop で外から注入するパターンに移行する。
これにより各ユースケースの差分は呼び出し元で表現できるようになり、
個別バグ（メニューボタン常時表示・deselect 不可・検索ワード引き継ぎ不可・編集ページ遷移）を同時に修正する。

---

## 問題の整理

| # | 問題 | 原因ファイル | 根本原因 |
|---|------|-------------|---------|
| 1 | 新規料理登録に検索ワードが引き継がれない | `DishSearchPanel/index.tsx` | `searchString` が内部 state で外から初期値を注入できない |
| 2 | 食事割当の連続登録後に検索ワードがリセット | `ChooseDish.tsx` + `DishSearchPanel` | `ChooseDish` が re-mount のたびに DishSearchPanel が再初期化される |
| 3 | 食事登録で選んだ料理が条件変更後に見えなくなる | `DishSearchPanel` + `ExistingDishes` | 「選択済み料理を検索条件に関わらず表示」する仕組みがない |
| 4 | 食事登録でチェックが外せない | `ExistingDishesForRegisteringWithMeal.tsx` | `setSelectedDishId(dish.id)` のみで null に戻す手段がない |
| 5 | 食事登録の料理検索にメニューボタンが表示される | `DishSearchCard/Library.tsx` | `onEdit/onDelete` が未定義でも `actionMenu` を常にレンダリングしている |
| 6 | 料理検索ページの編集がページ遷移 | `app/dishes/page.client.tsx` | `window.location.href` でページ遷移、カレンダーは `useFullScreenModal` |

### 根本原因の構造

```
DishSearchPanel の mode で3ユースケースを吸収しようとした
  ↓
"page" 専用: selectedIds (Set), onToggle
"library" 専用: onEdit, onDelete（渡されなくても Library カードが表示する）
"picker" 専用: DishSearchCardPicker の使用
  ↓
mode による分岐・不要 props の漏れ・個別挙動の制御不能
```

---

## Requirements

### MUST
- 食事登録時に「新規料理登録」ボタン押下時、検索ワードが新規料理フォームの初期値に入る
- 食事登録で一度選んだ料理を選択解除できる（ラジオボタン的な動きでも、明示的なクリアでもよい）
- 食事登録の料理検索にメニューボタン（⋮）が表示されない
- 料理検索ページの編集ボタンでインラインモーダル（EditDish コンポーネント）が開く（ページ遷移しない）
- 既存テストが全てグリーン
- ESLint エラーゼロ

### SHOULD
- 食事割当で連続登録後に検索条件・検索ワードが保たれる
- 食事登録で選んだ料理が検索条件変更後も「選択済み」として見える（リストにない場合でも上部に固定表示など）

### MAY
- 選択済み料理を検索条件に関わらずリスト上部に固定表示する

### 非目標
- DishSearchPanel の useDish 呼び出しを外に出す（dishes を外から注入するアーキテクチャ変更はスコープ外）
- テスト未整備の箇所への新規テスト追加（既存テストの維持のみ）
- ChooseDish / AssignDish フローの大幅な再設計

---

## Design

### 設計方針: `mode` を削除し `renderCard` prop で差分を注入

**Before（現状）**
```
DishSearchPanel(X)
  mode = "page"    → Library カード + selectedIds + onEdit/onDelete
  mode = "library" → Library カード + selectedDishId（onEdit/onDelete は任意）
  mode = "picker"  → Picker カード + selectedDishId
```

**After（案）**
```
DishSearchPanel(X)
  renderCard: (dish) => ReactNode
  initialSearchString?: string

各呼び出し元が自分のカード種別・選択状態・ハンドラを決める:
  - page.client.tsx   → Library カード + onEdit(モーダル)/onDelete
  - ExistingDishes    → Library カード（メニューなし）+ deselect 対応
  - ChooseDish        → Picker カード + initialSearchString
```

### 変更点サマリ

| ファイル | 変更内容 |
|---------|---------|
| `DishSearchPanel/index.tsx` | `mode` を削除し `renderCard` + `initialSearchString` + `onSearchStringChange` を追加 |
| `DishSearchCard/Library.tsx` | `onEdit` と `onDelete` が両方 undefined の場合はメニューボタンを非表示 |
| `ExistingDishesForRegisteringWithMeal.tsx` | `renderCard` で Library（メニューなし）を渡す。deselect ロジック追加。`initialSearchString` props 追加 |
| `ChooseDish.tsx` | `renderCard` で Picker を渡す。`initialSearchString` を受け取れるようにする（親に lift up） |
| `app/dishes/page.client.tsx` | `handleEdit` を `useFullScreenModal` + `EditDish` に変更 |

### renderCard インターフェース（案）

```tsx
// DishSearchPanel の新しい props
type DishSearchPanelProps = {
  renderCard: (dish: DishForSearchCard) => React.ReactNode;
  initialSearchString?: string;
  onSearchStringChange?: (s: string) => void;
};

// 使用例（ExistingDishes）
<DishSearchPanel
  initialSearchString={initialSearchString}
  onSearchStringChange={setSearchString}
  renderCard={(dish) => (
    <DishSearchCardLibrary
      dish={dish}
      selected={selectedDishId === dish.id}
      onToggle={handleToggle}
      // onEdit/onDelete を渡さない → メニューなし
    />
  )}
/>
```

### 選択解除（deselect）の実装

`ExistingDishesForRegisteringWithMeal` での修正:
- `handleToggle` で「同じ料理をクリックしたら null に戻す」ロジックを追加
```tsx
const handleToggle = (dish: DishForSearchCard) => {
  setSelectedDishId(prev => prev === dish.id ? null : dish.id);
};
```

### 検索ワードの引き継ぎ（問題 #1）

`ExistingDishesForRegisteringWithMeal` に `initialSearchString` prop を追加。
呼び出し元から「見つからなかったときの検索ワード」を受け取り、DishSearchPanel に渡す。

```tsx
// ExistingDishesForRegisteringWithMeal.tsx
type Props = {
  dishIdRegisteredWithMeal?: number;
  displayNewDishIconForSelect?: boolean;
  onNewDishIconForSelectClick?: (searchString: string) => void;
  initialSearchString?: string;  // ← 追加
};
```

呼び出し元（MealForm 側）で「新規料理登録ボタン」に渡すときに searchString を受け取る:
```tsx
<ExistingDishesForRegisteringWithMeal
  onNewDishIconForSelectClick={(searchString) => {
    // searchString を新規料理フォームの初期値として渡す
  }}
/>
```

→ ただし、ExistingDishes → MealForm 側への searchString の渡し方は MealForm の実装確認が必要。

### 食事割当の検索ワード保持（問題 #2）

ChooseDish が re-mount されるたびに DishSearchPanel の state がリセットされるのが原因。
最小変更: `ChooseDish` の親が searchString を state として持ち、ChooseDish に `initialSearchString` として渡す。

ただし ChooseDish の親コンポーネント（`useAssignDishModeResult`）の調査が必要。
→ **TBD**: ChooseDish の親構造を確認して設計を確定させる。

### 料理検索ページの編集モーダル化（問題 #6）

```tsx
// Before
const handleEdit = (dish: DishForSearchCard) => {
  window.location.href = `/dishes/${dish.id}/edit`;
};

// After（カレンダーの DishCard と同じパターン）
const EditDishModal = useFullScreenModal({ ... });
const [editingDish, setEditingDish] = useState<DishForSearchCard | null>(null);

const handleEdit = (dish: DishForSearchCard) => {
  setEditingDish(dish);
  EditDishModal.openModal();
};
```

---

## 代替案

### 代替案1: mode を維持して個別 props で細かく制御

`showMenu: boolean`, `allowDeselect: boolean`, `initialSearchString: string` などを追加。

**棄却理由**: props が増え続ける方向性で、設計の意図が不明瞭になる。「renderCard で外から注入」の方が各ユースケースの独立性が高く、DishSearchPanel 本体がシンプルになる。

### 代替案2: A/B/C それぞれ独立した Panel コンポーネントに分割

`DishSearchPagePanel`, `MealFormDishPanel`, `AssignDishPanel` を新規作成。

**棄却理由**: 検索フィルタ・件数表示などの共通ロジックが重複する。renderCard パターンの方が「コアは共有しつつ差分だけ外から注入」できて、コードの重複を避けられる。

---

## リスクと対策

| リスク | 対策 |
|--------|------|
| renderCard への移行で既存テストが壊れる | 各フェーズ後にテスト実行を必須とする |
| ExistingDishes の検索ワード引き継ぎが MealForm 側の実装に依存 | MealForm の実装を事前に確認してから設計確定（TBD） |
| ChooseDish の親構造が想定と違う | 設計前に ChooseDish の親を確認（TBD） |

---

## テスト方針

- 各フェーズ完了後: `docker compose exec frontend yarn test`
- 最終: `docker compose exec frontend yarn lint`
- DishSearchPanel の renderCard 移行後: 既存の `index.spec.tsx` が動くことを確認
- UI 確認: `visual-inspector` サブエージェントでスクリーンショット取得
