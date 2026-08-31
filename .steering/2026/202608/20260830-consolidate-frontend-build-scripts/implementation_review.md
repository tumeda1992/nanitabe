# 議論記録

> このfileは、Phase 1 の実装中に発生した事象についての事後記録である。chat 上で提案・feedback・合意が先に成立し、その後にこのfileへ再構成した。各イテレーションは実際に起きた順序どおりに並べてあり、成果物反映前に保存していたかのようには書いていない。

## 論点1: Tailwind watcher が VM を食い潰したときの知識をどこへどう記録するか

**ステータス:** 決定

**種別:** 認識齟齬 / レビュー指摘

### イテレーション0: 復旧の前提として host のメモリ枯渇を解消する

#### 提案0

`tasklist-executor` が Phase 1 の watcher 追随確認（`frontend/src/app/globals.css` を一時変更し `tailwind-output.css` が追随することを見る手順）を実行した際、`tailwindcss --watch` が 5〜6GB RSS まで膨張し、`nanitabe_front` が操作不能になった。

観測した事実:

- `docker compose exec -T frontend sh -c 'echo EXEC_OK'` が `OCI runtime exec failed: exec failed: unable to start container process: error executing setns process: exit status 1` で失敗
- `curl --max-time 15 http://localhost:18100/` が `status=000` で無応答
- `docker compose ps` は `Up 24 minutes` と表示し続けた

このとき assistant は次を根拠に host のメモリ枯渇と診断した。

```
PhysMem: 15G used (4374M wired, 6793M compressor), 74M unused
Pages free: 3932
```

提案した対応は、ユーザーが host のメモリを空けること（IDEA 約3GB、Docker VM 約8GB を挙げた）、その後に `docker compose restart frontend` を試すこと、効かなければ `docker compose rm -sf frontend && docker compose up -d frontend` へ進むことであった。

#### 提案背景

`nanitabe_front` が操作不能になり、Phase 1 の残り（watcher 追随確認、`visual-inspector` によるscreenshot）と Phase 2 以降を進められない状態だった。復旧手段を決める必要があった。

assistant は空きメモリの絶対値が極端に小さいことを枯渇の証拠として扱い、復旧させても同じ状態へ戻ると考えて、メモリ確保を復旧の前提条件に置いた。

#### 提案0へのフィードバック

**結果:** 前提の誤りを指摘。空きメモリの少なさはこの環境の常態であり、枯渇の証拠にならない。

> 正直いつもこんな感じなんだよな。VM側で調整しているだけで

### イテレーション1: 指標を測り直し、原因を VM 内の watcher 膨張として特定する

#### 提案1

指摘を受けて測り直した結果、メモリは足りていた。

```
memory_pressure:  System-wide memory free percentage: 33%
docker info:      Total Memory: 8217731072  (= 7.653GiB)
docker stats:     nanitabe_front  909.4MiB / 7.653GiB  (11.60%)
sysctl vm.swapusage: total = 20480.00M  used = 19257.19M  free = 1222.81M
```

macOS の `unused` は空きメモリをキャッシュへ回す設計上、小さくても正常である。枯渇の指標として使えるのは `memory_pressure` の free percentage であり、これは 33% だった。swap は 20GB 中 19.2GB を使っているが、ユーザーの環境では常態である。

したがって原因は host のメモリ残量ではなく、**その瞬間に watcher が Docker VM の 7.653GiB を食い潰したスパイク**である。`docker stats` が 909.4MiB を示すのは、watcher が既に kill された後だからである。壊れた `next-server` が zombie として残っているため、メモリが戻っても復旧しない。

この事実を `frontend/docs/ai_guideline/development_standard/docker.md` の「Tailwind watcher のトラブルシューティング」へ追記することを提案した。現行の記載は「手動実行すると競合して死ぬ」「復旧: `docker compose restart frontend`」までであり、死んだあとコンテナごと操作不能になることを扱っていない。

#### 提案背景

イテレーション0 の診断は、指標の選択を誤ったことによる誤診だった。`unused` と `Pages free` は macOS では逼迫を表さない。この誤診の上に「メモリを空けてから復旧する」という手順を組み立てていたため、前提ごと置き換える必要があった。

置き換えた診断では、復旧はメモリ確保を待たずに実行できることになる。壊れているのはプロセスであってメモリ残量ではないためである。

