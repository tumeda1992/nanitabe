# Design: 料理選択の検索条件変更後消失バグ・編集モーダルクラッシュの修正

## TL;DR
`ExistingDishesForRegisteringWithMeal` で選んだ料理が検索条件変更後に消えるバグと、料理検索ページの編集モーダルがクラッシュするバグを修正する。前者はバックエンドに既存の固定表示仕組みがあるにもかかわらずフロントエンドがそれを使っていないことが原因。後者は `useCodegenQuery` の React Hooks 違反が原因。

## Requirements

### MUST
- 食事登録の料理検索で、料理を選択した後に検索条件を変更しても、選んだ料理がリストから消えないこと
- 料理検索ページで編集ボタンを押したときにインラインモーダルが開くこと（クラッシュしないこと）

### 非目標
- `useCodegenQuery` の LazyQuery パスを活用する実装（今回は除去）
- 他ユースケース（ChooseDish 等）の `dishIdRegisteredWithMeal` の振る舞いの変更

### 受け入れ基準
1. WHEN 食事登録の料理検索で料理を選択した後に検索ワードを変更 THEN 選択済み料理がリスト先頭に表示され続ける
2. WHEN 料理検索ページで任意の料理の編集ボタンを押す THEN ページ遷移せずインラインモーダルが開き、料理情報が表示される
3. WHEN 既存テストを実行 THEN 全件グリーン

## Design

### 変更点サマリ

#### バグ1: 選んだ料理が検索条件変更後に消える
- **原因**: `DishSearchPanel` が `dishIdRegisteredWithMeal` をクエリに渡していない。バックエンドの `DishSearcher#fetch` はこの引数を受け取ると選択済み料理を検索条件に関わらず先頭に固定返却する仕組みを持つが、フロントが渡していないため機能していない。
- **修正**:
  1. `DishSearchPanel` に `dishIdRegisteredWithMeal?: number | null` prop を追加し、`existingDishesForRegisteringWithMeal` クエリ変数に流す
  2. `ExistingDishesForRegisteringWithMeal` で `selectedDishId` が変わるたびに `dishIdRegisteredWithMeal` として `DishSearchPanel` に渡す

#### バグ2: 編集モーダルがクラッシュする
- **原因**: `useCodegenQuery`（`queryUtils.ts`）が `requireFetchedData` の値によって `codegenLazyQueryHook` か `codegenQueryHook` を条件分岐で呼び分けており、React の Rules of Hooks 違反が発生する。`page.client.tsx` で `editingDishId` が `null → 数値` に変化したタイミングでクラッシュする。
- **修正**: `useCodegenQuery` の条件分岐を除去し、常に `codegenQueryHook({ variables, skip: !requireFetchedData })` を呼ぶ形に変更する。LazyQuery 分岐は除去。

### 設計選択と理由

**バグ1**: `DishSearchPanel` に prop を追加して下流に流す方式。バックエンドが既に完全実装済みのため、フロントエンドの配線修正のみで解決できる。

**バグ2**: `skip` オプションを使う方式を選択。「常に両方のhookを呼ぶ」案より `skip` を使う方がフェッチの無駄がなく、LazyQuery の仕組み全体を除去できてシンプルになる。

### 代替案と棄却理由

**バグ1の代替**: `ExistingDishesForRegisteringWithMeal` 側で選択済み料理を別途フェッチして上部に固定表示する（フロントエンドのみで解決）。バックエンドの既存仕組みを無駄にするため棄却。

**バグ2の代替**: LazyQuery を正しく動くように修正する。コメントに「使うようになったら要修正」とあり、現状不要なため棄却。常に両方のhookを呼ぶ案は不要なフェッチが発生するため棄却。

### リスクと対策

- `useCodegenQuery` の変更は `skip` を使わない既存呼び出し元にも影響するが、`requireFetchedData=false` で呼んでいた箇所が LazyQuery 代わりに通常クエリを `skip` で実行するようになるだけで、取得データが変わるわけではない
- `DishSearchPanel` の prop 追加は後方互換（optional）なので既存呼び出し元への影響なし

### テスト方針

- `useCodegenQuery` の変更: `requireFetchedData=false` 時に skip されること、`true` 時にフェッチされることを単体テストで確認
- `DishSearchPanel` の prop 追加: `dishIdRegisteredWithMeal` が渡されたとき、クエリ変数に含まれることをテストで確認
- `ExistingDishesForRegisteringWithMeal`: 料理選択後に検索条件変更しても選択済み料理の ID がクエリ変数に渡り続けることを確認
- 編集モーダル: visual-inspector で実際に開くことを確認
