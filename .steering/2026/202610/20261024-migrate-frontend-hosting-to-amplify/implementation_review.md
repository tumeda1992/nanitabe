# 議論記録

## 論点1: Phase 1 の build 確認が、起動済み watcher のある container での `yarn build` を指示していた

**ステータス:** 決定

**種別:** レビュー指摘、認識齟齬

### イテレーション0（論点1）: 停滞の原因と build 確認の方法

#### 提案0（論点1）

Phase 1 の build 確認を `docker compose exec frontend yarn build` から `docker compose restart frontend` に変える。`entrypoint.sh` の development 分岐が watcher 起動前に実行する `NODE_ENV=production yarn build` の成否を `docker compose logs frontend` で確認する。tasklist の Phase 1 の DoD、task、task 詳細をこの方法に書き換え、build が失敗しても再実行せずエラー原文を添えて停止する手順と、restart 前後のメモリ確認を足す。

#### 検討記録（論点1・イテレーション0）

**起きたこと。** tasklist-executor は Phase 1 で `amplify.yml`、`frontend/next.config.js`、`frontend/terraform/modules/amplify/main.tf` を 20:03 に書いた後、約 22 分間ほかのファイルを変えず、`yarn build` を 5 回実行して一度も成功しなかった。1・3・4・5 回目は tailwind の段階で `Killed`（exit 137）、2 回目は `/_global-error` の prerender で `TypeError: Cannot read properties of null (reading 'useContext')` だった。executor は 3 回目以降、原因を調べずに再実行していた。

**原因。** tasklist の Phase 1 が「`docker compose exec frontend yarn build` で確認する」と指示していた。`frontend/docs/ai_guideline/development_standard/docker.local.md` は「起動済み watcher がある状態で、Tailwind をコンパイルする操作を `docker compose exec frontend` から実行しない。`yarn build` は `build:css` を含むため該当する」を MUST としている。開発 container では `watch:css` と `next dev` が常駐しており、そこへ Tailwind のコンパイルを重ねたことが exit 137 を招いた見込みである。2 回目のエラーは container の `NODE_ENV=development` のまま `next build` を実行した影響の可能性があり、`next.config.js` の変更が原因だという根拠は無い。

**共有されていなかった知識の前提と、その所在。**

1. 前提: この repository の開発 container では、watcher 常駐中に `yarn build` を `exec` してはならない。build の成否は `entrypoint.sh` が起動時に確認する仕組みがある。
2. 分類: code（`entrypoint.sh`）と既存 docs（`docker.local.md`、`frontend/README.md` からの導線）に書かれていた。参考元 x_favorites の design もこの知識を参照していた。知識が無かったのではなく、task-design の設計前調査で、repository context が開発規約として返した `docker.md` と、`frontend/README.md` が案内する `docker.local.md` を読まなかった process の不足である。
3. 保存先: repository の docs は既に正しい。process 側は、task-design の設計前調査（PrepareStep 3）で repository context が返した開発規約を読む手順が既に skill にあり、それを実行しなかったことが原因である。skill へ新しい規則を足すより、手順の不実行として扱う。tasklist に検証 command を書く時は、その command の実行環境についての開発規約を読む、という点は既存の手順に含まれる。

**停滞を長引かせた二次的な原因。** steering 側（親 session）は、17 分経過時点で checkbox が 0 件であることを「更新漏れ」と読み、ファイルの更新時刻を確認せずに「Tailwind は重い」と推測で正当化した。利用者から二度指摘されて初めて実測した。

#### 提案0へのフィードバック（論点1）

**結果:** 合意

> ok

利用者からは、提案に先立って次の指摘を受けた。

> tasklistは 17分も何してんの？

> え、20分やってんの？あなたはそれ聞いて不思議に思わないの？

> tasklistを更新してないとかじゃなくて進んでないんじゃない？

> 何してんだよ。x_favoriteにも同じこと書かれてただろ

### 決定（論点1）

Phase 1 の build 確認は `docker compose restart frontend` で行い、`entrypoint.sh` が watcher 起動前に実行する `NODE_ENV=production yarn build` の成否を `docker compose logs frontend` で確認する。`docker compose exec frontend yarn build` は `docker.local.md` の MUST に反するため使わない。build が失敗した場合は再実行せず、エラー原文を添えて停止する。restart 前後に frontend のメモリを確認し、80% を超えていたら作業を続けない。tasklist の Phase 1 の DoD、task、task 詳細をこの内容へ更新した。design の変更は無い（plan の検証手順だけの変更）。

## 論点2: `terraform fmt` の適用範囲

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0（論点2）: 既存 file が fmt に適合していない場合の範囲

#### 提案0（論点2）

