# Design: frontend の動作確認環境を Amplify で立てて運用する

## 元の依頼内容

動作確認環境運用できるようにしたい（作業 branch は feature-280）

関連 issue #280: 「フロントエンドの動作確認環境をamplifyで立てる」

---

## TL;DR

`main` へ入れる前の変更を、PC 以外の端末から画面の操作で確かめられるようにする。backend の review 環境が API 単体で行っている確認を画面まで広げるため、frontend の動作確認環境を Amplify で立て、backend の review 環境（開発 DB を共有）を向かせる。本番の backend は向かない。

終了時には、確認対象を git の `review` branch へ載せると、frontend の動作確認環境（`https://review-nanitabe.<hosted zone>`）と backend の review 環境の両方が同じ commit で build され、backend を起動すれば PC 以外の端末から画面で確かめられる。Amplify app は Terraform で管理され、GitHub の token は Terraform にも GitHub にも残らない。

---

## 完成後の姿

### workflow

#### 動作確認の手順

```text
(1) 確認対象の branch を main へ rebase し、git push -f origin <branch>:review
      → backend: CodePipeline が image を build して ECR へ push
      → frontend: Amplify の review app が build して配信
(2) 両方の build の成否を確かめる
      backend: aws codepipeline list-pipeline-executions --pipeline-name nanitabe-back_codepipeline_review
      frontend: aws amplify list-jobs --app-id <review app id> --branch-name review
(3) ./scripts/review_backend/start.sh で backend を起動する（30 分で自動停止）
(4) https://review-nanitabe.<hosted zone> を PC 以外の端末で開いて確かめる
(5) ./scripts/review_backend/stop.sh で backend を止める
```

- frontend と backend は同じ `review` branch を監視する。載せた commit が両方で同じになり、片方だけ古いまま確かめる事故を防ぐ。frontend だけの変更を載せても、backend は `main` の上に frontend の変更が乗った commit を build するため、backend の挙動は `main` と同じになる。
- frontend の動作確認環境は常に配信し、起動・停止の操作を持たない。Amplify には app ごとの固定費が無く、操作を二つにすると片方だけ起動する誤りが増えるためである。
- backend が停止している間、frontend の画面は開けるが API が応答しない。データを変える操作はできない。
- 確かめるデータは開発 DB のもので、ローカルの確認と互いに影響する。本番の backend は向かないため、確かめる操作が本番のデータを変えることはない。

#### 立ち上げの手順

```text
(1) 利用者が GitHub で fine-grained personal access token を発行する
      対象は tumeda1992/nanitabe だけ。Contents: read、Metadata: read、Webhooks: read and write
(2) 利用者が手元の AWS CLI で app を作る
      aws amplify create-app --name nanitabe-front-review --repository https://github.com/tumeda1992/nanitabe
        --access-token <token> --platform WEB_COMPUTE
      token はこの command にだけ渡し、どこにも保存しない
(3) review root に import block と frontend の review env を追加し、作業 branch から review の apply を手動起動する
      → app を state へ取り込み、環境変数、branch review、domain association を作る
(4) git の review branch を main へ揃える（git push -f origin main:review）
      現在の review は Amplify 移行前の commit で amplify.yml を含まない
(5) review の build が起動しなければ aws amplify start-job --job-type RELEASE で起動し、成功を確かめる
(6) domain association が AVAILABLE になったら、backend を起動して画面で確かめる
```

- app を CLI で作って import するのは、`aws_amplify_app` が repository への接続に作成時の token を要し、token を Terraform と GitHub に置かない原則（`infrastructure/README.md`）を守るためである。import block は Actions の apply からも実行でき、token は Terraform の state にも GitHub にも残らない。ただし Amplify は token を保存して build のたびの clone に使う（`repositoryCloneMethod = TOKEN`）ため、token の期限が切れるとその app の build が止まる（`implementation_review.md` 論点1）。token を一時的に GitHub secrets に戻して Actions で作ると作成時の値が state に残り、Terraform で repository 無しの app を作って後から接続すると、branch を作れる時点と `repository` の差分の出方が未確認のまま apply が二段になる。
- import は (2) の app が存在してからでないと plan が失敗するため、(2) を (3) より先に行う。import block は取り込みが済んだ後に削除する。
- (4) の force push は backend の CodePipeline も起動するが、`main` の内容を build するだけで backend の挙動は変わらない。`review` への force push は `review_environment.md` の「review 環境に閉じる操作」に含まれる。