あわせて、この事象自体が docs に無い知識であることが分かった。既存記載は watcher が死ぬところまでで、死んだ結果コンテナが操作不能になり `docker exec` も `restart` も通らなくなることを書いていない。次に踏んだ人が現行記載どおり `docker compose restart frontend` を試して空振りする。

#### 提案1へのフィードバック

**結果:** 追記自体は承認。ただし記載先を `docker.md` ではなく `docker.local.md` にする方向を提示。

> docker.mdに書き足していい。というかローカルマシンの話だからdocker.local.mdへの反映にしようか

### イテレーション2: Tailwind watcher の節ごと `docker.local.md` へ移す

#### 提案2

事故と復旧手順だけを `docker.local.md` へ切り出すのではなく、**Tailwind watcher の節ごと `docker.md` から `docker.local.md` へ移す**。

file の責務境界:

| file | 持つもの |
| --- | --- |
| `docker.md` | container 内実行の原則、基本操作、開発フロー、マルチステージ等の一般規約 |
| `docker.local.md` | local 開発マシン固有の事象。Tailwind watcher の OOM、壊れ方、復旧手順 |

`frontend/docs/ai_guideline/development_standard/README.md` の索引へも 1 行追加する。

`docker.local.md` へ書く内容:

- MUST: 起動済み watcher がある状態で、Tailwind をコンパイルする操作を `docker compose exec frontend` から実行しない。`yarn build` は `build:css` を含むため該当する
- watcher は Docker VM の 7.653GiB に対し 5〜6GB まで膨張し得る
- 膨張すると VM 内でプロセス生成が不能になり、`docker compose exec` が `setns` で失敗する
- `next-server` が zombie 化し、HTTP が無応答になる。一方 `docker compose ps` は `Up` と表示し続けるため、表示だけでは壊れていることが分からない
- **この状態では `docker compose restart` も `tried to kill container, but did not receive an exit event` で失敗する**
- watcher が kill された後はメモリが戻る（実測 909.4MiB）ため、メモリを空けても復旧しない。壊れたプロセスが残っていることが原因である
- 復旧には Docker Desktop 本体の再起動が要る。再起動後は全コンテナが停止するため、`docker compose up -d frontend` で起動し直す
- watcher が死んでいる兆候（`globals.css` を変更しても `tailwind-output.css` が変わらない）は現行記載のまま維持する

#### 提案背景

ユーザーは記載先を `docker.local.md` にする方向を示した。この方向自体は妥当だが、切り出す範囲を決める必要があった。

事故と復旧だけを切り出すと、watcher の情報が `docker.md` と `docker.local.md` の 2 file へ分散する。次に watcher の問題を踏んだ人が、どちらを見ればよいか判断できない。

節ごと移す根拠は、**watcher が動くのは local の開発 container だけ**であることにある。CI（`.github/workflows/ci-frontend-build-verification.yml`）は `yarn build` を一度実行するだけで watcher を起動しない。Lambda イメージビルド（`frontend/buildOnLambda/Dockerfile`）も同様である。したがって「MUST 手動実行しない」という規約自体が local 限定の話であり、`docker.md` に置く理由がない。

#### 提案2へのフィードバック

**結果:** 提案2 を承認。あわせて、記録先を「マシン依存か否か」で分割する指示を受けた。

> 論点2のdocker.local.mdに書いたことは、ローカルPCで落ちたことはローカル依存だからそのまま残してもらって、ローカルに依存しないtailwindの特性や工夫については、frontend/docs/troubleshooting/tailwind/build_and_watch.md に移して。

### 決定

追随確認の手順は、追加先を `@layer base` に限定し、`docker stats` で 80% を超えたら確認を打ち切って即座に revert する。反映の遅延を前提に、変更直後の 1 回の観測で判定しない。「変更量を小さくすれば膨張を避けられる」という根拠は取り下げる。膨張は編集と因果関係がない。

記録先を 2 つに分ける。分割の軸は「特定のマシンや Docker 環境に依存するか」である。

