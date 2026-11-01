# FR-033: パターンのGraphQL子入力変換が作成・更新に重複する

- 優先度: P3
- 採否: 採用（全件適用の合意）
- 対応状況: 適用・関連自動検証完了
- 振る舞い維持の適用枠: 対象
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [backend/app/graphql/mutations/meal/frame/pattern/add_meal_frame_pattern.rb](../../../../../backend/app/graphql/mutations/meal/frame/pattern/add_meal_frame_pattern.rb)
- [backend/app/graphql/mutations/meal/frame/pattern/update_meal_frame_pattern.rb](../../../../../backend/app/graphql/mutations/meal/frame/pattern/update_meal_frame_pattern.rb)
- [backend/app/graphql/types/input/meal/frame/pattern/meal_frame_pattern_entry_input.rb](../../../../../backend/app/graphql/types/input/meal/frame/pattern/meal_frame_pattern_entry_input.rb)

## 問題と根拠

両resolverが同じentries.mapでday_offset/meal_type/meal_frame_idを転記している。子入力の追加や名称変更で二箇所の転記を同期させる必要がある。既存の料理入力変換と同じく、入力境界に閉じた共通責務である。

## 改善案

子InputObjectにCommand引数への変換を置くか、pattern専用の入力adapterへ抽出する。認可・transaction・作成更新のCommand選択はresolver/Commandの責務として保持する。

## 振る舞いを維持する条件

アプリケーションの公開動作を維持して実施できる。移動・テスト補助の修正と、入力契約や業務挙動の変更を混ぜない。

## 検証方法と確認結果

空配列と複数entryについて値・順序を維持し、作成/更新のGraphQL specを実行する。認可追加と同時変更しない。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `65dc499`

## 適用結果（2026-11-02）

MealFramePatternEntryInput#to_command_paramsへ3項目の転記を移し、両resolverはentries.mapで参照する。認可actor・更新対象・Command・transaction・返却値は保持した。独立hash、空配列、複数entryの値と順序の回帰を追加し、関連37 examples / 0 failures、変更6ファイルRuboCop成功。移行台帳は[evidence/fr033-migration.md](../evidence/fr033-migration.md)。commitはapplication.mdとGit履歴で追跡する。
