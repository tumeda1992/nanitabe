# AssignDish

食事割当フロー（料理選択 → 日付割当）を管理するコンポーネント群。

## フロー構造

`index.tsx` が `isChoosingDishMode` / `isAssigningSelectedDishMode` で `ChooseDish` と `AssignChosenDishForDate` を条件レンダリングする。

## 注意: ChooseDish の state は remount でリセットされる

- `ChooseDish` は条件レンダリングで mount/unmount されるため、内部 state は画面遷移のたびにリセットされる
- MUST: 画面遷移をまたいで保持が必要な state（検索ワードなど）は `index.tsx` で管理して `ChooseDish` に props として渡すこと
