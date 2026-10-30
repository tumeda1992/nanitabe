# FR-014: 共通mutationがloadingとerrorを取得できない

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-002（現行コードで再確認）。

## 対象

- [frontend/src/features/utils/mutationUtils.ts](../../../../../frontend/src/features/utils/mutationUtils.ts)

## 問題と根拠

codegenMutationHookの返り値を{mutationLoading, mutationError}として分解しているがApolloのプロパティ名はloading/error。値が常にundefinedとなり、利用側の送信中表示やエラー表示が機能しない。型がanyなので型検査も通る。

## 改善案

{loading: mutationLoading, error: mutationError}へ修正し、hook結果とexecutorのtupleを型付けする。複数mutationをまとめるhookも論理和の期待値を検証する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

loading=trueおよびApolloErrorを返すhookを使い、そのまま利用側へ伝わることと送信ボタンの状態を確認する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