`terraform fmt` の適用と Phase 8 の `terraform fmt -check` を、この tasklist で新規作成した Terraform file だけに限る。`terraform validate` は repository の terraform 一式を scratchpad へ複製し、`init -backend=false` の後に実行する形を tasklist に明記する。

#### 検討記録（論点2・イテレーション0）

tasklist は Phase 1 で `frontend/terraform` 全体へ `terraform fmt -recursive`、Phase 8 で `infrastructure/terraform/envs/prod` と `frontend/terraform` 全体へ `terraform fmt -check` を指示していた。tasklist-executor の報告によると、既存の file は元から fmt に適合しておらず、一括適用すると今回の変更と無関係な差分が大量に出る。executor は新規の amplify module だけに適用した。Phase 8 の `-check` も同じ理由で必ず失敗する。既存 file の整形は今回の scope 外であり、差分を混ぜると review で変更点を追いにくくなる。

`terraform validate` は本物の `envs/prod` で実行すると `init` が `.terraform` を書き換えるため、executor は scratchpad へ複製して実行した。この方法を tasklist へ反映する。

共有されていなかった前提は「既存の Terraform file が fmt 未適合である」という repository の現状で、tasklist 作成時に確認していなかった。code を見れば分かる事実であり、docs へ書く知識ではない（現状のスナップショットであり、整形されれば変わる）。

#### 提案0へのフィードバック（論点2）

**結果:** 合意

> ok

### 決定（論点2）

`terraform fmt` の適用と Phase 8 の `terraform fmt -check` は、この tasklist で新規作成した Terraform file（`frontend/terraform/modules/amplify/main.tf`）だけを対象とする。`terraform validate` は repository の terraform 一式を scratchpad へ複製し、`init -backend=false` の後に実行する。tasklist の Phase 1 の task 詳細と Phase 8 の task をこの内容へ更新した。

## 論点3: agent による本番 Terraform の apply が auto mode の分類器に拒否される

**ステータス:** 決定

**種別:** 認識齟齬

### イテレーション0（論点3）: apply の実行者

#### 提案0（論点3）

この tasklist の残りの apply は、tasklist-executor が plan を作って要約と apply コマンドを提示して止まり、利用者が `!` で承認済みの plan file を指定した `terraform apply <plan file>` を実行する。

#### 検討記録（論点3・イテレーション0）

tasklist は apply を tasklist-executor が実行する前提で書いていた。実際には、Claude Code の auto mode の分類器が `[Protected-Scope IaC Apply]` として本番 Terraform の apply を拒否した。利用者が `settings.local.json` に `Bash(terraform apply:*)` と `Bash(terraform plan:*)` を追加しても、この拒否は解けなかった。分類器の判定は allow rule と別の層で行われる。

共有されていなかった前提は「agent 実行環境では本番 IaC の apply を agent が実行できない」ことで、tasklist 作成時に確認していなかった。repository の `infrastructure/README.md` は review 環境について「agent が permission を持って `apply_terraform.sh` を実行する」と書いているが、それは review 環境の script に限った許可であり、prod には当たらない。この知識の保存先は、`terraform-on-github-actions` phase の設計で適用経路そのものを決めるときに扱う（適用の実行者は同 phase の scope である）。

#### 提案0へのフィードバック（論点3）

**結果:** 合意

> 少なくともローカル実施の今は方法2でいきたいよ。settings.local.jsonを変えた

方法 2（allow rule の追加）を試したが分類器の拒否は解けなかったため、以後は利用者が `!` で apply する形で進め、利用者は (1-a) 以降の apply をすべてこの形で実行した。

### 決定（論点3）

この tasklist の apply は、tasklist-executor が plan file を scratchpad に作り、要約と `cd <envs/prod> && export $(grep -v '^#' <.env> | xargs) && terraform apply <plan file>` の形のコマンドを提示して止まり、利用者が `!` で実行する。agent が apply を実行できない前提は、`terraform-on-github-actions` phase の設計で適用経路を決める際の入力とする。

## 論点4: 撤去の apply で失敗した resource（ACM 証明書、ECR、S3）

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0（論点4）: plan 確認で見落とした失敗要因

#### 提案0（論点4）

失敗した resource は、原因を解消してから plan を作り直して apply する。ACM 証明書は CloudFront の変更反映後に (3) の plan へ含めて削除し、ECR と S3 は利用者が中身を空にしてから再 plan して削除する。

#### 検討記録（論点4・イテレーション0）

