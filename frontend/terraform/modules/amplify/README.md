# modules/amplify

nanitabe frontend の本番配信先である AWS Amplify Hosting の app、branch、custom domain を作る。

## この module が持つもの / 持たないもの

持つもの。

- `aws_amplify_app`: SSR platform（`WEB_COMPUTE`）、GitHub 接続、環境変数
- `aws_amplify_branch`: `branch_names` で受け取った branch 群
- `aws_amplify_domain_association`: `custom_domain` が渡されたときだけ作る

持たないもの。

- **build 設定**: repository 直下の `amplify.yml` を使う。`build_spec` を指定すると repository の file より優先されてしまうため、この module では書かない
- **Route53 の record**: custom domain が同一 account の hosted zone を指す場合、Amplify が ALIAS record と ACM 検証用 CNAME を自動で作る。Terraform 側で作らない

## クイックマップ

| 知りたいこと | 見る場所 |
| --- | --- |
| build の手順、Node.js の version | repository 直下の `amplify.yml` |
| app の環境変数 | `main.tf` の `environment_variables`（`AMPLIFY_MONOREPO_APP_ROOT` と `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`） |
| 監視する branch | 呼び出し側 `envs/prod/main.tf` の `branch_names` |
| custom domain の割り当て | 呼び出し側の `custom_domain` と `custom_domain_sub_domains` |

## 不変条件

### 環境変数は build 時にしか効かない

`aws_amplify_app` の `environment_variables` は build container の環境変数として渡るだけで、SSR の server runtime には届かない。
現在の値は `NEXT_PUBLIC_` で始まるため、build 時にクライアント bundle へ埋め込まれる。
そのため Amplify app の環境変数を apply で変えても、再 build（`main` への push か Amplify console からの再実行）まで配信中の内容は変わらない。

`NEXT_PUBLIC_` 以外の値を実行時に渡す場合は、`amplify.yml` の build phase で `.env.production` へ書き出す必要がある。変数を足しただけでは runtime へ届かない。

### branch は「追加してから外す」

Terraform が作るのは Amplify 側の branch resource だけで、git の branch は作らない。次の順序を守る。

1. git branch を作り、push して origin に存在させる
2. `branch_names` へ追加する
3. `terraform apply` する

`branch_names` から外して apply すると、その branch の deploy が AWS 上から消える。apply の plan で destroy の対象を必ず確認する。
branch resource の作成は push event ではないため、build が自動で起動しない場合がある。`aws amplify list-jobs` に job が無ければ `aws amplify start-job --job-type RELEASE` で起動する。

### custom domain は親 domain と prefix で持つ

`custom_domain` は親 domain、`custom_domain_sub_domains` は branch ごとの割り当て（`branch_name` と `prefix` の組）である。
`aws_amplify_domain_association` は 1 つにまとめ、branch ごとに `sub_domain` を割り当てる。
`custom_domain` が `null` のあいだは association を作らず、default domain だけで公開できる。

`wait_for_verification = false` にしている。証明書の DNS 検証は Route53 への record 登録が要り、Amplify が作るまでに時間差がある。`true` だと apply がそこで待ち続けるため、apply 後に `aws amplify get-domain-association` の `domainStatus` が `AVAILABLE` になるのを確認する。

### GitHub personal access token

app は fine-grained personal access token で GitHub に接続する。

- 対象 repository は `tumeda1992/nanitabe` だけ
- 権限は Contents: read、Metadata: read、Webhooks: read and write
- 失効すると Amplify が repository を見られなくなり、build が起動しない。token を更新して apply する
- 値は `TF_VAR_amplify_github_access_token` で渡し、repository にも chat にも書かない

## 変更ガイド

| やりたいこと | すること |
| --- | --- |
| 環境変数を足す | `main.tf` の `environment_variables` へ足す。runtime で読む値は `amplify.yml` で `.env.production` へも書き出す |
| branch を足す | 上の「追加してから外す」の順序に従う |
| branch を外す | plan で対象 branch の destroy だけであることを確認してから apply する |
| Node.js の version を変える | `amplify.yml` の `nvm install` を変える。build log の `node -v` で確認する |

## 参照

- `amplify.yml`（repository 直下）
- 移行の design: `.steering/2026/202610/20261024-host-production-on-aws-amplify/design.md`
- 参考元の構成: x_favorites の `terraform/modules/amplify/README.md`
