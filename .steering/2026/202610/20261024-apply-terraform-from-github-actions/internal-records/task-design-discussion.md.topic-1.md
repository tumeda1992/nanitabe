# 内部検討記録: 論点1 — Actions へ移す目的と、Terraform を実行してよい場所の原則

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点1

## 開始context

親 roadmap の phase `terraform-on-github-actions` の設計を始める。親 design は「Terraform の適用を GitHub Actions へ移す」を範囲に含めたが、その目的は x_favorites を真似ることとしか合意していない。

- 決める範囲: Actions へ移す目的と、そこから導く「Terraform をどこで実行してよいか」の原則。workflow、role の権限、secrets の配置、spike 用途の扱いがすべてこの原則に依存する。
- 既決条件: 親 phase の scope と DoD（値を必要とする plan / apply を Actions だけで実行する）、module をローカル実行で確かめる用途を残すこと。
- 残る不足: DoD の「値を必要とする plan / apply は Actions だけ」と、ローカル実行の spike 用途が両立する形。

<a id="iteration-0"></a>

## イテレーション0: 目的と実行場所の原則

<a id="iteration-0-record-1"></a>

### 調査: x_favorites の目的と担保の仕方、nanitabe で今回起きたこと

- x_favorites の TL;DR は、「誰が apply を実行するか」を毎回の運用判断から外し、PR で plan の差分を読み merge で apply する形にすること、適用の履歴を PR と workflow の記録に残すこと、を目的としている。ローカルで実行しないことは、terraform だけが使う値の一部を手元へ置かないことで「規範ではなく構成として」担保している（x_favorites の `20260919-plan-and-apply-terraform-on-github-actions/design.md`）。
- nanitabe の Amplify 移行では、agent による本番の apply が Claude Code の分類器に拒否され、7 回の apply をすべて利用者が `!` で実行した。plan の確認と apply の実行が利用者と agent の間で往復した（子 steering `20261024-migrate-frontend-hosting-to-amplify/implementation_review.md` 論点3）。
- nanitabe には `verify-infra` の用途がある。module をローカル実行で Terraform が動くか確かめる spike 的な環境で、各 module の `test/` から local state で立てていた（同 論点8、issue #146）。この用途はローカルで AWS の認証情報と一部の値を必要とする。

<a id="iteration-0-record-2"></a>

### 判断: 原則の形

- x_favorites の「値を手元に置かない」担保は、ローカル実行の spike 用途と両立しない。spike は手元で apply するため、AWS の認証情報と値が手元に要る。
- 両立させるには、担保の対象を「値」から「state」へ移す。prod と review の state（S3 の `prod/`、`review/` key）へ書き込む plan / apply は Actions だけが行い、手元の apply は spike 用の別 state（local state、prod / review の resource と名前が重ならない stage）だけに限る。
- この担保は構成ではなく規範になる（手元の認証情報で prod の state に書けてしまう）。補強として、手元の `init_terraform.sh` / `apply_terraform.sh` を prod と review から取り除き、手元から prod / review の state を扱う入口を無くす。
- 目的は x_favorites の二点に、nanitabe で起きた「apply の実行が利用者と agent の往復になる」を加える。merge で apply されれば、agent は PR の作成までで止まり、利用者は plan を読んで merge するだけになる。
