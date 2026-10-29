# FR-031: 認証テストhelperの再ログイン分岐が存在しない引数を送る

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
- 振る舞い維持の適用枠: 対象
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューには独立項目として記載されていなかった観点。

## 対象

- [backend/spec/graphql/graphql_auth_helper.rb](../../../../../backend/spec/graphql/graphql_auth_helper.rb)
- [backend/app/graphql/backend_schema.rb](../../../../../backend/app/graphql/backend_schema.rb)

## 問題と根拠

既存LoginUserを検知するとloginUserLoginへuserid引数を送るが、そのmutationにはuseridが定義されていない。1つのexampleでfetch_mutation_with_authを2回呼ぶとGraphQL validationで失敗することを今回の検証で実測した。現在の多くのspecはexampleごとに登録から始めるため通り、複数操作・複数ユーザー検証を追加するとhelperが障害になる。

## 改善案

既存ログインには実schemaの引数だけを使い、ユーザー選択はfixture/login identityに対応させる。複数要求では一度発行したheadersを再利用するhelperも用意する。

## 振る舞いを維持する条件

アプリケーションの公開動作を維持して実施できる。移動・テスト補助の修正と、入力契約や業務挙動の変更を混ぜない。

## 検証方法と確認結果

同じexample内の連続2要求とA/B別identityの要求を検証する。今回の再現probeではheaders再利用に変更して本来のレビュー対象を確認した。

追加検証で問題の現行挙動を再現した。テスト成功は修正済みを意味しない。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用
