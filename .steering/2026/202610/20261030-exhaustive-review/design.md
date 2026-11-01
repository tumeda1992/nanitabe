# Design: CR-001〜004の適用

## 元の依頼内容と適用合意

利用者の「.steering/2026/202610 の*-review系…レビュー指摘後の反映をしていって」と、継続・コミット・push・PR更新の既存許可を引き継ぐ。[先行applicationの適用範囲](../20261027-full-repository-review/application.md#ローカルでの再開2026-11-01)でCR-001〜004も対象とした。各findingの「レビューのみ・未合意」はレビュー作成時点の記録であり、この後続指示によって適用へ進む。findingの過去の根拠・固定IDは維持する。

作業directoryは既存の`20261030-exhaustive-review`を再利用する。設計開始HEADは`fcac8606dddbb578b9c0bed5f38c580492a7e79e`。レビュー担当Astraと今回の設計・適用担当を区別する。適用前の通常作業treeには利用者由来の`.gitignore`、`frontend/Dockerfile`、`frontend/src/lib/generateApiOrigin.ts`の変更があり、今回の差分・コミットへ含めない。FR-001の明示保留は継続する。

## 要点

複数語検索は料理単位でANDを取り、別々のタグに分かれた語も拾う。既存タグIDの内容変更はIDを保持して保存する。関連料理のある出典の種別変更は、料理の詳細を暗黙に破棄せず拒否する。延期食事と通常食事の相互変換は、元レコードをtransaction冒頭で行ロックして一回だけ消費する。

4指摘は既存の本番アプリケーションの修正であり、1本のtasklistで独立して実装・検証できる。CR-001、CR-002、CR-003、CR-004の順で、各指摘をgreen・記録・1コミットまで完了して次へ進む。対象を一括コミットしない。

## 完成後の姿

### 保存値・検索結果・状態遷移

| 指摘 | 操作前と操作 | 完成後に観測する結果 |
| --- | --- | --- |
| CR-001 | 料理Aにタグ`alpha`と`beta`を別々に登録し、`alpha beta`で検索 | Aが1件返る。各語は料理名・出典名・その料理のいずれかのタグへ別々に一致してよい |
| CR-001 | Aに`alpha`だけ、別料理Bに`beta`だけを登録し、同じ検索をする | A/Bとも通常の検索結果に含めない。別料理のタグを横断して条件を満たさない |
| CR-002 | タグID=10、content=`alpha`をID=10、content=`ぶた`へ変更 | ID・user_id・dish_idを維持し、content=`ぶた`、normalized_content=`ブタ`へ保存する。辞書がある場合は既存Normalizerの結果を使う |
| CR-002 | 既存IDの更新と新規タグ追加、既存タグ削除を一度に送信 | 入力に残した既存IDは内容を保存、新規は新しいIDを発番、省略した既存IDは削除する |
| CR-003 | 本の出典にページ42を持つ料理を関連付け、出典をWebへ変更 | 出典のtype/name/comment、料理、関連詳細がすべて不変で、変更拒否を返す。同時に送ったrenameだけを部分保存しない |
| CR-003 | 同じtypeのrename/comment変更、または関連料理のない出典のtype変更 | 従来どおり保存できる。関連料理がある場合はYouTube→Webなど詳細形式が同じ変更もtype値が異なれば拒否する |
| CR-004 | 同じ延期食事IDへ同時に2件の確定要求 | 通常食事は1件だけ作成、元の延期食事は1回だけ削除。後続要求は既存の不存在エラーで拒否する |
| CR-004 | 同じ通常食事IDへ同時に2件の延期要求 | 延期食事は1件だけ作成、元の通常食事は1回だけ削除。元枠は従来どおり日時を保って未割当に戻る |

検索の先頭固定料理はFR-007適用後の本人スコープを維持する。先頭固定料理が通常条件に一致しなくても先頭へ置く契約、位置づけ・食事登録有無のフィルタ、既存の並び順、重複排除、検索前正規化を変更しない。既存LIKEのワイルドカード解釈を今回の検索修正で追加変更しない。

タグの内容更新は、タグを別料理へ移す操作ではない。本人の別料理のタグID、他人のタグID、不在タグIDを含む置換は失敗とし、対象料理・出典関連・既存タグ・追加候補タグを部分保存しない。入力IDの順序が同じでも内容更新を省略しない。

### 呼出元が依存する契約

GraphQLのoperation名・引数・成功payload・生成schemaは既存のまま使う。新規のAPIやDBカラム・index・恒久的な環境変数を追加しない。

- `existingDishesForRegisteringWithMeal`は、各検索語の条件をANDで結び、1語内の一致先をORで結ぶ。
- `updateDish`等から届く`dishTags`の既存IDとcontentを保存契約どおり扱う。既存タグ更新の失敗は呼出元へ例外を伝播し、GraphQLの既存transactionで失敗応答になる。
- `updateSource`の関連ありtype変更は、`ActiveRecord::RecordInvalid`と`type`のエラー「料理が関連付けられているレシピ元の種別は変更できません。」で拒否する。不存在・所有者拒否など今回変えないエラー契約を維持する。
- `schedulePostponedMeal`の二回目・不在・他人IDは「指定した延期された食事は存在しません。」、`postponeMeal`は「指定した食事は存在しません。」という既存の例外契約を維持する。成功した要求は既存の作成先IDを返す。
- 相互変換の作成・元レコード削除・関連枠解除は同じtransactionに属し、途中の例外を握らず全体をrollbackする。冪等キーや自動再試行は今回追加しない。一回消費という修正に必要な行ロックを使う。

### 責務配置と具体的な変更

#### CR-001: 語ごとの相関タグ検索

`backend/app/domain/business/food/dish/usecase/dish_searcher.rb`の語ごとの絞込みを変更する。1語について次のORを作り、その条件を既存relationへ追加する。

```text
COALESCE(dishes.normalized_name, dishes.name) LIKE :pattern
OR dish_sources.name LIKE :pattern
OR EXISTS (
  SELECT 1 FROM dish_tags AS matching_tags
  WHERE matching_tags.dish_id = dishes.id
    AND COALESCE(matching_tags.normalized_content, matching_tags.content) LIKE :pattern
)
```

`:pattern`は既存と同じ`%検索語%`をbindする。ユーザー入力をSQL文字列へ補間しない。既存のLEFT JOIN、preload、検索結果の構築は残し、タグ条件だけをJOINの単一行から料理に相関したEXISTSへ移す。これにより同一タグ・別タグ・料理名とタグ・出典名とタグのいずれも扱える。

#### CR-002: 既存タグの内容を保存

`backend/app/models/dish_tag.rb`の`replace_tags_of_dish`で、全入力の所有・所属を確認してから変更する。対象料理のuser_idと各Rootのuser_idを一致させ、既存IDは同じdish_idとuser_idのレコードから取得する。不在・異なる料理・異なる所有者は`ActiveRecord::RecordNotFound`で拒否する。Rootの必須値検証も変更前に行う。

ID配列一致だけの早期returnを除き、新規・既存の両Rootを既存の`persist_from_root`／`persist_from_food_dish_root`で保存する。既存contentとnormalized_contentはRootのContent値から保存する。新規IDをRootへ設定する既存契約と、置換後のRelationを返す契約は維持する。`persist_from_root`も既存IDを`id/dish_id/user_id`で絞り、別経路からの所属迂回を防ぐ。

タグ置換単体はtransactionに入れる。さらに`backend/app/models/dish.rb`の`persist_from_food_dish_root`全体もtransactionに入れ、料理保存→出典関連→タグ置換を一体にする。GraphQL以外のCommand・モデル直接呼出でも、タグ拒否・途中保存失敗で料理名等だけが残らない。辞書再反映の既存transactionとは通常のnested transactionとして合流する。

#### CR-003: 共通保存境界で種別変更を拒否

`backend/app/domain/business/food/dish/source/policy/type_change_policy.rb`に`Business::Food::Dish::Source::Policy::TypeChangePolicy.allowed?`を置く。入力は`current_type:`、`requested_type:`、`has_related_dishes:`、戻り値はbooleanとし、同一typeまたは関連なしなら許可する。PolicyにDB問い合わせや保存・GraphQL応答処理を持たせない。

`backend/app/models/dish_source.rb`は更新validationで保存前のtypeと要求typeを比較し、`DishSourceRelation.where(dish_source_id: id).exists?`をPolicyへ渡す。新規レコードには適用しない。拒否時は前述のtypeエラーを追加して`save!`／`update!`を失敗させる。

この位置を選ぶ理由は、`backend/app/graphql/mutations/dish/source/update_source.rb`が旧`Business::Dish::Dish::Source::Command::UpdateCommand`で先に保存し、現行`Business::Food::Dish::Source::Usecase::UpdateCommand`で再保存するためである。現行Commandだけへ変更前後比較を置くと、先行保存でtype差分が消え拒否を迂回する。旧・現行両経路を共通validationで覆い、今回は二重呼出を削除しない。通常rename・未関連type変更も両経路で検証する。

#### CR-004: 元レコードをロックして一回消費

`backend/app/graphql/mutations/meal/postponed/schedule_postponed_meal.rb`は既存transactionの最初の取得を`PostponedMeal.lock.find_by(id: ..., user_id: ...)`へ変更する。ロックを取得した本人のレコードからだけ通常食事を作り、元を削除する。後続要求は先行commit後のロック取得で行がないと判定され、作成を行わない。

逆方向の`backend/app/graphql/mutations/meal/postponed/postpone_meal.rb`も`Meal.lock.find_by(id: ..., user_id: ...)`をtransactionの最初に行う。既に読み込んだレコードへ後から`with_lock`する形や、transaction外の存在検査を一回消費の根拠にしない。

`Business::Food::Meal::Postponed::Usecase::RemoveCommand`の元レコード取得にもuser_idを含め、通常食事側と同じ本人条件を維持する。元レコードの読み取り・作成・削除を別transactionへ分割しない。延期と確定の別入口を包む新しい巨大Commandは作らない。

### 実行条件と未実測の扱い

通常回帰は既存の`compose.dev.local.yml`のbackendで実行する。`config/database.yml`のtestは既存SQLite設定で、今回書き換えない。Cloud向けの追加アプリComposeや重複アプリコンテナは作らない。

通常の逐次・所有者拒否・rollbackの回帰は`backend/spec/graphql/mutation/meal/postponed/`へ置く。MySQL専用の並行回帰は`backend/spec_mysql/meal_conversion_concurrency_spec.rb`、接続guard・同期・fixtureの補助は同directoryの`mysql_spec_helper.rb`へ置く。`spec_mysql/`は通常RSpecの探索対象外とし、標準のSQLite実行へMySQL用pending/skipを混在させない。MySQL profileは限定した`DATABASE_URL`を与え、既存backend内で`bundle exec rspec spec_mysql/meal_conversion_concurrency_spec.rb`を明示実行する。

CR-004の行ロックはMySQLで検証する。親担当が既存開発Composeプロジェクト内へ一時追加した`mysql-regression`サービスを使い、host portを公開せず、tmpfs・fixture認証だけで動かす。アプリは既存backendのままで、`DATABASE_URL`を一コマンドだけ上書きする。接続先はfixtureの`mysql-regression`、databaseは`nanitabe_concurrency_test`に固定し、adapter・host・database・`RAILS_ENV=test`を実行前に確認する。fixtureの接続値を実環境設定からコピーしない。

専用DBへのschema loadと検証はこの限定接続でだけ行う。接続guardに不一致があればDDL・データ作成前に停止する。並行検証終了後は一時DBサービスだけを除去し、既存backend/frontendと実環境DBを維持する。追加する一時設定fileと実コマンド・終了結果は適用担当がevidence/applicationへ記録する。

設計担当はアプリ修正・テスト・MySQL操作を実施していない。親から既存backend全体885件成功と、一時MySQL 8.0.46の起動・専用DBへのschema load・既存backendからの一コマンドURL指定・adapter/host/databaseの二重guard成功の報告を受領した。設計担当自身の実測ではなく、CR修正後の成功を示すものでもない。CR-004のMySQL並行結果は未実測であり、SQLiteの逐次成功で代替しない。

## 要件と受け入れ基準

**MUST**: CR-001〜004の具体的な結果を回帰テストで保証する。各指摘について現物確認→失敗再現→実装→関連テスト・lint成功→記録→固定ID付き1コミットの順を守る。既存未対応と誤指摘を区別し、撤回の場合も理由を独立記録する。

**MUST**: CR-004はMySQLの独立した二接続で相互変換両方向の一回消費を実測する。成功1件・既存エラーによる拒否1件・作成先1件・元行なしを確認する。意図的なlock timeout・deadlock・SQLite Busy例外だけを「重複拒否成功」と数えない。

**MUST**: 実DB・AWS・Webhookへの変更を行わない。個別コミット後に必要な全体回帰を行い、許可済みの既存branch/PRへpush・内容更新する。実装側でfinding/applicationの現行状態を更新し、過去レビューの実測と今回の修正結果を混ぜない。

**非目標**: 新規UI・operation・冪等キー、出典詳細の自動変換・破棄、恒久的なDB方式変更。元の指摘を直す最小契約として今回は行わない。将来これらの利用者操作を新たに要求された場合は、その操作とデータ移行を別途設計する。FR-001は既存の利用者保留に従い本tasklistへ入れず、保留解除時に先行レビューで再開する。

## リスクと対策

| リスク | 対策 |
| --- | --- |
| タグのJOIN条件をEXISTSへ変えて先頭固定や他フィルタを失う | 既存relationを保持し、新旧検索specとGraphQL query specを実行する |
| 既存タグの更新を新たに有効にして他料理のタグを変更する | 全入力のid/dish_id/user_idを確認し、保存境界とGraphQLの両方で拒否・rollbackを検証する |
| 出典の先行legacy保存がtype検査を迂回する | 共通モデルvalidationへ置き、実GraphQL・旧Command・現行Commandを検証する |
| 並行テストが実際には1接続で動く | poolから独立二接続を借り、transaction外にcommit済みfixtureを作り、開始barrierで同期する |
| MySQLの再現テストが実DBへ接続する | fixture接続guardをschema load前とspec開始時に確認し、危険なfallbackを設けない |

## テスト方針

通常の受付コマンドは`docker compose -f compose.dev.local.yml exec -T backend bundle exec rspec <対象spec>`、変更箇所lintは同じbackend内の`bundle exec rubocop <変更Rubyファイル>`とする。全体回帰は同じbackend内の`bundle exec rspec`と`bundle exec rubocop`、frontendは`docker compose -f compose.dev.local.yml exec -T frontend yarn test --runInBand`と`yarn lint`。既知のbaseline違反は今回差分と区別して結果を記録し、CR変更で導入した失敗を残して完了としない。

CR-001は別タグ・同タグ・料理名/出典との分散・別料理分散・一語不足・同一料理1件・本人先頭固定を検証する。CR-002はID維持の内容/正規化更新、追加削除混在、他人/本人別料理/不在ID拒否、後段失敗rollbackを検証する。CR-003はページ42を持つ関連料理で種別変更の拒否と全属性不変、同種rename成功、関連なしtype変更成功を旧/現行/GraphQLで検証する。

CR-004は逐次再送・所有者拒否・作成失敗/削除失敗rollback・枠解除の通常RSpecに加え、MySQLで独立二接続から実resolverを呼ぶ。元モデルの`destroy!`直前だけthread-local同期点で止め、元の`destroy!`自体は実行する。先行要求が削除直前へ到達してから後続要求を開始し、「後続も削除直前へ到達」または「MySQLの`INNODB_TRX`で後続の`LOCK WAIT`を確認」のいずれかまで待つ。旧実装では両要求が削除直前へ進めるため、順に解放して作成先2件を再現する。修正後は後続が冒頭の行ロックで待ち、先行commit後に不存在拒否となって作成先1件になる。SQL文字列一致や固定sleepを同期の根拠にしない。

観測用の`PROCESS`権限はこの一時MySQLサーバのfixture利用者へだけ付与する。実環境の権限を変更しない。各threadは別resolver/contextを使い、request specの共有responseを並列で使い回さない。同期・ロック観測・thread終了には上限を置き、fixture掃除と待機解放をensureで行う。環境不足は未完了として記録し、並行性の検証済みとは書かない。

## （付録）前提とする既存仕様

- `DishSearcher`は本人のrelation、LEFT JOIN、preload、distinctと並び順を構成後、語ごとに絞る。タグだけがJOINの1行へ全語一致を要求している。
- `DishTag.replace_tags_of_dish`はID配列が同一なら早期returnし、異なる場合も新規タグだけを保存する。既存Rootは変更後Contentを持つため保存漏れが起きる。
- `DishSourceRelation`はtype別のページ・URL・メモ列を使い、`set_value`が他形式の列を消す。型変更を暗黙受理すると詳細の不可視化・消失へつながる。
- 延期/確定resolverにはtransactionが既にあるが、元レコードをロックせず取得している。transactionだけでは二要求の一回消費を保証しない。
- 既存の公開条件は`.agents/skills/tumeda-dev-plugin-context.md`のtask-design Git/GitHub条件を参照する。既存許可によるcommit/push/PR更新を実施し、merge・deployは行わない。

## （付録）変更の実行区分

### task-design内で対象成果物へ適用済み

なし。今回作成した設計・tasklist自体をアプリケーション修正として数えない。

### task-design内の対象成果物反映待ち

なし。MySQLでの実行結果は実装の受け入れ検証に属し、未実測を設計判断の代わりに使わない。

### execution plan対象

| 対象 | 掲載理由 | 参照するdesign section |
| --- | --- | --- |
| CR-001の検索実装修正と回帰 | 本番アプリケーションcoding | CR-001: 語ごとの相関タグ検索 |
| CR-002のタグ保存・認可・原子性と回帰 | 本番アプリケーションcoding | CR-002: 既存タグの内容を保存 |
| CR-003のtype変更拒否と回帰 | 本番アプリケーションcoding | CR-003: 共通保存境界で種別変更を拒否 |
| CR-004の一回消費とMySQL検証 | 本番アプリケーションcodingと独立した並行受け入れ検証 | CR-004: 元レコードをロックして一回消費 |
| 個別/全体検証・適用記録・公開 | 上記成果物のacceptanceと既存の公開許可 | 要件と受け入れ基準 |
