# FR-030: ビルドworkflow自身だけの変更で検証をskipする

- 優先度: P2
- 採否: 採用
- 対応状況: 再適用・offline検証完了
- 振る舞い維持の適用枠: 対象外
- 対象コミット: `a3982e9e777070915b2337fbcaa6cfdac032b3df`
- 旧レビューとの対応: RV-019（現行コードで再確認）。

## 対象

- [.github/workflows/ci-frontend-build-verification.yml](../../../../../.github/workflows/ci-frontend-build-verification.yml)

## 問題と根拠

変更検出regexのファイル名がci-frontend-buid-verification.ymlで、実ファイルのbuildと一致しない。このworkflowだけを変更するとchanged=falseとなり、壊れたbuild設定でも成功扱いでskipされる。

## 改善案

実ファイル名へ修正する。変更検出条件をworkflowごとに複製する場合は、各workflow自身を含むことを機械検査する。

## 振る舞いを維持する条件

改善すると拒否条件・保存値・応答・タイミング・運用権限のいずれかが変わる。従来の「振る舞いを変えない」適用枠には自動投入しない。重要度を下げる意味ではない。

## 検証方法と確認結果

frontend変更、workflow単独変更、無関係変更の3つの変更ファイル集合で判定を確認する。

静的確認。上記の個別再現テストは未実行。

## 採否・対応記録

- ユーザー判断: 全review指摘反映の後続指示により採用
- 適用コミット: `a871b4c`

## 適用結果（2026-11-01）

変更検出regexのbuidを実ファイル名のbuildへ修正した。実workflowのDetect frontend changes blockをbashで実行し、gitの差分一覧だけをstubにする。frontendのみ/workflow自身のみ/無関係な複数ファイルの3ケースでGITHUB_OUTPUTを確認し、workflow単独変更のred後、3 tests成功。GitHub上でのworkflow実行はpush後のCIで確認する。commitはapplication.mdとGit履歴で追跡する。

## 適用取消と旧挙動の復元（2026-11-04）

workflow自身の変更を検出する修正は挙動を変えるため、a871b4cの親版へ戻した。
[復元結果](../evidence/scope-repair/fr030-attempt-1/result.md)はgit stubによる実script3 cases / 0 failures、
旧workflowのbyte一致、専用suite除去、利用者変更保持とdiff checkが成功した。
frontend変更=true、workflow自身だけ=false、backend/README変更=falseの旧条件を維持する。
元の検出漏れの指摘と旧検証は保存し、既知の不具合を直したとは報告しない。

## 再適用（2026-11-06）

frontend build workflow自身の変更を検出する。filter 3 testsとYAML parse成功、actionlint未導入。[結果](../evidence/scope-repair/fr030-retain-attempt-1/result.md)。
