# CR-001 複数タグAND検索の検証

request: `scope-repair-cr001-retain-1`、attempt: 1、status: passed。

- 指定RSpec: 43 examples、0 failures。同一料理の別タグによるAND検索、別料理・他人タグを組み合わせない例とGraphQL検索認可を含む。
- 指定RuboCop: 2 files inspected、0 offenses。
- 指定2 pathの実file blob hashは`ddfef5a`と一致。検索差分は各語の条件を料理に紐づくタグのEXISTSへ変更し、FR-007の所有者絞り込みを変更していない。
- 保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。`git diff --check`成功。

失敗test、直接原因、根本原因候補はなし。親は実測結果をtasklistのDoD判定に使用できる。
