# FR-013 手間保持の検証

request: `scope-repair-fr013-retain-1`、attempt: 1、status: passed。

- 指定Jest: 13 suites、68 tests成功。復帰specはID 17の表示、変更なし・名前変更で17送信、明示解除・位置づけ変更でnull送信を検証する。
- 指定RSpec: 2 examples、0 failures。
- `yarn tsc --noEmit`、指定frontend lintは終了コード0。backend RuboCopは2 files、0 offenses。
- `fb59312`で変更されたapplication 10 pathの実file blob hashは同commitと全て一致。未追跡の2 specも実fileを比較した。
- `cdb8e27`以降のbackend production差分を確認。FR-012の2 mutationは省略引数の既定値のみ変更し、pattern entryの3 fileは入力変換の抽出、FR-013の1 fileは出力field追加。FR-002〜012の認可・引数修正を保持する。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。
- `git diff --check` 成功。UI目視は別依頼で扱う。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
