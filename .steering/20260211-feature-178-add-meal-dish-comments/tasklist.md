# Tasklist: 食事と料理のコメント機能追加

## 概要
- 料理登録/編集と食事登録/編集フォームに `comment` フィールドの入力UIを追加
- カレンダーの食事表示アイコンにコメントを表示
- すべてテストファースト（Red → Green → Refactor）で実装

---

## フェーズ1: 事前調査・確認

### タスク1.1: GraphQLクエリの確認
- **内容**: カレンダーのGraphQLクエリで `comment` フィールドを取得しているか確認
- **ファイル**:
  - `frontend/src/features/meal/fetchMealsForCalenderQuery.ts` など
  - GraphQLクエリ定義を探す
- **確認項目**:
  - `meal.comment` が含まれているか
  - `meal.dish.comment` が含まれているか
  - 含まれていない場合は追加
- **DoD**: クエリに `comment` フィールドが含まれている

---

## フェーズ2: 料理フォームへのコメント追加

### タスク2.1: 料理フォームにコメント入力フィールドを追加（実装）
- **内容**: `DishFormOfOnlyDishFields.tsx` にコメント入力（テキストエリア）を追加
- **ファイル**: `frontend/src/components/dish/DishForm/DishForm/DishFormOfOnlyDishFields.tsx`
- **実装内容**:
  - `FormFieldWrapperWithLabel` を使用してラベル「コメント」を追加
  - `<Form.Control as="textarea" {...register('dish.comment')} />` を追加
  - プレースホルダー: 「料理のメモや感想を入力...」
  - `defaultValue={preFilledDish?.comment}` を設定（編集時）
- **依存**: なし
- **DoD**: フォームにコメント入力欄が表示される

### タスク2.2: 料理追加のテストを作成（Red）
- **内容**: `AddDish.spec.tsx` にコメント入力のテストを追加
- **ファイル**: `frontend/src/components/dish/DishForm/AddDish.spec.tsx`
- **テストケース**:
  1. コメントを入力して登録し、GraphQLに正しく送信される
  2. コメントなしで登録し、GraphQLに `undefined` が送信される
- **実装内容**:
  - 新しい `describe` ブロック: `'when add dish with comment'`
  - `userType(screen, 'dishComment', 'これは美味しい料理です')`
  - `expect(getLatestMutationVariables().dish.comment).toEqual('これは美味しい料理です')`
- **依存**: タスク2.1
- **DoD**: テストが失敗する（Red）

### タスク2.3: 料理追加のテストを実行・修正（Green）
- **内容**: Docker内でテストを実行し、失敗を修正
- **コマンド**: `docker compose exec frontend yarn test AddDish.spec.tsx`
- **実装内容**:
  - テストが失敗した場合、原因を分析して修正
  - スキーマやフォームの設定を調整
- **依存**: タスク2.2
- **DoD**: テストがグリーン

### タスク2.4: 料理編集のテストを作成・実行（Red → Green）
- **内容**: `EditDish.spec.tsx` にコメント編集のテストを追加
- **ファイル**: `frontend/src/components/dish/DishForm/EditDish.spec/` 配下のテストファイル
- **テストケース**:
  1. コメントを編集して保存し、GraphQLに正しく送信される
  2. コメントを空にして保存し、GraphQLに空文字列が送信される
- **実装内容**:
  - 既存のテストファイルに追加（例: `editDishWithUpdatingOnlyDIshField.spec.tsx`）
  - または新規ファイル: `editDishWithUpdatingComment.spec.tsx`
- **依存**: タスク2.3
- **DoD**: テストがグリーン

---

## フェーズ3: 食事フォームへのコメント追加

### タスク3.1: 食事フォームにコメント入力フィールドを追加（実装）
- **内容**: `MealForm/index.tsx` にコメント入力（テキストエリア）を追加
- **ファイル**: `frontend/src/components/meal/MealForm/MealForm/index.tsx`
- **実装内容**:
  - 日付・時間帯の後にコメントフィールドを追加
  - `FormFieldWrapperWithLabel` を使用してラベル「コメント」を追加
  - `<Form.Control as="textarea" {...register('meal.comment')} />` を追加
  - プレースホルダー: 「食事のメモや感想を入力...」
  - 編集時のデフォルト値: `defaultValue={registeredMeal?.comment}` （propsから受け取る）
- **依存**: なし
- **DoD**: フォームにコメント入力欄が表示される

### タスク3.2: 食事追加のテストを作成（Red）
- **内容**: `AddMeal.spec.tsx` にコメント入力のテストを追加
- **ファイル**: `frontend/src/components/meal/MealForm/AddMeal.spec.tsx`
- **テストケース**:
  1. コメントを入力して登録し、GraphQLに正しく送信される
  2. コメントなしで登録し、GraphQLに `undefined` が送信される
- **実装内容**:
  - 新しい `describe` ブロック: `'when add meal with comment'`
  - `userType(screen, 'mealComment', 'とても美味しかった')`
  - `expect(getLatestMutationVariables().meal.comment).toEqual('とても美味しかった')`
