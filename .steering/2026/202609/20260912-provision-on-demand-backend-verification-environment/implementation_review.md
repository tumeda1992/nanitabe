# 実装レビュー記録

## 論点1: apply の差分確認を誰がどう行うか

**ステータス:** 決定

**種別:** 実装中に判明した設計の不足

### イテレーション0: permission を script へ与えるときに契約が飛ばされないようにする

#### 提案0

`infrastructure/terraform/envs/review/apply_terraform.sh` を、plan の実行と差分の判定を含む形にする。

```sh
# 環境変数の export は既存 prod と同じ形のまま

terraform plan -out=tfplan.review

# destroy が 1 件でもあれば apply せず停止する
destroy_count=$(terraform show -json tfplan.review | python3 -c "
import json,sys
d = json.load(sys.stdin)
print(sum(1 for c in d.get('resource_changes', [])
          if 'delete' in c['change']['actions']))
")

if [ "$destroy_count" -ne 0 ]; then
  echo "ERROR: plan に destroy が ${destroy_count} 件含まれる。apply せず停止する。"
  exit 1
fi

terraform apply tfplan.review
```

これにより次が成立する。

- 常に plan、判定、apply の順で実行され、確認済みの差分だけが適用される。
- destroy を含む差分は script 自身が止める。design の「閉じる操作」の定義と一致する。
- permission を `Bash(bash infrastructure/terraform/envs/review/apply_terraform.sh)` の 1 行で与えられる。既存の `Bash(bash scripts/github/create_pr_from_branch_name.sh)` と同じ形になる。

`tfplan.review` は `.gitignore` の `**/tfplan*` で追跡対象から外す。

prod 側の `apply_terraform.sh` は変更しない。

#### 提案背景

**事象**

`tasklist-executor` が Phase 1 の `terraform apply` で停止した。harness の permission classifier が `terraform apply` を block し、flag の有無に関わらず AWS への呼び出し前に止まる。

**この事象は design が予期していた**

`design.md` の付録「前提とする既存仕様」に、参照元 steering の要点として次を記載していた。

> 実行者の線引きを満たしていても harness が実行を許可するとは限らない。block 時は plan を file へ保存し、その file を apply する。

つまり事象そのものは想定内であり、対処の方向も決まっていた。

**判明した設計の不足**

`design.md` は「`terraform apply` の前に必ず `terraform plan` を実行し、差分が定義の条件を満たすことを確認する。満たさない差分が 1 件でもあれば apply せず停止して報告する」と定めた。しかし**確認の実行主体を人または agent の目視としていた**。

permission rule を script へ与えて agent が実行できるようにすると、この目視確認を経ずに apply が走りうる。契約は残っているが、それを守らせる仕組みが無い状態になる。

契約を script 自身へ埋め込めば、permission を与えても契約が飛ばされない。

#### 提案0へのフィードバック

**結果:** 受諾。あわせて、この方式を他の env へ広げるかは別論点として扱うことになった。

> ok。ただ一般運用するかどうかは別だから一旦論点立てておいて

### 決定

review 環境の `apply_terraform.sh` に plan の実行と destroy 判定を組み込む。判定で destroy が 1 件でも見つかれば apply せず異常終了する。

permission は `Bash(bash infrastructure/terraform/envs/review/apply_terraform.sh)` として script 単位で与える。`terraform apply` を直接許可する rule は作らない。`-auto-approve` を使う経路を許可しないため。

prod 側の `apply_terraform.sh` は変更しない。この形を他の env へ広げるかは論点2で扱う。

`design.md` の「実行者の線引き」へ、確認の実行主体が script であることを反映する。

## 論点2: plan 検証を組み込んだ apply script を一般運用するか

**ステータス:** 保留

**種別:** TBDヒアリング

### この論点で扱うこと

論点1で review 環境の `apply_terraform.sh` に組み込んだ「plan、destroy 判定、apply」の形を、他の env（現時点では prod）へも広げるかを決める。

判断材料。

