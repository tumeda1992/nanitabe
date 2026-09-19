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
