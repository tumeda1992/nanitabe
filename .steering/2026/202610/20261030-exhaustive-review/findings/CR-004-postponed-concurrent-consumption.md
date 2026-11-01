# CR-004: 延期食事の同時確定で同じ食事を複数回作成できる

- 優先度: P2
- 対象スナップショット: `eb0ab2cd68ee3c3c9882b816cb707c70b7226ea1`
- 対象: `backend/app/graphql/mutations/meal/postponed/schedule_postponed_meal.rb:10`
- 観点: 並行処理・データ整合性
- 由来: 全体レビュー・既存。既存未対応指摘とは原因・修正を分離。
- 採否: 採用（全review指摘反映の後続指示）
- 対応状況: 適用・MySQL並行/関連自動検証完了
- 適用枠: 挙動変更が必要
- 依存する指摘: なし

## 問題と根拠

同じ延期食事を二つの要求が同時に読み、それぞれ食事を作成してから元を削除する。対象取得に行ロックがなく、RemoveCommandもfind_by後のdestroy!で削除件数を検証しない。双方が削除前に対象を取得した場合、後続のDELETEが0件でも例外にならず二つの作成が確定し得る。transactionだけでは一回消費を保証しない。二重送信・別タブ操作で予定が重複するP2。FR-019の枠割当多重化とは異なる。

## 改善案

transaction開始時に所有者条件付きで延期食事をlockして取得し、一回だけ消費する。必要なら冪等キーも追加する。延期へ移す逆方向も同じ契約で確認する。

## 振る舞いへの影響

記載した不具合時の検索結果・保存値・拒否条件が変わる。修正の適用は今回のレビュー依頼に含めない。

## 検証方法・証拠

静的確認のみ。MySQLの独立した二接続をbarrierで同期させ、同一IDの確定を同時実行する。作成数1、片方の拒否、元の消費数1を検証する。SQLiteでの逐次テストを並行動作の証明にしない。

実測3件の共通再現コードは[probes.rb](../evidence/probes.rb)、出力は[probes.log](../evidence/probes.log)。

## 合意・適用記録

- 合意した指示と対象範囲: 初回レビュー後の全review指摘反映・継続指示により本指摘を採用。
- 修正内容・判断理由: 後述の適用結果とdesign.mdを参照。
- 実行した検証と結果: 初回の問題再現は上記、今回の修正検証は後述の適用結果を参照。
- 適用コミット: `02e2caf`

## 適用結果（2026-11-02）

確定/延期の両resolverがtransaction冒頭で元の本人行をlockして取得し、一回だけ消費する。元の作成・削除・枠解除は同じtransactionに維持した。延期RemoveCommandの直接呼出も本人条件で取得する。

既存開発Composeプロジェクトへテスト用MySQL8.0.46だけを一時追加し、既存backendから限定URLで検証した。fixture専用DBのguardと二接続の同期手順・全実行条件は[evidence/cr004-mysql.md](../evidence/cr004-mysql.md)。修正前は両方向とも実際に成功2件・作成先2件を再現。修正後は実LOCK WAITを観測し、両方向で成功1/既存の不存在RuntimeError1/作成先1/元行なしを確認した。逆方向の元枠は未割当になる。

- MySQL並行: 2 examples / 0 failures。lock timeout/deadlockを成功扱いにしない。
- SQLite通常関連: 39 examples / 0 failures。逐次再送・他人・作成失敗・削除後失敗のrollback・直接Removeのowner scopeを含む。
- 変更6ファイルRuboCop成功。fixture以外のURLはRails/DB操作前に拒否することも確認。

20msのmetadata pollでは観測cacheが更新されなかったため、公式実装の100ms idle条件を確認して200msへ修正した。成功の根拠は経過時間でなく実LOCK WAITと一回消費の件数である。追加のMySQL補完検証後、一時service/データを除去済み。既存アプリは継続稼働し、実DB/AWS/Webhookは操作していない。commitはapplication.mdとGit履歴で追跡する。
