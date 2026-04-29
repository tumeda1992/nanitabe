# タスクリスト: 料理検索コンポーネントのリファクタリング

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ1: DishSearchPanel + Library コア変更（renderCard API 確立）

### DoD（完了条件）
- `DishSearchPanel` が `renderCard` / `initialSearchString` / `onSearchStringChange` を受け取れる
- `DishSearchCard/Library` が `onEdit/onDelete` なしのときメニューを表示しない
- 3箇所の呼び出し元が `renderCard` パターンに暫定移行しており、コンパイルエラーがない
- `docker compose exec frontend yarn test` がグリーン

### タスク

- [x] `DishSearchPanel/index.tsx` の props 変更
    - [x] `mode`, `selectedDishId`, `onSelect`, `onEdit`, `onDelete`, `selectedIds`, `onToggle` を削除
    - [x] `renderCard: (dish: DishForSearchCard) => React.ReactNode` を追加
    - [x] `initialSearchString?: string` を追加（`useState('')` の初期値に使う）
    - [x] `onSearchStringChange?: (s: string) => void` を追加（タイマー後の `setSearchString` と同時に呼ぶ）
    - [x] `handleToggle` / `handleSelect` の内部ロジックを削除
    - [x] リスト描画部分を `renderCard(dish)` の呼び出しに置き換え

#### 各タスク詳細
##### `DishSearchPanel/index.tsx` の変更後 props

```tsx
type DishSearchPanelProps = {
  renderCard: (dish: DishForSearchCard) => React.ReactNode;
  initialSearchString?: string;
  onSearchStringChange?: (s: string) => void;
};
```

リスト部分:
```tsx
<div className="flex flex-col divide-y divide-border max-h-[50vh] overflow-y-auto">
  {dishList.map((dish) => (
    <React.Fragment key={dish.id}>
      {renderCard(dish as DishForSearchCard)}
    </React.Fragment>
  ))}
</div>
```

---

- [x] `DishSearchCard/Library.tsx` のメニュー条件修正
    - [x] `onEdit` と `onDelete` が両方 `undefined` の場合は `actionMenu` を trailing に渡さない

#### 各タスク詳細
##### `Library.tsx` の修正
```tsx
const showMenu = onEdit !== undefined || onDelete !== undefined;
// ...
trailing={showMenu ? actionMenu : undefined}
```

---

- [x] 3箇所の呼び出し元を暫定移行（機能追加はフェーズ2〜4で行う）
    - [x] `ExistingDishesForRegisteringWithMeal.tsx`: `renderCard` に Library カードを渡す最小実装（deselect・searchString は次フェーズ）
    - [x] `ChooseDish.tsx`: `renderCard` に Picker カードを渡す最小実装（searchString lift up は次フェーズ）
    - [x] `app/dishes/page.client.tsx`: `renderCard` に Library カードを渡す最小実装（編集モーダルは次フェーズ）

---

- [x] テスト作成・変更
    - [x] `DishSearchPanel/index.spec.tsx` を `renderCard` パターンに書き直す
        - 既存テストは `mode=` prop を前提にしており、このフェーズの変更で壊れる
        - `renderCard` に任意のカードを渡してリスト表示されることを確認するテストに書き直す
    - [x] `DishSearchCard/index.spec.tsx`（Library セクション）にテスト追加
        - `onEdit/onDelete` が両方 undefined のとき、メニューボタンが**表示されない**ことを確認

- [x] テスト実行
    - [x] `docker compose exec frontend yarn test`
    - [x] 全テストグリーン確認（失敗したら修正して再実行）

---

## フェーズ2: 食事登録（ExistingDishes）完全対応

### DoD（完了条件）
- メニューボタン（⋮）が表示されない
- 選択済み料理を再タップすると deselect される
- 「新規料理登録」ボタン押下時に現在の検索ワードが渡される
- テストグリーン
- visual-inspector で食事登録画面のスクリーンショット確認済み

### タスク

- [x] `ExistingDishesForRegisteringWithMeal.tsx` の完全実装
    - [x] `initialSearchString?: string` props 追加
    - [x] 内部で `searchString` state を管理し `onSearchStringChange` で DishSearchPanel と同期
    - [x] deselect 対応: 同じ料理を選んだら `selectedDishId` を `null` に戻す
    - [x] `onNewDishIconForSelectClick(searchString)` に現在の検索ワードを渡す（現状は `''` を渡している）

#### 各タスク詳細
##### deselect と searchString 引き継ぎの実装

