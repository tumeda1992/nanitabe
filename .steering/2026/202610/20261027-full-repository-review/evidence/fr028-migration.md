# FR-028 private integrationへの移行台帳

## baselineと適用根拠

baselineは`7772f908910b7d92835ee0252ac56cb2b99548dd`。利用者の全指摘適用指示と[合意済みdesign](../design.md)の「Host検査だけをorigin制限とせずネットワークで経路を制限する」を根拠にする。実AWS適用・起動・停止・課金resource作成はこの作業に含めない。user由来の未commit3ファイルは対象外。

移行方向は、scriptによるpublic IP追跡・integration URI書換えから、Terraformが固定Cloud Map service ARNとVPC linkを持ち、ECSがprivate endpointの登録/解除を担う形への変更。起動・停止・30分の自動停止・失敗時cleanupという利用者の操作能力を維持する。

## 構造ledger（編集前に固定）

| sourceと範囲 | 役割・関係 | destination / 分類 |
| --- | --- | --- |
| start.sh 1–28 | env、region、resource名、分数、旧URI定数 | 同script。env/名前/分数KEEP、URI定数RETIRE |
| start.sh 29–86 | 値検証、EXIT/INT/TERM、cleanup、schedule削除helper | start.shと新common.sh。cleanup ADAPT、helper MOVE、code保存 |
| start.sh 87–127 | desired_countとAPI/role/JSON前提 | start.sh。起動済み修復KEEP、VPC link前提へADAPT、URI停止JSON RETIRE |
| start.sh 128–171 | 起動、wait、IP取得、integration書換え、時刻計算 | 起動/wait/時刻KEEP。IP/URI経路RETIRE、private readinessへCHANGE |
| start.sh 172–197 | schedule2本と完了出力 | ECS停止scheduleと出力KEEP、URI停止schedule RETIRE、旧schedule cleanup ADAPT |
| stop.sh 1–40 | ECS0、URI停止、schedule2本削除 | stop.sh/common.sh。ECS0 KEEP、URI停止RETIRE、終了待ちADD、旧schedule削除KEEP |
| start.spec.mjs 1–171 | 起動31ケース、AWS/JSON/date/signal stub | 同file。cleanup等KEEP、IP/URI固有scenarioをprivate readinessへCHANGE、stop scenario ADD |
| ecs/main.tf 1–40 | 入力、SSM ARN、default VPC/subnets | KEEP。VPC link用subnet選択ADD |
| ecs/main.tf 41–74 | cluster/logs/task SG | cluster/logs KEEP、SG ingress CHANGE、link SG ADD |
| ecs/main.tf 75–132 | execution role、SSM/KMS permission | KEEP |
| ecs/main.tf 133–193 | task定義、ECS service、outputs | CPU/memory/ARM/env/secrets/egress KEEP、health/registry/exports ADD |
| apigateway/main.tf 1–43 | 値、API、public HTTP integration | API KEEP、fixed service ARN+VPC linkへCHANGE、URI ignore_changes RETIRE |
| apigateway/main.tf 44–142 | route、logs、TLS、DNS、outputs | route/logs/TLS/DNS KEEP、不要URI output RETIRE、link output ADD |
| scheduler_role/main.tf 1–55 | ECS/API停止のpermission | ECS KEEP、API PATCH/GETとapi_id input RETIRE |
| envs/review/main.tf 1–68 | moduleの配線 | 既存resource wiring KEEP、ECS→APIへのprivate情報をADAPT、schedulerのapi_id RETIRE |
| infrastructure/README.md 1–179 | 実行owner、費用、network、共通前提 | runtime/network/cost節を新構成へCHANGE。他の規約/公開手順KEEP |
| backend/docs/ai_guideline/development_standard/review_environment.md 1–174 | 利用手順と停止応答 | 起動/停止URLの説明をCHANGE、他の利用規約・migration注意KEEP |

path省略のstart/stop/commonは`scripts/review_backend/`、Terraformのecs/apigateway/scheduler_roleは`backend/terraform/modules/`、envsは`backend/terraform/`を指す。

## contract ledger（編集前の分類）

