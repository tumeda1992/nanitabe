# 議論記録

## 論点1: x_favorites の Amplify 構成を真似る目的と範囲

**ステータス:** 決定

**種別:** TBDヒアリング

### イテレーション0（論点1）: 何を解消するために、どの要素を取り込むか

#### 認識合わせ0（論点1）

nanitabe okの frontend は、すでに AWS 上で本番稼働する構成を持っています（Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild）。そのため今回の作業は「AWS に本番を新しく作る」ではなく、「既存の frontend 本番構成を x_favorites の形へ置き換える」になります。

x_favorites から取り込める要素は次の三つです。

1. Amplify Hosting による frontend 配信（`aws_amplify_app` の `WEB_COMPUTE` と `amplify.yml`。push で Amplify が build・配信する）
2. 常設の review branch（同じ Amplify app に `review` branch を足し、本番と同じ設定で `main` へ入れる前に確認する）
3. Terraform の GitHub Actions 適用（OIDC で AWS role を assume し、PR で plan、merge で apply する）

次の二点を確認したいです。

- a. 置き換えで解消したいことは何ですか。たとえば、構成の resource 数と保守の手間、費用、deploy 経路の不安定さ、x_favorites と構成を揃えること自体、など。複数あれば優先順位もお願いします。
- b. 上の 1〜3 のうち、どれを今回真似たいですか。

#### 検討記録（論点1・イテレーション0）

この回答が design 全体の上位になります。WHY が変わると、置き換える範囲と旧構成の扱いが変わります。たとえば「resource と保守の手間を減らしたい」なら 1 を主にして旧構成の撤去までが範囲になります。「deploy 前に確認する場所がほしい」なら 2 が主になります。

3 は既存の構成前提と衝突します。`infrastructure/README.md` の「構成上の前提」は「GitHub 側に AWS の credentials も OIDC の信頼設定も置かない。deploy は AWS 側が GitHub を見る形にし、`.github/workflows/` は test と lint だけを行う」と定めています。3 を取り込むなら、この前提を変える判断も今回の範囲に入ります。

backend は対象にしにくいと見ています。backend の本番 deploy はこの repository の Terraform の管理外で、Amplify Hosting は Rails の server を動かす service ではないためです。backend も AWS へ移したい意図があれば、b で教えてください。

