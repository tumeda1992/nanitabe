# 議論記録

## 論点1: Actions へ移す目的と、Terraform を実行してよい場所の原則

**ステータス:** 決定

### イテレーション0（論点1）: 目的と実行場所の原則

#### 提案0（論点1）

**目的**

1. 「誰が apply を実行するか」を毎回の判断から外す。PR で plan の差分を読み、`main` への merge で apply される形にする。
2. 適用の履歴を、PR と workflow の実行記録に残す。
3. apply の実行が利用者と agent の往復にならないようにする。agent は PR の作成までで止まり、利用者は plan を読んで merge するだけにする。

**実行場所の原則**

| 実行するもの | 場所 | 使う state |
| --- | --- | --- |
| `envs/prod`、`envs/review` の `plan` / `apply` | GitHub Actions だけ | S3 の `prod/`、`review/` key |
| module がローカル実行で動くかの spike | 手元 | local state。stage 名を prod / review と重ねない |
| `fmt`、`validate` | 手元でも Actions でも | なし |

- 手元から prod / review の state を扱う入口（各 root の `init_terraform.sh` / `apply_terraform.sh`）は取り除く。
- 手元の AWS 認証情報と値は spike のために残る。したがって「手元で prod / review を apply しない」は構成ではなく規範で担保する。x_favorites のように「値を手元に置かないので apply できない」形にはならない。

#### 検討記録（論点1・イテレーション0）

親 design は Actions 化を範囲に入れましたが、目的は「x_favorites を真似る」までしか合意していません。目的によって、どこで Terraform を実行してよいかの原則が変わり、workflow、role の権限、secrets の置き場所、spike 用途の扱いがすべてその原則に従うため、最初に決めます。

x_favorites の目的は、apply の実行者を毎回判断しないこと（1）と、履歴を PR と workflow に残すこと（2）でした。nanitabe では今回、agent による本番の apply が Claude Code の分類器に拒否され、7 回の apply をすべてあなたが `!` で実行しました。plan の確認と実行の往復が作業時間の大半を占めたので、（3）を加えています。

x_favorites は「terraform だけが使う値の一部を手元に置かない」ことで、手元で plan / apply を実行できないことを構成として担保していました。nanitabe ではこれが使えません。module をローカル実行で確かめる spike 用途（旧 `verify-infra`）を残すと決めていて、spike は手元で apply するため AWS の認証情報と値が手元に要るからです。

そこで担保の対象を「値」から「state」へ移します。prod と review の state に書き込むのは Actions だけ、手元の apply は spike 用の別 state だけ、という分け方です。手元の認証情報で prod の state に書けてしまう以上、これは規範です。補強として、手元から prod / review の state を扱う script を取り除き、入口を無くします。