- `frontend/docs/troubleshooting/tailwind/build_and_watch.md`（新設）: Tailwind CSS v4 と Next.js Turbopack の組み合わせに起因する、マシン非依存の特性と工夫。CLI 独立プロセス方式の構成、`--watch=always` が必要な理由、`@layer utilities` の tree-shake と `@layer base` との違い、反映の遅延、再コンパイル時のメモリ膨張の性質と再現パターン、起動済み watcher と二重に走らせない原則
- `frontend/docs/ai_guideline/development_standard/docker.local.md`: ローカルの Docker 環境でどう壊れ、どう戻すか。`docker compose exec` からの実行禁止、`docker compose restart` による復旧、restart が効かない場合の症状（`setns` 失敗、zombie 化、`Up` 表示、Docker Desktop 再起動）、完全に壊れる前の介入、メモリを空けても復旧しないことと macOS の指標

両者は相互に参照し、同じ内容を複製しない。`frontend/README.md` の Tailwind 節からは両方への導線を張る。

**三問:**

1. **根本原因となる未共有知識:** 「この repository の Tailwind watcher は再コンパイル量に応じて VM を食い潰し得る」という推測が、検証されないまま tasklist の手順の根拠になっていた。実際には変更量と膨張に想定した関係がなかった。加えて `--watch` の stdin close による自己終了も共有されていなかった。
2. **code を読めば分かるか:** 読んでも分からない。実際に踏んで実測しないと得られない。
3. **どこに書けば次回不要か:** マシン非依存の特性は `build_and_watch.md`、ローカル環境固有の壊れ方は `docker.local.md`。反映済み。

**結果:** 承認。

> 1:ok。2:ok。3:ok

（この応答は本論点の提案2 と、論点2 の提案1 を含む 3 項目への一括承認である。1 と 2 が本論点にあたる）

### 決定

`frontend/docs/ai_guideline/development_standard/docker.local.md` を新設し、`docker.md` から「Tailwind watcher のトラブルシューティング」節を移す。`docker.md` は container 内実行の原則、基本操作、開発フロー、マルチステージ等の一般規約を持ち、`docker.local.md` は local 開発マシン固有の事象を持つ。`frontend/docs/ai_guideline/development_standard/README.md` の索引へ 1 行追加する。

分割の根拠は、watcher が動くのが local の開発 container だけであり、CI にも Lambda イメージビルドにも watcher が存在しないことである。したがって watcher に関する MUST 自体が local 限定の規約であり、事故と復旧だけを切り出して 2 file へ分散させない。

`docker.local.md` には、既存の watcher 記載に加えて、イテレーション2 の提案2 に列挙した実測事実を書く。とりわけ次の 3 点は現行記載が扱っておらず、次に踏んだ人を空振りさせるため必須である。

1. `docker compose ps` が `Up` に見えても壊れている場合がある
2. `docker compose restart` が `did not receive an exit event` で失敗する場合がある。復旧には Docker Desktop 本体の再起動が要る
3. watcher が kill された後はメモリが戻るため、メモリを空けても復旧しない

**三問:**

1. **根本原因となる未共有知識:** 2 つある。第一に、watcher が VM を食い潰したときの壊れ方と、その状態では `restart` が効かないことが docs に無かった。既存記載は「手動実行すると死ぬ、restart で復旧」までであり、restart が効かない状態を扱っていない。第二に、assistant 側に「macOS の `unused` と `Pages free` はメモリ逼迫の指標にならない」という知識が無く、イテレーション0 の誤診を生んだ。
2. **code を読めば分かるか:** 読んでも分からない。実際に踏んで実測しないと得られない環境固有の事実である。
3. **どこに書けば次回不要か:** watcher の壊れ方と復旧手順は `docker.local.md` へ書く。macOS のメモリ指標の話はこの repository 固有ではなく、書き先が `docker.local.md` で適切かは判断が分かれる。今回は `docker.local.md` の復旧手順の中で「メモリを空けても復旧しない」という形で、この repository の事象に紐づけて書くに留める。指標一般の話を repository docs へ持ち込まない。

---

## 論点2: watcher 追随確認の手順を変更するか

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0: 同じ手順で再試行する

#### 提案0

Phase 1 と Phase 4 の watcher 追随確認を、`tasklist.md` に書かれた手順のまま再試行する。

このとき提示した選択肢は次の 3 つで、1 を推奨した。

1. そのまま同じ手順で再試行する。メモリに余裕があれば通る見込み
2. 追随確認を軽量化する。`globals.css` 全体の再コンパイルではなく、既存の `tailwind-output.css` の mtime とサイズ変化だけを見る
3. 追随確認を落とす。ただし watcher が生きているかは今回の変更の核心なので、落とすと DoD が空洞になる

