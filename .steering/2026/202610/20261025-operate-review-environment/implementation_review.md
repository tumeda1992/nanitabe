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
