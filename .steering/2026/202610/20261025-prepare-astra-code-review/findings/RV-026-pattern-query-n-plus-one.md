# RV-026: パターン一覧が親・子ごとに追加SQLを発行する

- 観点: 保守性・性能・契約
- 優先度: 中
- 採否: 採用
- 対応状況: 完了
- 今回の適用対象: 対象
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/graphql/queries/meal/frame/pattern/meal_frame_patterns.rb; backend/app/graphql/types/output/meal/frame/pattern/meal_frame_pattern_for_list.rb: entries; meal_frame_pattern_entry_for_list.rb: meal_frame_name
- 依存する指摘: なし

## 問題と根拠

一覧queryで親だけを読み、各親のentries resolverで子を問い合わせ、さらに各子のmeal_frame_nameでMealFrame.find_byする。P個のパターンとE個のエントリなら通常1+P+E回のSELECTになる。frontendは一覧queryでentriesとmealFrameNameまで取得しており、この経路を通常使用する。

## 改善案

親→entries→meal_frameをまとめてpreloadし、出力resolverは取得済みの関連を参照する。または導入済みGraphQL::DataloaderでID別にbatch化する。

## 振る舞いを維持する条件

応答フィールド、親子の並び、空entries、枠が見つからないときの空文字を維持する。query数削減のみを狙い、ページング導入は含めない。同時更新下の読み取りタイミング差が問題になるなら適用前に契約を確認する。

## 検証方法

既存meal_frame_patterns_spec.rbで応答を比較し、複数パターン・同じ枠を共有する多数entriesでquery数が件数に比例して増えないことを確認する。

## 採否・対応記録

- 2026-10-26: ユーザーの適用指示により採用・実装済み。
- 検証: GraphQL Dataloaderでパターンentriesと枠名をbatch取得。追加SQL数テストは変更前13 SELECTで失敗、変更後3 SELECTで成功。順序・空一覧・他ユーザー除外・欠落枠空文字とpattern mutationを含むRSpec: 12 examples, 0 failures。
- 適用コミット: 本ファイルの完了記録と同じコミット（git logで参照可能）
