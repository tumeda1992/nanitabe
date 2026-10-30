# FR-010: 他人の枠を自分のパターンへ登録して枠名を読める

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [backend/app/domain/business/food/meal/frame/pattern/entry/usecase/add_command.rb](../../../../../backend/app/domain/business/food/meal/frame/pattern/entry/usecase/add_command.rb)
- [backend/app/domain/business/food/meal/frame/entry/usecase/add_command.rb](../../../../../backend/app/domain/business/food/meal/frame/entry/usecase/add_command.rb)
- [backend/app/graphql/sources/meal_frames.rb](../../../../../backend/app/graphql/sources/meal_frames.rb)

## 問題と根拠

子エントリの作成はmeal_frame_idの存在に依存し、親のユーザーと枠のユーザーの一致を検証しない。AがBの枠IDで自分のパターンを作成し、一覧からBの枠名を取得できることをGraphQLで実測した。枠の更新削除認可とは別の問題。単独枠エントリ作成にも同じ関連付け欠落がある。

## 改善案

パターン/枠エントリ作成時に関連枠が本人のものかを検証する。読み出し側でも不正関連を表示しない方針を決める。loaderだけを修正して不正な関連をDBへ残さない。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

Aの親とBの枠の組合せを登録・更新・適用・単独枠登録で検証する。今回、パターン登録と名前取得を実測。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