| ID | baseline contract | destinationと分類 | 根拠・検証予定 |
| --- | --- | --- | --- |
| C01 | env fileから構成を読み、secretをcodeへ埋めない | 両script KEEP | fixtureでenv pathだけ置換、実envを読まない |
| C02 | 既存region/resource名/到達URLを使う | 両script KEEP | 同じAPI/cluster/service、URL出力 |
| C03 | 停止分数は既定30、正の整数のみ | start KEEP | 0/負数/文字列拒否、既定値保持 |
| C04 | desired_countは0/1を扱う | start KEEP | 不在/未知値を拒否 |
| C05 | CLIの失敗前にAWSで起動が受理されてもcleanupする | start KEEP | update1後CLI失敗をstub |
| C06 | 既に起動中でも停止設定を修復する | start KEEP | desired1の正常/失敗 |
| C07 | taskの稼働待ちを行う | start KEEP | ECS waitの正常/失敗 |
| C08 | 不在の対象IDをそのまま使わない | start ADAPT | API/VPC link/registryの前提確認 |
| C09 | 現在のtaskへHTTP転送する | Terraform+ECS CHANGE | 上位のnetwork経路変更合意。fixed service ARNとSRV自動登録 |
| C10 | backend用Hostを送る | API request mapping KEEP | Host mappingとRails host validationを残す |
| C11 | request path/queryをbackendへ渡す | API mapping ADAPT | private stage prefix除去で既存pathを保持 |
| C12 | UTC one-time scheduleでECSを0へ戻し、実行後schedule削除 | start KEEP | target JSON、時刻、ACTION_AFTER_COMPLETION |
| C13 | URI停止scheduleでpublic IPへの誤送信を防ぐ | ECS登録解除へCHANGE | C09の帰結。固定private registryへ変更しURI停止scheduleをRETIRE |
| C14 | schedule不在は許容、権限等の失敗は隠さない | commonへMOVE | NotFound/AccessDenied双方 |
| C15 | 状態変更後の非zero終了はcleanupする | start KEEP | 各failure pointとstatus保持 |
| C16 | INT/TERMは130/143で終了しcleanupする | start KEEP | signal注入 |
| C17 | cleanup拒否を報告し、停止完了と偽らない | start ADAPT | 旧URI cleanupはC13で不要、ECS拒否は報告 |
| C18 | stopはECSを0へ戻し、既に停止していても使える | stop KEEP | 起動中/停止済み双方 |
| C19 | 停止後のbackendへ転送しない | stop ADAPT | URI変更の代わりにtask終了待ち。Cloud Mapに稼働endpointを残さない |
| C20 | 旧URI停止scheduleがprivate ARNを後から破壊しない | start/stop ADD | C09移行に必要。同名旧schedule削除を残す |
| C21 | Host偽装による直アクセスを防ぐ | task/link SG ADD | 上位合意。task port ingressはlink SGのみ |
| C22 | 公開IPは外向き通信に使う、ALB/NATを増やさない | ECS KEEP | assign_public_ipと既存egressを保持 |
| C23 | ARM/cpu/memory、env/secrets、IAM、logs/TLSを保持 | ECS/API KEEP | baseline差分の逆照合 |
| C24 | private経路のhealthy endpointへ転送する | ECS/Cloud Map/start ADD | C09/C21に必要。TCP health、DiscoverInstances、VPC link待ち |
| C25 | 停止中の費用を隠さない | README CHANGE | DNS namespace約$0.50/月+利用量。cost_judgmentに従いALB等と比較 |
| C26 | schedulerには停止に必要な権限だけを持たせる | scheduler role ADAPT | URI更新不要に伴うAPI PATCH/GET削除 |

C09/C13/C20/C21/C24/C25/C26は同じ上位decision（ネットワークでAPI Gateway経路を制限）の帰結として扱う。private DNS+SRV+VPC linkは、手動IP追跡を残すHTTP-only registryやService Connect sidecarを増やす案より、現構成の移行対象が少ない。ALB/NATの固定費を増やさない。