1 を推した理由は「原因は host のメモリ枯渇であって手順ではない。余裕がある状態なら通るはずで、2 は観測を弱めるだけ、3 は検証にならない」であった。

#### 提案背景

Phase 1 の watcher 追随確認が事故の引き金になったため、同じ手順を再実行してよいかを決める必要があった。

この提案は論点1 のイテレーション0 の診断、すなわち「原因は host のメモリ枯渇」を前提にしていた。手順そのものに問題がなく環境側の問題であるなら、環境を整えて同じ手順を通すのが最も観測を落とさない選択になる。

#### 提案0へのフィードバック

**結果:** assistant が自ら撤回。論点1 のイテレーション1 で前提が崩れたため、この推奨は成立しなくなった。ユーザーの評価を受ける前に提案1 へ置き換えた。

### イテレーション1: 追随確認を最小変更へ軽量化する

#### 提案1

`globals.css` のフル書き換えではなく**最小の 1 クラス追加**に留め、`tailwind-output.css` の mtime と行数の変化だけを見る。確認後は追加した 1 クラスを元へ戻す。

対象は `tasklist.md` の Phase 1 と Phase 4 の両方。

#### 提案背景

論点1 のイテレーション1 で原因が「host のメモリ枯渇」から「watcher 自体が VM を食い潰す挙動」へ置き換わった。この診断の下では、メモリに余裕があっても watcher が膨張し得るため、イテレーション0 で推した「そのまま再試行」は成立しない。前提が崩れた推奨をそのまま維持しない。

イテレーション0 で提示した選択肢 2 を採る形になるが、当時 2 を「観測を弱めるだけ」と評価したのは、手順に問題がないという前提があったためである。手順自体が膨張の量を決めるなら、再コンパイル量を抑えることは観測を弱めるのではなく、事故を起こさずに同じことを観測する手段になる。

観測対象は変えない。watcher が生きていれば `tailwind-output.css` は更新されるため、mtime と行数の変化で追随を確認できる。これは `docker.md` が挙げている「watcher が死んでいる兆候」（`globals.css` を変更しても `tailwind-output.css` の行数・内容が変わらない）を逆向きに使うという当初の方針から外れない。

#### 提案1へのフィードバック

**結果:** 承認。

> 1:ok。2:ok。3:ok

（3 項目への一括承認のうち、3 が本論点にあたる）

### イテレーション2: 変更量による膨張回避が成り立たないことを実測で確認する

#### 提案2

イテレーション1 の決定「再コンパイル量を抑えることで watcher の膨張を避ける」は成立しない。実測で否定された。

**実測の経過:**

1. baseline を記録: `tailwind-output.css` は `mtime=Aug 30 23:59:59, size=42446, lines=1816`
2. `globals.css` へ `@layer utilities { .tmp-watcher-check { color: red; } }` を追加。出力は変化せず、`grep tmp-watcher-check` も 0 件
3. 原因を切り分け。container 内から `globals.css` の追加行が見えるため bind mount は同期している。`docker compose logs` に `Done in 557ms` 等が連続しており watcher は再ビルドしている。**`@layer utilities` のカスタム CSS は `@source "../**/*.{ts,tsx}"` の対象で未参照だと tree-shake され、出力が 1 バイトも変わらない。**内容が同一なら tailwindcss はファイルを書き直さないため mtime も変わらない
4. `@layer base` は tree-shake されないことを確認（既存の `button { border: none }` が出力 1490 行目に存在）。検証手法を `@layer base { hr { border-top-width: 3px } }` へ差し替え
5. この時点で `docker stats` が `nanitabe_front 6.427GiB / 7.653GiB 83.98%` を示した。**CSS ルール 1 個の追加で 6.4GB まで膨張した**
6. 危険と判断して即座に追加分を revert。メモリは `1.689GiB / 7.653GiB 22.07%` へ復帰し、`docker compose exec` と HTTP は健全のまま
7. revert 後に `tailwind-output.css` が `mtime=Aug 31 08:20:48, size=42510` へ変化。**追加版の出力が十数分遅れて書き出された**

**この経過から確定した事実:**