- review 環境でこの形を採ったのは、agent が permission を持って apply を実行するためである。prod の apply を agent が実行する想定は現在ない。人が実行する場合、`terraform apply` の対話確認で差分を目視できるため、script 側の判定が無くても差分を見ずに適用することにはならない。
- 一方で、destroy を含む差分に対して人が確認を読み飛ばす可能性は prod でも同じであり、むしろ prod のほうが影響が大きい。
- prod の script を変えると、既存の運用手順（`./apply_terraform.sh` を実行する）の挙動が変わる。plan が毎回走るため実行時間が伸びる。
- `python3` への依存が増える。現在の script は `terraform` と shell の組み込みコマンドだけで完結している。

### 再開条件

今回の steering の実装とユーザー動作確認が完了した後に再開する。review 環境でこの script を実際に何度か使い、plan が毎回走ることの体感や、destroy 判定が誤検知しないかを確かめてから判断するほうが、材料が具体的になるためである。

再開時に決めること: prod へ広げるか、review 環境に限定したままにするか。広げる場合の移行手順と、`python3` 依存を許容するか。

## 論点3: 公開範囲の確認が steering 成果物へ及んでいなかった

**ステータス:** 決定

**種別:** 認識齟齬

### イテレーション0: 調査結果を成果物へ書く時点で公開可否を通す

#### 提案0

`design.md` と `task-design-discussion.md` から、既存の本番環境と DB の構成に関する記述を除去する。

除去する対象。

- 本番 backend と開発 DB が動いている場所、および両者が同一であること
- DB の port 番号
- DB 側の security group が接続元を IP で絞っていないこと、その具体的な開放範囲
- hosted zone の実名

設計判断の根拠は保つ。たとえば「DB 側の security group は接続元を IP で絞っていない。したがって task の public IP が起動ごとに変わっても DB へ到達できる」という形にし、なぜ接続元の登録が不要かという根拠は残したうえで、具体的な開放範囲を落とす。

今回作る review 環境自身の構成は残す。task の port を `0.0.0.0/0` で開けることと、それを `config.hosts` で遮断することは、この design の正本であり、対策と対で書かれている。

#### 提案背景

**事象**

Phase 1 の commit を検証したところ、`.steering/` 配下が commit され `review` branch として GitHub（public）へ push 済みであり、その中に次が含まれていた。

- 本番 backend と開発 DB が同一の場所にあること
- DB の port 番号
- DB 側の security group が接続元を絞っておらず、防御が認証だけであること

三つ目が最も重い。DB の到達先、port、防御の薄さが揃っており、攻撃経路をそのまま示す。

**根本原因**

`doc-enricher` の提案時に、開発 DB の所在を `docker.md` へ書く案がユーザーへ拒否された。理由は repository が public であることだった。その直後に公開範囲の確認を行ったが、**確認の対象を「これから書く公開 document」に限定し、既に書き終えていた `design.md` と `task-design-discussion.md` へ遡らなかった**。

さらに、公開範囲についてユーザーへ選択肢を示したとき、扱ったのは domain 名だけだった。同じ `.steering/` に DB の所在と security group の状態が含まれることを提示していなかった。ユーザーは domain 名についてのみ「`.steering/` は作業記録としてそのまま残す」と判断しており、DB の所在まで許容したわけではない。

**分類**

process の不足にあたる。調査で得た事実を `design.md` の付録へ書く時点で、公開可否のフィルタを通していなかった。調査の網羅性と、成果物へ書いてよいかは別の判断であり、後者を省いていた。

#### 提案0へのフィードバック

**結果:** 受諾。除去したうえで `review` branch を force push で上書きする方針が示された。

> 最新のスナップショットに情報が残ってなきゃ、感知されないから最新で消しときゃ大丈夫よ。スカッシュマージで、mainブランチのコミット履歴でもまるまるから

`feature-278` は `origin` へ未 push であり、`review` branch だけが公開されている。`review` を force push で上書きすれば最新から消える。`feature-278` は後で squash merge されるため、`main` の履歴に中間 commit は残らない。

### 決定

`design.md` と `task-design-discussion.md` から既存の本番・DB 構成の詳細を除去し、commit して `review` branch を force push で上書きした。

