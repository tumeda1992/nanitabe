# FR-029 deploy HTTP errorの検証

request: `scope-repair-fr029-retain-1`、attempt: 1、status: passed。

- loopback HTTP test: 6 tests成功、0 failures。実workflowのcurlをlocalhost fixtureへ向け、200=0、401/404/500=22、timeout=28と各1 requestを確認。timeout fixtureのみ総期限を0.2秒へ短縮し、productionの接続10秒・総計30秒とretryなしを別途確認した。
- workflowをPyYAMLで構文解析できた。`actionlint`は環境に存在せず、GitHub Actions固有lintは実行していない。
- 指定2 pathの実file blob hashは`d3e4515`と一致。未追跡specも実fileを比較した。workflow差分はcurl optionの追加に限定される。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。`git diff --check`成功。
- 実Webhook、AWSへの接続は行っていない。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
