# RV-019: ビルド検証workflow自身の変更が検出されない

- 観点: 契約・正しさ・運用
- 優先度: 中
- 採否: 未判断
- 対応状況: 未着手
- 今回の適用対象: 対象外
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: .github/workflows/ci-frontend-build-verification.yml: Detect frontend changes
- 依存する指摘: なし（関連指摘は本文参照）

## 問題と根拠

実ファイル名はci-frontend-build-verification.ymlだが、変更検出の正規表現はci-frontend-buid-verification\.yml（buildのl欠落）。workflowだけを変更するPRではchanged=falseとなり、Install dependenciesとBuildをskipして成功する。

## 改善案

正規表現を実ファイル名へ合わせる。別のCI構造へ変更せず、既存の差分検出方式を維持する。

## 振る舞いを維持する条件

CIの実行条件が変わるため今回対象外。アプリケーションの挙動とは別だが、運用上の振る舞い変更として明示する。

## 検証方法

workflowだけ、frontendコードだけ、無関係な文書だけの3入力で検出結果を確認し、workflowだけのPRでBuildが実行されることを確認する。

## 採否・対応記録

- ユーザーの判断: 未判断
- 確認: コードと記載した関連specの静的確認。動的再現・テストは未実行。
- 適用コミット: 未適用