再発防止として、調査で得た事実を成果物へ書く時点で公開可否を通す。対象は公開 document だけでなく `.steering/` 配下も含む。`.steering/` が tracked であることは `.agents/skills/tumeda-dev-plugin-context.md` の「公開範囲」に記載済みだが、そこでの制約が「repository へ commit する document」全般に及ぶことを、調査結果を書く場面でも適用する。

判断の分かれ目は、その記述が**既存環境の構成**か、**今回の design が作る対象**かである。前者は書かない。後者は対策と対で書く。

## 論点4: 停止中の挙動の書き方が実態とずれていた

**ステータス:** 決定

**種別:** 実装で判明した記述の不正確さ

### イテレーション0: 「到達できなくなる」を実際の応答へ合わせる

#### 提案0

`design.md` の受け入れ基準・テスト方針・環境別の完成状態にある「到達できなくなる」「応答しなくなる」を、「HTTP 500 を返す」へ改める。

`review_environment.md` へ「停止中に URL を叩くとどうなるか」の節を足し、500 が停止中の正常な状態であることと、その理由を書く。

#### 提案背景

Phase 2 の検証で、停止 script の実行後に URL を叩くと HTTP 500 と `{"message":"Internal Server Error"}` が返ることが分かった。

`design.md` は受け入れ基準を「同じ endpoint へ到達できなくなる」と書いていた。利用者から見た意味としては正しいが、実際の応答は「何も返らない」ではなく「500 が返る」である。

これは設計どおりの挙動である。API Gateway、ACM 証明書、Route53 レコードは常設であり、停止で変わるのは integration URI だけと決めた。停止時に URI を到達しない address（`192.0.2.1`）へ戻すため、API Gateway は転送先へ届かず 500 を返す。

問題は挙動ではなく記述である。「到達できなくなる」とだけ書かれていると、停止中に 500 を見た利用者が環境の異常と誤認する。停止中の 500 が正常であることを document へ明示しておかないと、次に使う人が原因調査を始めることになる。

#### 提案0へのフィードバック

**結果:** 実装の検証結果から一意に導ける記述の修正であり、設計判断を変えないため、design と document へ直接反映した。

### 決定

停止中の挙動を「HTTP 500 が返る」と明記する。`design.md` の受け入れ基準・テスト方針・環境別の完成状態を修正し、`review_environment.md` へ「停止中に URL を叩くとどうなるか」の節を追加した。

同節では、500 が停止中の正常な状態であることに加え、停止中に前の起動の IP を指したままにしない理由（IP が再割当され、request が第三者のホストへ届くため）も書いた。挙動だけを書くと、次に構成を変える人が「500 を返すより到達不能にしたほうが綺麗だ」と考えて URI を残す方向へ変える余地が生まれるためである。

## 論点5: EventBridge Scheduler の IAM action 名が誤っていた

**ステータス:** 決定

**種別:** 実装で判明した設計の誤り

### イテレーション0: API Gateway v2 の管理 API に必要な IAM action へ直す

#### 提案0

`design.md` の IAM role 表にある EventBridge Scheduler role の権限を、`ecs:UpdateService` と `apigatewayv2:UpdateIntegration` から、`ecs:UpdateService` と `apigateway:PATCH`、`apigateway:GET` へ改める。

理由を併記する。API Gateway v2 の管理 API は HTTP verb ベースの IAM action（`apigateway:PATCH` 等）で認可され、`apigatewayv2:UpdateIntegration` という action 名は評価されない。

#### 提案背景

**事象**

Phase 3 の `REVIEW_BACKEND_AUTO_STOP_MINUTES=1` による発火検証で、schedule が発火した後に `desired_count` は 0 になったが、API Gateway の integration URI が直前の task の実 IP を指したまま戻らなかった。

CloudTrail を確認したところ、Scheduler が assume した role が `apigateway:PATCH` の呼び出しで `AccessDenied` になっていた。role には `apigatewayv2:UpdateIntegration` を与えていたが、この action 名は評価されない。

**この失敗は design が名指ししていた状態そのものである**

