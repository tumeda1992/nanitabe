# 議論記録

## 論点1: frontend の動作確認環境の目的と、向く backend

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0（論点1）: 目的と backend の向き先

#### 提案0（論点1）

**目的:** `main` へ入れる前の変更を、PC 以外の端末（スマホ実機など）から**画面の操作で**確かめられるようにする。backend の review 環境が API 単体で行っている確認を、画面まで広げる。

**向き先:** frontend の動作確認環境は、backend の review 環境（`review-backend-nanitabe.<hosted zone>`、開発 DB を共有）を向く。本番の backend は向かない。

| 確かめたい変更 | 載せ方 | 確かめられること |
| --- | --- | --- |
| frontend だけ | frontend を review に載せ、backend の review 環境は `main` 相当のまま起動する | 画面の挙動。データは開発 DB |
| backend だけ | 現行どおり backend を review に載せる。画面からも叩ける | API と、それを使う画面 |
| frontend と backend の両方 | 両方を review に載せて起動する | 組み合わせた挙動 |

代償:

- 画面で確かめるたびに backend の review 環境の起動が要る。停止中は画面から API が応答しない。
- データは開発 DB のもので、ローカルの確認結果と互いに影響する（backend の review 環境と同じ）。

#### 検討記録（論点1・イテレーション0）

前の roadmap で、frontend の動作確認環境は review root から別の Amplify app として作ると決め、作ること自体は「どの backend を向くか」を本番移行へ持ち込まないために範囲外にしていました。この論点がその判断です。

本番の backend を向くと、確かめるための操作（献立の登録・削除など）が本番のデータを変えます。backend の review 環境を向けば本番に触れず、frontend と backend にまたがる変更も組み合わせて確かめられます。backend の review 環境の document は今「frontend とは繋がない」を「できないこと」に挙げており、これを変えることになります。

この後に決める予定の論点（目的と向き先によって変わるため、今は出していません）:

- git の branch と載せ方（backend の review 環境と同じ `review` branch を使うか）
- 起動・停止の運用（frontend は常時配信、backend は必要時だけ起動、の組み合わせ方）
- Amplify app の作成時の GitHub token の渡し方（token は今 GitHub にも `.env` にも無い）
- domain 名と、Terraform の配置（review root からの呼び出し、渡す値）
- docs の置き場所（backend の review 環境の document との関係）

