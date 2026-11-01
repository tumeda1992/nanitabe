# FR-018: 食事移動後も枠が旧日付の割当済み状態に残る

- 優先度: P2
- 採否: 採用
- 対応状況: 完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [backend/app/domain/business/food/meal/usecase/update_command.rb](../../../../../backend/app/domain/business/food/meal/usecase/update_command.rb)
- [backend/app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb](../../../../../backend/app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb)
- [backend/app/domain/business/food/meal/usecase/date_meals_finder.rb](../../../../../backend/app/domain/business/food/meal/usecase/date_meals_finder.rb)

## 問題と根拠

移動・日付交換はMealの日付だけを変更し、関連MealFrameEntryの日付や割当を変更しない。Finderは未割当枠だけを旧日へ出すため、旧日の枠は消え、移動先の食事には旧枠の名前が付く。ローカル検証で、移動後の旧日に枠も食事も返らずDBには割当済み枠が残ることを確認した。ドメイン文書の「枠は日付と時間帯に対する計画」と整合しない。

## 改善案

移動時に元の枠を解除するか、枠も移動するかの業務契約を決める。現行文書に従うなら元枠を解除して旧日に残す処理を同一transactionへ含める。時間帯変更と日付交換も同じ方針に揃える。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

割当済み食事の移動・時間帯変更・日付交換後に両日の一覧とDBを検証する。今回、単一食事の翌日移動を実測。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `25471fd`

## 適用結果（2026-11-01）

合意済みdesignの「枠は元の日付・時間帯に残す」契約を適用した。ReleaseFrameOnReschedulePolicyが保存前後のdate/meal_typeを比較し、Mealの保存境界で食事更新と全元枠のmeal_id解除を同一transactionにする。food側persistと旧Dish::Meal::Repository.updateから利用し、旧updateの戻値trueを維持した。新旧の交換Commandも両日の保存全体をtransactionへ含める。コメント・料理・同じ日時の更新では解除しない。

新旧それぞれの移動・時間帯変更・Finder出力・両日交換・解除失敗rollback・交換後半失敗rollbackを追加した。最初の実行に含まれた入力fixture不備を正した後、14 examples中12件が問題挙動で失敗するredを確認した。修正後の関連回帰は100 examples / 0 failures。

- `docker compose -f compose.dev.local.yml exec -T backend bundle exec rspec spec/domain/business/food/meal/usecase spec/domain/business/dish/meal spec/graphql/mutation/meal/ownership_spec.rb spec/graphql/mutation/meal/swap_meals_between_days_spec.rb`
- 同backendの`bundle exec rubocop app/models/meal.rb app/domain/business/food/meal/policy/release_frame_on_reschedule_policy.rb app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb app/domain/business/dish/meal/repository.rb app/domain/business/dish/meal/command/swap_meals_between_days_command.rb spec/domain/business/food/meal/usecase/frame_release_spec.rb`: 6 files / 違反なし。

DB検証はtest用SQLite。実DBの既存割当を移行・削除していない。適用commitはapplication.mdとGit履歴で追跡する。
