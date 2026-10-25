# 議論記録

## 論点1: GitHub Actions の OIDC provider が同じ account にすでにある

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0（論点1）: provider の所有

#### 提案0（論点1）

`infrastructure/terraform/modules/github_oidc/` では OIDC provider を作らず、既存の provider を `data "aws_iam_openid_connect_provider"`（URL `https://token.actions.githubusercontent.com`）で参照する。role 3 つは nanitabe が作る。provider は同じ account の別 repository（x_favorites）の Terraform が所有しており、その依存を module の README とコメントに書く。import はしない。

#### 検討記録（論点1・イテレーション0）

Phase 2 の apply で、利用者の実行が `EntityAlreadyExists: Provider with url https://token.actions.githubusercontent.com already exists.` で失敗した。失敗は最初の resource で起き、role は作られていない（`aws iam list-roles` で nanitabe の terraform role が無いことを確認）。GitHub Actions 用の OIDC provider は URL ごとに account に一つしか作れず、同じ account の x_favorites の Terraform がすでに作っていた（`x-favorites-terraform-plan`・`-apply` の role が使う）。audience は `sts.amazonaws.com` で、nanitabe の設計と同じである。

二つの state で同じ resource を管理すると、片方の apply や destroy が他方を壊すため import しない。参照にすると、x_favorites が provider を削除したとき nanitabe の Actions が AWS に接続できなくなる。この依存は README とコメントで示す。

共有されていなかった前提: 同じ AWS account に、account に一つしか作れない resource を別の repository がすでに作っていること。x_favorites が同じ account であることは設計前調査で把握していたが、`github_oidc` を設計するときに account に一つの resource の衝突を確かめなかった。account に一つしか存在できない resource を作る設計では、既存の有無と所有者を確かめる、という process の問いにあたる。この repository の docs へは、`infrastructure/README.md`「構成上の前提」に「OIDC provider は同じ account の別 repository が所有し、nanitabe は参照する」と書く（Phase 6 の README 更新で扱う）。

#### 提案0へのフィードバック（論点1）

**結果:** 合意

> ok

### 決定（論点1）

`github_oidc` module は OIDC provider を作らず、既存の provider を URL で参照する data source を使う。role 3 つは nanitabe が作る。provider の所有者は同じ account の x_favorites の Terraform とし、import しない。依存を module の README とコメント、`infrastructure/README.md`「構成上の前提」に書く。
