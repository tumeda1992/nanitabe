# RV-010: 枠割り当ての所有者確認が経路と関連IDによって抜ける

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/graphql/mutations/meal/frame_entry/fill_meal_frame_entry.rb; backend/app/graphql/mutations/meal/add_meal.rb; backend/app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb; backend/spec/graphql/mutation/meal/frame_entry/fill_meal_frame_entry_spec.rb
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

直接割り当てresolverは枠エントリ所有者を確認するがmeal_idの所有者を確認しない。食事登録3経路は同じCommandを直接呼び、frame_entry_id側の所有者確認も迂回する。CommandはRootへmeal_idを代入して保存するだけ。既存specの「meal_id belongs to another user」は他人の実在IDを渡さずmealId: 0を使うため、所有者検査の証拠にならない。

## 改善案

共通割り当て境界で枠と食事の両方を操作ユーザーで限定する。specでは本当に別ユーザーの食事を作ってそのIDを渡す。日付・時間帯の一致や多重割り当ての仕様は別に明文化する。

## 振る舞いを維持する条件

認可追加は対象外。日付・時間帯や多重割り当てまで一緒に修正すると別の仕様変更になるため混ぜない。

## 検証方法

本人枠＋他人食事、他人枠＋本人食事、食事新規登録＋他人枠を検証する。拒否時に新規料理・出典・食事がrollbackされることも確認する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