### runtime・設定・環境構築

**Terraform の配置:**

```text
infrastructure/terraform/envs/review/main.tf      module "frontend" を追加し、import block を置く（取り込み後に削除）
frontend/terraform/envs/review/main.tf            新設（.gitkeep を置き換える）。modules/amplify を stage = "review" で呼ぶ
frontend/terraform/modules/amplify/               aws provider の制約を ~> 5.0 から >= 5.0 にする（implementation_review.md 論点2）。それ以外は変えない
```

本番（`infrastructure/terraform/envs/prod` → `frontend/terraform/envs/prod` → `modules/amplify`）と同じ形にする。

| `modules/amplify` の入力 | 値 |
| --- | --- |
| `appname`、`stage` | `nanitabe-front`、`review`（app 名は `nanitabe-front-review`） |
| `repository_url` | `https://github.com/tumeda1992/nanitabe` |
| `branch_names` | `["review"]` |
| `backend_origin` | `"https://review-backend-nanitabe.${var.route53_name}"`。backend の review 環境の URL から組み立て、新しい secret を足さない |
| `custom_domain` | `var.route53_name` |
| `custom_domain_sub_domains` | `[{ branch_name = "review", prefix = "review-nanitabe" }]` |
| `github_access_token` | 渡さない（既定値 `null`。`access_token` は `ignore_changes`） |

- prefix を `review-nanitabe` にするのは、backend の review 環境の `review-backend-nanitabe`、x_favorites の動作確認環境の `review-x-favorites` と同じく、「`review-` + 対象」のフラットな 1 ラベルにするためである。同じ account・同じ親 domain を複数の Amplify app が関連付けられることは実測済み。
- build 設定は本番と同じ repository 直下の `amplify.yml`。`NEXT_PUBLIC_ENVIRONMENT` は設定せず、`generateApiOrigin.ts` は `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`（review backend の URL）を返す。backend の CORS は `origins "*"` で、frontend の origin を限定しない。

**workflow の paths:**

| workflow | 変更 |
| --- | --- |
| `terraform-plan-review.yml`、`terraform-apply-review.yml` | `frontend/terraform/envs/review/**` と `frontend/terraform/modules/amplify/**` を足す |
| `terraform-plan-prod.yml`、`terraform-apply-prod.yml` | `frontend/terraform/**` の後に `!frontend/terraform/envs/review/**` を足す |

`modules/amplify` を変える PR では prod と review の両方の plan が動く。どちらの app にも影響する変更なので、両方の plan を見る。

**更新する docs:**

| 対象 | 更新後に書かれていること |
| --- | --- |
| `backend/docs/ai_guideline/development_standard/review_environment.md` | 題名を「review 環境（動作確認環境）」にし、frontend と backend を合わせた環境として説明する。frontend の URL、向き先（backend の review 環境、開発 DB）、共通の `review` branch、frontend の build の確認方法、backend が停止中のときの画面の挙動を足し、「frontend とは繋がない」を消す。path は変えない |
| `frontend/docs/ai_guideline/development_standard/README.md` | 同 document への link |
| `infrastructure/README.md`「環境の使い方」 | frontend を含む review 環境の説明と link |
| `frontend/terraform/modules/amplify/README.md` | app を作り直すときの手順（CLI で作って import）と、review の呼び出し |

`review_environment.md` の path を変えないのは、移すと既存の link（backend の README、`infrastructure/README.md`、steering の記録）の張り替えが要り、効果が「backend の下にある」違和感の解消だけだからである。frontend の読者の導線は README の link で補う。

---

## 要件（Requirements）

### MUST（必達）

- frontend の動作確認環境は backend の review 環境を向き、本番の backend を向かない。
- frontend と backend は同じ git の `review` branch を監視する。
- Amplify app は Terraform で管理し、GitHub の token を Terraform と GitHub に置かない。

### SHOULD（できれば）

なし

### MAY（あれば嬉しい）

なし

### 非目標

- frontend の動作確認環境の起動・停止の仕組み。
- 本番の backend を向く確認環境。
- backend の review 環境の運用（起動・停止、自動停止、開発 DB の共有）の変更。

