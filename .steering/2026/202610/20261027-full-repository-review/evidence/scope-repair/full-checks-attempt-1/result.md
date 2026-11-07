# 全体test・static check

request: `scope-repair-full-checks-1`、attempt: 1、status: passed（指定された全検査の実測・既存offense分類を完了）。検査対象HEADは`3d832f5`。

- backend全RSpec: **874 examples、0 failures**、終了コード0。
- frontend全Jest: **46 suites、278 tests成功**、終了コード0。成功suite中にMSW未登録handler、Apollo fixture不足、React DOM属性のconsole警告が出力された。
- backend全RuboCop: **481 files、2 offenses**、終了コード1。いずれも`app/controllers/admin/base_controller.rb`の9行・10行、`Style/FetchEnvVar`。同fileの履歴上の最終変更は保留中FR-001 WIPの`d58c473`で、今回の復帰作業による新規offenseではない。その他のoffenseは出力されなかった。
- frontend全ESLint: 終了コード0、offense出力なし。
- frontend `yarn tsc --noEmit --incremental false`: 終了コード0。
- 最終時点で保護3 fileのSHA-256は保存hashと一致。Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。`git diff --check`成功。

RSpec/Jestの失敗はない。全RuboCop自体は既存2 offenseにより失敗しており、成功とは扱わない。親は既存FR-001保留を維持したうえで結果を消費できる。
