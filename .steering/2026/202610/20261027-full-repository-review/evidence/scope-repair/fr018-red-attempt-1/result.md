# FR-018 transaction red検証

request: `scope-repair-fr018-red-1`、attempt: 1、status: passed（指定されたredの確認成功）。

指定RSpecは23 examples、2 failures、終了コード1。失敗は期待された新旧Command各1例のみで、他21例は成功した。

- `spec/domain/business/food/meal/usecase/swap_meals_between_days_command_spec.rb:331`
- `spec/domain/business/dish/meal/command/swap_meals_between_days_command_spec.rb:107`

両例とも2回目保存で例外を発生させた後の属性比較に失敗。先に保存したMealのdateが2023-02-01から2023-02-02へ変更されたままで、updated_atも変化していた。直接原因は先行実保存がrollbackされないこと。setupや例外注入失敗ではない。production未修正の状態でtransaction境界の欠落が根本原因候補である。

親は両Commandのtransaction修正後に同specを再実行できる。
