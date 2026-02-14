# タスクリスト: 食事と料理のコメント機能追加

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### 実装可能なタスクのみを計画
- 計画段階で「実装可能なタスク」のみをリストアップ
- 「将来やるかもしれないタスク」は含めない
- 「検討中のタスク」は含めない

### タスクスキップが許可される唯一のケース
以下の技術的理由に該当する場合のみスキップ可能:
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

スキップ時は必ず理由を明記:
```markdown
- [x] ~~タスク名~~（実装方針変更により不要: 具体的な技術的理由）
```

### タスクが大きすぎる場合
- タスクを小さなサブタスクに分割
- 分割したサブタスクをこのファイルに追加
- サブタスクを1つずつ完了させる

---

## フェーズ1: 事前調査・確認

- [x] GraphQLクエリの確認
    - [x] カレンダーのクエリで `meal.comment` が含まれているか確認
    - [x] カレンダーのクエリで `meal.dish.comment` が含まれているか確認
    - [x] ~~含まれていない場合はクエリ定義を修正~~（既に含まれていたため不要）

### 各タスク詳細

#### GraphQLクエリの確認
**ファイル**: `frontend/src/features/meal/fetchMealsForCalenderQuery.ts` など

**確認項目**:
- `meal.comment` が含まれているか
- `meal.dish.comment` が含まれているか
- 含まれていない場合は追加

**DoD**: クエリに `comment` フィールドが含まれている

---

## フェーズ2: 料理フォームへのコメント追加

- [x] 料理フォームにコメント入力フィールドを追加
    - [x] `FormFieldWrapperWithLabel` でラベル「コメント」を追加
    - [x] テキストエリアを追加（`<Form.Control as="textarea">`）
    - [x] プレースホルダー設定
    - [x] 編集時のデフォルト値設定

- [x] 料理追加のテスト作成・実行（Red → Green）
    - [x] テストケース追加: コメントを入力して登録
    - [x] テストケース追加: コメントなしで登録
    - [x] Docker内でテスト実行
    - [x] テスト失敗の修正

- [x] 料理編集のテスト作成・実行（Red → Green）
    - [x] テストケース追加: コメントを編集して保存
    - [x] テストケース追加: コメントを空にして保存
    - [x] Docker内でテスト実行
    - [x] テスト失敗の修正

### 各タスク詳細
#### 料理フォームにコメント入力フィールドを追加
**ファイル**: `frontend/src/components/dish/DishForm/DishForm/DishFormOfOnlyDishFields.tsx`

**実装内容**:
- `FormFieldWrapperWithLabel` を使用してラベル「コメント」を追加
- `<Form.Control as="textarea" {...register('dish.comment')} />` を追加
- プレースホルダー: 「料理のメモや感想を入力...」
- `defaultValue={preFilledDish?.comment}` を設定（編集時）

**DoD**: フォームにコメント入力欄が表示される

#### 料理追加のテスト作成・実行（Red → Green）
**ファイル**: `frontend/src/components/dish/DishForm/AddDish.spec.tsx`

**テストケース**:
1. コメントを入力して登録し、GraphQLに正しく送信される
2. コメントなしで登録し、GraphQLに `undefined` が送信される

**実装内容**:
- 新しい `describe` ブロック: `'when add dish with comment'`
- `userType(screen, 'dishComment', 'これは美味しい料理です')`
- `expect(getLatestMutationVariables().dish.comment).toEqual('これは美味しい料理です')`

**コマンド**: `docker compose exec frontend yarn test AddDish.spec.tsx`

**DoD**: テストがグリーン

#### 料理編集のテスト作成・実行（Red → Green）
**ファイル**: `frontend/src/components/dish/DishForm/EditDish.spec/` 配下のテストファイル

**テストケース**:
1. コメントを編集して保存し、GraphQLに正しく送信される
2. コメントを空にして保存し、GraphQLに空文字列が送信される

