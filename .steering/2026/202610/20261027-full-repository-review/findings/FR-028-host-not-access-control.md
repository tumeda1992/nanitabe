# FR-028: Host制限を直接アクセス防止として扱っている

- 優先度: P1
- 採否: 今回は見送り（挙動維持の制約により適用取消）
- 対応状況: 適用取消・旧挙動の復元検証完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-028（現行コードで再確認）。

## 対象

- [backend/terraform/modules/ecs/main.tf](../../../../../backend/terraform/modules/ecs/main.tf)
- [backend/terraform/modules/apigateway/main.tf](../../../../../backend/terraform/modules/apigateway/main.tf)
- [backend/config/environments/production.rb](../../../../../backend/config/environments/production.rb)

## 問題と根拠

ECSのportを0.0.0.0/0へ開放してpublic IPを付与し、コメントではconfig.hostsで直接アクセスを防ぐとしている。HTTP Hostは接続元が任意に送れるため、許可Hostを指定した直接接続をこの検査では識別できない。API Gateway経由という境界の保証にならない。稼働環境の実到達性は検証していない。

## 改善案

必要な境界をネットワーク制限・private integration・検証可能なorigin認証などで実装する。Hostチェックはホスト名検証として残し、アクセス制御の代替にしない。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

Terraform上の経路とsecurity groupを検査し、隔離した検証環境で許可Hostを使った直接接続が拒否されることを確認する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `2bf938d`

## 適用結果（2026-11-01）

合意済みdesignに従い、taskの受信をVPC link SGだけへ限定し、API Gatewayを固定Cloud Map service ARNへのprivate integrationへ変更した。ECSがprivate IP/portをSRV登録し、taskの終了に追随する。Host検査・外向き通信のpublic IP・既存CPU/memory/ARM/env/secretsは維持する。ALB/NATは追加しない。private DNS namespaceには実適用後に約$0.50/月の固定費と利用量課金が加わる。

start/stopとschedulerも同時に移行した。runtimeのURI更新をなくし、旧URI停止scheduleを除去する。起動はhealthy登録/linkのAVAILABLEと認証不要GraphQL metadataの200/Query応答を待つ。正常時は従来どおり30分後のECS停止を作り、異常時はFR-027のrollbackを維持する。stopはtask終了を待ってから完了する。移行のbaseline・二層台帳・全contract照合は[evidence/fr028-migration.md](../evidence/fr028-migration.md)。

- 起動/停止50件、private構成6件、plan IAM3件: 合計59 tests成功。metadataの不正body4ケースも含む。
- Railsの認証なしmetadata request: 1 example成功、業務record件数不変。追加specのRuboCop成功。
- bash syntax、Terraform変更5ファイルfmt、diff check成功。実health commandをcontainer内loopback serverへ接続して確認。
- Terraform review rootのoffline init/validate成功。元version/lock hashesを維持した隔離copyにARM h1のみ補った。詳細とproviderの非推奨警告は移行台帳へ記録した。

実AWSは今回の合意範囲外のため、apply、許可Hostによる直アクセス拒否、実private経路のHTTP到達性は未確認。実適用時に再確認する。適用commitはapplication.mdとGit履歴で追跡する。

## 適用取消と旧挙動の復元（2026-11-04）

private integrationと関連構成・起動停止処理は挙動と適用条件を変えるため、2bf938dの非steering差分13pathを親版へ戻した。
追加の構成適用を要求せず、FR-027時点の起動停止契約を保持する。旧証拠は当時のコード検証として保存する。
[復元結果](../evidence/scope-repair/fr028-attempt-1/result.md)は既存Node31 tests / 0 failures、bash構文、
13path旧byte一致/不存在、FR-027残部と利用者変更保持、運用3docの現行notice訂正、diff checkが成功した。
運用READMEとreview_environmentを全文通読し、文書reviewで旧版との対応・現在状態と歴史の区別を確認した。
元のHost制限の問題を解消したとは数えない。実AWS・実DB・Webhookは操作していない。
