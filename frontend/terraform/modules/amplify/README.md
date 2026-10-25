# modules/amplify

nanitabe frontend の本番配信先と動作確認環境（review）である AWS Amplify Hosting の app、branch、custom domain を作る。

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
| 監視する branch | 呼び出し側 `envs/prod/main.tf`（`main`）と `envs/review/main.tf`（`review`）の `branch_names` |
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

親 domain と prefix で持つのは、hosted zone へ置く名前をフラットな 1 ラベル（`nanitabe.<hosted zone>`、`review-nanitabe.<hosted zone>` 等）にするためである。同じ account の別の Amplify app も同じ親 domain を関連付けられる（実測済み）。動作確認環境を作るときは、この app へ branch を足すのではなく、review root からこの module を `stage = "review"` で呼んで別の app を作る（`infrastructure/README.md`「構成上の前提」の環境の分け方）。

`wait_for_verification = false` にしている。証明書の DNS 検証は Route53 への record 登録が要り、Amplify が作るまでに時間差がある。`true` だと apply がそこで待ち続けるため、apply 後に `aws amplify get-domain-association` の `domainStatus` が `AVAILABLE` になるのを確認する。

### GitHub personal access token

app は fine-grained personal access token で GitHub に接続する。

- 対象 repository は `tumeda1992/nanitabe` だけ
- 権限は Contents: read、Metadata: read、Webhooks: read and write
- Amplify は token を app に保存し、build のたびの clone に使う（`repositoryCloneMethod = TOKEN`）。期限が切れると、その app の build が止まる。prod と review は別の app で、token も別に持つため、それぞれ期限を管理する。次の手順で token を入れ直す
- token は Terraform に通さない。`aws_amplify_app` は `ignore_changes = [access_token]` を持ち、`amplify_github_access_token` は既定値 `null` の optional である。値を repository にも GitHub secrets にも chat にも書かない
- 更新手順: 手元で `aws amplify update-app --app-id <app id> --access-token <新しい token>`（AWS CLI の設定の認証情報を使う）
- app を作り直すとき（destroy 後の apply）だけ、`TF_VAR_amplify_github_access_token` に値を個別に渡す（prod）

### review の app の作り方

review（`envs/review`）は `github_access_token` を受け取らない。app は token を CLI の一回だけに渡して作り、Terraform へ import する。token を Terraform と GitHub secrets に残さないためである。

1. token を発行する（上の権限）
2. `aws amplify create-app --name nanitabe-front-review --repository https://github.com/tumeda1992/nanitabe --access-token <token> --platform WEB_COMPUTE`（token はこの command にだけ渡し、保存しない）
3. review root（`infrastructure/terraform/envs/review/main.tf`）へ import block（`to = module.frontend.module.amplify.aws_amplify_app.this`、`id = "<app id>"`）を足し、PR の plan で import と追加（branch、domain association）だけであることを確認して apply する
4. 取り込み後に import block を削除する
5. git の `review` branch を `main` へ揃え、build が起動しなければ `aws amplify start-job --job-type RELEASE` で起動する

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
