# RV-016: 枠エントリの旧namespace実装と新実装が併存している

- 観点: 契約・正しさ・運用
- 優先度: 中
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 要調査
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/domain/business/food/meal/frame_entry/; backend/app/domain/business/food/meal/frame/entry/; backend/spec/domain/business/food/meal/frame_entry/; backend/app/models/meal_frame_entry.rb
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

FrameEntryとFrame::EntryにRoot・追加・削除・割り当てCommandの重複が残る。現行resolverとモデルのRoot復元はFrame::Entryを使う一方、旧namespaceを直接テストするspecが残る。片方だけを修正しても片方のテストが緑になるため、保守対象を見誤りやすい。旧Business::Dish全体は評価など現役の参照があり、一括削除は不適切。

## 改善案

このFrameEntry旧namespaceだけについて全参照を棚卸しし、新側へ有効なspecを移す。外部や動的参照がないことを確認して旧実装を削除する。必要なら互換入口を残すが、Rootのclass identity変化を確認する。

## 振る舞いを維持する条件

定数名や返却classは観測可能なので、参照検索だけで安全な削除と断定しない。調査完了までは自動適用しない。

## 検証方法

Rails eager load、旧新specのシナリオ差分、全GraphQL枠操作、動的constantize参照を確認する。新側だけで同じ操作が保証されることを検証する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
