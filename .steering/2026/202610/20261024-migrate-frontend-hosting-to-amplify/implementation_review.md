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
