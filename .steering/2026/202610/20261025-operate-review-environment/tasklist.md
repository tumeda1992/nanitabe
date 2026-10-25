# Tasklist: frontend の動作確認環境を Amplify で立てて運用する

設計参照: `./design.md`

前提:

- review の Terraform の apply は、作業 branch から `terraform-apply-review.yml` を手動起動して行う（agent が事前確認なしで行ってよい。destroy を含む plan では workflow が止まる）。prod の apply は行わない。
- GitHub の token、domain 名、account ID を chat、log、commit、PR に出さない。
- 止まるのは、利用者にしかできない操作（token の発行、app の作成、merge、端末での画面確認）と、想定外のときだけ。

## Phase 1: 定義と docs を用意する（AWS と remote は変えない）

### DoD（完了条件）

- `frontend/terraform/envs/review/main.tf` と、`infrastructure/terraform/envs/review/main.tf` からの呼び出しがあり、scratchpad に複製した repository で `terraform validate` が通る。
- workflow 4 本の paths が design の表のとおりになり、YAML として parse できる。
- design の「更新する docs」の 4 file が更新されている。

### Tasks

- [x] `frontend/terraform/envs/review/main.tf` を作り、`.gitkeep` を消す
- [x] `infrastructure/terraform/envs/review/main.tf` に `module "frontend"` を足す
- [x] workflow 4 本の paths を変える
- [x] scratchpad で `terraform fmt -check`（新規 file）と `terraform validate`（review root）を通す
- [x] docs を更新する（emit 前に document-review を通す）
  - [x] `backend/docs/ai_guideline/development_standard/review_environment.md`
  - [x] `frontend/docs/ai_guideline/development_standard/README.md`
  - [x] `infrastructure/README.md`「環境の使い方」
  - [x] `frontend/terraform/modules/amplify/README.md`
  - [x] `frontend/terraform/modules/amplify/README.md` に、Amplify が token を保存して clone に使うこと、期限切れで build が止まること、`aws amplify update-app --access-token` で入れ直す手順を足す（`implementation_review.md` 論点1）
- [x] app 作成用の script を scratchpad に用意する

### 各task詳細

#### `frontend/terraform/envs/review/main.tf`

`frontend/terraform/envs/prod/main.tf` と同じ書き方で、design の「`modules/amplify` の入力」の表の値を渡す。variable は `route53_name` だけを受け取る（`backend_origin` は `"https://review-backend-nanitabe.${var.route53_name}"` を module 内で組み立てる）。`github_access_token` は渡さない。

#### `infrastructure/terraform/envs/review/main.tf`

`module "frontend"`（`source = "../../../../frontend/terraform/envs/review"`、`route53_name = var.route53_name`）を足す。import block は Phase 3 で足す（app id が Phase 2 まで決まらないため）。

#### workflow の paths

design の「workflow の paths」の表のとおり。prod の 2 本は `frontend/terraform/**` の直後に `!frontend/terraform/envs/review/**` を置く（GitHub の paths は後に書いた否定が優先する）。

#### docs

design の「更新する docs」の表のとおり。domain 名は `<hosted zone>` と書く。`review_environment.md` には design の「動作確認の手順」と、backend が停止中のときの画面の挙動、確かめるデータが開発 DB であることを書く。`modules/amplify/README.md` には「app を作り直すときは、token を CLI の一回だけに渡して `aws amplify create-app` で作り、import block で取り込む」手順を書く。

#### app 作成用の script

`scratchpad/create_review_amplify_app.sh`。token を `read -rs` で標準入力から受け取り（画面に出さない）、`aws amplify create-app --name nanitabe-front-review --repository https://github.com/tumeda1992/nanitabe --access-token "$T" --platform WEB_COMPUTE` を実行し、app id と default domain だけを表示する。AWS CLI の設定の認証情報を使う。

## Phase 2: Amplify app を作る（利用者）

### DoD（完了条件）

- AWS に `nanitabe-front-review` の Amplify app があり、`aws amplify list-apps` で app id が分かる。

### Tasks

- [x] 利用者に、token の発行（`tumeda1992/nanitabe` だけ、Contents: read、Metadata: read、Webhooks: read and write）と、利用者の端末での `bash <scratchpad>/create_review_amplify_app.sh` の実行を依頼して止まる（`read -rs` を使うため、`!` ではなく利用者の terminal で実行する）
- [x] app id を `aws amplify list-apps` で確認する

## Phase 3: app を Terraform に取り込み、branch と domain を作る

