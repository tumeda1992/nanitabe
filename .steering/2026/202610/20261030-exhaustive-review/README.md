# nanitabe全体の再レビュー

対象: `eb0ab2cd68ee3c3c9882b816cb707c70b7226ea1`の作業tree（開始時clean）。未pushのFR-001 WIPも含む。直近差分だけには限定していない。

新規指摘4件（P2）。3件を隔離DockerのテストDBで再現、並行処理1件は静的確認。修正は実施していない。

- [CR-001: 複数タグに分かれた検索語をAND検索すると該当料理が消える](findings/CR-001-multi-tag-search.md)
- [CR-002: 既存タグID付きの内容変更を成功扱いで破棄する](findings/CR-002-existing-tag-content.md)
- [CR-003: 出典の種別変更が関連料理の詳細情報を不整合にする](findings/CR-003-source-type-details.md)
- [CR-004: 延期食事の同時確定で同じ食事を複数回作成できる](findings/CR-004-postponed-concurrent-consumption.md)

[確認範囲と限界](coverage.md)

既存FR-001〜030・032〜034は未対応のため重複登録をスキップした。FR-031は対応済みとして認証helperの状態を前回記録と照合。旧RVの未対応事項も重複候補から除いた。
