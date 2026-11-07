# CR-004 MySQL並行検証

## 接続と分離

既存の`compose.dev.local.yml`の`nanitabe-dev`プロジェクトへ、[mysql-regression.compose.yml](mysql-regression.compose.yml)のDBサービスだけを一時追加した。backend/frontendは既存コンテナを使い、DBのhost portは公開していない。MySQL 8.0.46/InnoDB、データはtmpfs、認証値はこのfixture専用。実環境の設定値をコピーしていない。host kernelではmem_limitが未対応との警告が出たため、memory上限を適用できたとは扱わない。

backendのDATABASE_URLは一コマンドのenvだけへ渡した。schema load前にadapter/host/databaseと`SELECT DATABASE()`を照合した。spec helperもURL/RAILS_ENVをRails起動前に、実効adapter/host/databaseをRSpecの自動schema検査前に検査する。fixture以外のlocalhost URLはSystemExitで拒否され、Rails/DB操作へ進まないことも実測した。通常SQLite回帰へMySQL用pending/skipを混ぜないよう、専用specは`backend/spec_mysql/`に置く。

## 再実行

以下はrepository rootで実行する。schema loadは破棄可能な専用DBだけへ行う。実測時は同内容のoverrideを`/tmp/nanitabe-concurrency.compose.yml`として使い、終了時のcleanupはtracked fixtureを使った。

```bash
docker compose -f compose.dev.local.yml -f .steering/2026/202610/20261030-exhaustive-review/evidence/mysql-regression.compose.yml --profile regression up -d mysql-regression

# DBの初期化が済んでから実行する。PROCESSはこの一時serverのfixture userだけへ付与。
docker compose -f compose.dev.local.yml -f .steering/2026/202610/20261030-exhaustive-review/evidence/mysql-regression.compose.yml --profile regression exec -T mysql-regression mysql --host=127.0.0.1 --user=root --password=regression-root-only -e "GRANT PROCESS ON *.* TO 'regression'@'%'"

docker compose -f compose.dev.local.yml exec -T backend env RAILS_ENV=test DATABASE_URL=mysql2://regression:regression-test-only@mysql-regression:3306/nanitabe_concurrency_test bundle exec rails runner '
  config = ActiveRecord::Base.connection_db_config.configuration_hash
  abort "unexpected regression database" unless config.values_at(:adapter, :host, :database) == ["mysql2", "mysql-regression", "nanitabe_concurrency_test"]
  abort "unexpected database session" unless ActiveRecord::Base.connection.select_value("SELECT DATABASE()") == "nanitabe_concurrency_test"
  load Rails.root.join("db/schema.rb")
'

docker compose -f compose.dev.local.yml exec -T backend env RAILS_ENV=test DATABASE_URL=mysql2://regression:regression-test-only@mysql-regression:3306/nanitabe_concurrency_test bundle exec rspec spec_mysql/meal_conversion_concurrency_spec.rb

# 完了後はこのDBサービスだけを除去する。プロジェクト全体のdownは行わない。
docker compose -f compose.dev.local.yml -f .steering/2026/202610/20261030-exhaustive-review/evidence/mysql-regression.compose.yml --profile regression rm --stop --force --volumes mysql-regression
```

## 実行経路と結果（2026-11-02）

2本の独立したAR接続から、それぞれ実GraphQL contextとresolverを作り、確定/延期を同時進行させた。元モデルのdestroy!直前だけthread-localのbarrierで止め、実際のdestroy!は実行する。先行が到達した後に後続を開始し、後続の同barrier到達またはInnoDBのLOCK WAITを確認してから先行commitを解放する。SQL文字列やelapsed timeだけを成功判定に使わない。

| 方向 | 修正前 | 修正後 |
| --- | --- | --- |
| 延期→確定 | 2接続が削除直前へ到達、成功2、作成先2でred | LOCK WAIT、成功1/不存在RuntimeError1、作成先1、元行なし |
| 通常食事→延期 | 2接続が削除直前へ到達、成功2、作成先2でred | LOCK WAIT、成功1/不存在RuntimeError1、作成先1、元行なし、元枠は未割当 |

MySQL専用2 examplesは最終成功。dish_id/meal_type/commentの引継ぎも確認した。通常のSQLite関連39 examplesも成功し、逐次再送、他人ID、作成失敗、削除後の例外による作成先/元行/枠割当のrollback、直接Removeの本人scopeを含む。変更6ファイルRuboCop成功。

観測側の20ms連続pollはINNODB_TRXの古いsnapshotを更新不能にし、最初の修正後実行では観測timeoutになった。[MySQL 8.0.46公式ソース](https://github.com/mysql/mysql-server/blob/mysql-8.0.46/storage/innobase/trx/trx0i_s.cc#L710-L726)は最後のreadから100ms超のidleを更新条件にしており、[read終了時にlast_readを更新する](https://github.com/mysql/mysql-server/blob/mysql-8.0.46/storage/innobase/trx/trx0i_s.cc#L912-L917)。pollを200msへ変更した後、両方向で実LOCK WAITを観測した。待ち時間を満たしただけでは成功にしていない。lock timeout/deadlockも期待する不存在拒否の代用にしていない。

専用DBでFR-019のMySQL補完検証も行った後、一時serviceとデータを除去した。既存backend/frontendはそれぞれ42時間/21時間の継続稼働を確認した。実DBへのmigration、実AWS/Webhook操作は行っていない。