- (2) の apply で us-east-1 の ACM 証明書の削除が 19 分待ったあと `ResourceInUseException` で失敗した。CloudFront distribution の update は完了していたが、反映が終わる前に Terraform が証明書を削除しようとしたと見ている。その後 `InUseBy` が空になり、(3) の apply で 1 秒で削除できた。この待ちで本番の停止時間が想定より伸びた。
- (5) の apply で ECR repository が image 10 件残存（`RepositoryNotEmptyException`）、S3 bucket が version と delete marker 3,557 件残存（`BucketNotEmpty`）で失敗した。tasklist は S3 だけを想定していて、ECR の image は plan 確認時に見落とした。利用者が scratchpad の script で両方を空にし、再 plan（2 to destroy）を apply して削除した。

共有されていなかった前提は「中身を持つ resource（ECR、versioning 有効な S3）は Terraform の destroy では消えず、`force_delete` / `force_destroy` が無い限り事前に空にする必要がある」ことと「CloudFront から外した証明書はすぐには削除できない」ことである。どちらも Terraform と AWS の一般的な挙動で、この repository の docs へ書く知識ではない。撤去を設計する時に、中身を持つ resource を列挙して事前に空にする手順を tasklist へ入れる、という process の問いに当たる。

#### 提案0へのフィードバック（論点4）

**結果:** 合意（利用者が script と再 plan の apply を実行）

### 決定（論点4）

ACM 証明書は (3) の apply で、ECR repository と S3 bucket は中身を空にした後の再 plan の apply で削除した。撤去を設計する時は、中身を持つ resource を列挙し、空にする手順を apply の前に置く。

## 論点5: `docker-compose.yml` の `frontend_next_lambda` service の削除

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0（論点5）: tasklist 外の変更の追認

#### 提案0（論点5）

tasklist-executor が tasklist 外で行った `docker-compose.yml` からの `frontend_next_lambda` service の削除を維持する。

#### 検討記録（論点5・イテレーション0）

この service は削除した `frontend/buildOnLambda/Dockerfile` を参照しており、残すと `docker compose` の構成が壊れる。design の「Amplify 移行で更新する docs」と変更対象の洗い出しで、`docker-compose.yml` からの参照を確認していなかった。旧構成の撤去を設計する時に、削除する定義を参照している file を repository 全体から探す必要があった。

#### 提案0へのフィードバック（論点5）

**結果:** 異論なし（steering から報告し、利用者から反対が無かった）

### 決定（論点5）

`docker-compose.yml` から `frontend_next_lambda` service を削除した状態を維持する。`docker compose config` は成功している。

## 論点6: アプリケーションのログを AWS resource と一緒に destroy しない構成にする

**ステータス:** 保留

**種別:** レビュー指摘

### イテレーション0（論点6）: ログの lifecycle の方針

#### 検討記録（論点6・イテレーション0）

撤去の前に利用者から、CloudWatch Logs も消えるのかと質問があった。確認した事実は次のとおり。

- Terraform が管理する log group は API Gateway のアクセスログ（`aws_cloudwatch_log_group.api_logs`）だけで、撤去の apply で中身ごと削除された。
- 旧 Lambda と CodeBuild のログ（`/aws/lambda/nanitabe-front-prod`、`/aws/codebuild/nanitabe-front_build_prod`）は各 service が自動で作った log group で Terraform の管理外であり、撤去後も残っている。保存期間は無期限。
- Amplify の SSR のログも Amplify が自動で作る log group で、Terraform の destroy では消えない見込み（未確認）。

利用者の方針:

> まぁそのリソース固有のログはそのリソースに紐ついて消えてもいいか。だけど、アプリケーションのログは、AWSリソースというよりアプリケーションに紐ついているから、今後は一緒にデストロイしないようにそもそも構築から考えたいね。

この方針は今回の phase の変更を必要としない（アプリケーションのログは結果的に残っている）。どこへ反映するか（`infrastructure/README.md`「構成上の前提」への原則の追加、log group を Terraform で管理する場合の `prevent_destroy` 等）は未決である。

### 再開条件（論点6）

phase `amplify-migration` の完了報告の後、反映先と内容を利用者と決める。`terraform-on-github-actions` phase で `infrastructure/README.md` を書き換える際の入力にもなる。

## 論点7: phase 完了時の途中 merge を本線 branch から出していた

**ステータス:** 決定

**種別:** レビュー指摘、認識齟齬

### イテレーション0（論点7）: 途中 merge の branch

#### 提案0（論点7）

PR #283（head は本線 `feature-258`）を merge せずに閉じ、派生 branch `feature-258-amplify-migration` を同じ commit から作って、そこから `Closes` を持たない PR #288 を出す。本線 `feature-258` は issue #258 の完了まで使い続け、#288 の merge 後に `main` を取り込む。design の該当記述をこの形へ直す。

#### 検討記録（論点7・イテレーション0）

