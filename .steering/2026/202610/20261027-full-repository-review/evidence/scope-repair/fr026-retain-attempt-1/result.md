# FR-026 plan IAMの検証

request: `scope-repair-fr026-retain-1`、attempt: 1、status: passed。

- offline Node policy test: 3 tests成功、0 failures。plan log書込み、state読取、lock操作を許し、state・apply log等への書込みを拒否する評価とroleへの接続を検証した。
- `terraform fmt -check infrastructure/terraform/modules/github_oidc/main.tf` は終了コード0。
- 指定2 pathの実file blob hashは`df42ad7`と一致。未追跡specも実fileを比較した。`infrastructure/README.md`の保存先は`plans/<root>/<run id>.txt`で一致する。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。`git diff --check`成功。
- AWSへのquery・applyは実施していない。実環境への反映には既存IAM更新のapplyが必要であり、現行AWS権限の状態はこのoffline検査では確認していない。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
