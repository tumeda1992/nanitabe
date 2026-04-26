# features/utils

フロントエンド全体で共有されるユーティリティフック群。

## useCodegenQuery

GraphQL Codegen が生成したクエリフックをラップし、`requireFetchedData` フラグで
フェッチの実行/スキップを制御するユーティリティ。

### 不変条件

- MUST: `requireFetchedData` を動的に変化させる呼び出し元では、
  フックの呼び出し順が変わらないよう注意すること
  （内部で `skip: !requireFetchedData` を使っており、条件分岐でフックを
  切り替える実装は React の Rules of Hooks 違反になる）
- MUST: LazyQuery パスは使用しないこと（除去済み。必要なら `skip` で代替する）

#### requireFetchedData の意味と注意点

- `requireFetchedData` を省略する（デフォルト）とクエリが発火する
- `requireFetchedData: false` を渡すとクエリ自体が発火しない（返却データは常に `[]`）
- やってしまいがちな失敗: 「ロード完了を待たずに使いたい」という意図で `false` を渡す → クエリが発火せずデータが永久に空になる
- スクリーンショット確認でデータが空に見える場合、「データ未登録」と「クエリスキップ」は見た目で区別できない → DB にデータが存在する状態で確認すること

## buildMutationExecutor

### refetchQueries

mutation 後に一覧・詳細などのクエリキャッシュを更新する必要がある場合は `refetchQueries` を設定すること。

設定しない場合、Apollo が `cache-first` で古いキャッシュを返し、mutation 後も一覧が更新されない。

```ts
buildMutationExecutor(
  useSomeMutation,
  { refetchQueries: [{ query: SOME_LIST_QUERY }] },
)
```

- MUST: mutation が他の query のデータに影響する場合は必ず設定する
