# FR-030: ビルドworkflow自身だけの変更で検証をskipする

- 優先度: P2
- 採否: 未判断
- 対応状況: 未着手
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

- ユーザー判断: 未判断
- 適用コミット: 未適用