[内部検討記録: 論点1・イテレーション0](internal-records/task-design-discussion.md.topic-1.md#iteration-0)

#### 提案0へのフィードバック（論点1）

**結果:** 合意

> ok

### 決定（論点1）

**目的:** (1)「誰が apply を実行するか」を毎回の判断から外し、PR で plan の差分を読み `main` への merge で apply される形にする。(2) 適用の履歴を PR と workflow の実行記録に残す。(3) apply の実行が利用者と agent の往復にならないようにし、agent は PR の作成まで、利用者は plan を読んで merge するだけにする。

**実行場所の原則:** `envs/prod` と `envs/review` の `plan` / `apply`（S3 の `prod/`、`review/` key の state）は GitHub Actions だけで実行する。module がローカル実行で動くかの spike は手元で、local state と prod / review に重ならない stage 名で行う。`fmt`、`validate` は場所を問わない。手元から prod / review の state を扱う入口（各 root の `init_terraform.sh` / `apply_terraform.sh`）は取り除く。手元の AWS 認証情報と値は spike のために残るため、「手元で prod / review を apply しない」は構成ではなく規範で担保する。x_favorites のように値を手元に置かないことで担保する形を採らないのは、spike 用途を残すためである。


## 論点2: public repository で plan / apply の出力をどこまで公開するか

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0（論点2）: 出力の置き場所

> 事後記録: この回の提案は chat で先に提示し、合意を受けてから保存した。提案本文と回答は chat の内容をそのまま記録している。

#### 提案0（論点2）

plan / apply の全文は Actions の log に出さず、state 用の S3 bucket（非公開、暗号化済み）に保存する。PR コメントと log には、resource の種別ごとの add / change / destroy の件数と、destroy の有無だけを出す。全文は利用者か agent が `aws s3 cp` で取り寄せて読む。

代替として、repository を private にする案と、公開を受け入れる案を併記した。

#### 検討記録（論点2・イテレーション0）

`tumeda1992/nanitabe` は public で、Actions の log と PR コメントは誰でも読める。plan / apply の出力には hosted zone の domain 名（Amplify の domain association、API Gateway の custom domain、review root の `cert_validation` の resource アドレスのキー）、ARN 内の AWS account ID、Route53 の zone ID が出る。この repository は domain 名を document に書かず（`<hosted zone>` と表記）、account ID も実値を書かない識別子として扱っている。x_favorites は private repository なので plan をそのまま PR コメントにしていた。`route53_name` を sensitive にしても、review root は domain を `for_each` のキーに使っており sensitive 値はキーにできず、ARN の account ID も隠せない。

private 化は repository の公開方針の変更になり、GitHub Free の private repository では branch protection も使えない。公開の受け入れは既存の記載方針と食い違う。要約だけを公開する案の欠点は、エラー時の Terraform のメッセージに値が混ざることを防ぎきれない点と、PR 上で差分を直接読めない点である。

#### 提案0へのフィードバック（論点2）

**結果:** 合意（案 a）

> a

### 決定（論点2）

plan / apply の全文は Actions の log に出さず、state 用の S3 bucket（非公開、暗号化済み）へ保存する。PR コメントと log に出すのは、resource の種別ごとの add / change / destroy の件数と destroy の有無だけとする。全文は利用者か agent が `aws s3 cp` で取り寄せて読む。エラー時の Terraform のメッセージに値が混ざる可能性は残る。

## 論点3: workflow の構成と起動条件

**ステータス:** 決定

### イテレーション0（論点3）: root ごとの plan / apply workflow

#### 提案0（論点3）

root ごとに plan と apply の workflow を分け、4 file にする。

| file | 起動条件 | 行うこと |
| --- | --- | --- |
| `terraform-plan-prod.yml` | `main` への PR（同じ repository の branch だけ）で、`infrastructure/terraform/envs/prod/**`、`infrastructure/terraform/modules/**`、`frontend/terraform/**`、`.terraform-version`、自身の workflow file が変わったとき。手動起動 | plan role で `terraform plan`。全文を S3 へ保存し、要約を PR コメントへ出す（同じ PR では既存コメントを更新） |
| `terraform-apply-prod.yml` | `main` への push で同じ paths が変わったとき。手動起動 | apply role で `terraform apply`。続けて plan し、差分が空であることを確認する。全文は S3、log には結果の要約だけ |
| `terraform-plan-review.yml` | 同上。paths は `infrastructure/terraform/envs/review/**`、`backend/terraform/**`、`.terraform-version`、自身 | 同上 |
| `terraform-apply-review.yml` | 同上 | 同上 |

- fork からの PR では secrets が渡らないため、plan job は同じ repository の branch からの PR だけで動かす。
- review root の `apply_terraform.sh` が持っていた「destroy を含む plan では apply しない」判定は、PR コメントの要約で destroy の有無を先頭に示し、人が読んで merge する形に置き換える。
- review の変更を merge すると、起動中の review 環境は `desired_count = 0` に戻って停止する。これは現行の手元 apply と同じ挙動で、変えない。

#### 検討記録（論点3・イテレーション0）

x_favorites は root が一つで、plan と apply の 2 file だった。nanitabe は root が二つあり、変わる file の集合も別々（prod は frontend の Terraform、review は backend の Terraform）なので、root ごとに分ける。一つの workflow で条件分岐させると、plan role と apply role、prod と review の値の切替が一 file に集まり、片方の変更が他方へ効く。

#### 提案0へのフィードバック（論点3）

**結果:** 修正要求（説明不足）

> 3は自明じゃない。4,5,6はok。7は紋切り型じゃない。必要なときにやる。方針は書いておく。特に1つ1つ不確実性があるときにverify-infraしたい。さらにはかっちりした初回作成は本番ライクにどんどん積み上げていくけど、ちょっと試したいレベルの新しいリソースを軽く使ってみますってときや、既存の本番を破壊的に変えるのを試し無しで行えないときに部品で試すことができるときにverify-infraは有用。8はokだけど、どれくらい.envの内容消していいかも気になる。

workflow を 4 本に分ける理由が提案から自明に読めない、という指摘として受け取った。次の回で、分け方の候補と決め手を具体的に示す。

### イテレーション1（論点3）: 分け方の候補と決め手

#### 提案1（論点3）

workflow は「plan / apply」×「prod / review」の 4 file に分ける（提案0と同じ）。分け方の決め手は次の二つである。

**決め手1: plan と apply を同じ file に入れない。** apply role は `AdministratorAccess` を持つ（論点4）。一つの file に入れて `if` で role を切り替えると、条件の書き誤り一つで PR から apply role を assume する経路ができる。file を分ければ、plan の file には apply role の ARN が現れず、apply の file は `main` への push でしか起動しない。x_favorites も同じ理由で分けていた。

**決め手2: prod と review を同じ file に入れない。** 起動条件の `paths` は workflow file 単位でしか書けない。一つの file で「prod の file が変わったら prod だけ plan する」を実現するには、job の中で変更 file を判定する仕組み（第三者の action `dorny/paths-filter` 等、または `git diff` の自作 script）が要る。apply の file は `AdministratorAccess` で動くため、そこへ第三者の action を足すと、その action の改ざんが account 全体の権限につながる。自作 script は判定の誤りで別 root を apply する経路になる。file を分ければ GitHub 自身の `paths` だけで root を選べる。

具体的な動き:

| 変更した file | PR で動く workflow | merge で動く workflow |
| --- | --- | --- |
| `frontend/terraform/modules/amplify/main.tf` | `terraform-plan-prod.yml` | `terraform-apply-prod.yml` |
| `backend/terraform/modules/ecs/main.tf` | `terraform-plan-review.yml` | `terraform-apply-review.yml` |
| 両方 | 両方の plan | 両方の apply（並行） |
| `backend/app/...` だけ | なし | なし |

代償は、4 file に同じ手順（checkout、setup-terraform、init、出力の S3 保存と要約）が重複することである。重複は GitHub の composite action（repository 内の `.github/actions/`）へ切り出し、各 file は root と role と値の対応だけを持つ形にする。

#### 検討記録（論点3・イテレーション1）

提案0は分け方の結果だけを示し、なぜ一つや二つの file ではいけないのかを書いていなかった。候補は「1 file」「plan / apply の 2 file で job ごとに root を切り替える」「root ごとの 2 file で plan / apply を条件分岐」「4 file」の四つで、前の三つはいずれも、`AdministratorAccess` を持つ apply の経路に条件分岐か外部の判定を入れることになる。4 file だけが、role と root の選択を GitHub の起動条件（event と `paths`）だけで決められる。

#### 提案1へのフィードバック（論点3）

**結果:** 合意

> まず3だけで行こうか。内容ok。

### 決定（論点3）

workflow は `terraform-plan-prod.yml`、`terraform-apply-prod.yml`、`terraform-plan-review.yml`、`terraform-apply-review.yml` の 4 file に分ける。prod の `paths` は `infrastructure/terraform/envs/prod/**`、`infrastructure/terraform/modules/**`、`frontend/terraform/**`、review の `paths` は `infrastructure/terraform/envs/review/**`、`backend/terraform/**`、どちらも `.terraform-version` と自身の workflow file を含む。plan は `main` への PR（同じ repository の branch だけ）と手動起動、apply は `main` への push と手動起動で動く。plan と apply を同じ file に入れないのは、`AdministratorAccess` を持つ apply role を条件分岐で切り替えると、書き誤りで PR から apply role を assume する経路ができるためである。prod と review を同じ file に入れないのは、`paths` が workflow file 単位でしか書けず、一つの file で root を選ぶには第三者の action か自作の判定 script が apply の経路に入るためである。4 file に重複する手順は repository 内の composite action（`.github/actions/`）へ切り出す。review root の `apply_terraform.sh` が持っていた destroy の拒否判定は、PR コメントの要約で destroy の有無を先頭に示し人が読んで merge する形に置き換える。review の変更の merge で起動中の review 環境が停止する挙動は、現行と同じで変えない。

## 論点4: OIDC と AWS role の権限

**ステータス:** 決定

### イテレーション0（論点4）: role の数、信頼条件、権限

#### 提案0（論点4）

- OIDC の identity provider を一つと、role を二つ作る。prod と review で共有する。
  - plan role: 信頼条件は `repo:tumeda1992/nanitabe:pull_request` と手動起動。権限は AWS 管理の `ReadOnlyAccess`、state 用 S3 bucket への読み書き（plan の全文の保存を含む）、lock 用 DynamoDB への読み書き。
  - apply role: 信頼条件は `repo:tumeda1992/nanitabe:ref:refs/heads/main` だけ。権限は `AdministratorAccess`。
- 定義は新設する `infrastructure/terraform/modules/github_oidc/` に置き、`envs/prod` から呼ぶ。account に一つの resource であるため。
- 初回の作成だけは、利用者の手元 apply で行う（role が無いと Actions が AWS に接続できないため）。これが手元からの最後の prod apply になる。

#### 検討記録（論点4・イテレーション0）

x_favorites は apply role に操作対象の service ごとの action を列挙した。nanitabe の review root は ECS、API Gateway、ACM、Route53、SSM、SNS、CloudWatch、CodePipeline、CodeBuild、Scheduler、security group、IAM role を作る。IAM role を作れる権限は、それ自体で他の権限を作れるため、列挙しても実質的な制限にならない。列挙は resource を足すたびに role の更新が要り、目的の「保守対象を減らす」に反する。そこで apply role は `AdministratorAccess` とし、代わりに信頼条件を `main` の push だけに絞る。現在の手元の認証情報も同じ広さの権限を持っており、広さは変わらない。`main` への直接 push を防ぐのは論点6の branch protection が担う。

role を root ごとに分けない理由は、どちらも `AdministratorAccess` になり、分けても権限の境界が生まれないためである。

#### 提案0へのフィードバック（論点4）

**結果:** 合意

> 3は自明じゃない。4,5,6はok。7は紋切り型じゃない。必要なときにやる。方針は書いておく。特に1つ1つ不確実性があるときにverify-infraしたい。さらにはかっちりした初回作成は本番ライクにどんどん積み上げていくけど、ちょっと試したいレベルの新しいリソースを軽く使ってみますってときや、既存の本番を破壊的に変えるのを試し無しで行えないときに部品で試すことができるときにverify-infraは有用。8はokだけど、どれくらい.envの内容消していいかも気になる。



### 決定（論点4）

OIDC の identity provider を一つ、role を二つ作り、prod と review で共有する。plan role の信頼条件は `repo:tumeda1992/nanitabe:pull_request` と手動起動、権限は `ReadOnlyAccess` と state 用 S3 bucket・lock 用 DynamoDB の読み書き。apply role の信頼条件は `repo:tumeda1992/nanitabe:ref:refs/heads/main` だけ、権限は `AdministratorAccess`。定義は新設の `infrastructure/terraform/modules/github_oidc/` に置き `envs/prod` から呼ぶ。初回の作成だけ利用者の手元 apply で行う。apply role の権限を列挙しないのは、review root が IAM role を作るため列挙が実質的な制限にならず、resource を足すたびの更新が保守対象を増やすためである。

## 論点5: GitHub secrets へ移す値と、state の lock

**ステータス:** 決定

### イテレーション0（論点5）: 値の移動と lock

#### 提案0（論点5）

- repository secrets に次を置く。AWS の access key は置かない（OIDC で role を assume するため）。
  - 共通: `AWS_TERRAFORM_PLAN_ROLE_ARN`、`AWS_TERRAFORM_APPLY_ROLE_ARN`、`TERRAFROM_STATE_S3_BUCKET`、`TERRAFROM_STATE_DYNAMODB_TABLE`、`ROUTE53_HOSTZONE_NAME`
  - prod: `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`、`AMPLIFY_GITHUB_ACCESS_TOKEN`
  - review: `AWS_ACCOUNT_ID`、`CODEBUILD_ARTICACT_S3_BUCKET`、`AWS_CODE_CONNECTION_ID_TO_GITHUB`、`ROUTE53_HOSTZONE_ID`、`DB_NAME`、`DB_HOST`、`DB_PORT`、`DB_USER`、`DB_PASS`、`RAILS_MASTER_KEY`、`REVIEW_BACKEND_ALARM_EMAIL`
  - secret 名は `.env` の key 名に揃える。workflow が `TF_VAR_*` へ読み替える。
- 登録は、`.env` から値を読んで `gh secret set` する script を scratchpad に用意し、利用者が `!` で実行する。値は chat と log に出さない。
- state の lock は現行の DynamoDB のまま使う。S3 の native lockfile へは移さない。

#### 検討記録（論点5・イテレーション0）

secret 名を `.env` の key に揃えるのは、手元の spike と Actions で同じ値を同じ名前で参照でき、読み替えの対応表を一つにできるためである（`TERRAFROM` の綴りも既存の key に合わせる）。lock を移さないのは、DynamoDB の lock は Actions からもそのまま使え、移行は今回の目的に寄与せず手順だけを増やすためである。

#### 提案0へのフィードバック（論点5）

**結果:** 合意

> 3は自明じゃない。4,5,6はok。7は紋切り型じゃない。必要なときにやる。方針は書いておく。特に1つ1つ不確実性があるときにverify-infraしたい。さらにはかっちりした初回作成は本番ライクにどんどん積み上げていくけど、ちょっと試したいレベルの新しいリソースを軽く使ってみますってときや、既存の本番を破壊的に変えるのを試し無しで行えないときに部品で試すことができるときにverify-infraは有用。8はokだけど、どれくらい.envの内容消していいかも気になる。



### 決定（論点5）

repository secrets に、共通（`AWS_TERRAFORM_PLAN_ROLE_ARN`、`AWS_TERRAFORM_APPLY_ROLE_ARN`、`TERRAFROM_STATE_S3_BUCKET`、`TERRAFROM_STATE_DYNAMODB_TABLE`、`ROUTE53_HOSTZONE_NAME`）、prod（`NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`、`AMPLIFY_GITHUB_ACCESS_TOKEN`）、review（`AWS_ACCOUNT_ID`、`CODEBUILD_ARTICACT_S3_BUCKET`、`AWS_CODE_CONNECTION_ID_TO_GITHUB`、`ROUTE53_HOSTZONE_ID`、`DB_NAME`、`DB_HOST`、`DB_PORT`、`DB_USER`、`DB_PASS`、`RAILS_MASTER_KEY`、`REVIEW_BACKEND_ALARM_EMAIL`）を置く。名前は `.env` の key に揃え、workflow が `TF_VAR_*` へ読み替える。AWS の access key は置かない。登録は `.env` を読んで `gh secret set` する script を利用者が `!` で実行する。state の lock は DynamoDB のまま使う。

## 論点6: branch protection と、provider の lock file・Terraform の version

**ステータス:** 決定

### イテレーション0（論点6）: main の保護と再現性

#### 提案0（論点6）

- `main` に branch protection を設定し、PR を経ない push を禁止する。required check は設定しない（paths で絞った workflow を required にすると、Terraform に触れない PR が check 待ちのまま merge できなくなるため）。設定は利用者が GitHub の画面か `gh api` で行う。
- 両 root の `.terraform.lock.hcl` を追跡対象にする（現在は `.gitignore` の `**/.terraform.lock.hcl` で除外されている）。`linux_amd64` と `darwin_arm64` の hash を持たせる。Actions の `terraform init` は `-lockfile=readonly` とする。
- repository 直下に `.terraform-version` を置き、Actions と手元で同じ Terraform の version を使う。

#### 検討記録（論点6・イテレーション0）

apply role の信頼条件は「`main` への push」なので、`main` へ直接 push できると PR の plan を経ずに apply される。nanitabe は public repository で、GitHub Free でも branch protection を使える（x_favorites は private のため使えず、規範で代替していた）。lock file を追跡するのは、Actions の `init` が実行のたびに provider の version を選び直すと、PR の plan と merge 後の apply で provider が違う可能性があるためである。

#### 提案0へのフィードバック（論点6）

**結果:** 合意

> 3は自明じゃない。4,5,6はok。7は紋切り型じゃない。必要なときにやる。方針は書いておく。特に1つ1つ不確実性があるときにverify-infraしたい。さらにはかっちりした初回作成は本番ライクにどんどん積み上げていくけど、ちょっと試したいレベルの新しいリソースを軽く使ってみますってときや、既存の本番を破壊的に変えるのを試し無しで行えないときに部品で試すことができるときにverify-infraは有用。8はokだけど、どれくらい.envの内容消していいかも気になる。



### 決定（論点6）

`main` に branch protection を設定し、PR を経ない push を禁止する。required check は設定しない。両 root の `.terraform.lock.hcl` を追跡対象にし、`linux_amd64` と `darwin_arm64` の hash を持たせ、Actions の `terraform init` は `-lockfile=readonly` とする。repository 直下に `.terraform-version` を置く。

## 論点7: module をローカル実行で確かめる spike の持ち方

**ステータス:** 決定

### イテレーション0（論点7）: spike の置き場所と形

#### 提案0（論点7）

- 旧構成と同じく、各 module の `test/` に spike 用の root（`main.tf`）を置き、local state と stage `verify-infra` で手元から立てる形を引き継ぐ。
- 今回は `frontend/terraform/modules/amplify/test/main.tf` を追加する。Amplify app の名前は `nanitabe-front-verify-infra` とし、prod と重ならないようにする。custom domain は付けない。
- spike は確かめた後に destroy する。立てっぱなしにしない。
- この形と注意点（local state は commit されない、立てたら destroy する、prod / review の state を使わない）を `infrastructure/README.md` に書く。

#### 検討記録（論点7・イテレーション0）

旧 `verify-infra` は各 module の `test/` に local state を持ち、module が消えた後も state だけが手元に残って、撤去範囲の洗い出しから漏れた（`20261024-migrate-frontend-hosting-to-amplify/implementation_review.md` 論点8）。形は引き継ぎ、立てっぱなしにしないことと、README に置き場所を書くことで同じ漏れを防ぐ。

#### 提案0へのフィードバック（論点7）

**結果:** 修正要求（spike を一律に作らない。用途と使う場面を方針として書く）

> 3は自明じゃない。4,5,6はok。7は紋切り型じゃない。必要なときにやる。方針は書いておく。特に1つ1つ不確実性があるときにverify-infraしたい。さらにはかっちりした初回作成は本番ライクにどんどん積み上げていくけど、ちょっと試したいレベルの新しいリソースを軽く使ってみますってときや、既存の本番を破壊的に変えるのを試し無しで行えないときに部品で試すことができるときにverify-infraは有用。8はokだけど、どれくらい.envの内容消していいかも気になる。

各 module に spike 用 `test/` を紋切り型に用意するのではなく、必要になったときに作る。方針として、どんなときに verify-infra を使うかを書いておく。利用者が挙げた場面は次のとおり。

- 一つ一つに不確実性があるとき。
- かっちりした初回作成は本番ライクにどんどん積み上げていく。verify-infra は、ちょっと試したいレベルの新しい resource を軽く使ってみるときに使う。
- 既存の本番を破壊的に変えるのを試しなしで行えないとき、部品で試せる場合に使う。

### 決定（論点7）

spike 用の `test/` は module ごとに一律には作らず、必要になったときに作る。`modules/amplify/test/` は今回作らない。`infrastructure/README.md` に verify-infra の方針を書く。用途は「module をローカル実行で Terraform が動くか確かめる」こと、使う場面は (1) 一つ一つに不確実性があるとき、(2) ちょっと試したいレベルの新しい resource を軽く使ってみるとき、(3) 既存の本番を試しなしで破壊的に変えられず、部品で試せるとき。かっちりした初回作成は verify-infra を経ず、本番ライクに積み上げる。立てたら確かめた後に destroy し、local state と prod / review と重ならない stage 名（`verify-infra`）を使う。

## 論点8: 移行の手順

**ステータス:** 決定

### イテレーション0（論点8）: 手元 apply から Actions への切替順

#### 提案0（論点8）

```text
(1) github_oidc module を追加し、利用者の手元 apply で OIDC と role を作る（最後の手元 prod apply）
(2) 利用者が script で GitHub secrets を登録する
(3) workflow 4 本、lock file、.terraform-version、spike の test/ を feature-258 で追加する
    → feature-258 の PR で plan workflow が動き、要約コメントと S3 の全文を確認する
(4) apply workflow は main でしか動かないため、派生 branch からの途中 merge（Closes なし）で main へ入れる
    → apply workflow が No changes で通ることを確認する
(5) 手元の init_terraform.sh / apply_terraform.sh を削除し、.claude/settings.json の review apply の allow を外す
    README と review_environment.md を新しい経路に書き換える
(6) branch protection を設定する
(7) feature-258 の PR に Closes #258 を付けて merge する（roadmap の完了）
```

#### 検討記録（論点8・イテレーション0）

(1) を手元で行うのは、role が無いと Actions が AWS に接続できないためである。(4) は plugin の `development_flow/branch_pr_issue.md` の経路 2 で、派生 branch から出す（本線 `feature-258` は (7) まで使う）。(4) の時点で apply workflow が `No changes` になるのは、(1) で作った resource と定義が一致しているためで、ここで差分が出れば定義か値の誤りである。branch protection は PR の merge を妨げないため、どの段階で設定してもよい。直接 push が拒否されることを、新しい経路が動いた後に確かめるため最後に置く。

#### 提案0へのフィードバック（論点8）

**結果:** 合意（加えて `.env` からどれだけ消してよいかの確認が来た）

> 3は自明じゃない。4,5,6はok。7は紋切り型じゃない。必要なときにやる。方針は書いておく。特に1つ1つ不確実性があるときにverify-infraしたい。さらにはかっちりした初回作成は本番ライクにどんどん積み上げていくけど、ちょっと試したいレベルの新しいリソースを軽く使ってみますってときや、既存の本番を破壊的に変えるのを試し無しで行えないときに部品で試すことができるときにverify-infraは有用。8はokだけど、どれくらい.envの内容消していいかも気になる。

`.env` の扱いは別の論点（論点9）で扱う。

### 決定（論点8）

論点8の提案0の (1)〜(7) の順で移行する。

## 論点9: 手元の `.env` から消してよい値

**ステータス:** 応答待ち

### イテレーション0（論点9）: `.env` の各 key の利用者

#### 提案0（論点9）

`/etc/opt/app_setting_files/nanitabe/.env` は Terraform だけでなく、`docker-compose.yml`（`frontend`・`backend` の `env_file`）と `scripts/review_backend/start.sh`・`stop.sh` も読んでいる。key ごとの扱いを次のとおりにする。

| key | 今後も手元で使うもの | 扱い |
| --- | --- | --- |
| `RAILS_MASTER_KEY`、`DB_NAME`、`DB_HOST`、`DB_PORT`、`DB_USER`、`DB_PASS`、`FRONTEND_PROD_HOST`、`BACKEND_PROD_HOST` | local の app container（`docker-compose.yml`） | 残す |
| `AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY`、`AWS_DEFAULT_REGION`、`ROUTE53_HOSTZONE_NAME` | review 環境の start / stop script、verify-infra、AWS CLI | 残す |
| `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`、`AMPLIFY_GITHUB_ACCESS_TOKEN`、`AWS_ACCOUNT_ID`、`ROUTE53_HOSTZONE_ID`、`CODEBUILD_ARTICACT_S3_BUCKET`、`AWS_CODE_CONNECTION_ID_TO_GITHUB`、`REVIEW_BACKEND_ALARM_EMAIL`、`TERRAFROM_STATE_S3_BUCKET`、`TERRAFROM_STATE_DYNAMODB_TABLE` | 移行後は prod / review の Terraform では使わない。verify-infra で同じ値が要る場合がある | 残す（理由は下記） |
| `NEXT_PUBLIC_ASSET_ORIGIN` | 誰も使わない（旧構成の static asset の配信元） | 今回消す |

Terraform 専用の値も消さない。GitHub secrets は登録後に値を読み出せないため、`.env` を消すと値を確認できる場所が無くなる。secret の更新や verify-infra のたびに値を再取得する手間が生じる。消すのは、どこからも参照されなくなった `NEXT_PUBLIC_ASSET_ORIGIN` だけにする。

#### 検討記録（論点9・イテレーション0）

`.env` を読む file を repository 全体から探した（`grep` で path を検索）。Terraform の script 4 本に加え、`docker-compose.yml` の `frontend`・`backend` service、`scripts/review_backend/start.sh`・`stop.sh` が読む。`backend/config/application.rb` は `FRONTEND_PROD_HOST`・`BACKEND_PROD_HOST` を参照する。review の script は AWS の認証情報と `ROUTE53_HOSTZONE_NAME` を使う。`NEXT_PUBLIC_ASSET_ORIGIN` は Amplify 移行で `next.config.js` から参照が消えた。

論点1で、手元の値は verify-infra のために残ると決めた。手元で prod / review を apply しないことは規範で担保しており、値を消すことは担保の手段ではない。

#### 提案0へのフィードバック（論点9）