### DoD（完了条件）

- `feature-280` の PR で review の plan が成功し、要約が import 1 件と追加（branch、domain association）だけを示す。prod の plan は動かない。
- 作業 branch から review の apply を手動起動して成功し、post-apply plan が 0 になる。
- `aws amplify get-domain-association` の `domainStatus` が `AVAILABLE` になる（`AWAITING_APP_CNAME` 等の途中の状態は待つ）。

### Tasks

- [x] `infrastructure/terraform/envs/review/main.tf` に import block（`to = module.frontend.module.amplify.aws_amplify_app.this`、`id = "<app id>"`）を足す
- [ ] Phase 1・3 の変更を意味単位で commit し、`feature-280` を push して `main` への PR を作る（`Closes #280` は付けない。Phase 5 で付ける）
- [ ] plan workflow の要約を確認する（review は import と追加だけ、destroy 0。prod の plan は起動しない）
- [ ] `gh workflow run terraform-apply-review.yml --ref feature-280` で apply し、成功と post-apply plan 0 を確認する
- [ ] `domainStatus` が `AVAILABLE` になるまで待つ（15 秒間隔、上限 30 分。`FAILED` か上限で抜けて止まる）

## Phase 4: `review` branch を揃え、build を確かめる

### DoD（完了条件）

- `review` branch が `main` と同じ commit を指す。
- frontend の review app の `review` の build と、backend の CodePipeline が成功する。
- `curl` で `https://review-nanitabe.<hosted zone>/login` が 200 を返す。

### Tasks

- [ ] `git push -f origin main:review` を実行する
- [ ] frontend の build を確認する（job が無ければ `aws amplify start-job --job-type RELEASE` で起動し、完了を待つ）
- [ ] backend の CodePipeline の実行が成功することを確認する
- [ ] `curl` で frontend の `/login` の応答を確認する（hosted zone 名は `.env` から読み、chat に出さない）

## Phase 5: import block を外し、品質を確かめる

### DoD（完了条件）

- import block が無く、review の plan が `No changes` になる。
- 新規 Terraform file の `terraform fmt -check` と、review root の `terraform validate` が通る。

### Tasks

- [ ] import block を削除して commit・push し、PR の review の plan が変更なしで通ることを確認する
- [ ] `terraform fmt -check`（新規 file）と `terraform validate`（scratchpad、review root）

## Documentation reviewと実装後振り返り

- [ ] code readingまたは実装で永続化候補を得た場合、その場でdoc-enricherを提案modeで適用する
  - [ ] 提案がある場合だけユーザー承認後に既存READMEまたは既存docsへ反映する
- [ ] 実装、review、validationからfeedbackまたは実装とのずれが生じた場合、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用する
  - [ ] 「共有されていなかった知識の前提は何か」「codeを読めば分かるか、設計意図か、process不足か」「どこに書けば次回この議論が不要になるか」を確認し、合意後だけ反映する
  - [ ] designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す。review後に実装を自動再開しない

---

## 動作確認

### DoD

Tasks に挙げた確認をユーザーが行い、期待どおりであることを確認した。

### Tasks

- [ ] agent が `start.sh` で backend を起動し、frontend の `/login` と backend の `/graphql` の応答を `curl` で確かめてから、ユーザーに依頼する（PC 以外の端末で `https://review-nanitabe.<hosted zone>` を開き、ログイン、カレンダーの表示、献立の登録ができ、登録したデータが本番に入らないこと）。確認後に `stop.sh` で止める
- [ ] feedbackがあれば、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用し、decisionをcallerへ返す
  - [ ] feedbackがなければ`[x] ~~feedback収集~~（feedbackなし）`の形式で完了扱いにする

---

## 完了後のaction

> ⚠️ 動作確認phaseが完了するまでcommit、push、PRを促したり実行したりしない。急かすことも禁止する。Phase 3〜5 の commit・push・PR は、各 phase の検証に必要なため例外とする。

- [ ] 残りの変更を意味単位で commit し、`feature-280` を push する
- [ ] Phase 3 で作った PR の本文に `Closes #280` を加え、変更内容と確認結果を書く（plugin の `development_flow/branch_pr_issue.md` の経路 1）
- [ ] merge は利用者が行う

---

## 参照

- 設計の正本: 同じdirectoryの `./design.md`
- 完了条件、取消完了、subtask分割、checkbox更新timingの規則の正本: `tasklist-executor/SKILL.md`
- tasklistへ載せるtaskの範囲の正本: `task-design/tasklist-design.md`
