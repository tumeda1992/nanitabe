# 議論記録

## 論点1: GitHub の token は Amplify に保存され、期限切れで build が止まる

**ステータス:** 決定

### イテレーション0（論点1）: token の扱いの記述と、本番と別 token にするか

#### 提案0（論点1）

- 本番と review で token を分ける必要はない。権限が同じ（`tumeda1992/nanitabe` の Contents read、Webhooks）で、漏れたときに読まれるものが変わらないため。本番と review の境界は AWS 側（別 app、別 backend、別 DB）にあり、token を分けても増えない。差は運用だけで、分ければ片方の失効・作り直しがもう片方の build を止めない。
- `frontend/terraform/modules/amplify/README.md` に次を足す。app は `repositoryCloneMethod = TOKEN` で、Amplify は token を保存して build のたびに clone に使う。token の期限が切れると、その app の build が止まる。切れたら新しい token を `aws amplify update-app --app-id <app id> --access-token <token>` で入れ直す。
- design の「token は CLI の一回にしか渡らない」を、「Terraform と GitHub には残らない。Amplify は保存して clone に使う」に直す。

#### 検討記録（論点1・イテレーション0）

利用者から「本番と違う PAT を発行しなければいけないか。見られるものが同じなのでセキュアではない」と問われた。確かめると本番の app は `repositoryCloneMethod = TOKEN` だった。design は token を作成時の一回だけ使うものとして書いていたが、Amplify は保存して使い続ける。Terraform と GitHub に残さないという原則は満たしているが、期限切れで build が止まるという運用上の帰結が docs にも design にも無かった。

- 共有されていなかった前提: Amplify の GitHub 接続方式（TOKEN）では token が Amplify 側に残り、期限が build の可否を決める。
- code を読んでも分からず、AWS の app 設定を見て初めて分かる。module README が置き場所として適切である（app を作る・作り直す人が読む）。

#### 提案0へのフィードバック（論点1）

**結果:** 合意

> ok。

### 決定（論点1）

本番と review で GitHub の token を分けない（分けてもよい）。安全性は変わらず、差は失効時の影響範囲だけである。`modules/amplify/README.md` に、Amplify が token を保存して clone に使うこと、期限切れで build が止まること、`aws amplify update-app --access-token` で入れ直す手順を書く。design の token の記述を、Amplify には保存されることが分かる形に直す。review の app は利用者が token を渡して作成済み（app id は `aws amplify list-apps` で引く）。

## 論点2: review root の aws provider が 6.x で、`modules/amplify` の `~> 5.0` と衝突する

**ステータス:** 決定

### イテレーション0（論点2）: provider の version 制約

#### 提案0（論点2）

`frontend/terraform/modules/amplify/main.tf` の aws provider の制約を `~> 5.0` から `>= 5.0` に変える。version の固定は module ではなく各 root の `.terraform.lock.hcl` が持つ。

- prod: lock は 5.100.0 のままで、挙動は変わらない。
- review: lock の 6.70.0 のまま `modules/amplify` を使う。6.x での `aws_amplify_app` 等の差分は、変更後の review の plan で確かめる（import 1 件と追加だけであること）。
- `infrastructure/terraform/modules/github_oidc` の `~> 5.0` は prod root からだけ呼ばれ、衝突しないため変えない。
- design の「`modules/amplify` は変えない」を、この制約の変更だけを例外として直す。

#### 検討記録（論点2・イテレーション0）

PR #291 の review の plan が `init` で失敗した（`locked provider hashicorp/aws 6.70.0 does not match configured version constraint ~> 5.0`）。

- review root と backend の module は provider の version を制約しておらず、review の lock は 6.70.0 になっていた。prod の lock は 5.100.0。
- `modules/amplify` は prod だけから呼ばれる前提で `~> 5.0` を持っていた。module が上限付きの制約を持つと、lock の異なる root から呼べない。
- Phase 1 の validate は scratchpad で lock を消して init し直したため、この衝突を検出できなかった。本物の lock で init していれば設計時に分かった。

採らなかった案:

- review の lock を 5.x へ下げる: review の state は 6.70 で書かれている。provider の downgrade は state の schema を読めなくするおそれがあり、backend の review 資源まで巻き込む。
- prod を 6.x へ上げる: 本番の provider の major を上げる変更で、今回の範囲（動作確認環境）を越える。

#### 提案0へのフィードバック（論点2）

**結果:** 合意

> ok

### 決定（論点2）

`frontend/terraform/modules/amplify/main.tf` の aws provider の制約を `>= 5.0` にし、version の固定は各 root の `.terraform.lock.hcl` に任せる。prod は 5.100.0、review は 6.70.0 のまま使い、6.x での差分は review の plan で確かめる。`github_oidc` の `~> 5.0` は変えない。review の lock を下げる案は state の schema を読めなくするおそれ、prod を 6.x へ上げる案は範囲外として採らない。あわせて、workflow file を変える PR では prod の plan も起動する（結果は変更なし）ことを tasklist の DoD の例外として記録する。

