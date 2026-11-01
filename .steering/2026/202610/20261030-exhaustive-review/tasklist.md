# Tasklist: CR-001〜004の適用

設計の正本は[design.md](design.md)。各指摘は固定IDを維持し、完了状態は本tasklist、詳細な根拠・実測は各finding/applicationに記録する。利用者の全指摘反映・継続・commit/push/PR更新許可を適用し、開始確認を重ねない。各指摘は関連テストと変更箇所lintを成功させ、記録と独立commitまで完了して次へ進む。

## CR-001: 別タグへ分かれた検索語を料理単位でAND検索する

**DoD**: 別タグ・同タグ・料理名/出典との分散で全語に一致する料理が1件返り、一語不足・別料理分散を除外する。既存の本人先頭固定・位置づけ・食事有無・並び順を維持し、この指摘だけを検証・コミットする。

- [x] `backend/spec/domain/business/food/dish/usecase/dish_searcher_spec.rb`へ上記の検索回帰を追加し、現行の別タグケースの失敗を確認する。
- [x] `DishSearcher`の語ごとのOR条件に相関タグEXISTSを使い、元のrelationとbind変数を維持する。
- [x] 新規回帰と`backend/spec/graphql/query/dish/existing_dishes_for_registering_with_meal_spec.rb`を既存開発backendで実行しgreenを確認する。変更箇所RuboCopを成功させる。
- [x] findingへ現行成立確認・修正・red/green/lintを記録し、applicationへ適用範囲・検証・残りを追記する。文書変更にdocument-reviewを適用する。
- [x] CR-001だけを固定ID入りmessageでコミットし、commit SHAをapplicationの次の追記へ記録する。利用者由来3ファイルをstageしない。

## CR-002: 既存タグIDの内容・正規化値を保存する

**依存**: CR-001の検証・記録・コミット完了。コード上の共通基盤依存はないが、1指摘ずつの進行順を維持する。

**DoD**: IDを変えずcontent/normalized_contentを保存する。追加・削除との混在でも成立し、他人・本人別料理・不在のタグIDを拒否する。タグ途中失敗でも料理・出典・タグの部分保存がない。

- [x] `backend/spec/models/dish_tag_spec.rb`と`backend/spec/graphql/mutation/dish/update_dish_spec.rb`へ同IDの内容変更・再取得、追加削除混在、所有/所属拒否を追加しredを確認する。後段タグ保存失敗で料理名・出典関連も不変となる回帰をモデルまたはCommandのspecへ追加する。
- [x] `DishTag.replace_tags_of_dish`の早期returnを除き、全入力の所有/所属/必須値確認後、既存と新規Rootを保存する。`persist_from_root`の既存ID取得を同じdish_id/user_idへ限定する。
- [x] `DishTag`の置換と`Dish.persist_from_food_dish_root`全体をそれぞれtransactionへ入れ、直接呼出でもrollbackを保証する。
- [x] 変更前baselineと構造・契約ledgerを固定し、`ReflectLatestNormalizeWordCommand`を`dish_root.tags`自身の再正規化→料理保存での一回保存へ適応する。全料理・ログ・例外wrap・辞書CRUDとのatomicityを維持し、古い正規化値へ戻る既存失敗specをgreenにする。
- [x] タグ置換入力が空の場合だけ認可用の料理再読を省き、既存タグ削除とRelation返却を維持する。入力ありの所有・所属拒否を維持し、辞書反映の既存performance specの60 query未満を満たす。
- [x] タグモデル・料理の作成/更新Command・GraphQL作成/更新・辞書再反映の関連specを実行し、既存の新規ID設定/Relation返却もgreenにする。変更RubyファイルのRuboCopを成功させる。
- [x] finding/applicationへ結果を記録しdocument-review後、CR-002だけを独立commitする。前指摘のSHAも追記する。

## CR-003: 関連料理の詳細を壊す出典種別変更を拒否する

**依存**: CR-002の検証・記録・コミット完了。

**DoD**: 関連料理がある異なるtype値への変更を、legacy先行保存を含む全現行入口で拒否する。出典・料理・ページ/URL/メモが不変で、同種rename/comment・未関連type変更・既存認可を維持する。

