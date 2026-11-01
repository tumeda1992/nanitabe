# FR-027: 起動途中の失敗で自動停止なしの稼働状態が残る

- 優先度: P1
- 採否: 採用
- 対応状況: 完了（stub検証済み、実AWS未実施）
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-024（現行コードで再確認）。

## 対象

- [scripts/review_backend/start.sh](../../../../../scripts/review_backend/start.sh)

## 問題と根拠

desired_countを1へ変更した後、wait・IP取得・integration更新をset -eで実行し、自動停止scheduleは最後に作る。rollbackが呼ばれるのは一部の後段失敗だけで、前段失敗は起動状態を残す。再実行もdesired_count=1なら即終了してscheduleを修復しない。

## 改善案

起動変更前に失敗時cleanupを登録し、状態変更後の全経路を対象にする。既に起動中の分岐でも停止scheduleとintegrationの整合性を検証する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

aws CLIをstub化し各stepを失敗させ、desired_countが戻るか停止scheduleが必ず残ることを検証する。外部AWSへの実変更はしない。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 未判断
- 適用コミット: 未適用

## 適用結果（2026-11-01）

状態変更より前にEXIT/INT/TERMのcleanupを登録した。新規起動ではupdate-service要求の直前にrollback対象へ印を付けるため、AWS側で受理後にCLIだけ失敗した場合も停止を試みる。既にdesired_count=1でも早期returnせず、integrationと停止scheduleを再整合する。ECS停止が失敗してもintegration停止を独立に試み、元の終了codeを保つ。cleanup拒否は明示的に報告し、完全に停止したとは扱わない。

API/integration IDとscheduler role、target JSONを起動変更前に確認し、不在値や不正な停止分数を拒否する。task/ENI/public IPのNone/空値とIPv4不正値も拒否する。schedule削除はResourceNotFoundExceptionだけを許容し、権限エラーを隠さない。自動停止時刻の計算は従来どおりintegration更新後に行う。

Node harnessは実start.shを一時copyし、秘密のenv file pathだけを人工fixtureへ差し替える。AWS/jq/dateをPATH上のstubに置換し、AWS操作・状態・JSON targetを検証する。実AWSや実env fileには接続・アクセスしない。修正前は26件中22件が失敗。修正後の初回は25/26成功し、1件は負荷によりテスト受付の15秒deadlineへ到達したため、case deadlineを30秒へ広げた。起動済みの修復失敗やcleanup拒否の追加を含む最終31件は全成功した。

- `node --test scripts/review_backend/start.spec.mjs`: 31 tests / 0 failures。
- `bash -n scripts/review_backend/start.sh`: 成功。
- `git diff --check`: 成功。

SIGINTは130、SIGTERMは143で終了して停止を試みる。cleanupの権限自体が拒否された場合、失敗を報告できても実resourceを強制停止できる保証はない。実AWSでの起動・停止は今回の範囲外で実施していない。FR-028ではこのpublic-IP integration方式をprivate方式へ置き換える。適用commitはapplication.mdとGit履歴で追跡する。
