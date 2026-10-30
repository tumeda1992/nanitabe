# RV-009: 検索の先頭固定料理だけユーザー条件を迂回する

- 観点: 契約・正しさ・運用
- 優先度: 高
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: backend/app/domain/business/food/dish/usecase/dish_searcher.rb: fetch; backend/app/graphql/queries/dish/existing_dishes_for_registering_with_meal.rb: resolve
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

通常結果はDish.for_user(access_user_id)で限定するが、dish_id_registered_with_mealはDish.where(id:)で別取得し、先頭へ連結する。入力はGraphQLの任意Intとしてクライアントが指定できるため、別ユーザーの料理名・コメント・出典等を返す経路がある。

## 改善案

先頭固定料理も同じfor_userスコープから取得する。所有する料理について、検索条件に合わなくても先頭へ出す既存仕様は維持する。

## 振る舞いを維持する条件

情報の返却範囲が変わるため対象外。

## 検証方法

別ユーザーの料理IDを指定し応答に混ざらないこと、本人の料理が条件不一致でも先頭へ出て重複しないことをdish_searcher_spec.rbとquery specで確認する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
