# FR-019: 1食事を複数枠へ割り当てられhas_one契約が破れる

- 優先度: P2
- 採否: 採用
- 対応状況: 完了（SQLite/MySQL検証済み。実DB migrationは未適用）
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [backend/app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb](../../../../../backend/app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb)
- [backend/app/models/meal.rb](../../../../../backend/app/models/meal.rb)
- [backend/db/schema.rb](../../../../../backend/db/schema.rb)

## 問題と根拠

FillWithMealCommandは対象枠へmeal_idを代入するだけ。meal_frame_entries.meal_idのindexもuniqueではない。一方Mealはhas_oneを宣言し、クエリとUIは単一mealFrameEntryIdを前提にする。2枠への連続割当で同じmeal_idを持つ行が2件できることを実測した。UIの候補除外だけでは古い画面や並行要求を防げない。

## 改善案

1食事1枠が契約なら既存重複を整理したうえでnullableなmeal_idにunique制約を置く。既存割当を移すのか拒否するのかをCommandで明示し、transactionで保証する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

同じ食事を2枠へ割り当てる逐次・並行要求、解除、削除を検証する。今回、逐次要求で重複作成を実測。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `01e5394`（実装）、`3dcad04`（MySQL補完）

## 適用結果（2026-11-01）

1食事1枠という合意済みdesignを適用。同一枠への再割当は許可し、別枠が利用中ならAssignMealPolicyが拒否する。Commandはtransaction内で食事、対象枠の順にrow lockして確認・保存する。最後の防壁としてnullable meal_idへunique indexを追加した。新index追加後に旧indexを削除するため、MySQLの外部キー用indexを一時的に失わない。

migrationは重複meal_idを検出したらデータもindexも変更せずMigrationErrorで停止する。既存データを任意に選んで解除しない。実環境へ適用する前に重複が見つかった場合、その割当を人が判断・整理してから再実行する。downは元の非unique indexを先に作ってからunique indexを外す。

修正前は追加4件中2件が失敗し、CommandとDBの両方で重複が成立することを確認した。修正後の関連103 examplesは成功。全体回帰で844 examples / 0 failures、変更5ファイルのRuboCop違反なし。既存の解除認可specは同じ食事を2枠へ置いていたため、他利用者が所有する別食事へfixtureを正し、拒否後の割当不変も検証した。

- `docker compose -f compose.dev.local.yml exec -T backend env RAILS_ENV=test bundle exec rails db:migrate`: test DBだけへ適用。続く同環境`rails db:schema:dump`でversionとunique indexのみ差分を確認。
- 同backendの`bundle exec rspec spec/domain/business/food/meal/frame spec/domain/business/food/meal/frame_entry spec/graphql/mutation/meal/frame_entry spec/migrations/ensure_one_frame_per_meal_spec.rb spec/domain/business/food/meal/usecase/frame_release_spec.rb`: 103 examples成功。
- 同backendの`bundle exec rspec`: 844 examples成功。
- 同backendの`bundle exec rubocop app/domain/business/food/meal/frame/entry/policy/assign_meal_policy.rb app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb spec/domain/business/food/meal/frame/entry/usecase/cardinality_spec.rb spec/migrations/ensure_one_frame_per_meal_spec.rb spec/graphql/mutation/meal/frame_entry/unassign_meal_from_frame_entry_spec.rb`: 違反なし。

migration specは独立した一時SQLite DBで重複時の停止・値の維持・up/down・複数NULLを検証した。barrierで独立2接続から同時INSERTし、1件成功/1件RecordNotUnique、最終1行を実測した。これはDB制約の並行検証であり、MySQL上のCommand並行要求・row lockの実測は未実施。実DBへのmigrationやデータ整理も今回の範囲外で実行していない。適用commitはapplication.mdとGit履歴で追跡する。

## MySQLでの補完検証（2026-11-02）

CR-004用の隔離MySQL8.0.46/InnoDBを再利用し、既存backendからfixture限定URLで追加4 examplesを実行して全成功した。

- nullable unique indexのdown/upを実行し、MySQLのmeal外部キーと複数NULL割当を保持する。
- unique導入前の重複をfixtureで作り、upがデータ/既存indexを変更せず停止する。fixture整理後の再upも成功。
- 独立二接続を開始barrierで同期し、同じmealへの2つのFill Commandは成功1・既存の重複拒否1・割当1件となる。
- Commandを迂回した同時DB書込みも成功1・RecordNotUnique1・割当1件となる。

specはbackend/spec_mysql/frame_assignment_spec.rb。RuboCopも成功。接続guard・setup/cleanupは[CR-004のMySQL evidence](../../20261030-exhaustive-review/evidence/cr004-mysql.md)と同じで、通常SQLite回帰へpendingを混ぜない。専用DBは全検証後に除去済み。開発/本番DBへmigrationを適用した結果ではない。これにより11月1日時点のMySQL検証保留を解消した。