- watcher の膨張は変更量に依存しない。CSS ルール 1 個でも 6.4GB に達する
- watcher の反映には十数分の遅延がある。変更直後に出力を確認しても判定できない
- `@layer utilities` のカスタム CSS は未参照だと tree-shake されるため、追随確認の材料に使えない。`@layer base` を使う
- 膨張しても、変更を戻せばメモリは戻り container は健全を保つ場合がある。今回は VM を壊すに至らなかった

**提案する対応:**

1. 追随確認の手順は「最小の 1 ルール追加」を維持する。膨張は避けられないが、変更量が小さいほど revert が容易で、出力の差分も読み取りやすい。ただし**「膨張を避けるため」という理由は取り下げる**
2. 追加先を `@layer base` に限定する。`@layer utilities` は tree-shake され判定できない
3. 手順へ**メモリ監視と即時 revert** を組み込む。`docker stats` で 80% を超えたら確認を打ち切って revert する
4. 反映の遅延を前提に、変更直後の 1 回の観測で判定しない
5. `docker.local.md` の記述を「再コンパイル量に応じて膨張」から「**変更量に関わらず膨張する**」へ改め、遅延と tree-shake の挙動も書く

#### 提案背景

イテレーション1 の決定は、前回の事故が `globals.css` の大きな書き換えによる再コンパイル量の増大で起きたという推測に基づいていた。この推測は検証されていなかった。

今回 CSS ルール 1 個の追加で 6.427GiB まで膨張したことで、変更量と膨張の間に想定した関係がないことが分かった。したがって「軽量化すれば安全」という前提で手順を組むことはできない。安全は変更量ではなく、監視と即時 revert で確保する。

あわせて、当初の検証手法そのものが誤っていたことも判明した。`@layer utilities` に書いたカスタム CSS は tree-shake されるため、watcher が正常に動いていても出力が変わらない。これを「watcher が死んでいる兆候」と読むと誤診する。`docker.md` の既存記述は `globals.css` の変更で `tailwind-output.css` が変わらないことを兆候として挙げているが、**変更の書き方によっては watcher が生きていても変わらない**。この区別が docs に無い。

#### 提案2へのフィードバック

---

## 論点3: `escalate-plugin-skill-fix` の起動を保留したままにするか

**ステータス:** 保留

**種別:** レビュー指摘

### イテレーション0: 今回の steering では起動しない

#### 提案0

`task-design` skill の Step 0.75 へ「変更対象 file を説明している既存 docs を探す」観点を追加する提案を、この steering では実施しない。

#### 提案背景

`task-design-discussion.md` の論点8 で、`frontend/README.md` が execution plan 対象から漏れていた原因を「Step 0.75 の調査範囲に、変更対象 file を説明している既存 docs を探す観点がない」と特定した。ユーザーは「1,2ok。3は後回しで」と応答し、この提案の実施を保留した。

本論点で改めて記録するのは、今回の実装中に**同じ原因による 2 件目**が発生したためである。`docker.md` の Tailwind watcher 節は、今回の変更で記述が不正確になる file であり、かつ Phase 3 で更新対象に含めていた。しかし「local 固有の事象と container 規約が同じ file に混在している」という構造上の問題は、design phase では検出できていなかった。実装中に事故を踏んで初めて分割の必要が判明した。

1 件目（`frontend/README.md` の漏れ）は Step 4 の gate で検出できた。2 件目は gate でも検出できず、実装中の事故によって判明した。保留したままにするか、優先度を上げるかの判断材料としてこの事実を記録する。

#### 提案0へのフィードバック

### 再開条件

ユーザーが `escalate-plugin-skill-fix` の起動を決めた時点で再開する。その際は `task-design-discussion.md` の論点8 と、本論点に記録した 2 件目の事例を必要性の実例として渡す。

---

## 論点4: `tasklist-executor` が機能しない状況で steering 自身が実装したこと

**ステータス:** 決定

**種別:** レビュー指摘

### イテレーション0: 契約からの逸脱を記録し、扱いを決める

#### 提案0

`tumeda-dev:steering` の「このskillが絶対にやらないこと」は次を定めている。

> steering自身が実装codeを変更する。実装は明示承認後にtasklist-executorまたは子steeringへdispatchする。

今回、Phase 1 の残り、Phase 2、Phase 3 を steering 自身が実装した。契約からの逸脱である。

**逸脱に至った経緯:**

