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
