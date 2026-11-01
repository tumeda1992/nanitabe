# CR指摘の適用記録

## 適用合意と実行条件

利用者の全review指摘反映・継続指示によりCR-001〜004を反映する。[design](design.md)と[tasklist](tasklist.md)に従い、関連green・記録・1指摘1commitで進める。設計commitは`486811d`、FR-034のcommitは`fcac860`。FR-001保留と利用者由来の未commit3ファイルを維持する。実DB・AWS・Webhookは操作せず、既存開発Composeのアプリコンテナを使う。レビュー担当Astraと今回の適用担当は区別する。

## CR-001の適用完了（2026-11-02）

タグ条件を語ごとの相関EXISTSへ変更し、別タグAND検索を修正した。新規7件のうち本指摘の1件のred後、検索/GraphQL関連36 examples / 0 failures、変更2ファイルRuboCop成功。次はCR-002の既存タグ内容保存へ進む。

## CR-002の適用完了（2026-11-02）

既存タグ内容/正規化をID保持で保存し、全入力の所有/所属を検証、料理・出典関連・タグの全保存を原子的にした。辞書反映callerの古いRoot上書きも適応し、7 contractの移行台帳を照合した。新規10件のred後、関連204 examples、backend全体902 examples、性能基準、変更5ファイルlint成功。CR-001のcommitは`ddfef5a`。次はCR-003の関連出典の種別変更拒否へ進む。
