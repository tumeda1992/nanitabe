# FR-032: パターン作成・編集で入力schemaが重複している

- 優先度: P3
- 採否: 採用（全件適用の合意）
- 対応状況: 適用・関連自動検証完了
- 振る舞い維持の適用枠: 対象
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [frontend/src/features/meal/frame/pattern/addMealFramePatternMutation.ts](../../../../../frontend/src/features/meal/frame/pattern/addMealFramePatternMutation.ts)
- [frontend/src/features/meal/frame/pattern/updateMealFramePatternMutation.ts](../../../../../frontend/src/features/meal/frame/pattern/updateMealFramePatternMutation.ts)

## 問題と根拠

フォームは共通化されたが、mealFramePatternEntrySchemaとname/entriesの定義は二重に残る。必須条件やdayOffsetの検証を変更すると作成と編集が異なる入力を許す状態になりやすい。共通項目と更新専用idは明確に分離できる。

## 改善案

同ディレクトリのschema.tsへ共通entryとpattern本体を切り出し、更新用はextend({id})で構築する。mutation operationとrefetch設定は各ファイルへ残す。

## 振る舞いを維持する条件

アプリケーションの公開動作を維持して実施できる。移動・テスト補助の修正と、入力契約や業務挙動の変更を混ぜない。

## 検証方法と確認結果

移動前後でparse結果・エラーメッセージ・推論型を維持し、作成/編集フォーム既存specと型検査を実行する。新しいバリデーション追加は別変更とする。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用

## 適用結果（2026-11-02）

schema.tsをentry/body/create/update schemaの正本にし、mutation側は型とhookのbindingを参照する。numberの許容範囲、日本語error、unknown keyのstrip、配列順序・空配列、作成id不要/更新id必須を保持した。更新用はidを先頭にしたobjectへ共通bodyをmergeし、errorのid→name→entries順も維持する。

移行前11件のcharacterization、移行後関連33 tests、最終schema13件、型検査、変更4ファイルlintが成功。表示・markup変更はなく、schemaに新しいvalidationを追加していない。baselineと全contract照合は[evidence/fr032-migration.md](../evidence/fr032-migration.md)。commitはapplication.mdとGit履歴で追跡する。
