# nanitabe全体の再レビュー

対象: `eb0ab2cd68ee3c3c9882b816cb707c70b7226ea1`の作業tree（開始時clean）。未pushのFR-001 WIPも含む。直近差分だけには限定していない。

初回レビューでは新規指摘4件（P2）を記録した。後続の全件反映指示により4件を修正し、関連・全体自動検証を完了した。

- [CR-001: 複数タグに分かれた検索語をAND検索すると該当料理が消える](findings/CR-001-multi-tag-search.md)
- [CR-002: 既存タグID付きの内容変更を成功扱いで破棄する](findings/CR-002-existing-tag-content.md)
- [CR-003: 出典の種別変更が関連料理の詳細情報を不整合にする](findings/CR-003-source-type-details.md)
- [CR-004: 延期食事の同時確定で同じ食事を複数回作成できる](findings/CR-004-postponed-concurrent-consumption.md)

[確認範囲と限界](coverage.md)

初回レビュー時点で既存FR-001〜030・032〜034との重複登録をスキップした。FR-031は対応済みとして認証helperの状態を前回記録と照合。旧RVの未対応事項も重複候補から除いた。

## 現在の反映結果（2026-11-02）

- CR-001: 複数タグに分散した語を料理単位でAND検索する。
- CR-002: 既存タグIDの内容/正規化を保存し、料理・出典関連・タグを原子的に反映する。
- CR-003: 関連済み出典の種別変更を共通保存境界で拒否し、ページ等の詳細を保持する。
- CR-004: 相互変換の元行をlockし一回消費する。MySQL二接続で両方向の旧2件作成→修正後1件を実測した。

[適用記録・commit一覧](application.md#最終対応表2026-11-02)、[design](design.md)、[tasklist](tasklist.md)、[最終検証と限界](../20261027-full-repository-review/coverage.md#最終検証2026-11-02)を参照。FR-001は利用者保留を維持する。実DB/AWS/Webhookの変更とmergeは実施していない。
