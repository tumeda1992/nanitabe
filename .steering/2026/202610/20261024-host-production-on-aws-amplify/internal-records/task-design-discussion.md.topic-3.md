# 内部検討記録: 論点3 — custom domain の切替と旧構成撤去の順序

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点3

## 開始context

論点1・2で、Amplify 移行を手元 apply で先に行い、旧構成の撤去まで終えることが決まった。

- 決める範囲: 本番の custom domain（`nanitabe.<hosted zone>`）を旧 CloudFront から Amplify へ移す手順と、旧構成をどの時点で撤去するか。停止時間と rollback の可否がこの順序で決まる。
- 既決条件: 論点1・2の決定。
- 残る不足: 同じ domain を旧 CloudFront と Amplify へ同時に割り当てられるか。Amplify の default domain で事前確認できるか。

<a id="iteration-0"></a>

## イテレーション0: 切替と撤去の順序

<a id="iteration-0-record-1"></a>

### 調査: domain の現在の持ち方と、事前確認の成立条件

#### 問いと探索範囲

- 問い: custom domain は今どこで定義されているか。Amplify の default domain から本番 backend を呼べるか。
- source: `frontend/terraform/modules/cloudfront/`、`frontend/terraform/modules/cloudfront/dns/main.tf`、`backend/config/application.rb`、`frontend/src/features/auth/accessTokenAccesser.ts`、x_favorites の `terraform/modules/amplify/README.md`。

#### 見つかった事実

- custom domain は旧 CloudFront distribution の `aliases` と、us-east-1 の ACM 証明書（`modules/cloudfront/cert`）、Route53 の A / AAAA alias record（`modules/cloudfront/dns`）の三か所で Terraform 管理されている。
- Amplify の `aws_amplify_domain_association` は、同一 account の hosted zone なら ALIAS record と証明書検証用の CNAME を Amplify 自身が作る（x_favorites の module README）。Amplify Hosting は内部で CloudFront を使う。CloudFront の alternate domain name は distribution 間で重複できないため、旧 distribution が alias を持ったままでは Amplify への関連付けが成立しない見込みである。この挙動は実 apply で確認する（未実測）。
- backend の CORS は `origins "*"`（`backend/config/application.rb`）で、frontend の origin を限定していない。認証 token は frontend 側の cookie で持つ。Amplify の default domain から本番 backend を呼ぶ確認は CORS で阻まれない。

#### 言える範囲

default domain で機能確認を先に済ませられる。custom domain は旧 distribution から外してからでないと Amplify へ付けられない見込みのため、外してから Amplify の証明書検証が終わるまでの間、custom domain は応答しない。旧 distribution と Lambda を残しておけば、alias と record を戻すことで rollback できる。

<a id="iteration-0-record-2"></a>

### 判断: 順序と停止時間の扱い

- 評価軸: rollback の手段を最後まで残す。停止時間を許容できる範囲に収める。
- 推奨: (1) Amplify app を default domain で作って機能確認 → (2) 旧 distribution から alias・証明書・record を外す apply → (3) Amplify へ domain を関連付けて証明書検証を待つ → (4) custom domain で確認 → (5) 旧構成の残りを撤去する apply。
- 停止時間: (2) から (3) の検証完了まで。利用者がほぼ本人だけ（`frontend/README.md`「想定ユーザ」）であるため、利用しない時間帯に行えば許容できる。
- 代償: (2)〜(4) の間は本番 URL が応答しない。