[公式private integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-private.html)はECS登録時のSRVを要求する。[VPC link](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-vpc-links-v2.html)は60日無通信でINACTIVEになり、再要求からENI再作成に数分かかるため起動確認へ含める。[Cloud Map pricing](https://aws.amazon.com/cloud-map/pricing/)によるprivate DNS namespaceの固定費は約$0.50/月で、実適用後に発生する。今回のcode編集では課金resourceを作らない。

## 検証欄

baselineの全対象範囲と現行差分を順方向・逆方向に照合した。start→common→stop、ECS→Cloud Map→VPC link→integration、schedulerの各ownerを合算し、次の対応を確認した。

| contract | white-box照合と検証 |
| --- | --- |
| C01–C04 | env参照、resource名、分数の既定値/拒否条件、desired0/1の分岐を維持。testはenvのpathだけ人工fixtureへ置換する |
| C05–C08 | EXIT/INT/TERMとrollback flagの順序を維持。既に1の場合もrepairし、API/link/registry/role/JSONの不足を状態変更前に検出する |
| C09–C11 | public IPの収集とURI更新の削除は固定service ARNへの変更へ対応。SRV/container名/port、link SGとsubnetの配線を確認。Host mappingを維持し、pathはstage prefixを除去。queryを変更するmappingは追加していない |
| C12–C14 | 稼働確認後にUTC停止時刻を計算し、ECS0のtargetだけを作る。one-time/実行後DELETEを維持。旧URI scheduleを削除し、NotFoundだけを許容するhelperをcommonへ移す |
| C15–C17 | 起動・wait・discovery・時刻・schedule失敗とsignalの全経路からECS0へ戻す。元のstatusを保ち、cleanup拒否も報告する。固定ARNはcleanupで書換えない |
| C18–C20 | stopのECS0と冪等性を維持し、task終了待ち後にscheduleを除去する。停止失敗時は成功表示せずauto-stopをfallbackとして残す |
| C21–C24 | task ingressのCIDR許可をlink SG参照へ置換。task SGのdescriptionは不変属性のためbaseline値を維持し、受信規則とは分離。CPU/memory/ARM/env/secrets/IAM/egress/logs/TLSの既存値を通読比較した。TCP healthとSRV登録、healthy discovery/link状態に加え、GraphQL metadataの200/Query型/errorsなしまで確認する |
| C25–C26 | 停止時のnamespace固定費と利用量課金を記載。schedulerのECS権限を維持し、不要になったAPI権限だけ削除する |

削除したIP/URI定数、ENI取得、URI書換え、URI停止target/output/permission、READMEの旧owner/固定費説明はC09/C13/C25/C26へ逆引きした。追加したSG/namespace/SRV/health/link/wiring/readinessはC09/C20/C21/C24へ対応する。新しいreadiness request specとprivate integration spec、BASH_ENV用stubは各contractを検証するartifactであり、独立した業務機能の追加ではない。新common.shにhelperの正本を移し、script側へ実装を複製していない。

構造台帳16範囲を照合済み。contract集計は **適合20（KEEP14/MOVE1/ADAPT5） / 合意済み追加3 / 合意済み変更3 / 独立した明示廃止0 / 未監査0 / 未分類削除0 / 未分類追加0**。public IP方式の部分廃止は独立機能の撤去ではなくC09/C13の合意済み方式変更に含む。

black-box検証は旧contractから作った起動・停止50 cases、private構成6 cases、FR-026のIAM3 casesの合計59 testsが成功。AWS/date/curl/sleepだけをstubにし、jqは実binaryでtarget/metadataのJSONを検査する。argument logはNUL区切り+record separatorで実jqの複数行出力も保持する。providerの大きなarchive検証を同時に行った実行では30秒timeoutが出たため、負荷を分けて59件を再実行し全成功を確認した。

Railsの認証なしmetadata requestは1 example成功し、User/Dish/Meal件数を変えないことも確認した。追加specのRuboCop、bash syntax、変更Terraform5ファイルのfmt、diff checkが成功。task health用の実Ruby commandは既存backend containerのloopback TCP serverへ接続・切断する形で成功した。

実AWSへのapply/起動/停止、Host偽装による直アクセス拒否、実VPC link経由の到達性と費用は未実測。コード検証と実環境確認を区別し、後者は実適用を別途実施する際に確認する。

Terraform 1.9.4とprovider 6.70.0（review）/5.100.0（prod）は公式releaseのSHA256と元lockfileのzh hashを照合した。元lockfileにはこの実行platformのh1がなかったため、隔離した検証copyだけへ当該ZIPから計算したARM h1を1件ずつ追加した。version/constraint/既存hashは全保持し、repositoryのlockfileは変更していない。対象Terraform sourceのcopyは原本とbyte比較した。host sandboxではprovider起動が失敗したが、既存の開発用backend containerの一時領域でoffline init後、review rootのvalidateが成功した。provider 6のfailure_threshold非推奨警告は残る（AWSで値は常に1）。plan/applyやstate backend接続は行っていない。