- **依存**: タスク3.1
- **DoD**: テストが失敗する（Red）

### タスク3.3: 食事追加のテストを実行・修正（Green）
- **内容**: Docker内でテストを実行し、失敗を修正
- **コマンド**: `docker compose exec frontend yarn test AddMeal.spec.tsx`
- **実装内容**:
  - テストが失敗した場合、原因を分析して修正
  - スキーマやフォームの設定を調整
- **依存**: タスク3.2
- **DoD**: テストがグリーン

### タスク3.4: 食事編集のテストを作成・実行（Red → Green）
- **内容**: `EditMeal.spec.tsx` にコメント編集のテストを追加
- **ファイル**: `frontend/src/components/meal/MealForm/EditMeal.spec.tsx`
- **テストケース**:
  1. コメントを編集して保存し、GraphQLに正しく送信される
  2. コメントを空にして保存し、GraphQLに空文字列が送信される
- **依存**: タスク3.3
- **DoD**: テストがグリーン

---

## フェーズ4: カレンダー表示へのコメント追加

### タスク4.1: カレンダーのMealIconにコメント表示を追加（実装）
- **内容**: `MealIcon/index.tsx` でコメントを表示
- **ファイル**: `frontend/src/components/calender/calenderComponents/MealIcon/index.tsx`
- **実装内容**:
  - 料理コメント: `meal.dish.comment` を表示
  - 食事コメント: `meal.comment` を表示
  - 表示ロジック:
    - コメントがない場合は非表示
    - 30文字以上の場合は省略表示（「...」）
  - 配置: 既存の `caption` の下に新しい `<div>` を追加
  - CSSクラス: `style['dish-content-comment']` など（後で調整可能）
- **依存**: タスク1.1
- **DoD**: カレンダーにコメントが表示される（デザインは雑でOK）

### タスク4.2: カレンダー表示のテストを作成（Red）
- **内容**: `MealIcon/index.spec.tsx` を作成（存在しない場合）
- **ファイル**: `frontend/src/components/calender/calenderComponents/MealIcon/index.spec.tsx`
- **テストケース**:
  1. 料理コメントがある場合、表示される
  2. 食事コメントがある場合、表示される
  3. 両方のコメントがある場合、両方表示される
  4. コメントがない場合、非表示
  5. 長いコメント（30文字以上）の場合、省略表示される
- **実装内容**:
  - モックデータを準備（`meal` オブジェクトに `comment` と `dish.comment` を含める）
  - `screen.getByText` でコメントが表示されているか確認
- **依存**: タスク4.1
- **DoD**: テストが失敗する（Red）

### タスク4.3: カレンダー表示のテストを実行・修正（Green）
- **内容**: Docker内でテストを実行し、失敗を修正
- **コマンド**: `docker compose exec frontend yarn test MealIcon`
- **実装内容**:
  - テストが失敗した場合、原因を分析して修正
  - 表示ロジックやCSSを調整
- **依存**: タスク4.2
- **DoD**: テストがグリーン

---

## フェーズ5: フォーマット・最終確認

### タスク5.1: ESLintを実行
- **内容**: 修正したコードに対してESLintを実行
- **コマンド**: `docker compose exec frontend yarn lint`
- **実装内容**:
  - エラーがある場合は修正
  - 自動修正可能な場合は `yarn lint --fix`
- **依存**: すべての実装タスク完了
- **DoD**: ESLintエラーなし

### タスク5.2: 全テストを実行
- **内容**: すべてのテストを実行して、グリーンであることを確認
- **コマンド**: `docker compose exec frontend yarn test`
- **依存**: タスク5.1
- **DoD**: すべてのテストがグリーン

### タスク5.3: 手動確認
- **内容**: ブラウザで実際に動作確認
- **確認項目**:
  1. 料理登録時にコメントを入力し、保存後に編集画面で確認できる
  2. 食事登録時にコメントを入力し、保存後に編集画面で確認できる
  3. カレンダーの食事アイコンで料理コメント・食事コメントが表示される
- **依存**: タスク5.2
- **DoD**: すべての確認項目が動作する

---

## 備考

### 前提条件
- Docker環境が起動している（`docker compose up -d`）
- フロントエンドコンテナが正常に動作している

### 不確実な項目
- **TBD**: カレンダーのGraphQLクエリに `comment` フィールドが含まれているか
  - 調査項目: タスク1.1で確認
  - 含まれていない場合は、クエリ定義を修正してから進める

### タスク完了の目安時間
- フェーズ1: 15分
- フェーズ2: 1.5時間
- フェーズ3: 1.5時間
- フェーズ4: 1時間
- フェーズ5: 30分
- **合計**: 約5時間

---

## 実行順序
1. フェーズ1（事前調査）
2. フェーズ2（料理フォーム）
3. フェーズ3（食事フォーム）
4. フェーズ4（カレンダー表示）
5. フェーズ5（フォーマット・確認）

各フェーズ内のタスクは、番号順に実行する。