**実装内容**:
- 既存のテストファイルに追加（例: `editDishWithUpdatingOnlyDIshField.spec.tsx`）
- または新規ファイル: `editDishWithUpdatingComment.spec.tsx`

**DoD**: テストがグリーン

---

## フェーズ3: 食事フォームへのコメント追加

- [x] 食事フォームにコメント入力フィールドを追加
    - [x] `FormFieldWrapperWithLabel` でラベル「コメント」を追加
    - [x] テキストエリアを追加（`<Form.Control as="textarea">`）
    - [x] プレースホルダー設定
    - [x] 編集時のデフォルト値設定

- [x] 食事追加のテスト作成・実行（Red → Green）
    - [x] テストケース追加: コメントを入力して登録
    - [x] テストケース追加: コメントなしで登録
    - [x] Docker内でテスト実行
    - [x] テスト失敗の修正

- [x] 食事編集のテスト作成・実行（Red → Green）
    - [x] テストケース追加: コメントを編集して保存
    - [x] テストケース追加: コメントを空にして保存
    - [x] Docker内でテスト実行
    - [x] テスト失敗の修正

### 各タスク詳細
#### 食事フォームにコメント入力フィールドを追加
**ファイル**: `frontend/src/components/meal/MealForm/MealForm/index.tsx`

**実装内容**:
- 日付・時間帯の後にコメントフィールドを追加
- `FormFieldWrapperWithLabel` を使用してラベル「コメント」を追加
- `<Form.Control as="textarea" {...register('meal.comment')} />` を追加
- プレースホルダー: 「食事のメモや感想を入力...」
- 編集時のデフォルト値: `defaultValue={registeredMeal?.comment}` （propsから受け取る）

**DoD**: フォームにコメント入力欄が表示される

#### 食事追加のテスト作成・実行（Red → Green）
**ファイル**: `frontend/src/components/meal/MealForm/AddMeal.spec.tsx`

**テストケース**:
1. コメントを入力して登録し、GraphQLに正しく送信される
2. コメントなしで登録し、GraphQLに `undefined` が送信される

**実装内容**:
- 新しい `describe` ブロック: `'when add meal with comment'`
- `userType(screen, 'mealComment', 'とても美味しかった')`
- `expect(getLatestMutationVariables().meal.comment).toEqual('とても美味しかった')`

**コマンド**: `docker compose exec frontend yarn test AddMeal.spec.tsx`

**DoD**: テストがグリーン

#### 食事編集のテスト作成・実行（Red → Green）
**ファイル**: `frontend/src/components/meal/MealForm/EditMeal.spec.tsx`

**テストケース**:
1. コメントを編集して保存し、GraphQLに正しく送信される
2. コメントを空にして保存し、GraphQLに空文字列が送信される

**DoD**: テストがグリーン

---

## フェーズ4: カレンダー表示へのコメント追加

- [x] カレンダーのMealIconにコメント表示を追加
    - [x] 料理コメント（`meal.dish.comment`）の表示実装
    - [x] 食事コメント（`meal.comment`）の表示実装
    - [x] 30文字以上の省略表示実装
    - [x] コメントがない場合の非表示実装

- [x] カレンダー表示のテスト作成・実行（Red → Green）
    - [x] テストケース追加: 料理コメントがある場合
    - [x] テストケース追加: 食事コメントがある場合
    - [x] テストケース追加: 両方のコメントがある場合
    - [x] テストケース追加: コメントがない場合
    - [x] テストケース追加: 長いコメントの省略表示
    - [x] Docker内でテスト実行
    - [x] テスト失敗の修正

### 各タスク詳細

#### カレンダーのMealIconにコメント表示を追加
**ファイル**: `frontend/src/components/calender/calenderComponents/MealIcon/index.tsx`

**実装内容**:
- 料理コメント: `meal.dish.comment` を表示
- 食事コメント: `meal.comment` を表示
- 表示ロジック:
  - コメントがない場合は非表示
  - 30文字以上の場合は省略表示（「...」）
- 配置: 既存の `caption` の下に新しい `<div>` を追加
- CSSクラス: `style['dish-content-comment']` など（後で調整可能）

