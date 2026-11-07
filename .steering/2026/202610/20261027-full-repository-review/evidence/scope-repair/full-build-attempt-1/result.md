# 隔離production build検証

request: `scope-repair-full-build-1`、attempt: 1、status: failed。

`3d832f5`のfrontendをarchiveからコンテナ内一時directoryに展開し、指定された既存node_modules symlinkと生成済CSSを用いて`NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 yarn next build`を実行した。buildは終了コード1。Turbopackが`Symlink [project]/node_modules is invalid, it points out of the filesystem root`と報告し、最適化build開始時に停止した。直接原因は指定の隔離copy外を指す依存symlinkがTurbopackのfilesystem root制限に拒否されたこと。application sourceのbuild成否はこの実行では判定できない。

再検証には依存を隔離copyのfilesystem root内に置く方法を用意し、新しいrequestで実行することを推奨する。今回作成したarchive、隔離copy、panic logは削除した。常駐devの`.next`とsourceは変更していない。

HEADは`3d832f5`のまま。保護3 fileのSHA-256は保存hashと一致し、Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。`git diff --check`成功。実DB、AWS、Webhookへの操作なし。