`design.md` は停止処理を「task の終了」と「integration URI を到達しない値へ戻す」の 2 つが揃って完了すると定義し、片方だけが成功する状態を明示的に避けるべきものとして扱っていた。停止中に解放済みの IP を指したままにすると、その IP が別の AWS 利用者へ再割当された後、URL を叩いた request が第三者のホストへ届くためである。

検証で実際にその状態が発生した。発生後ただちに `stop.sh` を実行して安全な状態へ戻している。

**なぜ短い検証で見つかったか**

`REVIEW_BACKEND_AUTO_STOP_MINUTES=1` で実際に発火させたことで見つかった。schedule の作成が成功したことだけを確認して発火を待たない形にしていたら、この欠陥は本番の 30 分後に初めて現れ、しかも誰も見ていない時間帯に起きた可能性が高い。

tasklist を「1 分に縮めて実際に発火させる」形へ変えた判断が、結果としてこの欠陥を捕まえた。30 分待つ代わりに短縮したのであって、発火自体を省いたわけではないことが効いている。

#### 提案0へのフィードバック

**結果:** 実測で確定した事実であり、設計判断の選択ではないため design へ直接反映した。

### 決定

EventBridge Scheduler role の権限を `ecs:UpdateService`、`apigateway:PATCH`、`apigateway:GET` とする。`design.md` の IAM role 表を修正し、API Gateway v2 の管理 API が HTTP verb ベースの IAM action で認可されることを理由として併記した。

実装側は `backend/terraform/modules/scheduler_role/main.tf` で修正済みであり、再 apply 後の検証で integration URI が停止側へ戻ることを確認している。

## 論点6: repository に無い migration が DB へ適用済みとして記録されている

**ステータス:** 保留

**種別:** 実装中に判明した既存の問題

### 判明した事実

Phase 5 の後に `git status` を確認したところ、`backend/db/schema.rb` が変更されていた。内容は次の 2 点である。

- schema version が `2026_04_25_122541` から `2026_08_30_110413` へ進んでいた。
- 全テーブルから `charset: "utf8mb4"` と `collation: "utf8mb4_0900_ai_ci"` が消えていた。

調べた結果、次が分かった。

- `backend/db/migrate/` にある migration file の最大は `20260425122541` であり、**`20260830110413` に対応する file は repository に存在しない**。
- それにもかかわらず、開発 DB（MySQL）と test DB（sqlite）の両方の `schema_migrations` に `20260830110413` が記録されている。
- `main` の `schema.rb` は version `2026_04_25_122541` で、charset の記述を 14 箇所持っている。

charset が消えたのは、schema.rb が sqlite から再生成されたためである。開発用 `backend/entrypoint.sh` が `./bin/rails db:migrate RAILS_ENV=test` を実行しており、test DB は `database.yml` で sqlite3 に設定されている。Phase 5 で container を操作した際にこれが走った。

### 今回の作業との関係

**今回の作業は開発 DB のスキーマを変えていない。** ECS 上で実行される `rails db:migrate` は repository にある migration だけを対象にする。その最大は `20260425122541` であり、開発 DB では適用済みであるため no-op になった。CloudWatch Logs に migration の開始と完了のログは出たが、実際の変更は発生していない。

論点2で「動作確認環境の migration が開発 DB のスキーマを変える」というリスクを受け入れたが、今回の実行ではそれが顕在化しなかった。

### 対処

`backend/db/schema.rb` の変更は破棄した。今回の成果物ではなく、かつ sqlite 由来で MySQL の charset 情報が落ちているため、commit すると schema.rb が壊れるためである。

### 再開条件

今回の steering の動作確認が完了した後に再開する。この drift は今回の変更が作ったものではなく、動作確認の完了を妨げないためである。

再開時に扱うこと。

- `20260830110413` が何の migration だったかを特定する。別 branch にあるのか、削除されたのか、手作業で `schema_migrations` へ入ったのか。
- repository に無い migration が DB へ記録されている状態をどう解消するか。
- 開発用 `entrypoint.sh` が `rails db:migrate RAILS_ENV=test` を実行することで、MySQL 前提の `schema.rb` が sqlite から再生成され charset が落ちる問題をどう防ぐか。これは container を起動するたびに起こりうる。
