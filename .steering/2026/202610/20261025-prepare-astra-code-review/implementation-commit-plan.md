# レビュー適用差分のコミット計画

- 作成日: 2026-10-27（Asia/Tokyo）
- repository / branch: `tumeda1992/nanitabe` / `feature-287`
- 比較元: 現在のHEAD `fca18590d70244fba5e5a994d0413510834099b5`
- 既存のレビュー記録コミットは変更しない。この計画は、その後の未コミット差分を対象とする。
- 計画作成時のstaged差分はなし。tracked変更とuntrackedの本文・呼出元・テストを確認した。
- 手順: [plan-commits](https://github.com/tumeda1992/ai_agent_dev_skill_plugin/blob/main/plugins/tumeda-dev/skills/plan-commits/SKILL.md)。今回は計画のみ。stage・commit・pushは行わない。

## コミット前に解消する事項

最新の最終検証は、backendが568 examples / 0 failures、frontendが214成功 / 1失敗、型検査が成功。
以前のfrontend全215件成功の後、型検査用fixture補完によって期待値の不整合が1件生じた。現時点を全成功とは扱わない。

失敗箇所は `frontend/src/components/dish/DishForm/EditDish.spec/editDishWithUpdatingTag.spec.tsx` の「既存タグを削除し新規タグを追加」ケース。
fixtureの `existingTag2` へ追加した `dishId` が、同じオブジェクトを再利用する送信payload期待値へ混入した。
入力fixtureには所有料理のIDを保持し、送信期待値は `{ id: existingTag2.id, content: existingTag2.content }` として契約を明示する。
アプリケーション側へ不要な `dishId` を送る修正は行わない。これは下記2の仕事に含め、当該spec・全Jest・型検査の成功後にコミット可能とする。

変更コードのESLintとRuby 20ファイルのRuboCopは成功済み。ただし最後に補完したfixture 3ファイルのlint結果は未取得なので追加確認が必要。
索引の「全件未判断」「実行検証未実施」と実装記録の整合、チェックリストの環境・最終検証欄、再発防止文書の提案も最後に更新する。

## 分割方針

**全11コミット。** 9件の独立した変更（レビュー8件と既存fixture補完1件）に、事前の方針記録・事後の全体検証記録をそれぞれ付ける。
各修正は実装・呼出元・テスト・対応findingの結果を同じコミットに閉じる。単独の共通化基盤だけを先に入れたり、全呼出元を後へ送ったりしない。
8件の修正同士に実行時の依存はない。順序は既存の適用順を基本とし、型検査を通すfixture補完を前へ置く。
すべて意味単位で分割する。実装した時系列だけによる分割はない。

### 1. レビュー適用の範囲と検証方針を記録する

- 仕事: 対象8件・挙動維持条件・項目ごとの検証方針を、実装差分より前に参照できる状態にする。
- 対象: この `implementation-commit-plan.md`、`design.md`、`tasklist.md` の開始版。READMEにはこの計画へのリンクだけを追加する。
- 取り消す効果: 今回の適用計画が履歴から外れる。既存レビュー29件は残る。
- 依存・制約: tasklist開始版は全項目未チェックへ再構成する。現在のチェック済み状態を実装前の完了記録として保存しない。これは既存コミットの改変ではなく、未コミットファイルのstage版の分割である。

### 2. 料理と食事のテストデータを型定義に揃える

- 仕事: 既存specの不足属性5エラーを解消し、全体型検査を実行できるようにする。
- 対象:
  - `frontend/src/components/calendar/calendarComponents/MealCard/index.spec.tsx`: `mealFrameEntryId` の既定値。
  - `frontend/src/components/dish/DishForm/EditDish.spec/editDishSourceOfDishRelatedToSource.spec.tsx`: 出典relationの `dishId` と `type`。
  - `frontend/src/components/dish/DishForm/EditDish.spec/editDishWithUpdatingTag.spec.tsx`: タグfixtureの `dishId` と、入力から分離した送信期待値。
- 取り消す効果: テストデータ補完が外れ、従来の型エラーが戻る。アプリケーションの動作と各リファクタリングは残る。
- 依存・制約: 実装8件とは独立した既存テストの整備。RV-015へ混ぜない。前述の1失敗を修正してから保存する。

### 3. foodの責務境界と枠エントリの設計説明を現行構成に揃える（RV-025）

- 仕事: 設計入口から開発標準と同じ責務境界・現行namespaceへ到達できるようにする。
- 対象: `backend/app/domain/business/food/README.md` と `findings/RV-025-conflicting-domain-orchestration-docs.md`。
- 取り消す効果: 設計文書の訂正だけが戻る。アプリコードは変わらない。
- 依存・制約: 正本の開発標準と現行 `Meal::Frame::Entry` は既存のまま参照する。

### 4. カレンダーモードを定義済み文字列に限定する（RV-015）

- 仕事: 未定義のモードを型検査で拒否し、既存のモード切替・Escape操作を維持する。
- 対象: `frontend/src/components/calendar/calendarComponents/` の `calendarMode.ts`、`useCalendarMode.ts`、`useCalendarMode.spec.ts` と、`operationComponents/` 配下の `useAssignDishMode.ts`、`useMoveMealMode.ts`、`useSwapMealsMode.ts`、`usePostponedMealMode.ts`。対応findingも含める。
- 取り消す効果: literal型・共有setter型・その検証が外れる。他の入力変換やフォーム変更は残る。
- 依存・制約: 定数と旧import先の再export、全hookの利用を同時に含める。非同期の待機方法を変更しない。全体型検査の成功には2のfixture補完が必要だが、実行時依存はない。

### 5. 正規化辞書の登録と更新で保存属性の生成を共有する（RV-014）

- 仕事: 入力と正規化済み値の生成を同じ仕様で行えるようにする。
- 対象: `backend/app/domain/business/food/dish/word/usecase/` の `normalize_word_attributes.rb`、`add_command.rb`、`update_command.rb` と、対応する `add_command_spec.rb`、`update_command_spec.rb`。対応findingも含める。
- 取り消す効果: 生成helperと両呼出元が従来実装へ戻る。GraphQLやfrontendの共通化は残る。
- 依存・制約: create / update!、正規化の順序と全料理への反映を一緒に維持する。helperだけを別コミットにしない。

### 6. GraphQLの料理出典・タグ入力変換を共有する（RV-013）

- 仕事: 複数の登録・更新経路が同じ出典relation・タグ変換を利用できるようにする。
- 対象:
  - `backend/app/graphql/mutations/dish/food_dish_input.rb`。
  - 同ディレクトリの `add_dish.rb`、`add_dish_with_new_source.rb`、`update_dish.rb`、`update_dish_with_new_source.rb`。
  - `backend/app/graphql/mutations/meal/` の `add_meal_with_new_dish.rb`、`add_meal_with_new_dish_and_new_source.rb`、`update_meal_with_new_dish.rb`、`update_meal_with_new_dish_and_new_source.rb`。
  - `backend/spec/graphql/mutations/dish/food_dish_input_spec.rb` と対応finding。
- 取り消す効果: adapter・全利用先・専用specが一緒に戻る。Command側の辞書変換やfrontend変換は残る。
- 依存・制約: transactionと集約間orchestrationは各resolverに残す。新規出典IDの受渡しも同じコミットへ含める。

### 7. frontendの料理登録・食事登録更新で出典入力変換を共有する（RV-001）

- 仕事: 既存/新規出典の入力変換を各操作から一貫して利用できるようにする。
- 対象: `frontend/src/features/dish/` の `normalizeFunctions.ts`、`addDishMutation.ts`、`updateDishMutation.ts`、`dishInputConversion.spec.ts` と、`frontend/src/features/meal/` の `addMealMutation.ts`、`updateMealMutation.ts`。対応findingも含める。
- 取り消す効果: 抽出した関数と呼出元が従来実装へ戻る。backendのadapterは残る。
- 依存・制約: 入力の非破壊性、余剰payload、既存出典の料理更新の別構造を維持する。4や6への実依存はない。

### 8. 週・月カレンダーでURL日付の解釈を共有する（RV-029）

- 仕事: URL日付とfallbackの契約を1箇所で維持できるようにする。
- 対象: `frontend/src/features/calendar/calendarDateFromPath.ts`、`calendarDateFromPath.spec.ts`、`frontend/src/app/calendar/week/[date]/page.tsx`、`frontend/src/app/calendar/month/[date]/page.tsx` と対応finding。
- 取り消す効果: 共通パーサー・両ページの利用・専用specが一緒に戻る。カレンダーのモード型は残る。
- 依存・制約: 09:00、query付きURLのfallback、形式のみの検査を維持し、日付検証の改善を混ぜない。

### 9. パターンの作成・編集で入力フォームを共有する（RV-012）

- 仕事: 初期値・送信APIの違いをwrapperに残し、共通の入力操作と検証を使えるようにする。
- 対象: `frontend/src/components/meal/frame/pattern/` の `MealFramePatternFields.tsx`、`MealFramePatternForm.tsx`、`MealFramePatternEditForm.tsx`、`MealFramePatternEditor.spec.tsx` と対応finding。
- 取り消す効果: 共通フォームと利用wrapperが従来実装へ戻る。一覧取得のbatch化は残せる。
- 依存・制約: DOM、ラベル、日削除時の番号、payload、成功callbackを一体で検証する。10との実依存はない。

### 10. パターン一覧のエントリと枠名をまとめて取得する（RV-026）

- 仕事: パターン・エントリ数に比例するSQLを、同じGraphQL応答を維持してbatch化する。
- 対象: `backend/app/graphql/sources/meal_frame_pattern_entries.rb`、`meal_frames.rb`、`backend/app/graphql/types/output/meal/frame/pattern/` の `meal_frame_pattern_for_list.rb`、`meal_frame_pattern_entry_for_list.rb`、`backend/spec/graphql/query/meal/frame/pattern/meal_frame_patterns_spec.rb` と対応finding。
- 取り消す効果: loader・resolverの利用・SQL数検査が従来実装へ戻る。パターンフォームの共通化は残る。
- 依存・制約: 既存SchemaのGraphQL::Dataloaderを使用する。新loaderと利用先は同時に保存する。順序・欠落枠の空文字・ユーザー限定を維持する。

### 11. 適用結果と再発防止の文書更新案を記録する

- 仕事: 読み手が適用済み8件・残り21件・最新の検証結果・追加文書案を判別できるようにする。
- 対象: READMEの現在状態・引継ぎ、coverage.mdへの実装検証記録の案内、implementation_review.mdの全体結果、tasklist.mdの最終検証欄。再発防止案は `documentation-proposal.md` として追加予定（現時点で未作成）。
- 取り消す効果: 全体の適用結果の案内と予防文書案が外れる。各実装とfinding単位の結果は残る。
- 依存・制約: 2〜10の検証完了後に確定する。未来の検証成功を先に書かない。予防規約そのものの標準文書への適用は、このコミットには含めない。

## 共有記録の分割方法

- `implementation_review.md` は、3〜10の対応コミットで該当RVの節だけを追加する。2のfixture補完結果も2で記録する。全体結果は11に置く。
- `tasklist.md` は1で未チェックの開始版を置き、3〜10で各項目の結果だけを反映する。環境確認と全体検証の最終結果は11で反映する。
- 対応findingの採否・完了・検証記録を、実装を含む3〜10から11へ追い出さない。共有ファイルの段階的なstage版の再構成が必要である。
- これらは各仕事を辿るための記録であり、独立した修正を一括で取り消す境界にはしない。

## 実行時の確認

現在の全体差分では各項目のテストを実行済みだが、分割した各中間コミットの再構成・テスト・revert試験は未実施。
実行時は各中間版で該当テストと差分の空白・リンクを確認する。最後にJest全件、backendのfood domain/GraphQL回帰、型検査と変更ファイルlintを成功させる。
テスト依存やignoredなnode_modules、テストDB、/tmpの実行設定・ログはコミットに含めない。
既存履歴のamend・rebaseやforce pushは、この計画に含めない。
