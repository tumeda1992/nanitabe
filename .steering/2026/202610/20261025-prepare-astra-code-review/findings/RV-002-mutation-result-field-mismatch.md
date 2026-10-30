# RV-002: 共通mutation処理がloadingとerrorを取得できない

- 観点: 保守性・契約
- 優先度: 中
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: frontend/src/features/utils/mutationUtils.ts:20 buildMutationExecutor
- 依存する指摘: なし

## 問題と根拠

codegenMutationHookの結果をmutationLoading・mutationErrorというプロパティ名で分割代入している。生成されたuseAddMealMutation等はApollo.useMutationを返し、その状態プロパティはloading・errorである。結果として各useAddMeal等に返す状態がundefinedになる。any指定がこの不整合を隠している。

## 改善案

loading: mutationLoading、error: mutationErrorとして取得し、hook引数と戻り値tupleにApolloの型を与える。状態の修正と型の改善は別の変更として扱う。

## 振る舞いを維持する条件

修正すると待機中・失敗時の値が変わるため今回の適用対象外。現在のundefinedを保持する型改善だけで本件を解決済みにはしない。

## 検証方法

共通executorをrenderHookで呼び、loading=trueとerror設定時にその値を返すことを検証する。実際の利用画面で送信中表示・エラー表示の変化を確認する。

## 採否・対応記録

静的コード確認のみ。テスト未実行、未適用。
