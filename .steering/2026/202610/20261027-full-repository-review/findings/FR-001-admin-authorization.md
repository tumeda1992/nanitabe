# FR-001: 管理CRUDに認証・管理権限の確認がない

- 優先度: P1
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-022（現行コードで再確認）。

## 対象

- [backend/config/routes.rb](../../../../../backend/config/routes.rb)
- [backend/app/controllers/application_controller.rb](../../../../../backend/app/controllers/application_controller.rb)
- [backend/app/controllers/admin/food/dish/effort_level/dish_effort_levels_controller.rb](../../../../../backend/app/controllers/admin/food/dish/effort_level/dish_effort_levels_controller.rb)
- [backend/app/controllers/admin/food/dish/word/normalize_words_controller.rb](../../../../../backend/app/controllers/admin/food/dish/word/normalize_words_controller.rb)

## 問題と根拠

管理用URLが常時登録され、両controllerにも共通基底にも認証・管理者判定がない。SetUserByTokenのincludeはアクセス拒否の代わりにならない。未認証GETで手間レベル管理画面がHTTP 200になることをローカルrequest specで確認した。create/update/destroyにもガードがなく、全ユーザーに影響するマスタと正規化辞書を変更できるコード構造である。外部ネットワーク上の到達可否は別途未確認。

## 改善案

管理controller共通基底で認証と管理権限を検証する。GraphQL用Authorizationヘッダーに依存する現在のログインと、別タブで開く管理画面の認証方法を設計してから導入する。ネットワーク制限だけを認可の代替にしない。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

未認証・一般利用者・管理者のGET/POST/PATCH/DELETEをrequest specで比較し、拒否時にDBが変わらないことを確認する。今回は未認証GETの成功を実測。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
