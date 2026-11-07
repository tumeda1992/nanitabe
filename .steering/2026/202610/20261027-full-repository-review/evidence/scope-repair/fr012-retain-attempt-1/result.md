# FR-012 省略可能引数の検証

request: `scope-repair-fr012-retain-1`、attempt: 1、status: passed。

- 指定RSpec: 19 examples、0 failures。復帰したspecの6例で、2 mutationそれぞれについて省略・null・有効値による更新と結果を確認した。
- 指定RuboCop: 3 files inspected、0 offenses。
- 指定3 pathのworktree blob hashは`ceb1da7`の各blobと一致。specは未追跡のため通常の`git diff`では削除と表示されるが、実fileを`git hash-object`で比較した。
- `cdb8e27`はHEADの祖先。そこから現在のbackend production差分は2 mutationの引数既定値とpattern entryの3 fileのみ。前者はcurrent user渡しを維持し、後者は3値の変換を共通methodに移してcurrent user渡しを維持するため、FR-002〜011の認可実装を保持する。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、worktree modeは全て644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。
- `git diff --check` は成功。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
