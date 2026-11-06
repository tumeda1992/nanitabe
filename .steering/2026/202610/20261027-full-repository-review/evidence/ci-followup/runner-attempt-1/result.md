# backend CI runner YAML検証

request: `ci-followup-runner-1`、attempt: 1、status: passed。

- backendコンテナのRuby Psychで2 workflowを順にparseし、いずれも終了コード0。一時copyは削除した。
- 両workflowのdiffは各1行の`runs-on: ubuntu-latest`から`ubuntu-24.04`への変更のみ。Ruby 3.3.8と他stepは維持される。
- indexは空、`git diff --check`成功。保護3 fileのSHA-256は保存hashと一致、Git追跡modeは全て100644でmode差分なし。初回OS modeの独立snapshotはない。

失敗・直接原因・根本原因候補はなし。GitHub上でのrunner実行結果はこの構文検査には含まれない。
