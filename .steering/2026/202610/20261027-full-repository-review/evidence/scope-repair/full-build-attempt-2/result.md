# 隔離production build再検証

request: `scope-repair-full-build-2`、attempt: 2、status: passed。

`3d832f5`のfrontendをarchiveからコンテナ内一時directoryに展開し、既存node_modulesの実体copyと生成済CSSを配置した。準備前の`du -sk`は907844 KiB、`df -Pk /tmp`の空きは42421816 KiB。

指定の`NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 yarn next build`は終了コード0。Turbopack compile、TypeScript、19 static pages生成、最終最適化が成功した。Next.js出力の実行時間は749.68秒。常駐devの`.next`とsourceは変更していない。

今回作成したarchiveと隔離copyは削除した。HEADは`3d832f5`のまま。保護3 fileのSHA-256は保存hashと一致、Git追跡modeは全て100644、Git差分にmode変更なし。初回OS modeの独立snapshotはない。`git diff --check`成功。実DB、AWS、Webhookへの操作なし。attempt 1の失敗結果は保持した。