### 受け入れ基準

- `review` branch へ push すると、frontend の review app の build と backend の CodePipeline が両方起動し、成功する。
- backend を起動した状態で、`https://review-nanitabe.<hosted zone>` を PC 以外の端末で開き、ログインしてカレンダーが表示され、献立を登録できる。登録したデータは開発 DB に入り、本番には入らない。
- review root の `terraform plan` が `No changes` で、state に Amplify app があり、GitHub secrets と Terraform の state に GitHub の token が無い。
- `review_environment.md` の手順だけを読んで、確認対象を載せて画面で確かめられる。

---

## リスクと対策

| リスク | 対策 |
| --- | --- |
| import block の定義と CLI で作った app の属性が食い違い、取り込み後の apply が意図しない変更を出す | 作業 branch からの手動起動の apply は destroy を含む plan で止まる。plan の要約と全文で、変更が環境変数・branch・domain の追加だけであることを確かめてから進める |
| app 名や環境変数を CLI で作るときに誤る | import 後の plan が差分として示す。Terraform が定義どおりに直す |
| domain association の証明書検証が長引く | 動作確認環境であり、本番には影響しない。`domainStatus` が `AVAILABLE` になるまで待つ |
| backend の停止中に frontend を開いて、壊れていると誤解する | document の「何ができて、何ができないか」に書く |

---

## テスト方針

- Terraform は `terraform validate` と、PR の plan（review は import と追加だけ、prod は変更なし）で確かめる。
- 立ち上げ後、受け入れ基準の画面操作を行う。画面の確認は利用者が端末で行い、agent は build の成否、`domainStatus`、`curl` での応答を先に確かめる。

---

## （付録）前提とする既存仕様

- 本番 frontend: `frontend/terraform/modules/amplify/` を `infrastructure/terraform/envs/prod`（`frontend/terraform/envs/prod` 経由）が `stage = "prod"` で呼び、`main` を監視する。`aws_amplify_app` は `access_token` を `ignore_changes` にしており、variable `github_access_token` は既定値 `null`。GitHub の token は repository secrets にも `.env` にも無い。確認元: `frontend/terraform/modules/amplify/main.tf`、`README.md`。
- 動作確認環境の作り方の原則: 本番の resource に review 用の変種を作らず、同じ module を `stage` 違いで呼んで別の実体として作る。frontend の動作確認環境は review root から `modules/amplify` を `stage = "review"` で呼ぶ。確認元: `infrastructure/README.md`「構成上の前提」の環境の分け方、`frontend/terraform/modules/amplify/README.md`。
- backend の動作確認環境（review 環境）: `infrastructure/terraform/envs/review` が `backend/terraform/envs/review` を呼ぶ。git の `review` branch への push で CodePipeline が image を build し、`scripts/review_backend/start.sh` / `stop.sh` で ECS を起動・停止する（起動から 30 分で自動停止）。`https://review-backend-nanitabe.<hosted zone>/graphql` で応答する。開発 DB を共有する。frontend とは繋がない、と明記されている。確認元: `backend/docs/ai_guideline/development_standard/review_environment.md`。
- Terraform の適用: review root は PR で plan、`main` への merge と作業 branch からの手動起動（destroy を含む plan では止まる）で apply する。値は repository secrets（`ROUTE53_HOSTZONE_NAME` 等）から渡す。確認元: `infrastructure/README.md`。
- frontend が backend を指す値: `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` を build 時に埋め込む。backend の CORS は `origins "*"`。認証 token は frontend 側の cookie で持つ。
- 同じ account・同じ親 domain を複数の Amplify app が関連付けられることは実測済み（本番移行の手順 (3)）。

---

## （付録）変更の実行区分

### task-design内で対象成果物へ適用済み

なし

### task-design内の対象成果物反映待ち

なし

### execution plan対象

| 対象 | 掲載理由 | 参照するdesign section |
| --- | --- | --- |
| `frontend/terraform/envs/review/`、`infrastructure/terraform/envs/review/main.tf`、workflow の paths、docs、app の作成と import、`review` branch の更新 | 本番と同じ account の infrastructure を変え、利用者の CLI 操作・import・apply・branch の更新と順序依存の段階を持つ | [立ち上げの手順](#立ち上げの手順)、[runtime・設定・環境構築](#runtime設定環境構築) |