- [x] `backend/spec/graphql/mutation/dish/source/type_change_boundaries_spec.rb`にmodel・旧/現行Command・実GraphQLの共通シナリオをまとめ、ページ42の保持・rename同時拒否・同種変更成功・未関連変更成功を追加しredを確認する。YouTube→Webの関連あり変更も拒否する。
- [x] 純粋な`Business::Food::Dish::Source::Policy::TypeChangePolicy`を追加する。`DishSource`の更新validationから旧/new typeと関連有無を渡し、拒否時に設計どおりのtypeエラーを追加する。
- [x] GraphQLの既存legacy/food両呼出を維持して旧/現行/モデル/GraphQLの関連specをgreenにし、変更箇所RuboCopを成功させる。拒否後の料理再取得と再保存でも旧詳細を保持することを確認する。
- [x] finding/applicationへ現行の先行保存問題と検証結果を記録し、document-review後、CR-003だけを独立commitする。

## CR-004: 相互変換で元レコードを一回だけ消費する

**依存**: CR-003の検証・記録・コミット完了。MySQL試験の接続guardを満たすこと。

**DoD**: 確定・延期の両方向で同時2要求の成功1件/既存不存在拒否1件/作成先1件/元行なしをMySQL二接続で実測する。通常の所有者拒否・逐次再送・途中失敗rollback・枠解除を維持し、試験後に一時DBだけを除去する。

- [x] `backend/spec/graphql/mutation/meal/postponed/`へ両方向の逐次再送・他人/不在ID・作成/削除失敗rollbackの回帰を追加し、既存の枠解除と元属性の引継ぎを確認する。
- [x] 通常RSpecの探索対象外である`backend/spec_mysql/meal_conversion_concurrency_spec.rb`と同directoryの`mysql_spec_helper.rb`へMySQL専用の並行回帰を置く。標準のSQLite実行へpending/skipを混在させず、transactional fixtureを使わず、commit済みfixtureと独立二接続・開始barrier・有限待ちを用意する。各threadを別resolver/contextにし、元モデルのdestroy!直前だけをthread-local同期点で止め、元処理を実行する。先行到着後に後続を開始し、後続の削除直前到達またはINNODB_TRXのLOCK WAITを観測して順に解放する。観測用PROCESS権限は一時MySQLのfixture利用者だけへ付与する。固定sleepや両threadのロック取得完了待ちで同期しない。
- [x] 親担当が用意した既存開発Composeプロジェクト内の一時`mysql-regression`について、実行前にadapter=mysql2・host=mysql-regression・database=nanitabe_concurrency_test・RAILS_ENV=testのguardを確認する。schema loadもこの限定接続でのみ行い、接続値を実envから継承しない。設定・commandをevidenceに保存し、並行回帰の修正前再現をこの限定接続で確認する。
- [x] 確定resolverの最初の本人取得を`PostponedMeal.lock.find_by`、延期resolverを`Meal.lock.find_by`へ変更する。既存transactionを維持し、延期RemoveCommandも本人条件で元を取得する。
- [x] 通常の延期/確定/往復specと変更箇所RuboCopをgreenにする。限定DATABASE_URLを与えた既存backend内で`bundle exec rspec spec_mysql/meal_conversion_concurrency_spec.rb`を明示実行して両方向の並行要求を検証し、待機中に一方だけが元row lockを保持することと、解放後の一回消費を確認する。DB lock timeout/deadlockは成功に数えない。
- [x] fixtureを掃除し一時MySQLサービスだけを除去する。既存アプリコンテナと実環境DBを変更していないことを確認する。
- [x] finding/applicationへ接続方式・実コマンド・件数・例外・未確認を記録しdocument-review後、CR-004だけを独立commitする。環境障害なら未完了のまま停止理由を返す。

## 全体回帰と公開

**DoD**: CR変更の関連・全体検証の結果を区別して追跡でき、4指摘の適用commitと残るFR-001保留が既存PRから読める。実AWS・実DB・Webhookへの変更を行わない。

- [ ] 既存開発backend内で全RSpecと全RuboCop、既存開発frontend内で`yarn test --runInBand`と`yarn lint`を実行する。CR変更による失敗は修正して再実行し、baseline違反があれば範囲・理由を明示する。
- [ ] 各findingの完了根拠・4件のcommit SHA・application・coverageの実測/未実測を照合する。FR-001保留と利用者由来3ファイルの未commit状態を維持する。記録だけの追跡commitが必要なら実装の1指摘1commitと区別する。
- [ ] 実装で得た再発防止知識をdoc-enricher提案modeでreviewする。必要な既存README更新案だけ提示し、未承認の恒久docsを自動追加しない。
- [ ] 実際に作成したcommitと現在の非default branchを確認し、既存許可に従ってpush・既存PRの説明/検証結果を更新する。追加PR・merge・deployを行わない。
- [ ] 利用者へ適用ID・commit・検証結果・索引path・未確認範囲を返す。任意の手動確認で追加feedbackを受けた場合は実装reviewへ記録して必要な設計へ戻す。
