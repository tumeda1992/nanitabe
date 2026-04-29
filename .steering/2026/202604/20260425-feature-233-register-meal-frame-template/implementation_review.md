# Implementation Review: 食事枠パターン登録・適用機能

## Phase 9 ユーザー動作確認で発覚した不備

---

### [Bug] `/mealframepatterns/new` の食事枠セレクタが常に空になる

**発覚タイミング:** Phase 9 ユーザー動作確認（`/mealframepatterns/new` 操作時）

**症状:**
- meal_frame データが DB に存在しているにもかかわらず、枠追加後の `meal_frame` セレクタに選択肢が表示されない
- 新規作成フォーム・編集フォームの両方で発生

**原因:**
`MealFramePatternForm.tsx` および `MealFramePatternEditForm.tsx` で `useMealFrame({ requireFetchedData: false })` と呼んでいた。

`useCodegenQuery` の実装は `skip: !requireFetchedData` であり、`requireFetchedData: false` を渡すと Apollo クエリが完全にスキップされる。その結果 `mealFrames` が常に `[]` のままとなり、セレクタが空になっていた。

開発時の visual-inspector 確認（Phase 2）では「meal_frame のデータは未登録状態のため空」と記録されており、この時点では再現しない状態だった。パラメータの誤りが発覚しなかった。

**修正内容:**
`MealFramePatternForm.tsx:32` および `MealFramePatternEditForm.tsx:60`
```diff
- const { mealFrames } = useMealFrame({ requireFetchedData: false });
+ const { mealFrames } = useMealFrame();
```

**再発防止の観点:**
- visual-inspector 確認でデータが空の場合、「データ未登録」と「クエリスキップ」を区別できない
- 実際にデータが存在する状態でのスクリーンショット確認が必要だった
- `requireFetchedData` というパラメータ名が「ロード完了を待たない」と誤読されやすい（実際は「クエリ自体をスキップする」フラグ）

---

### [Bug] 新規作成・編集後に一覧へ戻ると古いデータが表示され、かつ「読み込み中」になる

**発覚タイミング:** Phase 9 ユーザー動作確認（`/mealframepatterns/new` や編集後に一覧へ遷移した時）

**症状:**
- 新規作成・更新直後に `/mealframepatterns` へ遷移すると、更新前の古いデータが表示される（例: 3日分が0日分と表示）
- データ量が少ないにもかかわらず「読み込み中...」が表示される

**原因:**
2つの独立した問題が重なっていた。

1. **古いデータ**: `addMealFramePattern` / `updateMealFramePattern` の mutation に `refetchQueries` が設定されていなかった。Apollo キャッシュが mutation 後も更新されず、一覧画面が `cache-first` ポリシーでそのまま古いキャッシュを返していた。

2. **「読み込み中」**: `mealFramePatternsQuery.ts` が `previousData` を活用していなかった。再フェッチ中は `data` が一時的に `undefined` になるため、`mealFramePatterns` が `[]` に落ち、`MealFramePatternList` の loading early return が発火していた。

**修正内容:**

`mutationUtils.ts` に `refetchQueries` オプションを追加:
```diff
  type BuildMutationOption<Input> = {
    normalizeInput?: (input: Input) => Input;
+   refetchQueries?: any[];
  };
```

`addMealFramePatternMutation.ts` / `updateMealFramePatternMutation.ts` に refetchQueries を設定:
```diff
+ import { MEAL_FRAME_PATTERNS } from './mealFramePatternsQuery';

  buildMutationExecutor<...>(
    useAddMealFramePatternMutation,
+   { refetchQueries: [{ query: MEAL_FRAME_PATTERNS }] },
  );
```

`mealFramePatternsQuery.ts` で previousData フォールバックを追加:
```diff
- mealFramePatterns: data?.mealFramePatterns ?? [],
+ mealFramePatterns: (data ?? previousData)?.mealFramePatterns ?? [],
```

`MealFramePatternList.tsx` で loading 表示をデータが空のときのみに限定:
```diff
- if (fetchMealFramePatternsLoading) {
+ if (fetchMealFramePatternsLoading && mealFramePatterns.length === 0) {
```

**再発防止の観点:**
- mutation 後にデータ更新が必要なクエリには `refetchQueries` を設定する必要がある。Phase 2〜5 の実装時に一貫して漏れていた
- visual-inspector の確認は mutation → 一覧遷移という画面遷移を含むシナリオでの確認が必要だった（各画面の静的な表示確認にとどまっていた）