[内部検討記録: 論点1・イテレーション0](internal-records/task-design-discussion.md.topic-1.md#iteration-0)

#### 提案0へのフィードバック（論点1）

**結果:** 合意

> ok

### 決定（論点1）

frontend の動作確認環境の目的は、`main` へ入れる前の変更を、PC 以外の端末から画面の操作で確かめられるようにすることである。backend の review 環境が API 単体で行っている確認を画面まで広げる。frontend の動作確認環境は backend の review 環境（開発 DB を共有）を向き、本番の backend は向かない。確かめるための操作が本番のデータを変えないためであり、frontend と backend にまたがる変更も両方を載せて組み合わせて確かめられる。画面で確かめるたびに backend の review 環境の起動が要ること、データが開発 DB のものであることを代償として受け入れる。backend の review 環境の document の「frontend とは繋がない」は変える。

## 論点2: 確認対象の載せ方（git の branch）

**ステータス:** 決定

### イテレーション0（論点2）: branch

#### 提案0（論点2）

backend の review 環境と同じ git の `review` branch を、frontend の動作確認環境の Amplify app も監視する。載せ方は現行の手順（確認対象の branch を `main` へ rebase して `git push -f origin <branch>:review`）のまま変えない。push 一回で、backend の CodePipeline と frontend の Amplify の build が両方動く。

#### 検討記録（論点2・イテレーション0）

論点1で、frontend と backend の両方を載せて組み合わせて確かめると決めた。branch を分けると、組み合わせて確かめるたびに二つの branch へ同じ commit を push する必要があり、片方だけ古いまま確かめる事故が起きる。同じ branch なら、載せた commit が frontend と backend の両方で同じになる。frontend だけの変更を載せた場合も、backend は `main` の上に frontend の変更が乗った commit を build するため、backend の挙動は `main` と同じになる。`review` branch は `main` へ rebase してから載せる運用のため、`main` にある `amplify.yml` が常に含まれる。

#### 提案0へのフィードバック（論点2）

**結果:** 合意

> されてたわ。よかった。論点2~6はok

### 決定（論点2）

論点2の提案0のとおりとする。

## 論点3: 起動・停止の運用

**ステータス:** 決定

### イテレーション0（論点3）: frontend の常時配信と backend の起動

#### 提案0（論点3）

- frontend の動作確認環境は常に配信する。起動・停止の操作を持たない。
- 画面で確かめるときは、現行どおり `scripts/review_backend/start.sh` で backend の review 環境を起動する。30 分の自動停止もそのまま。
- backend が停止している間、frontend の画面は開けるが API が応答しない。document の「何ができて、何ができないか」に書く。

#### 検討記録（論点3・イテレーション0）

Amplify には app ごとの固定費が無く、課金は build 時間と request に応じる。配信を止めても止めなくても費用はほぼ変わらない。backend の review 環境は ECS の task が時間課金のため起動・停止を持つ。frontend にも起動・停止を足すと、操作が二つになり、片方だけ起動して確かめる手順の誤りが増える。backend の停止中に frontend が開けても、データを変える操作はできない（API が応答しない）ため害は無い。

#### 提案0へのフィードバック（論点3）

**結果:** 合意

> されてたわ。よかった。論点2~6はok

### 決定（論点3）

論点3の提案0のとおりとする。

## 論点4: Amplify app の作成時の GitHub token の渡し方

**ステータス:** 決定

### イテレーション0（論点4）: token を Terraform にも GitHub にも置かずに app を作る

#### 提案0（論点4）

frontend の動作確認環境の Amplify app は、利用者が手元の AWS CLI で作り、Terraform に import して以後を管理する。

```text
(1) 利用者が GitHub で fine-grained personal access token を発行する（nanitabe だけ、Contents: read、Metadata: read、Webhooks: read and write）
(2) 利用者が `aws amplify create-app` で app を作る（名前 nanitabe-front-review、repository、access token、platform WEB_COMPUTE）
    token はこの command にだけ渡し、どこにも保存しない
(3) review root に import block を置き、作業 branch から review の apply を手動起動する
    → Terraform が app を state に取り込み、環境変数、branch、domain を定義どおりにする
```

- `aws_amplify_app` は本番と同じく `access_token` を `ignore_changes` にしている。import 後も Terraform は token を必要としない。
- 本番の app を作り直すことになった場合も同じ手順を使う。`modules/amplify/README.md` に書く。

#### 検討記録（論点4・イテレーション0）

`aws_amplify_app` は GitHub の repository に接続するとき作成時に token を要する。論点14（Actions 移行）で token を Terraform と GitHub から外したため、Actions の apply では app を作れない。候補は次の三つだった。

- token を一時的に GitHub secrets に戻して Actions で作る: 作成時の値が state に残り、外した理由（認証情報を Terraform に通さない）に反する。
- Terraform で repository 無しの app を作り、後から CLI で repository を接続する: `aws_amplify_branch` が接続前に作れるか、`repository` の差分がどう出るかが未確認で、apply が二段になる。
- CLI で作って import する: token は CLI の一回だけに渡り、state にも GitHub にも残らない。import は Terraform 1.5 以降の import block で Actions からも行える。

三つ目は token の扱いが原則どおりで、手順も一度で終わる。手元で AWS を操作するのは AWS CLI の設定の認証情報で、論点10（Actions 移行）の決定と合う。

#### 提案0へのフィードバック（論点4）

**結果:** 合意

> されてたわ。よかった。論点2~6はok

### 決定（論点4）

論点4の提案0のとおりとする。

## 論点5: domain と Terraform の配置

**ステータス:** 決定

### イテレーション0（論点5）: 呼び出しの形と値

#### 提案0（論点5）

- `infrastructure/terraform/envs/review/main.tf` から `frontend/terraform/envs/review/main.tf`（現在は `.gitkeep` だけ）を呼び、そこから `modules/amplify` を `stage = "review"` で呼ぶ。本番の `infrastructure` → `frontend/terraform/envs/prod` → `modules/amplify` と同じ形にする。
- 入力値:
  - `branch_names = ["review"]`
  - `custom_domain = var.route53_name`、`custom_domain_sub_domains = [{ branch_name = "review", prefix = "review-nanitabe" }]`。URL は `https://review-nanitabe.<hosted zone>`
  - `backend_origin = "https://review-backend-nanitabe.${var.route53_name}"`。backend の review 環境の URL から組み立て、新しい secret を足さない
  - `github_access_token` は渡さない（論点4）
- workflow の paths:
  - review の plan / apply に `frontend/terraform/envs/review/**` と `frontend/terraform/modules/amplify/**` を足す
  - prod の plan / apply の `frontend/terraform/**` に `!frontend/terraform/envs/review/**` を足し、review だけの変更で prod が動かないようにする

#### 検討記録（論点5・イテレーション0）

prefix を `review-nanitabe` にするのは、backend の review 環境が `review-backend-nanitabe`、x_favorites の動作確認環境が `review-x-favorites` で、どちらも「`review-` + 対象」のフラットな 1 ラベルだからである。同じ account・同じ親 domain を複数の Amplify app が関連付けられることは本番移行で実測している。`modules/amplify` を変える PR では prod と review の両方の plan が動くが、どちらの app にも影響する変更なので両方の plan を見る必要がある。

#### 提案0へのフィードバック（論点5）

**結果:** 合意

> されてたわ。よかった。論点2~6はok

### 決定（論点5）

論点5の提案0のとおりとする。

## 論点6: docs の置き場所

**ステータス:** 決定

### イテレーション0（論点6）: review 環境の document

#### 提案0（論点6）

`backend/docs/ai_guideline/development_standard/review_environment.md` を、frontend と backend を合わせた review 環境の document として書き換える。path は変えない。

- 題名を「review 環境（動作確認環境）」にし、frontend の URL、向き先、載せ方（共通の `review` branch）、frontend の build の確認方法、backend が停止中のときの画面の挙動を足す。「frontend とは繋がない」を消す。
- `frontend/docs/ai_guideline/development_standard/README.md` から同 document へ link を張る。
- `infrastructure/README.md` の「環境の使い方」の説明を、frontend を含む形に直す。

#### 検討記録（論点6・イテレーション0）

path を `infrastructure/` 等へ移すと、既存の link（backend の README、`infrastructure/README.md`、steering の記録）を張り替える必要があり、移動の効果は「backend の下にある」違和感の解消だけである。frontend の読者の導線は README の link で補える。

#### 提案0へのフィードバック（論点6）

**結果:** 合意

> されてたわ。よかった。論点2~6はok

### 決定（論点6）

論点6の提案0のとおりとする。