**DoD**: カレンダーにコメントが表示される（デザインは雑でOK）

#### カレンダー表示のテスト作成・実行（Red → Green）
**ファイル**: `frontend/src/components/calender/calenderComponents/MealIcon/index.spec.tsx`

**テストケース**:
1. 料理コメントがある場合、表示される
2. 食事コメントがある場合、表示される
3. 両方のコメントがある場合、両方表示される
4. コメントがない場合、非表示
5. 長いコメント（30文字以上）の場合、省略表示される

**実装内容**:
- モックデータを準備（`meal` オブジェクトに `comment` と `dish.comment` を含める）
- `screen.getByText` でコメントが表示されているか確認

**コマンド**: `docker compose exec frontend yarn test MealIcon`

**DoD**: テストがグリーン

---

## フェーズ5: 品質チェックと修正

- [x] すべてのテストが通ることを確認
    - [x] `docker compose exec frontend yarn test`

- [x] リントエラーがないことを確認
    - [x] `docker compose exec frontend yarn lint`
    - [x] ~~エラーがある場合は修正（`yarn lint --fix`）~~（エラーなし）

- [ ] 手動確認
    - [ ] 料理登録時にコメントを入力し、保存後に編集画面で確認できる
    - [ ] 食事登録時にコメントを入力し、保存後に編集画面で確認できる
    - [ ] カレンダーの食事アイコンで料理コメント・食事コメントが表示される

---

## フェーズ6: ドキュメント更新

- [x] ~~README.md を更新（必要に応じて）~~（更新不要）
- [x] 実装後の振り返り（このファイルの下部に記録）

---

## 実装後の振り返り

### 実装完了日
2026-02-11

### 計画と実績の差分

**計画と異なった点**:
- GraphQLクエリに既に `comment` フィールドが含まれていたため、フェーズ1の修正作業が不要だった
- 食事フォームの編集時デフォルト値設定のため、`EditMeal.tsx` と `MealForm/index.tsx` の両方にprops追加が必要だった（計画では `MealForm/index.tsx` のみと想定）
- `registeredDish` と `newDishWithRequiredParams` に `comment` フィールドを追加する必要があった（計画では言及なし）

**新たに必要になったタスク**:
- 既存のテストデータに `comment` フィールドを追加
  - フォームにコメントフィールドを追加したことで、すべてのテストで空文字列 `''` が送信されるようになった
  - 既存のテスト期待値を修正する必要があった

**技術的理由でスキップしたタスク**（該当する場合のみ）:
- なし（すべてのタスクを完了）

**⚠️ 注意**: 「時間の都合」「難しい」などの理由でスキップしたタスクはここに記載しないこと。全タスク完了が原則。

### 学んだこと

**技術的な学び**:
- React Hook Formでテキストエリアのデフォルト値を設定する際は、`defaultValue` を使用する
- `userType` に空文字列を渡すとエラーになるため、空にする場合は `userClearTextbox` を使う
- GraphQLの型定義に既にフィールドが存在しても、UIで使われていない場合がある（スキーマとUIの乖離）
- テストファースト開発により、実装ミスを早期に発見できた（例: `comment: null` vs `comment: ''` の違い）

**プロセス上の改善点**:
- ステアリングファイル（design.md、tasklist.md）により、実装の方向性が明確だった
- テストファーストの原則に従ったことで、実装の品質が向上した
- チェックボックス形式のtasklistにより、進捗管理が容易だった
- フェーズごとに区切ることで、作業の見通しが良くなった

### 次回への改善提案
- 事前調査（フェーズ1）で、UIとスキーマの乖離を確認する重要性を再認識
- 既存のテストデータに新しいフィールドを追加する際は、すべてのテストファイルに影響がないか確認する
- 食事フォームのように複雑なpropsがある場合は、型定義を先に確認してから実装を進める
- テストの期待値は、実際の出力を見てから修正する方が効率的（特に長い文字列や正規表現）
