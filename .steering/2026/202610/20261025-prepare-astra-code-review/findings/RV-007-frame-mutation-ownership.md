# RV-007: 枠マスタ更新・削除と枠エントリ削除に所有者確認がない

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/domain/business/food/meal/frame/usecase/update_command.rb; remove_command.rb; frame/entry/usecase/remove_command.rb; backend/app/graphql/mutations/meal/frame_entry/remove_meal_frame_entry.rb
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

枠マスタはIDだけでRootを取得・削除し、枠エントリもfind(id).destroy!で削除する。user_idの存在検証はあるが対象の所有者を確認しない。既存のFillMealFrameEntryとUnassignMealFromFrameEntryのresolverでは所有者条件があり、削除経路には同じ制約がない。

## 改善案

更新・削除対象を操作ユーザーで絞る。枠マスタの参照エントリ存在チェックも、所有する枠の取得後に行う。

## 振る舞いを維持する条件

拒否対象が増えるため今回対象外。削除時の関連チェックの文言や順序を不用意に変更しない。

## 検証方法

他人の未使用枠・エントリで更新・削除を試し、DBが不変であることと、本人の操作・参照中の削除拒否を確認する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
