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
