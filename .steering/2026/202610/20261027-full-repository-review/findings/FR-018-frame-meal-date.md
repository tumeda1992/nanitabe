# FR-018: 食事移動後も枠が旧日付の割当済み状態に残る

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
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

- ユーザー判断: 未判断
- 適用コミット: 未適用