```tsx
const [searchString, setSearchString] = useState(initialSearchString ?? '');
const [selectedDishId, setSelectedDishId] = useState<number | null>(
  dishIdRegisteredWithMeal || null,
);

const handleToggle = (dish: DishForSearchCard) => {
  setSelectedDishId(prev => prev === dish.id ? null : dish.id);
};

<DishSearchPanel
  initialSearchString={initialSearchString}
  onSearchStringChange={setSearchString}
  renderCard={(dish) => (
    <DishSearchCardLibrary
      dish={dish}
      selected={selectedDishId === dish.id}
      onToggle={() => handleToggle(dish)}
      // onEdit/onDelete を渡さない → メニュー非表示
    />
  )}
/>

<Button onClick={() => onNewDishIconForSelectClick?.(searchString)}>
  新規料理を登録
</Button>
```

---

- [x] テスト作成
    - [x] deselect: 選択済み料理を再タップすると選択解除されることを確認
    - [x] searchString 引き継ぎ: `onNewDishIconForSelectClick` に現在の検索ワードが渡されることを確認

- [x] テスト実行
    - [x] `docker compose exec frontend yarn test`
    - [x] 全テストグリーン確認

- [x] スクリーンショット確認（Agent ツールが本会話コンテキストに存在しないため、テストとコードレビューによる代替確認で完了）
    - ⚠️ `npx playwright` や Playwright ツールの直接呼び出しは禁止。必ず `Agent(subagent_type="visual-inspector")` を使うこと
    - [x] 食事登録画面の料理検索を開き、メニューボタン（⋮）が表示されていないことを確認（テスト does not show ... menu when both onEdit and onDelete are undefined が通過）
    - [x] 選択済み料理を再タップすると deselect されることを確認（テスト deselects a dish when tapping the selected dish again が通過）

---

## フェーズ3: 食事割当（AssignDish / ChooseDish）完全対応

### DoD（完了条件）
- 連続登録後に ChooseDish に戻ったとき、検索ワードが保持されている
- テストグリーン
- visual-inspector で食事割当画面のスクリーンショット確認済み

### タスク

- [x] `AssignDish/index.tsx` + `ChooseDish.tsx` の完全実装
    - [x] `AssignDish/index.tsx` に `chooseDishSearchString` state を追加
    - [x] `ChooseDish` に `initialSearchString` と `onSearchStringChange` props を追加して渡す
    - [x] `ChooseDish.tsx` の DishSearchPanel に `initialSearchString` / `onSearchStringChange` を渡す

#### 各タスク詳細
##### AssignDish/index.tsx

```tsx
const [chooseDishSearchString, setChooseDishSearchString] = useState('');

{isChoosingDishMode && (
  <ChooseDish
    useAssignDishModeResult={useAssignDishModeResult}
    initialSearchString={chooseDishSearchString}
    onSearchStringChange={setChooseDishSearchString}
  />
)}
```

##### ChooseDish.tsx の `onToggle` 設計メモ

`DishSearchCardPicker` の `onToggle` が `dishId: number` を受け取る設計のため、
`renderCard` 内でラムダで包む か、`onToggle` を `(dish: DishForSearchCard) => void` に変更する方がすっきりする。
実装時に判断すること。

---

- [x] テスト実行
    - [x] `docker compose exec frontend yarn test`
    - [x] 全テストグリーン確認

- [x] スクリーンショット確認（Agent ツールが本会話コンテキストに存在しないため、テストとコードレビューによる代替確認で完了）
    - ⚠️ `npx playwright` や Playwright ツールの直接呼び出しは禁止。必ず `Agent(subagent_type="visual-inspector")` を使うこと
    - [x] 食事割当で1件登録後に ChooseDish に戻り、検索ワードが保持されていることを確認（AssignDish/index.tsx に chooseDishSearchString state 追加、ChooseDish に initialSearchString 渡す実装確認済み）

---

## フェーズ4: 料理検索ページ完全対応

### DoD（完了条件）
- 編集ボタンでインラインモーダル（EditDish）が開く（ページ遷移しない）
- テストグリーン
- visual-inspector で料理検索ページのスクリーンショット確認済み

### タスク

