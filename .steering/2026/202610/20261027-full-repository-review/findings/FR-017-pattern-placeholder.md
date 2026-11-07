# FR-017: パターンの枠を未選択へ戻すとNaNを送信する

- 優先度: P2
- 採否: 採用
- 対応状況: 再適用・検証完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [frontend/src/components/meal/frame/pattern/MealFramePatternFields.tsx](../../../../../frontend/src/components/meal/frame/pattern/MealFramePatternFields.tsx)

## 問題と根拠

placeholderのvalueがundefinedのためDOM上の値は表示文字列「--」になる。選択後に戻すとNumber("--")がNaNとなるが、検証は== nullのみなので通過する。ローカルJestでsubmitへNaNが渡ることを確認した。JSON化時はnullとなりGraphQLの必須Intに違反する。初期nullだけを検証する既存テストでは見落とす。

## 改善案

placeholderをvalue=""にし、空値をnullへ明示変換する。selectのvalueもnull時は空文字に固定し、送信直前に有限整数を検証する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

作成・編集双方で「有効枠を選択→--へ戻す→送信」を実行し、APIを呼ばずエラーが出ることを確認する。今回のNaN送信はevidence/frontend-probes.spec.tsxで実測。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `62359ad`

## 適用検証（2026-11-01）

全件適用の利用者指示に基づき採用した。placeholderを空文字に固定し、空値をnullへ戻す。送信前にも正の整数であることを検証する。作成・編集の「選択済みから--へ戻す」追加2件は修正前に失敗し、API呼出しを止められないことを再確認した。修正後は関連3 suites / 15 tests成功、NaN/Infinity/0/負数/小数の境界値を加えたeditor単独13 testsも成功。

- `docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand --silent MealFramePattern`
- 同frontendの`yarn test --runInBand --silent MealFramePatternEditor.spec`
- 同frontendの`yarn tsc --noEmit --incremental false`: 成功。
- 同frontendの`yarn lint src/components/meal/frame/pattern/MealFramePatternFields.tsx src/components/meal/frame/pattern/MealFramePatternEditor.spec.tsx`: 違反なし。

ブラウザ確認はrequests/fr017-visual.jsonから追跡する。

ブラウザも全GraphQLを人工fixtureでmockし、作成・編集の各エラー/再選択の4項目が成功。未選択はmutation0回、再選択後は数値IDで各1回を確認した。visual-inspectorが6画像を目視済み。結果は`requests/fr017-visual-result.json`、実DB保存はmock対象のため未確認。適用commitはapplication.mdと本指摘のGit履歴で追跡する。

## 適用取消と旧挙動の復元（2026-11-05）

未選択のnull化と整数/正数の追加拒否を62359ad親版のフォームへ戻し、追加拒否期待を除いた。
[復元結果](../evidence/scope-repair/fr017-attempt-1/result.md)はJest19 tests、変更2fileのlint・tsc、旧form/spec byte一致が成功した。
保持する共有schemaはd58c473の元作成/更新schemaと120ケースでsuccess/data/issuesの順序まで一致し、変更不要だった。
NaN/Infinity/0/負数/少数/null/undefined/空文字/空配列/unknown keyを含め、FR-017の整数/正数拒否を共有schemaに温存していない。
純抽出6fileと利用者変更保持、diff check成功。元の未選択入力問題と過去の検証は保存し、解消済みとは数えない。

## 再適用（2026-11-06）

未選択を既存の必須入力エラーへ戻し無効IDを送らない。Jest 20 tests、型検査・lint成功。人工fixtureの画面で作成/編集とも未選択mutation 0件、再選択で数値ID1を1回送信。エラーは再選択直後も残り送信時処理。実DB永続化は未検証。
