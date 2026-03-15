# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ1: useCodegenQuery バグ修正（編集モーダルクラッシュ）

**対象ファイル**: `frontend/src/features/utils/queryUtils.ts`

### DoD（完了条件）
- `useCodegenQuery` の条件分岐が除去され、常に `codegenQueryHook({ variables, skip: !requireFetchedData })` を呼ぶ実装になっている
- 料理検索ページで編集ボタンをクリックするとインラインモーダルが開く（クラッシュしない）
- テストグリーン
- visual-inspector で編集モーダル動作確認済み

### タスク

- [x] `useCodegenQuery` の修正
    - [x] `codegenQueryHook` の呼び出しに `skip: !requireFetchedData` を追加
    - [x] `codegenLazyQueryHook` の条件分岐を除去
    - [x] 関数シグネチャから `codegenLazyQueryHook` 引数を削除
    - [x] 影響する呼び出し元（`codegenLazyQueryHook` を渡している箇所）を確認・修正

- [x] テスト作成・修正
    - [x] `useCodegenQuery` の `requireFetchedData=false` 時に `skip=true` でクエリが呼ばれることをテストで確認
    - [x] `requireFetchedData=true` 時に `skip=false` でクエリが呼ばれることをテストで確認
    - [x] 既存テストが新インターフェースで通ることを確認

- [x] テスト実行（`docker compose exec frontend yarn test`）
    - [x] 全件グリーン確認

- [x] visual-inspector で動作確認
    - steering ディレクトリ: `20260315-feature-210-fix-dish-selection-edit-modal-bugs/phase1/`
    - [x] 料理検索ページ（`/dishes`）にアクセス
    - [x] 任意の料理の編集ボタンを押してインラインモーダルが開くことを確認（クラッシュしないこと）
    - [x] モーダル内に料理情報が表示されることを確認
    - [x] `result.md` に確認結果を記録し、tasklist に転記

  > 確認日時: 2026-03-15 23:30
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260315-feature-210-fix-dish-selection-edit-modal-bugs/phase1/result.md
  >
  > 項目1: 料理検索ページ（/dishes）にアクセス ✅
  >   期待値: /dishes ページが正常に表示される
  >   結果: 料理検索ページが正常に表示された。料理一覧が表示され、各料理カードに操作メニューボタンが表示されている
  >
  > 項目2: 編集ボタンを押してインラインモーダルが開く ✅
  >   期待値: 操作メニューをクリックすると編集項目が表示され、クリックでモーダルが開く
  >   結果: 「しゃぶしゃぶ」の操作メニューから「編集」をクリックすると料理修正モーダルが開き、料理情報が正常に表示された。クラッシュなし

---

## フェーズ2: 選択済み料理の検索条件変更後固定表示

**対象ファイル**:
- `frontend/src/components/dish/DishSearchPanel/index.tsx`
- `frontend/src/features/dish/fetchDishQuery.ts`
- `frontend/src/components/meal/MealForm/MealForm/ExistingDishesForRegisteringWithMeal.tsx`

### DoD（完了条件）
- 食事登録の料理検索で料理を選んだ後に検索ワードを変更しても、選択済み料理がリスト先頭に表示され続ける
- テストグリーン
- visual-inspector で動作確認済み

### タスク

- [x] `DishSearchPanel` に `dishIdRegisteredWithMeal` prop を追加
    - [x] `DishSearchPanelProps` に `dishIdRegisteredWithMeal?: number | null` を追加（実装済み）
    - [x] `fetchDishQuery.ts` の `useExistingDishesForRegisteringWithMeal` に `dishIdRegisteredWithMeal` を変数として渡す（実装済み）
    - [x] `DishSearchPanel` 内でこの prop をクエリ変数に流す（実装済み）

- [x] `ExistingDishesForRegisteringWithMeal` の修正
    - [x] `selectedDishId` が変化するたびに `dishIdRegisteredWithMeal={selectedDishId}` として `DishSearchPanel` に渡す（実装済み）

- [x] テスト作成・修正
    - [x] `DishSearchPanel` に `dishIdRegisteredWithMeal` を渡したときクエリ変数に含まれることをテストで確認
    - [x] `ExistingDishesForRegisteringWithMeal` で料理選択後に `dishIdRegisteredWithMeal` が更新されてクエリ変数に渡ることを確認
    - [x] 既存テストが新インターフェースで通ることを確認
    - 補足: `renderWithApollo.tsx` がシングルトンの ApolloClient を使っていたためキャッシュが共有されテストが失敗していた。毎回新しいクライアントを生成するよう修正。

