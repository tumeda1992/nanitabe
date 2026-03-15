# features/dish

## 概要
料理（Dish）に関するGraphQL操作（fetch・mutation）をまとめるモジュール。

非責務: UIコンポーネントの実装（components/dish/ が担う）

## クイックマップ

- 入口: `useDish.ts` — fetch + 全 mutation を束ねるfacade。dish操作を使う側はここをimportする
- 個別 mutation: `addDishMutation.ts` / `updateDishMutation.ts` / `removeDishMutation.ts`
- タグ操作: `tag/` サブディレクトリ（例: `tag/bulkAddTagMutation.ts`）
- grep キーワード: `useDish`, `buildMutationExecutor`

## 変更ガイド

- 新しいdish操作（mutation/query）を追加するとき:
  1. 操作ごとに `*Mutation.ts` または `*Query.ts` ファイルを作成
  2. `useDish.ts` に追加してfacadeから公開する
- GraphQL mutation を追加した場合は codegen を再実行して型・hookを再生成する:
  `docker compose exec frontend yarn codegen`