design は「phase 完了時に `feature-258` を `main` へ merge する。経路 2 なので `Closes` を付けない」とし、tasklist も PR #283（本線 `feature-258` から `main`）の本文から `Closes` を外す形にしていた。これを merge すると、roadmap の後段 phase を続ける branch が無くなる。`feature-258` を使い続ければ merge 済みの branch 名の再利用になり、別 branch で続ければ issue を閉じる本線が無くなる。

plugin の `development_flow/branch_pr_issue.md` は、検証のための merge を「同じ issue に属する派生 branch で立てる」とし、「merge 済みの branch 名を再利用しない」としている。この標準は設計前調査で読んでおり、(1-b) の途中 merge では派生 branch を使っていた。それなのに phase 完了時の merge には当てはめなかった。知識の不足ではなく、同じ判断を二か所で行う設計で片方にだけ標準を当てた process の不足である。利用者の指摘のとおり、roadmap で issue を一つにすると決めた時点で分かることだった。

#### 提案0へのフィードバック（論点7）

**結果:** 合意（案 b）

> bだし、こんなのこの段になって聞くなよ。最初からわかることだろ

### 決定（論点7）

PR #283 は merge せずに閉じた。派生 branch `feature-258-amplify-migration` から PR #288（`Closes` なし、#258 を参照）を出した。本線 `feature-258` は issue #258 の完了まで使い続け、#288 の merge 後に `main` を取り込む。子 design の該当記述を更新した。

## 論点8: 旧 module 用の spike 環境 `verify-infra` と、手元に残った旧 module directory

**ステータス:** 決定

**種別:** レビュー指摘、認識齟齬

### イテレーション0（論点8）: 撤去範囲の洗い出し漏れ

#### 提案0（論点8）

旧 module 用の `verify-infra` 環境の撤去と、手元の旧 module directory の削除を、この phase の Phase 9 として行う。module をローカル実行で確かめる用途は残し、新しい構成での持ち方を roadmap の phase `terraform-on-github-actions` の scope と dependency results に加える。

#### 検討記録（論点8・イテレーション0）

Phase 7 の完了後、利用者から「旧来の構成を消したと言っていたが、これが消した状態か」と指摘を受けた。確認すると、git が追跡する旧 module の file は削除されていたが、手元の `frontend/terraform/modules/{apigateway,cicd,cloudfront,ecr,lambda,s3}` は、ignore されている `test/terraform.tfstate` と `.terraform/` を残して存在していた。その state が AWS 上の `verify-infra` 環境（Lambda、API Gateway、CloudFront と証明書・record、ECR、CodeBuild・CodePipeline、S3）を管理していた。

steering は最初、`verify-infra` を「旧構成の複製」と決めつけて撤去を提案し、利用者から「なぜ消せると思っているのか」と指摘された。利用者によると、`verify-infra` はローカル実行経由で Terraform が動くかを確かめる spike 的な環境である（issue #146 で `deploy-test` から改名）。steering は続けて「試す対象の module を消したので用途も無くなった」と述べ、利用者から「この用途は今後存在しないと思っているのか」と指摘された。用途は新しい module（`modules/amplify`）にも当てはまり、残る。撤去してよいのは旧 module 用の実体だけである。

共有されていなかった前提と原因:

1. 撤去の範囲を決めた時、git が追跡する file と prod の state だけを見て、旧 module を prod 以外の誰が使っているか（ignore された local state とそれが管理する環境）を洗い出していなかった。
2. 環境の実体と、その環境が担う用途を区別していなかった。実体を消すときに、用途の受け皿が新しい構成にあるかを問わなかった。

2 は repository を問わず起きる判断の誤りで、撤去を設計する時の問い（「この実体が担っている用途は何か。撤去後にその用途の受け皿はあるか」）にあたる。保存先は roadmap 全体の完了時の再発防止 review で決める。

#### 提案0へのフィードバック（論点8）

**結果:** 合意

> ok

利用者の指摘の原文:

> 旧来の構成を消したって言ってたけど、これが消した状態なの？

> なんでverify-infraを消せると思ってるの？ 今回はlambdaによるビルドを消しただけでしょ。 2が残っていて終わったとできる理由がわからない

> ちげぇよ。ローカル実行経由でterraformが動くか確かめるspike的な扱いの環境だよ。

> は？じゃあこの用途は今後存在しないって思ってるってこと？

### 決定（論点8）

旧 module 用の `verify-infra` 環境を撤去し、手元の旧 module directory を削除する作業を tasklist の Phase 9 として追加した。module をローカル実行で確かめる用途は残し、新しい構成での持ち方を roadmap の phase `terraform-on-github-actions` の scope と dependency results へ追加した。PR #288 は Phase 9 の完了後に merge する。