現在の読解では、x_favorites で Amplify が少ない構成で動いたのを見て、nanitabe の自前構成（resource が多く、過去に「CD 整備後にバックエンド通信ができない」(#145、#154)、「CodeBuild が失敗している」(#161) があった）を簡素にしたい、という動機が最も自然に読めます。ただし依頼文には書かれていない推論なので、確定には使いません。

[内部検討記録: 論点1・イテレーション0](internal-records/task-design-discussion.md.topic-1.md#iteration-0)

#### 認識合わせ0への回答（論点1）

**結果:** 動機と取り込む要素を受領。2 は範囲に含めるかを提案側で判断する

> aについて。興味も含めて自分でCloudfrontやAPIGateway使ってフロントエンド環境を作ったけど、結局amplifyの内製だった。作りもわかった今、メンテコストが低いamplifyに移行したい。今後動作確認環境を作るのに、複製するのがだるかったというのもある。bについては1,3。2は終わった後に別ブランチでやろうと思っていた。ついでにここでやったほうが楽なら混ぜてもいい

- a: 自前の CloudFront・API Gateway 構成は学習を兼ねて作ったもので、Amplify が内部で提供しているものと同じだった。構造を理解した今は保守の手間が少ない Amplify へ移したい。加えて、動作確認環境を作るたびに自前構成を複製するのが負担だった。
- b: 1 と 3 を取り込む。2 は完了後に別 branch で行う予定だが、混ぜたほうが楽なら混ぜてよい。backend への言及はなく、対象外の見立ては否定されていない。


### イテレーション1（論点1）: 目的と範囲を確定する

#### 提案1（論点1）

**目的（design.md の TL;DR の WHY）**

学習を兼ねて自前で組んだ frontend の配信基盤（Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild）は、Amplify Hosting が managed に提供しているものと同じだった。構造を理解した今、この自前構成を Amplify へ移し、保守対象を減らす。あわせて、今後の動作確認環境を自前構成の複製ではなく branch の追加で作れる土台にする。

**範囲**

| 対象 | 扱い |
| --- | --- |
| frontend の本番配信を Amplify Hosting へ移す（x_favorites の要素 1） | 含める |
| 移行後に旧構成を撤去する（上記の AWS resource と、`frontend/terraform/` 配下・`frontend/buildOnLambda/` の定義） | 含める |
| Terraform の適用を GitHub Actions へ移す（要素 3） | 含める。`infrastructure/README.md` の「GitHub 側に AWS の credentials も OIDC の信頼設定も置かない」前提を変える判断も含む |
| 常設の review branch（要素 2） | 含めない。ただし今回の Amplify 構成は、branch を list で持ち、custom domain を branch ごとの sub domain の集合で持つ形にする。後から 2 を足す作業が list への追加で済むようにする |
| backend | 含めない |

各対象の具体的な形（環境変数の渡し方、domain の切替順、撤去順、OIDC role の権限、既存の review 環境の Terraform を Actions から適用するか等）は、この論点では決めない。後続の論点で一つずつ扱う。

#### 検討記録（論点1・イテレーション1）

認識合わせ0の回答で、目的は「保守の手間を減らす」と「動作確認環境の複製をやめる」、取り込む要素は 1 と 3 に確定しました。この回で判断したのは、委ねられた 2 の扱いと、回答に明示されていなかった旧構成の撤去です。

**2 を含めない理由。** frontend の review branch を作ると、それがどの backend を指すかという、本番移行と無関係な設計判断が入ります。backend の review 環境はすでに git の `review` branch を監視し、必要時だけ起動する ECS で動いています（`backend/docs/ai_guideline/development_standard/review_environment.md`）。止まっている時間が長いため、frontend の review が常にそれを指す形は成立しにくく、別の設計が要ります。一方、x_favorites では review branch の追加が `branch_names` への一要素と sub domain の一組の追加だけで済んでいて、証明書もワイルドカード形式のため再発行が起きません。今回の構成を同じ形にしておけば、後から足しても今回作るものを作り直しません。代償は review 環境が使えるのが移行後になることですが、元々の予定と同じです。

**旧構成の撤去を含める理由。** 旧構成を残したままだと、保守対象は Amplify の分だけ増えて減らず、目的を満たしません。

[内部検討記録: 論点1・イテレーション1](internal-records/task-design-discussion.md.topic-1.md#iteration-1)

#### 提案1へのフィードバック（論点1）

**結果:** 合意

> ok

### イテレーション2（論点1）: issue #258 に書かれた移行の緊急性を目的へ加える

#### 提案2（論点1）

決定の「目的」へ、次の一文を加える。

> 現行の CodeBuild は build 中の apt で特定の version を取得できず、本番 build が失敗している。本番 deploy が止まっているため、移行を急ぐ。

範囲と制約は変えない。

#### 検討記録（論点1・イテレーション2）

作業 branch `feature-258` に対応する issue #258 のタイトルは「本番フロントエンドをamplifyに置き換える（CodeBuildでのaptでのライブラリ取得で特定のバージョン取れなくて本番ビルド失敗しているから早く移行したい）」である。論点1で合意した目的（保守対象を減らす）とは別に、本番 deploy が現在止まっていることが移行を急ぐ理由になっている。認識合わせ0の時点ではこの issue を確認しておらず、目的に含めていなかった。範囲は変わらないが、論点2の順序判断を後押しする事実でもあるため目的へ残す。chat で提示した内容を、合意を受けてこの回へ保存した。

#### 提案2へのフィードバック（論点1）

**結果:** 合意

> ok

### イテレーション3（論点1）: Terraform の Actions 移行を別 steering へ分ける

#### 提案3（論点1）

範囲から「Terraform の適用を GitHub Actions へ移す」を外し、この steering は Amplify 移行（旧構成の撤去まで）だけで完了させる。Actions 移行は、この steering の完了後に別の steering で設計・実行する。

- この steering の design の非目標へ「Actions 移行は別 steering で行う」と理由を書く。
- Actions 移行の steering は Amplify 移行の結果（Amplify 構成と variable の実物）を入力にして始める。
- issue の扱い: Actions 移行用に別 issue を立て、この steering の PR で #258 を閉じる。

#### 検討記録（論点1・イテレーション3）

イテレーション2では範囲を変えないとしましたが、Amplify 移行の設計（論点2〜6）を終えて Actions 移行の中身を調べたところ、決める事項が Amplify 移行と同じくらい残っていました。

- **適用対象の root。** nanitabe には `envs/prod` と `envs/review` の二つがあります（x_favorites は一つ）。`envs/review` の `apply_terraform.sh` は agent が permission を持って実行する前提で、destroy を含む plan を script 自身が拒否します。Actions へ移すなら、この仕組みと agent の権限を決め直す必要があります。
- **apply role の権限。** `envs/review` は ECS、API Gateway、IAM role、SSM、CodePipeline 等、十数種類の resource を持ちます。IAM role を作れる権限を Actions の role へ渡すかは、それだけで一つの判断です。
- **secret の移動。** `envs/review` は DB の接続情報と `RAILS_MASTER_KEY` を受けます。Actions へ移すと、これらを GitHub secrets へ置くことになります。
- その他、state の lock、`infrastructure/README.md` の前提の書き換え、public repository で使える branch protection の扱いがあります。

論点2で、Actions 移行は Amplify 移行の後にしか始めないと決めました。同じ steering に入れても並行して進む部分は無く、この steering の完了（本番 build の停止の解消）が Actions 移行の設計を待つことになるだけです。分ければ、Amplify 移行だけで完了できます。Actions 移行の設計も、Amplify 構成と variable の実物を見てから行えます。

代償は issue の扱いです。#258 は Amplify 置き換えの issue なので、Actions 移行には別 issue を立て、この steering の PR で #258 を閉じる形を提案します。

[内部検討記録: 論点1・イテレーション3](internal-records/task-design-discussion.md.topic-1.md#iteration-3)

#### 提案3へのフィードバック（論点1）

**結果:** 修正要求。分ける理由の根拠が弱く、比較した選択肢が足りない

> まぁ、別steeringでやってもいいけど、安易に別steeringでやるって言いがち。干渉しないところに追い出してるだけにも見える。roadmapでやるとかいくらでも考えられるし、ほぼ踏襲なら決めることは多くても負担じゃない
>
> そこそこ大きいやつだから別に今回は妥当にも見えるけど。

- 「決める事項が多い」は分ける理由にならない。x_favorites をほぼ踏襲するなら、事項が多くても負担ではない。
- 別 steering へ出すことは、同じテーマの中で干渉しない場所へ追い出しているだけに見える。同じテーマ内で段階を分ける方法（roadmap 等）と比較していない。
- 結論として分けること自体は、規模から妥当にも見える。

### イテレーション4（論点1）: Actions 移行を同じテーマの roadmap の後段 phase にする

#### 提案4（論点1）

範囲は決定のまま変えない（Actions 移行を含める）。そのうえで、この steering の execution plan を roadmap にし、二つの phase に分ける。

```text
phase「Amplify 移行」                     phase「Terraform の Actions 移行」
  論点2〜6で合意した手順で、                  Amplify 移行後の root を対象に、
  本番配信を Amplify へ移し、        →        適用を GitHub Actions へ移す
  旧構成を撤去する                            （詳細は子 steering の task-design で設計する）
  完了時点で本番 build の停止が解消する
```

- 依存は「Amplify 移行」→「Terraform の Actions 移行」。論点2の順序決定をそのまま依存にする。
- 「Amplify 移行」phase の設計は、この design.md で合意済みの内容を子 task-design の上位制約として渡す。子 design で同じ内容を再設計しない。
- 「Terraform の Actions 移行」phase は、この design では目的、scope、scope外、完了条件までを確定する。適用対象の root、apply role の権限、secret の移動、state の lock、`infrastructure/README.md` の前提の書き換えは、子 task-design で「Amplify 移行」phase の結果（Amplify 構成と variable の実物）を入力にして設計する。
- issue は #258 一つのまま、roadmap 全体の完了で閉じる。

#### 検討記録（論点1・イテレーション4）

提案3の理由として挙げた「決める事項が多い」は、フィードバックのとおり分ける根拠になっていませんでした。x_favorites をほぼ踏襲するなら、事項の数は負担ではありません。

分ける本当の理由を考え直すと、「Actions 移行の設計が終わるまで、Amplify 移行の実行を待たせたくない」でした。現行の flow では、leaf の tasklist は design 全体の合意後に実行が始まります。Actions 移行を同じ leaf に入れると、その設計の完了まで本番 build の停止（イテレーション2）が直りません。

この理由を満たす方法は別 steering だけではありません。roadmap にして phase を分ければ、「Amplify 移行」phase を先に実行し、その完了を待って「Terraform の Actions 移行」phase を設計・実行できます。別 steering との違いは、Actions 移行がこのテーマの完了条件に残ることです。別 steering にすると、Actions 移行を行う義務がこのテーマから消え、フィードバックの言う「追い出し」になります。roadmap ならこのテーマの完了は両 phase の完了で判定されます。

Actions 移行の詳細を後段の子 design へ回すのは、task-design の「実行して初めて確定することは段階を分けて設計する」の条件にも当たります。apply role に必要な権限や GitHub secrets へ移す variable は、Amplify 移行後に root に残る resource と variable の実物で決まり、Amplify 移行で作るものは捨てずに次の phase の土台になるためです。

[内部検討記録: 論点1・イテレーション4](internal-records/task-design-discussion.md.topic-1.md#iteration-4)

#### 提案4へのフィードバック（論点1）

**結果:** 合意

> ok

### 決定（論点1）

**目的:** 学習を兼ねて自前で組んだ frontend の配信基盤（Lambda、API Gateway、CloudFront、S3、ECR、CodePipeline、CodeBuild）は、Amplify Hosting が managed に提供しているものと同じだった。この自前構成を Amplify へ移して保守対象を減らし、今後の動作確認環境を自前構成の複製ではなく branch の追加で作れる土台にする。現行の CodeBuild は build 中の apt で特定の version を取得できず、本番 build が失敗している。本番 deploy が止まっているため、移行を急ぐ。

**範囲:**

- 含める: frontend の本番配信を Amplify Hosting へ移すこと。移行後に旧構成（上記の AWS resource と、`frontend/terraform/` 配下・`frontend/buildOnLambda/` の定義）を撤去すること。Terraform の適用を GitHub Actions へ移すことと、それに伴い `infrastructure/README.md` の「GitHub 側に AWS の credentials も OIDC の信頼設定も置かない」前提を変えること。
- 含めない: 常設の review branch、backend。

**実行の構造:** execution plan は roadmap とし、phase「Amplify 移行」→ phase「Terraform の Actions 移行」の二つに分ける。「Amplify 移行」phase は、この design で合意した内容を子 task-design の上位制約として渡し、子 design で再設計しない。「Terraform の Actions 移行」phase は、この design で目的、scope、scope外、完了条件までを確定し、適用対象 root の扱い、apply role の権限、secret の移動、state の lock、`infrastructure/README.md` の前提の書き換えを、「Amplify 移行」phase の結果（Amplify 構成と variable の実物）を入力にして子 task-design で設計する。issue は #258 一つとし、roadmap 全体の完了で閉じる。

**制約:** 今回の Amplify 構成は branch を list で持ち、custom domain を branch ごとの sub domain の集合で持つ。後から review branch を足す作業を list への追加で済ませるためである。review branch を含めないのは、frontend の review がどの backend を指すかという本番移行と無関係な設計判断を持ち込むためである。旧構成の撤去を含めるのは、残すと保守対象が減らず目的を満たさないためである。roadmap にするのは、Actions 移行の設計完了まで Amplify 移行の実行（本番 build 停止の解消）を待たせず、かつ Actions 移行をこのテーマの完了条件に残すためである。別 steering にすると Actions 移行を行う義務がこのテーマから消える。

skill 改善の保留メモ: [pending-escalations/001-compare-staging-before-splitting-scope.md](pending-escalations/001-compare-staging-before-splitting-scope.md)（提案3へのフィードバックを起点とする plugin skill の修正。保留中・未引渡し）

## 論点2: Amplify 移行と Terraform の Actions 移行の順序

**ステータス:** 決定

### イテレーション0（論点2）: どちらを先に行うか

#### 提案0（論点2）

Amplify 移行を先に、現行の手元 apply（`infrastructure/terraform/envs/prod` の script）で行い、旧構成の撤去まで終える。その後に Terraform の適用を GitHub Actions へ移す。

```text
Amplify 移行（手元 apply）            Actions 移行
  Amplify app を作る                    OIDC と plan / apply の workflow を作る
  custom domain を切り替える      →     値を host の .env から GitHub secrets へ移す
  旧構成を撤去する                      以後の apply は PR と merge で行う
```

#### 検討記録（論点2・イテレーション0）

先に行う側が、後に行う側の実行経路と、GitHub へ移す値と権限の範囲を決めます。

Actions を先に行うと、現行の prod root をそのまま Actions から適用することになります。prod root は旧構成のために長期の IAM access key（`aws_access_key`、`aws_secret_access_key`）を受け取り、CodeBuild の環境変数へ平文で渡しています（`frontend/terraform/modules/cicd/codebuild/main.tf` に `# TODO: secret化する` とある）。この key を GitHub secrets へ置き、apply role に Lambda、API Gateway、CloudFront、ECR、CodePipeline、CodeBuild、ACM 等への権限を付ける必要が出ます。どれも Amplify 移行が終われば不要になります。

Amplify 移行を先に行えば、Actions へ移す時点の variable と apply role の権限は、Amplify 構成と state 用 resource の分だけになります。x_favorites も同じ順序（Amplify を手元 apply で成立させてから Actions へ移す）でした。本番移行の作業中に、適用経路の変更という別の不確実性を重ねずに済みます。

代償は、Amplify 移行の間だけ Amplify が GitHub へ接続するための値を host 上の `.env` に置くことです。Actions 移行時に GitHub secrets へ移します。

[内部検討記録: 論点2・イテレーション0](internal-records/task-design-discussion.md.topic-2.md#iteration-0)

#### 提案0へのフィードバック（論点2）

**結果:** 合意

> ok

### 決定（論点2）

Amplify 移行を先に、現行の手元 apply（`infrastructure/terraform/envs/prod` の script）で行い、旧構成の撤去まで終える。その後に Terraform の適用を GitHub Actions へ移す。

Actions を先に行うと、旧構成のために長期の IAM access key を GitHub secrets へ置き、撤去予定の service への権限を apply role へ付けることになるためである。Amplify 移行の間だけ、Amplify が GitHub へ接続するための値を host 上の `.env` へ置き、Actions 移行時に GitHub secrets へ移す。


## 論点3: custom domain の切替と旧構成撤去の順序

**ステータス:** 決定

### イテレーション0（論点3）: 切替と撤去の順序

#### 提案0（論点3）

次の順で進める。各 apply は現行の手元 apply（`infrastructure/terraform/envs/prod`）で行う。

```text
(1) Amplify app を作る（custom domain なし）
      → Amplify の default domain で機能を確認する
(2) 旧 CloudFront から custom domain を外す apply
      （distribution の alias、us-east-1 の ACM 証明書、Route53 の A / AAAA record）
      旧 distribution と Lambda は残す
(3) Amplify へ custom domain を関連付ける apply → 証明書の検証完了を待つ
(4) custom domain で機能を確認する
(5) 旧構成の残り（CloudFront、API Gateway、Lambda、S3、ECR、CodePipeline、CodeBuild）を撤去する apply
```

- (2) から (3) の検証完了までは、本番 URL が応答しない。利用しない時間帯に行う。
- (3) または (4) で失敗したら、(2) を戻す apply（旧 distribution へ alias と record を戻す）で旧構成へ戻す。(5) を行うまでは、この rollback の手段を残す。

#### 検討記録（論点3・イテレーション0）

custom domain は現在、旧 CloudFront distribution の `aliases`、us-east-1 の ACM 証明書、Route53 の A / AAAA alias record の三か所で Terraform 管理されています（`frontend/terraform/modules/cloudfront/`）。Amplify Hosting は内部で CloudFront を使い、CloudFront の alternate domain name は distribution 間で重複できません。このため、旧 distribution が alias を持ったままでは Amplify へ同じ domain を関連付けられない見込みです。実際にそうなるかは (3) の apply で確かめます（未実測）。外してから付ける順序にすると、その間だけ custom domain が応答しなくなります。

この停止時間を避ける方法（domain の一時的な付け替え先を用意する等）は採りません。利用者がほぼ本人だけ（`frontend/README.md`「想定ユーザ」）で、利用しない時間帯に行えば影響が無いためです。

(1) の確認を default domain で行えるのは、backend の CORS が `origins "*"`（`backend/config/application.rb`）で frontend の origin を限定しておらず、認証 token も frontend 側の cookie で持つためです。

旧構成の撤去を最後に分けるのは、(3)・(4) が失敗したときに alias と record を戻すだけで旧構成へ戻れるようにするためです。build が失敗していても、Lambda は最後に deploy できた image のまま動いている見込みのため、戻し先として使えます（現在応答しているかは未確認）。

[内部検討記録: 論点3・イテレーション0](internal-records/task-design-discussion.md.topic-3.md#iteration-0)

#### 提案0へのフィードバック（論点3）

**結果:** 合意

> ok

### 決定（論点3）

custom domain の切替と旧構成の撤去は、現行の手元 apply（`infrastructure/terraform/envs/prod`）で次の順に行う。

1. Amplify app を custom domain なしで作り、Amplify の default domain で機能を確認する。
2. 旧 CloudFront から custom domain を外す apply を行う（distribution の alias、us-east-1 の ACM 証明書、Route53 の A / AAAA record）。旧 distribution と Lambda は残す。
3. Amplify へ custom domain を関連付ける apply を行い、証明書の検証完了を待つ。
4. custom domain で機能を確認する。
5. 旧構成の残り（CloudFront、API Gateway、Lambda、S3、ECR、CodePipeline、CodeBuild）を撤去する apply を行う。

2 から 3 の検証完了までは本番 URL が応答しないため、利用しない時間帯に行う。利用者がほぼ本人だけであるため、この停止時間を避ける仕組みは作らない。3 または 4 で失敗したら 2 を戻す apply で旧構成へ戻し、5 を行うまでこの rollback の手段を残す。外してから付ける順序にするのは、CloudFront の alternate domain name が distribution 間で重複できず、Amplify も内部で CloudFront を使うためである（3 の apply で実測する）。1 の確認を default domain で行えるのは、backend の CORS が frontend の origin を限定しておらず、認証 token を frontend 側の cookie で持つためである。


## 論点4: Amplify app の build・実行設定

**ステータス:** 決定

### イテレーション0（論点4）: nanitabe の frontend を Amplify でどう build し、何を渡すか

#### 提案0（論点4）

x_favorites の構成を基にし、nanitabe 固有の差を次のとおり埋める。

| 項目 | 設定 | x_favorites との差 |
| --- | --- | --- |
| build 設定の置き場所 | repository 直下の `amplify.yml`。`applications` の `appRoot: frontend` で `frontend/` を対象にする。Amplify app の環境変数 `AMPLIFY_MONOREPO_APP_ROOT=frontend` を設定する | x_favorites は repository 直下が app だった |
| Node version | `preBuild` で `nvm install 24` を実行し、`node -v` を build log へ出す | CI（Node `24.11.1`）と同じ major に揃える。x_favorites は固定しなかった |
| install と build | `yarn install --frozen-lockfile`、`yarn build`（Tailwind の `build:css` を随伴する）。cache は `.next/cache` と `node_modules` | x_favorites は npm |
| artifacts | `baseDirectory: .next` | 同じ |
| platform | `WEB_COMPUTE` | 同じ |
| 実行時の値 | Amplify app の環境変数に `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` だけを置く。値の供給元は現行と同じ host の `.env`（`apply_terraform.sh` が `TF_VAR_backend_origin` として渡す） | `NEXT_PUBLIC_` の値は build 時に埋め込まれるため、`.env.production` への書き出しは行わない |
| access gate | 置かない | x_favorites は application に認証が無いため Basic authentication を置いた。nanitabe は application のログインがある |
| `frontend/next.config.js` | `assetPrefix` と `compress: false` を削除する。`NEXT_PUBLIC_ASSET_ORIGIN` も使わなくなる | 旧構成専用の設定 |
| `/system/warmup` | route を残す | — |

#### 検討記録（論点4・イテレーション0）

x_favorites との違いは、Next.js が `frontend/` にあること（monorepo）、package manager が yarn であること、Node version を CI と揃える必要があることです。build の条件は、PR ごとに通っている `ci-frontend-build-verification.yml`（`frontend/` で Node `24.11.1`、`yarn install --frozen-lockfile`、`yarn build`）に合わせます。Amplify の build image で Node 24 を使えるかは未実測で、論点3の手順 (1) の build log で確認します。使えなかった場合は (1) で止まって design へ戻ります。

frontend が参照する環境変数は `NEXT_PUBLIC_ENVIRONMENT`、`NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN`、`NEXT_PUBLIC_ASSET_ORIGIN` の三つだけです。`NEXT_PUBLIC_ENVIRONMENT` は未設定なら本番の分岐に入ります。`NEXT_PUBLIC_` 接頭辞の値は build 時に bundle へ埋め込まれるため、Amplify の環境変数が build container にしか届かないという x_favorites の落とし穴は当たりません。

`assetPrefix`（`NEXT_PUBLIC_ASSET_ORIGIN`）は static asset を S3 と CloudFront の別 origin から配信するための設定で、`compress: false` は「API Gateway で gzip させるため」とコメントされています。どちらも旧構成を前提にしていて、Amplify では static asset も圧縮も Amplify 側が扱うため削除します。`compress` を既定へ戻すと Next.js 自身が gzip しますが、圧縮が二重になっても応答は壊れません。

`/system/warmup` は Lambda の cold start 対策として作られた route です。repository 内に呼び出し元はありません（外部から呼ばれているかは未確認）。route 自体は Lambda に依存しないため、削除せず残します。

access gate を置かないのは、nanitabe には application のログイン（`frontend/src/app/login`、backend の devise）があるためです。

表の各行は独立して変えられます。異論のある行があれば、その行だけ別の論点に分けます。

[内部検討記録: 論点4・イテレーション0](internal-records/task-design-discussion.md.topic-4.md#iteration-0)

#### 提案0へのフィードバック（論点4）

**結果:** 合意

> ok

### 決定（論点4）

Amplify app の build・実行設定は、x_favorites の構成を基に次のとおりとする。

- build 設定は repository 直下の `amplify.yml` に置き、`applications` の `appRoot: frontend` で `frontend/` を対象にする。Amplify app の環境変数 `AMPLIFY_MONOREPO_APP_ROOT=frontend` を設定する。
- `preBuild` で `nvm install 24` を実行し、`node -v` を build log へ出す。CI（Node `24.11.1`）と同じ major に揃えるためである。Amplify の build image で Node 24 を使えるかは論点3の手順 1 の build log で確認し、使えなければ手順 1 で止まって design へ戻る。
- install と build は `yarn install --frozen-lockfile` と `yarn build`。cache は `.next/cache` と `node_modules`。artifacts の `baseDirectory` は `.next`。platform は `WEB_COMPUTE`。
- 実行時の値は、Amplify app の環境変数 `NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN` だけとする。値の供給元は現行と同じ host の `.env` で、`apply_terraform.sh` が `TF_VAR_backend_origin` として渡す。`NEXT_PUBLIC_` の値は build 時に埋め込まれるため、`.env.production` への書き出しは行わない。
- access gate は置かない。application にログインがあるためである。
- `frontend/next.config.js` から `assetPrefix` と `compress: false` を削除する。どちらも旧構成（S3 の別 origin、API Gateway の gzip）を前提にした設定である。
- `/system/warmup` の route は残す。route 自体は Lambda に依存しない。


## 論点5: Amplify が監視する branch の移り方

**ステータス:** 決定

### イテレーション0（論点5）: 監視 branch の移り方

#### 提案0（論点5）

論点3の手順 (1) を、x_favorites と同じく次のように進める。

```text
(1-a) Amplify app を作り、branch_names = ["feature-258"] で監視する
        → feature-258 の default domain で build と機能を確認する
        （amplify.yml の試行錯誤はこの branch で行う）
(1-b) 確認済みの amplify.yml と frontend/next.config.js の変更だけを、
        main から切った feature-258-amplify-build-config から main へ PR で入れる
        （Closes を付けない途中 merge。本文に「issue #258 の完了を意味しない」と書く）
(1-c) branch_names = ["feature-258", "main"] にして apply
        → main の default domain で build と機能を確認する
(1-d) branch_names = ["main"] にして apply し、feature-258 を外す
```

手順 (3) で custom domain を関連付ける先は `main` とする。

#### 検討記録（論点5・イテレーション0）

Amplify は監視 branch に `amplify.yml` が無いと build できません。作業中の `amplify.yml` は `feature-258` にしかないため、最初は `feature-258` を監視させ、そこで試行錯誤します。試行錯誤のたびに `main` へ PR を merge する形を避けるためです。

確認後に `main` へ移すときは、`branch_names` を差し替えずに「追加してから外す」順にします。`branch_name` の差し替えは Amplify branch resource の再作成になり、`main` を確認する前に `feature-258` の環境が消えるためです（x_favorites の実績）。

途中 merge は、plugin の `development_flow/branch_pr_issue.md` の「経路 2」（既定 branch 上でしか確認できない仕組みのための merge）にあたります。`Closes` を付けず、同じ issue に属する派生 branch で立てます。branch 名は `feature-258-amplify-build-config` とします。nanitabe の context は公開可能な branch を `feature-<issue番号>` 形式と宣言していて、派生形式の宣言はありません。この名前は issue 番号を一意に引ける形を保ったまま、本線 `feature-258` と区別します。

途中 merge で起動する自動処理は二つです。旧 CodePipeline は `main` を監視して build しますが、現在 apt の取得で失敗しているため Lambda は更新されません（issue #258）。`backend-deploy.yml` も backend の deploy webhook を呼びますが、backend の差分が無いため挙動は変わりません。merge の内容に `frontend/next.config.js` の変更を含めるのは、`main` の Amplify build を (1-a) で確認した構成と同じにするためです。

[内部検討記録: 論点5・イテレーション0](internal-records/task-design-discussion.md.topic-5.md#iteration-0)

#### 提案0へのフィードバック（論点5）

**結果:** 合意

> ok

### 決定（論点5）

論点3の手順 1 を次のように進める。

1. Amplify app を `branch_names = ["feature-258"]` で作り、`feature-258` の default domain で build と機能を確認する。`amplify.yml` の試行錯誤はこの branch で行う。
2. 確認済みの `amplify.yml` と `frontend/next.config.js` の変更だけを、`main` から切った `feature-258-amplify-build-config` から `main` へ PR で入れる。`Closes` を付けない途中 merge とし、本文に「issue #258 の完了を意味しない」と書く。
3. `branch_names = ["feature-258", "main"]` にして apply し、`main` の default domain で build と機能を確認する。
4. `branch_names = ["main"]` にして apply し、`feature-258` を外す。

custom domain は `main` へ関連付ける。試行錯誤のたびに `main` へ merge しないために作業 branch から始め、Amplify branch resource の再作成で確認前に環境を失わないために「追加してから外す」順にする。branch 名は、context が宣言する `feature-<issue番号>` から issue 番号を一意に引ける形を保ったまま、本線と区別する。途中 merge で旧 CodePipeline と backend の deploy webhook が一度起動するが、旧 CodePipeline の build は失敗中で Lambda を更新せず、backend は差分が無いため挙動を変えない。


## 論点6: Amplify 移行の Terraform 構成

**ステータス:** 決定

### イテレーション0（論点6）: 定義の配置と変え方

#### 提案0（論点6）

**配置**

```text
infrastructure/terraform/envs/prod/main.tf      root（変えるのは variable だけ）
frontend/terraform/
├── envs/prod/main.tf                           module "amplify" を呼ぶ。手順 (5) で旧 module の呼び出しを消す
├── modules/
│   ├── amplify/main.tf                         新設
│   └── apigateway/ cicd/ cloudfront/ ecr/      手順 (5) で test/ ごと削除
│       lambda/ s3/
└── values/values.tf                            変えない（appname = "nanitabe-front"）
frontend/buildOnLambda/                         手順 (5) で削除
```

**`modules/amplify`**

x_favorites の module から、Basic authentication を除いた形にする。

- `aws_amplify_app`: name は `${appname}-${stage}`（`nanitabe-front-prod`）、repository は `https://github.com/tumeda1992/nanitabe`、`platform = "WEB_COMPUTE"`、環境変数は論点4の二つ。build 設定は repository の `amplify.yml` を使い、`build_spec` を書かない。
- `aws_amplify_branch`: `branch_names` を `for_each` で持ち、`enable_auto_build = true`。
- `aws_amplify_domain_association`: `custom_domain` が null の間は作らない。`domain_name` は hosted zone の親 domain（`var.route53_name`）、`sub_domain` は `{ branch_name = "main", prefix = "nanitabe" }` の一組。`wait_for_verification = false`。

**手順 (2) の切替口**

`modules/cloudfront` に bool の variable `enable_custom_domain` を足す。false のとき、`aliases` を空にし、`viewer_certificate` を CloudFront の既定証明書にし、`module "cert"` と `module "dns"` を作らない。(2) で false にし、rollback は true へ戻す apply で行う。

**GitHub への接続 token**

prod root に sensitive な variable `amplify_github_access_token` を足し、host の `.env` の `AMPLIFY_GITHUB_ACCESS_TOKEN` から `apply_terraform.sh` が渡す。token は `tumeda1992/nanitabe` だけを対象にした fine-grained personal access token（Contents: read、Metadata: read、Webhooks: read and write）。

**手順 (5) で消す variable**

prod root と `frontend/terraform/envs/prod` から `aws_account_id`、`aws_access_key`、`aws_secret_access_key`、`codebuild_artifact_s3_bucket`、`aws_code_connection_id_to_github`、`branch`、`route53_zone_id` と us-east-1 の provider を消し、`apply_terraform.sh` の対応する export も消す。`backend_origin` と `route53_name` は残す。

#### 検討記録（論点6・イテレーション0）

二層構成（`infrastructure/terraform/envs/prod` が `frontend/terraform/envs/prod` を呼ぶ）は変えません。Amplify は frontend の配信基盤なので、旧構成と同じく `frontend/terraform/` に置きます。

旧 CloudFront module は custom domain を必須の値として distribution の alias、us-east-1 の証明書、Route53 の record に使っていて、外す口がありません。手順 (2) と rollback を variable 一つの切替で行えるよう、`enable_custom_domain` を足します。この module は手順 (5) で消えるので、足すのは切替に必要な分だけです。

custom domain の関連付けは x_favorites と同じく、親 domain と branch ごとの prefix で持ちます。後から review branch を足すとき、prefix を一組増やすだけで `review-nanitabe.<hosted zone>` のようなフラットな名前を作れるためです（「hosted zone のレコードはフラットな 1 ラベルにする」前提に合う）。

未実測の点が一つあります。x_favorites の Amplify app が、同じ account・同じ親 domain をすでに関連付けています。同じ親 domain を別の app へ関連付けると「already associated with another Amplify app」で拒否される事例がある一方、API から別の prefix を指定すれば共有できたという報告もあります（AWS re:Post）。公式文書での明記は確認できていません。手順 (3) の apply で確かめ、拒否された場合は (2) を戻して旧構成へ戻し、design へ戻ります。代わりに `domain_name` を `nanitabe.<hosted zone>` 自体にすると、review branch が `review.nanitabe.<hosted zone>` になってフラットな 1 ラベルの前提を崩すため、その場では決めません。

旧構成の variable は、どれも旧構成の ECR、Lambda、CI/CD、証明書、record だけが使っています。`aws_access_key` と `aws_secret_access_key` は長期の IAM access key で、CodeBuild へ平文で渡されていたものです。手順 (5) でまとめて消します。

[内部検討記録: 論点6・イテレーション0](internal-records/task-design-discussion.md.topic-6.md#iteration-0)

#### 提案0へのフィードバック（論点6）

**結果:** 合意

> ok

### 決定（論点6）

- 二層構成（`infrastructure/terraform/envs/prod` が `frontend/terraform/envs/prod` を呼ぶ）を保ち、`frontend/terraform/modules/amplify/` を新設して `frontend/terraform/envs/prod` から呼ぶ。`frontend/terraform/values/values.tf` は変えない。
- `modules/amplify` は x_favorites の module から Basic authentication を除いた形とする。`aws_amplify_app` は name `nanitabe-front-prod`、repository `https://github.com/tumeda1992/nanitabe`、`platform = "WEB_COMPUTE"`、環境変数は論点4の二つで、`build_spec` を書かない。`aws_amplify_branch` は `branch_names` の `for_each` で `enable_auto_build = true`。`aws_amplify_domain_association` は `custom_domain` が null の間は作らず、`domain_name` を hosted zone の親 domain（`var.route53_name`）、`sub_domain` を `{ branch_name = "main", prefix = "nanitabe" }` の一組、`wait_for_verification = false` とする。
- 手順 2 の切替口として、`modules/cloudfront` に bool の variable `enable_custom_domain` を足す。false のとき `aliases` を空にし、`viewer_certificate` を CloudFront の既定証明書にし、`module "cert"` と `module "dns"` を作らない。rollback は true へ戻す apply で行う。
- prod root に sensitive な variable `amplify_github_access_token` を足し、host の `.env` の `AMPLIFY_GITHUB_ACCESS_TOKEN` から `apply_terraform.sh` が渡す。token は `tumeda1992/nanitabe` だけを対象にした fine-grained personal access token（Contents: read、Metadata: read、Webhooks: read and write）。
- 手順 5 で、`frontend/terraform/modules/` の apigateway、cicd、cloudfront、ecr、lambda、s3 を `test/` ごと、`frontend/buildOnLambda/` を削除する。prod root と `frontend/terraform/envs/prod` から `aws_account_id`、`aws_access_key`、`aws_secret_access_key`、`codebuild_artifact_s3_bucket`、`aws_code_connection_id_to_github`、`branch`、`route53_zone_id` と us-east-1 の provider を消し、`apply_terraform.sh` の対応する export も消す。`backend_origin` と `route53_name` は残す。

親 domain と prefix で関連付けるのは、後から review branch を足すときに prefix を一組増やすだけでフラットな 1 ラベルの名前を作れるためである。同じ account の別の Amplify app が同じ親 domain を関連付け済みで、共有が通るかは未実測のため手順 3 の apply で確かめる。拒否された場合は手順 2 を戻して旧構成へ戻し、design へ戻る。

