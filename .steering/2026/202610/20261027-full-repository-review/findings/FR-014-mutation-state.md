# FR-014: 共通mutationがloadingとerrorを取得できない

- 優先度: P2
- 採否: 採用
- 対応状況: 再適用・検証完了
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

- ユーザー判断: 既存レビュー反映の合意により採用
- 適用コミット: `601d722`

## 適用結果（2026-11-01）

Apolloの`loading/error`を正しい名前で取得し、戻り値をexecutor・boolean・ApolloErrorのtupleへ型付けした。executorは`Promise<FetchResult<Output>>`を返す。型検査で判明した既存のcallback省略呼出を受け付けるよう既定値を追加し、交換開始日がない状態から必須日付を送らないguardも追加した。フォーム入力とGraphQL変換後の型を全面変更せず、既存normalize/callback契約を維持する。

実Apolloと保留可能なObservableでloadingのfalse→true→false、errorの同一オブジェクト伝達、normalizeと完了callbackを検証し、6つのmutation経路の状態集約も確認した。初回9 tests / 8 failuresで状態欠落を再現。callback省略も別のredで既存のdestructure例外を確認した。料理/食事フォームを含む61 tests成功後、追加修正を含む最終14 testsが成功した。最終TypeScript noEmitと変更4ファイルlintも成功。ブラウザ画面の構造変更はなく、送信状態のhook契約を対象にした。

## 適用取消と旧挙動の復元（2026-11-05）

Apollo状態の読み取り修正、callback/公開型の強化と付随するswap guardを601d722親版へ戻した。
[復元結果](../evidence/scope-repair/fr014-attempt-1/result.md)はJest22 tests、変更3fileのlint・型検査、
4path旧byte一致/不存在、先行入力共通化・モード型・純抽出と利用者変更保持、diff checkが成功した。
loading/error取得の元の問題と過去の検証は保存し、解消済みとは数えない。

## 再適用（2026-11-06）

Apollo loading/errorとcallbackを既存callerに返し未選択guardを復帰。Jest 21 tests、型検査・lint成功。画面確認は人工fixtureで未選択0件、有効交換1件とpending→通常、人工失敗時pageerror 0と交換画面維持を確認。画面内エラー表示は観測されずconsoleにApolloError。内部error同一性とnull guardはunit検証。初回visualは観測不能な内部条件を要求しblocked、attempt 2で画面範囲をfresh確認。実DB未操作。
