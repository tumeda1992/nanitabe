# RV-025: 集約をまたぐ処理の配置について設計文書が矛盾する

- 観点: 保守性・責務・型
- 優先度: 中
- 採否: 採用
- 対応状況: 完了
- 今回の適用対象: 対象
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/domain/business/food/README.md: モジュール外への公開エンドポイント; backend/docs/ai_guideline/development_standard/application_architecture.md: レイヤードアーキテクチャ; backend/app/domain/business/food/meal/README.md
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

開発標準は「異なる集約をまたぐオーケストレーションはプレゼンテーション層」とするが、food/READMEは「businessと同階層のapplicationで行う」と記す。またfood/READMEの一覧にはFrameEntryが残り、meal/READMEはFrame::Entryを正本としている。新規実装時に読む入口によって異なる配置へ誘導される。

## 改善案

開発標準と現行resolverの構造を基準に、food/READMEの該当箇所を更新し、詳細規約は正本へリンクする。Frame::Entryを現行として記し、旧FrameEntryの残存は互換/移行事項として明示する。

## 振る舞いを維持する条件

文書だけを更新するため実行時挙動は維持される。旧実装の削除や移動はRV-016の調査後に別途判断する。

## 検証方法

文書の相互リンクと現行mutationの配置を照合し、food/READMEとmeal/READMEから同じ正本へ到達できることを確認する。

## 採否・対応記録

- 2026-10-26: ユーザーの適用指示により採用・実装済み。
- 検証: food/READMEの責務境界・現行namespaceを統一。相対リンク検査成功。docker exec -e RAILS_ENV=test nanitabe-review-tests-backend-1 bundle exec rspec spec/domain/business/food/meal/usecase/add_command_spec.rb: 8 examples, 0 failures。
- 適用コミット: 本ファイルの完了記録と同じコミット（git logで参照可能）