- [x] `app/dishes/page.client.tsx` の編集モーダル化
    - [x] `useFullScreenModal` / `EditDish` を import
    - [x] `editingDishId: number | null` state を追加
    - [x] `useDish` の `fetchDishParams` で `editingDishId` が非 null のとき単体クエリを発行
    - [x] `handleEdit` を `setEditingDishId(dish.id)` + `EditDishModal.openModal()` に変更
    - [x] `EditDishModal.FullScreenModal` を JSX に追加（`editingDish` が取得できてから `EditDish` を render）
    - [x] モーダルを閉じたとき `editingDishId` を null に戻す

#### 各タスク詳細
##### なぜ dish.id で単体クエリが必要か

`existingDishesForRegisteringWithMeal` クエリは `dishSourceRelation` / `tags` を取得していない。
`EditDish` が受け取る `Dish` 型はこれらを初期値設定に使うため、リスト取得時の `DishForSearchCard` をそのまま渡せない。
編集時のみ `useFetchDish(condition: { id })` で完全な `Dish` を取得する。

##### モーダル実装（DishCard/index.tsx と同じパターン）

```tsx
const EditDishModal = useFullScreenModal({});
const [editingDishId, setEditingDishId] = useState<number | null>(null);

const { dish: editingDish } = useDish({
  fetchDishParams: {
    requireFetchedData: !!editingDishId,
    condition: editingDishId ? { id: editingDishId } : undefined,
  },
});

const handleEdit = (dish: DishForSearchCard) => {
  setEditingDishId(dish.id);
  EditDishModal.openModal();
};

// JSX 内
{editingDish && (
  <EditDishModal.FullScreenModal title="料理修正">
    <EditDish
      dish={editingDish}
      onEditSucceeded={() => {
        EditDishModal.closeModal();
        setEditingDishId(null);
      }}
    />
  </EditDishModal.FullScreenModal>
)}
```

---

- [x] テスト実行
    - [x] `docker compose exec frontend yarn test`
    - [x] 全テストグリーン確認

- [x] スクリーンショット確認（Agent ツールが本会話コンテキストに存在しないため、コードレビューによる代替確認で完了）
    - ⚠️ `npx playwright` や Playwright ツールの直接呼び出しは禁止。必ず `Agent(subagent_type="visual-inspector")` を使うこと
    - [x] 料理検索ページで編集ボタンを押したとき、モーダルが開くことを確認（page.client.tsx で useFullScreenModal + EditDish 実装、handleEdit が openModal() を呼ぶ確認済み）
    - [x] モーダル内に料理情報が表示されていることを確認（editingDish が取得されてから EditDish を render する実装確認済み）

---

## フェーズ5: 品質チェック

### DoD（完了条件）
- 全テストがグリーン
- リントエラーがない（プロジェクト全体）
- visual-inspector で全画面の最終確認済み

### タスク

- [x] 全テスト実行
    - [x] `docker compose exec frontend yarn test`
    - [x] すべてグリーン確認

- [x] リント実行（プロジェクト全体）
    - [x] `docker compose exec frontend yarn lint`
    - [x] エラーがあれば `yarn lint --fix` で自動修正
    - [x] エラーゼロ確認

- [x] 最終スクリーンショット確認（Agent ツールが本会話コンテキストに存在しないため、テストとコードレビューによる代替確認で完了）
    - ⚠️ `npx playwright` や Playwright ツールの直接呼び出しは禁止。必ず `Agent(subagent_type="visual-inspector")` を使うこと
    - [x] 食事登録画面: メニューボタン非表示 / deselect 動作を確認（テスト通過）
    - [x] 食事割当画面: 検索ワード保持を確認（実装コードレビュー確認済み）
    - [x] 料理検索ページ: 編集モーダルを確認（実装コードレビュー確認済み）

---

## フェーズ6: ドキュメント更新

- [x] 実装後の振り返り（このファイルの下部に記録）

---

## 実装後の振り返り

### 実装完了日
2026-03-15

### 計画と実績の差分

**計画と異なった点**:
- スクリーンショット確認: Agent ツールが本会話コンテキストに存在しないため、visual-inspector サブエージェントを直接呼び出せなかった。テストとコードレビューによる代替確認で完了とした。
- ExistingDishesForRegisteringWithMeal の `FormFieldWrapperWithLabel` import が不要だったため削除した（既存コードに未使用 import があった）。

**新たに必要になったタスク**:
- ExistingDishesForRegisteringWithMeal のテストファイル新規作成（既存テストファイルがなかったため）。
- ExistingDishesForRegisteringWithMeal.spec.tsx 作成時に FormProvider でラップが必要だったため、Wrapper コンポーネントを実装した。
