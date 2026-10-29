# FR-017: パターンの枠を未選択へ戻すとNaNを送信する

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
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

- ユーザー判断: 未判断
- 適用コミット: 未適用
