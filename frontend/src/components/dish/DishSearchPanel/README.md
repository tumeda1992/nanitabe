# DishSearchPanel

料理の検索フィルタ・リスト表示を担う共有コンポーネント。以下3箇所で使われる。

| 使用箇所 | カード種別 |
|---------|-----------|
| `app/dishes/page.client.tsx` | DishSearchCardLibrary（メニュー付き） |
| `MealForm/MealForm/ExistingDishesForRegisteringWithMeal.tsx` | DishSearchCardLibrary（メニューなし） |
| `AssignDish/ChooseDish.tsx` | DishSearchCardPicker |

## クエリ制約

- `existingDishesForRegisteringWithMeal` クエリは表示用最小フィールド（name/mealPosition/comment/dishSourceName/evaluationScore）のみ取得する
- MUST: `EditDish` コンポーネントに dish を渡す場合は `useFetchDish({ condition: { id } })` で詳細クエリを別途実行すること（`dishSourceRelation`/`tags` が必要なため）
- MUST: `ExistingDishesForRegisteringWithMeal` で料理を選択した場合、`dishIdRegisteredWithMeal` を DishSearchPanel に渡すこと。バックエンドがこの ID の料理を検索条件に関わらず先頭固定で返却する仕組みを持っており、渡さないと検索条件変更後に選択済み料理がリストから消える。
