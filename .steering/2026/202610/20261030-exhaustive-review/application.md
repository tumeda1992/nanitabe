# CR指摘の適用記録

## 適用合意と実行条件

利用者の全review指摘反映・継続指示によりCR-001〜004を反映する。[design](design.md)と[tasklist](tasklist.md)に従い、関連green・記録・1指摘1commitで進める。設計commitは`486811d`、FR-034のcommitは`fcac860`。FR-001保留と利用者由来の未commit3ファイルを維持する。実DB・AWS・Webhookは操作せず、既存開発Composeのアプリコンテナを使う。レビュー担当Astraと今回の適用担当は区別する。

## CR-001の適用完了（2026-11-02）

タグ条件を語ごとの相関EXISTSへ変更し、別タグAND検索を修正した。新規7件のうち本指摘の1件のred後、検索/GraphQL関連36 examples / 0 failures、変更2ファイルRuboCop成功。次はCR-002の既存タグ内容保存へ進む。

## CR-002の適用完了（2026-11-02）

既存タグ内容/正規化をID保持で保存し、全入力の所有/所属を検証、料理・出典関連・タグの全保存を原子的にした。辞書反映callerの古いRoot上書きも適応し、7 contractの移行台帳を照合した。新規10件のred後、関連204 examples、backend全体902 examples、性能基準、変更5ファイルlint成功。CR-001のcommitは`ddfef5a`。次はCR-003の関連出典の種別変更拒否へ進む。

## CR-003の適用完了（2026-11-02）

関連料理ありの出典type変更を共通モデルvalidationと純粋Policyで拒否し、先行legacy保存も覆った。4経路20件でred12件後、関連158 examplesと変更4ファイルRuboCop成功。既存HTTP 422の拒否応答と複数料理の詳細不変も確認した。CR-002のcommitは`30c86bb`。次はCR-004の相互変換一回消費とMySQL並行検証へ進む。

## CR-004の適用完了（2026-11-02）

相互変換の冒頭で本人の元行をlockし、延期Removeも本人scopeに揃えた。MySQL8.0.46二接続で両方向の旧2件作成を再現後、実LOCK WAIT/成功1/不存在拒否1/作成先1を確認した。専用2 examplesと通常関連39 examples、変更6ファイルlint成功。接続guard・setup・cache由来の観測timeoutと解消根拠はevidence/cr004-mysql.mdへ記録。一時DBは削除済み、既存アプリは継続稼働。CR-003のcommitは`45074dc`。次は全体回帰・索引/PR更新・公開を完了する。

## 全体回帰からのCR-003補完（2026-11-02）

最初の全体936件で旧Repository specのtype変更成功期待だけが合意契約と衝突したため、拒否/不変の期待へ更新し、合法なURL詳細更新の回帰を残した。関連26 examplesとlint成功。実装本体の追加変更はない。経緯はimplementation_review.md。CR-004のcommitは`02e2caf`。frontend全体47 suites / 283 testsは成功済み。

## 最終対応表（2026-11-02）

| 指摘 | 実装commit | 補完 |
| --- | --- | --- |
| [CR-001](findings/CR-001-multi-tag-search.md) | `ddfef5a` | — |
| [CR-002](findings/CR-002-existing-tag-content.md) | `30c86bb` | — |
| [CR-003](findings/CR-003-source-type-details.md) | `45074dc` | `852718f`（旧spec契約の補完） |
| [CR-004](findings/CR-004-postponed-concurrent-consumption.md) | `02e2caf` | — |


## 全体検証への参照（2026-11-02）

backend937件、frontend283件、MySQL6件、運用系68件が成功。最終Next production build・型検査・lintの条件と、保留FR-001の既存lint2件を含む限界は[coverageの最終検証](../20261027-full-repository-review/coverage.md#最終検証2026-11-02)を正本とする。

CR-003のspec補完は`852718f`、FR-019のMySQL補完は`3dcad04`。公開済み。feature-287のpushとPR #292の説明更新を完了し、GitHubのhead一致を確認した。[公開結果](../20261027-full-repository-review/application.md#公開結果2026-11-02)を正本とする。
