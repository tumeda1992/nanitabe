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

## 論点2: 実装中に直した workflow の不具合と、design からのずれ

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0（論点2）: tasklist-executor の報告の記録

#### 変更内容0（論点2）

tasklist-executor が実装・検証中に見つけて直したもの、または design から外れたものを記録する。いずれも tasklist の実施メモに詳細がある。

- **plan workflow の初回失敗:** GitHub Actions の `run` は bash を `-e` 付きで動かす。`terraform plan -detailed-exitcode` は差分があると終了コード 2 を返し、script がそこで中断して S3 への保存と要約が行われなかった。composite action の該当箇所に `set +e` を入れて直した。
- **要約の数え方:** state から外すだけの変更（`removed` block による forget）が update と数えられていた。要約の表に forget の列を足した。
- **plan が Environment secrets を読めない:** discussion 論点12で扱い、値を repository secrets に置く形へ design を改めた。
- **OIDC provider の衝突:** 論点1。
- **`aws_codestarconnections_connection` の一過性の DNS 解決エラー:** 一度だけ発生し、endpoint が解決できることを確かめてから再実行して通った。再現していない。

#### 検討記録（論点2・イテレーション0）

前二つは、GitHub Actions の shell の既定値と、Terraform の `removed` の plan 上の表れ方という、実際に動かして初めて確かめられる挙動だった。design は要約の形（種別ごとの件数と destroy の有無）までを決めており、forget の扱いは決めていなかった。どちらも design の判断を変えず、実装の誤りとして直した。repository の docs へ書く知識としては、GitHub Actions の shell の既定値は一般的な挙動であり書かない。forget の列は `infrastructure/README.md`「出力の読み方」の件数の説明に含めた（tasklist-executor が反映済み）。

### 決定（論点2）

上の修正を維持する。design の判断は変わらない。
