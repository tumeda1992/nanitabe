# infrastructure

AWS 上のインフラを Terraform で定義する場所。

## 構成

```text
infrastructure/terraform/
├── values/values.tf        # appname = "nanitabe"
└── envs/
    ├── prod/               # 本番。state key = prod/terraform.tfstate
    └── review/             # 動作確認環境。state key = review/terraform.tfstate
```

`envs/*` が root module であり、各アプリケーションの `terraform/envs/*` を module として呼ぶ。

| env | 呼ぶ module | 中身 |
| --- | --- | --- |
| `prod` | `state_in_s3`、`frontend/terraform/envs/prod` | Terraform state 用の S3 と DynamoDB、frontend の ECR、Lambda、API Gateway、CloudFront、CI/CD |
| `review` | `backend/terraform/envs/review` | backend の動作確認環境。ECR、ECS、API Gateway、CI/CD |

state を分けているため、`review` への適用が `prod` の resource を対象にしない。逆も同じ。

## 適用のしかた

各 env の directory で、`init_terraform.sh` を実行してから `apply_terraform.sh` を実行する。

どちらの script も `/etc/opt/app_setting_files/nanitabe/.env` を読み、必要な値を `TF_VAR_*` へ export する。
secret を repository へ置かないため、この形になっている。

```sh
cd infrastructure/terraform/envs/review
./init_terraform.sh
./apply_terraform.sh
```

`init_terraform.sh` は S3 backend の設定を `-backend-config` で渡す。state key は env ごとに違う。

`review` env の `apply_terraform.sh` は、prod 側と違い plan の実行と差分の判定を含む。
plan を file へ保存し、destroy を含む変更が 1 件でもあれば apply せず異常終了する。
review 環境では agent が permission を持ってこの script を実行するため、
差分の確認を人の目視に委ねず script 自身が行う形にしている。

## review 環境に固有の注意

### `terraform apply` は起動中の review 環境を落とす

`review` 環境の ECS service は、Terraform の定義上 `desired_count = 0` を持つ。
`lifecycle { ignore_changes = [desired_count] }` は付けていない。

そのため、環境が起動している最中に `terraform apply` を実行すると、`desired_count` が 0 へ戻され、環境が停止する。

これは意図した挙動である。「停止している状態が正しい」を定義が表し、起動は一時的な逸脱として扱う。
定義と実態がずれたまま放置されるより、apply が常に停止側へ倒れるほうが、止め忘れによる課金を生まない。

環境を使っている最中に構成を変えたい場合は、先に停止してから apply する。

### 実行時の状態は Terraform が持たない

起動・停止のたびに変わる値は Terraform の管理外にある。

| 値 | 誰が変えるか |
| --- | --- |
| ECS service の `desired_count` | `scripts/review_backend/start.sh` が 1 へ、`stop.sh` と EventBridge Scheduler が 0 へ |
| API Gateway の integration URI | 同上。起動時に task の public IP を指し、停止時に到達しない値へ戻る |

integration URI については、Terraform 側で `lifecycle { ignore_changes = [integration_uri] }` を設定している。
`desired_count` と扱いが逆なのは、両者が表すものが違うためである。

- `desired_count` は「起動しているべきか」という**意図**。apply が停止側へ倒れることに意味がある。
- integration URI は「今どの task を指しているか」という**実体との対応**。
  apply が実体と食い違う値を書き込むと、service は動いているのに到達できないという中途半端な状態が生まれる。

### 停止中にかかる費用

停止中も課金される resource を、次の 3 つに限っている。合計で月 $0.3 程度。

- ECR の image 保存。lifecycle policy で最新 1 世代だけを残している。
- CloudWatch Logs の保存。取り込み側の課金は起動中にしか発生しない。
- CloudWatch alarm 1 つ。止め忘れの検知に使う。

存在するだけで時間課金が発生する resource（ALB、RDS、NAT Gateway、Elastic IP）と Secrets Manager、
Container Insights は構成に含めていない。
構成を変えるときは、この前提を崩さないか確認する。

resource を構成へ含めるかを金額で判断する基準は [`cost_judgment.md`](./cost_judgment.md) にある。
課金モデルの見分け方、損益分岐の出し方、サービス別の要点を扱う。

## 構成上の前提

新しい resource を足すときに、既に成立している前提。崩す場合は影響を確認する。

- **network**: VPC は default の 1 つだけで、subnet は 3 つとも public。
  private subnet と NAT Gateway を持たない。private subnet に置く前提の構成は、NAT Gateway の新設を伴う。
- **GitHub と AWS の関係**: GitHub 側に AWS の credentials も OIDC の信頼設定も置かない。
  deploy は AWS 側（CodePipeline / CodeBuild）が `CodeStarSourceConnection` で GitHub を見る形にする。
  `.github/workflows/` は test と lint だけを行う。
- **CPU architecture**: container の build と実行を ARM で統一する。
  CodeBuild は `ARM_CONTAINER`、Fargate は `ARM64`。
- **課金**: resource を足すかどうかを金額で判断するときは [`cost_judgment.md`](./cost_judgment.md) を見る。
  時間課金と保存・件数課金を分けて考え、防ぐ対象の損失と固定費を並べて比べる。
- **host 名**: hosted zone へ置くレコードはフラットな 1 ラベルにする。sub-sub ドメインを掘らない。
  domain 名は `.env` の `ROUTE53_HOSTZONE_NAME` から渡し、terraform の定義にも document にも直接書かない。
- **API Gateway v2 の管理 API 権限**: EventBridge Scheduler 等の AWS SDK 統合から apigatewayv2 の操作
  （`UpdateIntegration` 等）を呼ぶ場合、IAM policy は HTTP verb ベースの action（`apigateway:PATCH` 等）で与える。
  `apigatewayv2:UpdateIntegration` のような friendly な action 名は評価されず、`AccessDenied` になる。
- **EC2 系 resource の `description` は ASCII のみ**: `aws_security_group` 等の `description` 属性へ
  日本語を書くと `InvalidParameterValue` で失敗する。設計意図は属性値ではなく HCL コメント（`#`）へ書く。

## 環境の使い方

review 環境へ何を載せ、どう起動して確認するかは、
[`review_environment.md`](../backend/docs/ai_guideline/development_standard/review_environment.md) にある。
