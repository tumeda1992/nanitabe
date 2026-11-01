# FR-033 GraphQL入力変換の移行台帳

baselineは`5a2fd44`。全件適用の合意のうち、作成/更新に重複する3項目の転記をInputObjectへ移す。

| sourceの連続範囲 | destination / 分類 |
| --- | --- |
| add_meal_frame_pattern.rb 1–7 / 15–25 | resolver定義/Command/返却値 KEEP |
| 同8–14 | entry InputObject#to_command_paramsへMOVE、mapのbinding ADAPT |
| update_meal_frame_pattern.rb 1–7 / 15–26 | resolver定義/認可actor/対象id/Command/返却値 KEEP |
| 同8–14 | entry InputObject#to_command_paramsへMOVE、mapのbinding ADAPT |
| meal_frame_pattern_entry_input.rb 1–7 | 既存GraphQL引数/型/必須をKEEP、転記のownerを受ける |

resolverのpathはbackend/app/graphql/mutations/meal/frame/pattern/、InputObjectはbackend/app/graphql/types/input/meal/frame/pattern/。consumerは両resolver、後続のPattern Commandとentry作成処理、GraphQL spec。

| contract | 分類 / destination |
| --- | --- |
| I01 day_offset/meal_type/meal_frame_idをsymbol keyで値を変えず転記 | MOVE / entry InputObject |
| I02 配列順序と空配列を保持し、entryごとに独立hashを返す | ADAPT / resolverのmap |
| I03 GraphQLの3必須Int定義を維持 | KEEP / entry InputObject |
| I04 current_user_id、更新対象id、Commandとtransaction/認可を維持 | KEEP / resolverとCommand |
| I05 meal_frame_pattern_idの返却を維持 | KEEP / resolver |

編集前に固定。適用後にwhite-box照合と自動検証を追記する。

## 適用後の照合（2026-11-02）

構造5範囲を通読し、両resolverの削除hash fieldをI01のInputObjectへ、追加map bindingをI02へ逆引きした。actor/対象id/Command/transaction/GraphQL引数/返却値の差分はない。生成するhashは毎回独立で、空配列と複数entryの値・順序も維持する。

集計: 適合5（MOVE1/ADAPT1/KEEP3） / 合意済み追加0 / 合意済み変更0 / 明示廃止0 / 未監査0 / 未分類削除0 / 未分類追加0。

新InputObject境界の1件はNoMethodErrorのred、移行前GraphQL4件は成功。移行後は入力spec、作成・更新・認可とpattern Commandを含む37 examples / 0 failures。変更6ファイルRuboCopは追加assertionの書式を自動修正後に成功。diff check成功。