- [x] テスト実行（`docker compose exec frontend yarn test`）
    - [x] 全件グリーン確認（103件 pass）

- [x] visual-inspector で動作確認
    - steering ディレクトリ: `20260315-feature-210-fix-dish-selection-edit-modal-bugs/phase2/`
    - [x] 食事登録画面で料理を選択する
    - [x] 検索ワードを変更しても選択済み料理がリスト先頭に表示され続けることを確認
    - [x] `result.md` に確認結果を記録し、tasklist に転記

  > 確認日時: 2026-03-15 23:50
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260315-feature-210-fix-dish-selection-edit-modal-bugs/phase2/result.md
  >
  > 項目1: 食事登録画面アクセス ✅
  >   期待値: /meal/new にアクセスできる
  >   結果: URL http://localhost:18100/meal/new に正常アクセス
  >
  > 項目2: 料理リスト表示確認 ✅
  >   期待値: 料理カードが表示される
  >   結果: 881 件の料理カードが表示された
  >
  > 項目3: 料理を選択 ✅
  >   期待値: 料理カードをクリックすると選択状態になる
  >   結果: "しゃぶしゃぶ"（existingDish-256）を選択。チェックボックスが選択状態になった
  >
  > 項目4: 検索ワード変更後の料理リスト件数 ✅
  >   期待値: 検索ワード変更後も料理が表示される
  >   結果: 検索ワード "zzz" 入力後も 2 件表示（選択済み料理 + α）
  >
  > 項目5: 選択済み料理がリスト先頭に固定されるか ✅
  >   期待値: 先頭に existingDish-256 が表示される
  >   結果: 先頭カードが existingDish-256（しゃぶしゃぶ）のまま固定表示。"zzz" にマッチしない料理でも選択済み料理だけが1件表示された

---

## フェーズ3: 品質チェック

### DoD（完了条件）
- 全テストグリーン
- ESLint エラーゼロ
- visual-inspector で両修正の最終確認済み

### タスク

- [x] 全テスト実行（`docker compose exec frontend yarn test`）
    - [x] 全件グリーン確認（103件 pass）

- [x] ESLint 実行（`docker compose exec frontend yarn lint`）
    - [x] エラーがあれば修正して再実行
    - [x] エラーゼロ確認

- [x] visual-inspector で最終確認
    - steering ディレクトリ: `20260315-feature-210-fix-dish-selection-edit-modal-bugs/phase3/`
    - [x] 料理検索ページの編集モーダルが正常に開くことを確認
    - [x] 食事登録画面で選択済み料理が検索条件変更後も固定表示されることを確認
    - [x] `result.md` に確認結果を記録し、tasklist に転記

  > 確認日時: 2026-03-15 23:54
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260315-feature-210-fix-dish-selection-edit-modal-bugs/phase3/result.md
  >
  > 項目1: 料理検索ページ: 編集モーダルが開く ✅
  >   期待値: 操作メニューから「編集」を選択するとインラインモーダルが開く
  >   結果: 「しゃぶしゃぶ」の操作メニューから「編集」クリック後、「料理修正」モーダルが開き料理情報が表示された
  >
  > 項目2: 食事登録: 選択済み料理が検索条件変更後も先頭固定 ✅
  >   期待値: 検索ワード変更後も選択済み料理がリスト先頭に表示され続ける
  >   結果: existingDish-256（しゃぶしゃぶ）を選択後、"zzz" で検索してもリスト先頭に固定表示された

---

## フェーズ4: ドキュメント更新

- [x] doc-enricher スキルを利用した README.md 更新（不要: DishSearchPanel/README.md はフェーズ1以前から更新済みで `dishIdRegisteredWithMeal` の説明が含まれている）
- [x] 実装後の振り返り（このファイルの下部に記録）

---

## 実装後の振り返り

### 実装完了日
2026-03-15

### 計画と実績の差分

**計画と異なった点**:
- フェーズ2の実装（DishSearchPanel/ExistingDishesForRegisteringWithMeal の修正）はすでにコードベースに反映済みだったため、テスト作成と動作確認のみ実施した
- テスト実行時に `renderWithApollo.tsx` のシングルトン ApolloClient 問題でキャッシュ共有によるテスト失敗が発覚。毎回新しいクライアントを作成する修正が必要だった

**新たに必要になったタスク**:
- `renderWithApollo.tsx` のシングルトン → クライアントファクトリー関数への修正（テスト間キャッシュ共有問題の解消）

**技術的理由でスキップしたタスク**（該当する場合のみ）:
- フェーズ4 README 更新: DishSearchPanel/README.md に `dishIdRegisteredWithMeal` の説明が既に記載済みのため不要
