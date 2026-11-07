# FR-032 schema移行台帳

baselineは`a871b4cca2b2e009cc6a99cb9c28b04f6f42b382`。全件適用の合意のうちschema重複の解消だけを行い、validation追加は含めない。

| sourceの連続範囲 | destination / 分類 |
| --- | --- |
| addMealFramePatternMutation.ts 1–20 | import bindingのADAPT、operationはKEEP |
| 同21–36 | schema.tsへMOVE。entry/name/entriesの正本を共通化 |
| 同37–58 | infer型の参照をADAPT、hook/返却値/refetchはKEEP |
| updateMealFramePatternMutation.ts 1–20 | import bindingのADAPT、operationはKEEP |
| 同21–37 | schema.tsへMOVE。共通bodyに更新専用idを合成 |
| 同38–58 | infer型の参照をADAPT、hook/返却値/refetchはKEEP |

pathの基準はfrontend/src/features/meal/frame/pattern/。consumerはuseMealFramePatternとEditor/Form、そのspec。GraphQL operation/codegenの変更は不要。

| contract | baselineの意味 | 分類 / destination |
| --- | --- | --- |
| S01 | dayOffsetはnumberかつ1以上、既存の日本語error | MOVE / entry schema |
| S02 | mealType/mealFrameIdはnumber。追加の整数/正数制約を導入しない | MOVE / entry schema |
| S03 | nameはstring必須、欠落/空文字の既存日本語error | MOVE / body schema |
| S04 | entriesはarray、空配列を許容、順序を保持 | MOVE / body schema |
| S05 | createはid不要、updateはnumberのid必須 | ADAPT / create/update wrapper |
| S06 | objectのunknown keyをstripし、値をcoerceしない | KEEP / 同じZod object/number |
| S07 | updateの検査順はid→name→entries | KEEP / idを先頭にしたobjectへ共通bodyをmerge |
| S08 | 公開infer型、mutation/返却tuple/refetch、add hookのschema返却 | KEEP / 元moduleと同じschema binding |

編集前に固定した台帳。適用後に順逆照合・characterization・型検査結果を追記する。

## 適用後の照合（2026-11-02）

6構造範囲を順方向に通読し、削除した各schema fieldをS01–S07の新ownerへ、追加importとwrapperをS05/S08へ逆引きした。bodyとentryの業務validationは各1箇所になり、operation/GraphQL引数/返却値/refetchは変更していない（整形だけの差分を含む）。更新専用idのmerge順を先頭にして既存のerror順も維持した。S02の許容値をFR-017のフォーム検証へ勝手に揃えず、移行前と同じnumber契約に保っている。

集計: 適合8（MOVE4/ADAPT1/KEEP3） / 合意済み追加0 / 合意済み変更0 / 明示廃止0 / 未監査0 / 未分類削除0 / 未分類追加0。S01–S04がMOVE、S05がADAPT、S06–S08がKEEPであり、内訳はMOVE4/ADAPT1/KEEP3である。

移行前の11 characterization testsが成功。移行後は更新id/検査順を加えたschema13件と関連フォームを含む33 tests、型検査が成功した。lintが検出したtestでのhook呼出しをrenderHookへ修正し、最終schema13件と変更4ファイルlintも成功した。markupや表示動作は変更していない。

## 挙動維持への復元時の再照合（2026-11-05）

旧baselineは過去の比較対象として保存し、現在の比較基準はd58c473とする。全件指示が挙動維持条件を解除したという旧記録はassistantの誤判断である。
元作成/更新moduleからschemaの連続範囲を抽出し、現在の共通ownerへ各field・message・順序・bindingを再対応付けた。
S01〜S07は元の入力schemaとの120ケースのsuccess/data/issues順比較で一致し、S08は既存schema specでhook bindingと公開infer型を確認した。
[結果と抽出本文](scope-repair/fr017-attempt-1/result.md)を参照。0/負数/少数を拒否するFR-017の追加条件はフォームだけに存在しており、今回フォームから取り消した。
共有schemaのnumber契約は元版と一致するため変更していない。この照合は旧不具合の解消や今回の最終全体検証を意味しない。