`tasklist-executor` を 2 回起動し、いずれも完走しなかった。

1. 1 回目: Phase 1 の watcher 追随確認で container を壊し、`blocked` で停止。Docker Desktop の再起動が必要な状態になり、agent からは復旧できなかった
2. 2 回目: design と tasklist を更新したうえで再起動したが、`Agent stalled: no progress for 600s (stream watchdog did not recover)` で `failed`。**git status が起動前と同一であり、executor は 1 件も変更を行っていない**

2 回目の停止後、ユーザーから「続けて」の指示を受けた。ユーザーは「一旦寝るから、聞かずにわかってることは自分で考えて進めて」とも述べており、不在である。

**逸脱を選んだ判断:**

3 回目の dispatch より steering 自身の実行を選んだ。判断材料は次の 3 点。

1. 残作業に設計判断が残っていない。`tasklist.md` に対象 file、変更前後の内容、削除する行、新設する file の全文まで書いてある。executor が判断する余地がなく、実行者が誰であっても同じ結果になる
2. 2 回目の失敗が executor 側の watchdog によるものであり、環境にも tasklist にも原因が見当たらない。3 回目も同じ結果になる可能性を否定できない
3. ユーザーが不在で、失敗のたびに確認を取ることができない

**提案する扱い:**

この逸脱を「やむを得ない例外」として正当化しない。契約は維持したうえで、次の 2 点をユーザーの判断に委ねる。

1. 今回の実装結果をそのまま採用するか、`tasklist-executor` で再実行し直すか
2. `steering` skill に「executor が繰り返し機能しない場合の扱い」を定める必要があるか。定めるなら `escalate-plugin-skill-fix` の対象になる

#### 提案背景

契約違反を記録せずに進めると、次回同じ状況で「前回もそうした」という前例だけが残り、判断の根拠が失われる。逸脱そのものより、逸脱を記録しないことのほうが害が大きい。

現行の `steering` skill は executor が機能しない場合の扱いを定めていない。「時間不足、難しさ、host停止、tool制限、外部環境未準備を取消理由にしない。これらは未完了のまま適切な停止・再開状態を返す」という規定は `tasklist-executor` 側の task 取消条件であり、caller 側が executor 自体の故障にどう対処するかは書かれていない。

選択肢は理論上 3 つあった。

- a. 3 回目を dispatch する。同じ watchdog で失敗する可能性があり、ユーザー不在のまま試行を繰り返すことになる
- b. 停止してユーザーの帰りを待つ。「聞かずに進めて」という指示に反する
- c. steering 自身が実装する。契約から外れるが、残作業に判断が残っておらず結果は変わらない

c を選んだが、a と b にも理があり、この選択が唯一の正解だとは考えていない。とりわけ b は、契約を守るという一点では最も安全である。ユーザーの明示指示（「進めて」）と skill 契約（「実装は dispatch する」）が競合したときにどちらを優先するかは、この steering 単独で決めるべきことではない。

**三問:**

1. **根本原因となる未共有知識:** `steering` skill が、dispatch 先の executor 自体が機能しない場合の扱いを定めていない。task の失敗と executor の故障を区別していない。
2. **code を読めば分かるか:** 読んでも分からない。skill の process 設計にあたる。
3. **どこに書けば次回不要か:** `tumeda-dev:steering` skill。ただし repository を問わず再発する process の問題であるため、正本 repository での対応になる。論点3 と同じく `escalate-plugin-skill-fix` の対象であり、ユーザーが着手を決めた時点で今回の事例を実例として渡す。

#### 提案0へのフィードバック

**結果:** 逸脱として扱わない。設計を終えた後の不測の事態への対処としては妥当と評価された。あわせて、許容される場合と禁止される場合の境界、および今後の確認手順の指示を受けた。

> 論点4は仕方ないケースだから別にいいよ。なんだったら予期せぬ状況でよくやってくれた。なんだったら、実装中に、決めてないことを勝手に決める、なんだったらdesignの最中に決められたようなことを勝手に判断したりやspikeできたら弾けた不確実性ををえいやで試しながら進むのはご法度だけど、ちゃんと設計しきってこれで行けると思った状態で不測の事態に陥った際は、報告しながらも、試行錯誤してくれるのはありがたい。

### 決定

steering 自身が実装したことを逸脱として扱わない。ただし許容される範囲には境界がある。

**禁止される行動（今回に該当しない）:**

- 実装中に、design で決めていないことを勝手に決める
- design の最中に決められたはずのことを、実装中に勝手に判断する
- spike で潰せたはずの不確実性を、えいやで試しながら進む

**許容される行動（今回に該当する）:**

- design を完了させ「これで行ける」と判断した状態で不測の事態に陥った際、報告しながら試行錯誤する
- 不測の事態から脱出した後は、`tasklist.md` に沿う

境界は「設計を尽くしたか」にある。設計で潰せた不確実性を実装中の試行錯誤へ持ち込むことは禁止され、設計を尽くしてなお生じた不測の事態への対処は歓迎される。

**今後 steering が確認すべきこと:**

不測の事態に陥った時点で、ユーザーの指示の有無に関わらず次を確認する。選択肢は `a` / `b` / `c` のように添字で答えられる形にし、`yes-no` のような入れ子の表現をそのまま問わない。

1. 不測の事態を解消するために、いったん tasklist から離れて動いてよいか
2. 動いてよい場合、逐一方針を確認するか、自走できる限り自走するか

この確認手順は `tumeda-dev:steering` skill へ組み込む。repository を問わず再発する process であるため、正本 repository での対応になる。

---

## 論点5: 前回 executor が tasklist へ書き残した実測を steering が読み落としていたこと

**ステータス:** 決定

**種別:** 認識齟齬

### イテレーション0: 読み落とした事実を反映し、原因を扱う

#### 提案0

Phase 4 完了後に `tasklist.md` の checkbox 状態を確認した際、1 回目の `tasklist-executor` が Phase 1 の task 配下へ書き残した詳細な note を初めて読んだ。steering は executor の返却 result（`blocked` と要約）だけを読んでおり、executor が tasklist 本体へ書き込んだ実測を読んでいなかった。

**読み落としていた事実:**

1. **`--watch` には欠陥がある。** tailwindcss CLI は stdin が閉じられると watcher を自己終了させる。`entrypoint.sh` から `yarn dev` 経由で background 起動した場合、container 起動後およそ 60 秒で stdin が閉じ、watcher が黙って終了する。executor はこれを `ps` の定点観測で特定し、`package.json` を `--watch=always` へ修正していた。**design.md は `--watch` のまま残っており、実装と食い違っていた。**
2. **メモリ膨張は `globals.css` の編集と因果関係がない。** executor は 3 パターンで独立に再現している。
   - CSS ルール 1 個を追加して即座に削除 → 4 秒後に 2.5GiB
   - CSS ルール 1 個を追加のみ → 25 秒後に 4.45GiB
   - **編集せず `curl` と `docker stats` の定点観測のみ → 45 秒後に 5.25GiB**
3. **原因の推測。** tailwindcss CLI の watcher 単体ではなく、`tailwind-output.css` を `import` している `layout.tsx` を Next.js Turbopack が再コンパイルする経路にある。`FATAL: An unexpected Turbopack error occurred` の panic ログが同経路で観測されている。この構成は build script の集約より前から存在する
4. **早期介入で復旧できる。** `docker compose exec` が生きているうちに revert または `docker compose stop frontend` で介入すれば、`setns` 失敗を伴う完全 wedge へ至る前に 450〜750MiB へ戻せる

**すでに適用した修正:**

- `design.md` の `watch:css` を `--watch=always` へ修正し、`--watch` を使わない理由を設計意図として追記。runtime section へ「watcher の生存」の不足・不整合時の項目を追加
- `tasklist.md` の `package.json` 例と説明を `--watch=always` へ修正
- `docker.local.md` へ `### watcher は --watch=always で起動する` を新設。膨張の記述を「再コンパイル量に応じて」から実測 4 パターンの列挙へ差し替え、`### 完全に壊れる前に介入する` を追加

**論点2 のイテレーション2 への影響:**

イテレーション2 で「CSS ルール 1 個の追加でも 6.4GB まで膨張した」と書いたが、これは追加が原因であるかのように読める。executor の再現（編集なしでも 5.25GiB）と合わせると、**編集は膨張の必要条件ですらない**。論点2 の提案2 のうち「追加先を `@layer base` に限定する」「メモリ監視と即時 revert を組み込む」は維持できるが、「最小の 1 ルール追加を維持する」の根拠は弱まる。変更量は膨張の量を決めていない。

**Phase 4 の残 task の扱い:**

`tasklist.md` の Phase 4 に残る「development へ戻した後に `globals.css` へ 1 ルール追加して追随を確認する」は実行しない。Phase 1 で双方向の追随（42446 → 42510 → 42446）を既に観測しており、再実行は新しい情報を生まず膨張リスクだけを負う。取消完了ではなく、未完了のまま理由を記録して残す。

#### 提案背景

**根本原因（三問の 1 番目）:** steering が subagent の成果を「返却 result」だけで受け取り、subagent が共有成果物へ書き込んだ内容を読んでいなかった。`tasklist-executor` は tasklist の single writer であり、実測は tasklist 本体へ書かれる。result は要約にすぎない。

この読み落としは実害を出した。steering は `--watch` を前提に design を書き続け、ユーザーへの説明でも `--watch` を提示した。実装は既に `--watch=always` になっており、design と実装が食い違ったまま Phase 2 から Phase 4 まで進んだ。また論点2 のイテレーション2 で「1 ルール追加でも膨張」という因果を提示したが、executor が既に「編集なしでも膨張」を 3 回再現していた。同じ実験を精度の低い形でやり直したことになる。

**知識の性質（三問の 2 番目）:** process の不足である。tasklist を読めば書いてあった。読む手順が無かった。

**保存先（三問の 3 番目）:** `tumeda-dev:steering` skill。dispatch した executor が停止・失敗した場合に、result だけでなく executor が更新した成果物を読んでから次の判断へ進む、という手順が要る。repository を問わず再発するため正本 repository での対応になり、論点3 および論点4 と同じく `escalate-plugin-skill-fix` の対象である。

論点3 は「変更対象 file を説明している既存 docs を探す観点が Step 0.75 に無い」、論点4 は「executor 自体の故障時の扱いが定められていない」、本論点は「executor の成果物を読む手順が無い」。いずれも subagent と caller の境界に関する process の不足であり、3 件が同じ領域に集まっている。`escalate-plugin-skill-fix` を起動する際は、3 件をまとめて渡すのが適切と考える。

#### 提案0へのフィードバック

**結果:** 提案として扱わない。読み落とし自体は事実として受け止め、再発防止を運用で担保する指示を受けた。

> 提案5は提案じゃないな。提案5自体については、不測の事態が起きたら、そのsteeringディレクトリの中で、subagent_report/の中にレポーティングをしてもらおうかな。.steering直下の.gitignoreでsubagent_report配下は管理対象外にして。この.gitignore自体もスキルプラグインのsteeringスキルのディレクトリの中に.gitignore.sampleの形で置いてもらって

### 決定

不測の事態が起きた場合、その steering ディレクトリ配下の `subagent_report/` へレポートを書く。

- 配置: `.steering/YYYY/YYYYMM/YYYYMMDD-slug/subagent_report/`
- 追跡対象外にする。`.steering/.gitignore` へ `*/*/*/subagent_report/` を置く。調査ログであり、design / tasklist / discussion のような合意の正本ではないため
- `.steering/.gitignore` 自体は追跡する
- 同じ `.gitignore` を `tumeda-dev` plugin の `steering` skill ディレクトリへ `.gitignore.sample` として置き、他 repository でも同じ構成を再現できるようにする

今回の事態については `subagent_report/20260830-tailwind-watcher-container-wedge.md` を作成済み。経過、誤診とその訂正、読み落とし、判明した事実、未解決事項を記録した。

`design.md` や `implementation_review.md` との棲み分けは次の通り。`subagent_report/` は「何が起きてどう対処したか」の調査ログを持つ。合意した設計、決定、再発防止の反映先は従来どおり `design.md` と `implementation_review.md` が持つ。

**三問:**

1. **根本原因となる未共有知識:** steering が subagent の成果を返却 result だけで受け取り、subagent が共有成果物へ書き込んだ内容を読む手順が無かった。
2. **code を読めば分かるか:** process の不足。tasklist を読めば書いてあった。
3. **どこに書けば次回不要か:** `tumeda-dev:steering` skill。dispatch した executor が停止・失敗した場合に、result だけでなく executor が更新した成果物を読んでから次の判断へ進む手順を加える。あわせて不測の事態を `subagent_report/` へ記録する運用も skill へ組み込む。
