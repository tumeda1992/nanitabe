# FR-034 FrameEntry互換委譲の移行台帳

baselineは`65dc499a1da8fb527a75e9edf2c146d7d3bf6357`。方向は旧`Meal::FrameEntry`から現行`Meal::Frame::Entry`への実装集約。利用者の全件適用とdesignの互換委譲方針に従い、外部参照の不存在を断定せず旧定数を維持する。旧Removeの本人scope追加はFR-005/FR-034の認可契約に含む合意済み変更である。

| sourceの連続範囲 | destination / 分類 |
| --- | --- |
| frame_entry/root.rb 1–29 | 現行Rootの属性/validation/操作を継承。旧class名はKEEP、実装はMOVE。旧公開method集合を保持 |
| frame_entry/usecase/add_command.rb 1–31 | 現行Addを継承しcall結果だけ旧RootへADAPT。保存処理を二重化しない |
| frame_entry/usecase/remove_command.rb 1–15 | 現行RemoveへMOVE。所有者scopeはCHANGE |
| frame_entry/usecase/fill_with_meal_command.rb 1–4 | FR-008で既に現行へ委譲済み。KEEP |
| ../README.md 1–49 | L10のconsumer記載も照合対象。34行の正本/互換入口説明をADAPTし、他はKEEP |

pathはbackend/app/domain/business/food/meal/基準。参照検索はbackend/app・backend/spec・scripts・.githubを対象にし、旧Business定数は旧specと両namespaceの所有者specに存在した。GraphQLのMutations::Meal::FrameEntryとInput namespaceは別の公開名であり削除しない。modelが返す現行Root、Meal/food READMEもconsumerとして確認する。外部scriptの不存在は確認できない。

| contract | 分類 / destination |
| --- | --- |
| L01 旧Root/3 Commandの定数名・autoload・private constructorを維持 | KEEP / 旧互換class |
| L02 Rootの6属性・型変換・4必須validation・例外を維持 | MOVE / 現行Rootの継承 |
| L03 assign_meal、初回set_id、再変更拒否を維持。旧Rootにunassign_mealは公開しない | MOVE / 継承と互換method制限 |
| L04 Addの本人frame確認・1回の保存・採番を維持 | MOVE / 現行Add |
| L05 Addの返却は旧Rootのclass名と同じ属性 | ADAPT / superの結果を旧Rootへ包み直す |
| L06 Removeの本人削除・返却id・不存在例外 | MOVE / 現行Remove |
| L07 Removeは他人のentryを拒否し副作用を残さない | CHANGE / 現行Removeのowner scope。上記合意に対応 |
| L08 Fillの現行Root返却、認可/lock/transaction/cardinalityを維持 | KEEP / 既存委譲 |
| L09 modelのRoot返却・GraphQLの入口名を維持 | KEEP / 元ownerのまま |
| L10 READMEから現行正本と互換入口の役割を辿れる | ADAPT / food READMEの実装状態説明 |

編集前に固定。white-box照合、旧contract由来の互換spec、eager load/全体回帰結果を適用後に追記する。

## 適用後のwhite-box照合（2026-11-02）

旧4fileとREADMEの5構造範囲を通読し、全削除行をL02–L07の現行ownerへ逆引きした。追加したsuper返却の包み直しはL05、旧Rootのunassign_meal非公開化はL03、README説明はL10に対応する。Rootの6属性/4必須validation、ID操作とCommand初期化は同じ基底を継承し、現行Rootには変更を加えていない。旧Addが保存するのは現行Rootへ変わるが、同じ属性を1回だけ保存してから旧Rootを返す。modelとGraphQLは元の現行Root/入口名のままであり、旧moduleから現行への委譲の逆流・二重保存はない。

集計: 適合9（KEEP3/MOVE4/ADAPT2） / 合意済み追加0 / 合意済み変更1（L07） / 明示廃止0 / 未監査0 / 未分類削除0 / 未分類追加0。外部利用が不明な定数の削除・aliasによるclass名変更は行わない。

互換9 examplesは修正前に本人scopeの1件だけred。他の8件で旧contractを固定し、変更後は新旧Command・認可・GraphQLを含む57 examples / 0 failures。変更4ファイルRuboCop成功。test設定のzeitwerk:checkも成功（既存のlibはeager_load対象外という警告は継続）。backend全体回帰も885 examples / 0 failures。diff check成功。

## 再適用範囲（2026-11-06）

旧入口の内部継承変更と他人削除拒否は今回の許容差分。旧定数・本人操作の返却classと属性・単一保存を維持し、旧Fillの現行委譲とFR-008認可を保持する。上記2026-11-02の検証は当時の記録であり、今回の再実測は新request/resultに記録する。

README document-review（2026-11-06）: 全文と前版差分を通読し、内容・記法・指示対象・既存記述の保持・公開情報・暫定性を確認。現行/互換入口と旧返却class、削除前の利用確認を読者が辿れ、前版の外部利用確認条件も保持する。指摘なし。

## 旧domain削除前の台帳（baseline 94623f6、2026-11-07）

利用者の「いらない方消して」により旧 `Meal::FrameEntry` Root/Add/Fill/Remove の4定数と4file、旧Root返却class、旧Rootのunassign非公開をRETIREする。GraphQLのFrameEntry名、ActiveRecord `MealFrameEntry` とtable、現行 `Meal::Frame::Entry` はKEEP。

| 旧構造・機能 | 分類・移管先 |
| --- | --- |
| 旧Root/Add/Fill/Removeと旧compat identity | RETIRE。現行Root/Add/Fill/RemoveをKEEP |
| 旧Add 4、Fill 2、Remove 3例 | 現行specと重複のためRETIRE |
| 旧path Unassign 3例 | 現行entry/usecaseへMOVE、require階層を適応 |
| compat Root属性・変換・assign/set_id・4必須 | 現行root_specへMOVE |
| compat Add単一保存・属性・private constructor | 現行Add specへMOVE |
| compat Remove他人拒否・属性不変 | 現行Remove specへMOVE |
| ownership namespace loop | 旧側RETIRE、現行5例KEEP |
| 旧Fillの現行Root返却・保存 | 現行Fill specにKEEP |
| food README・architecture例 | 現行domainへADAPT |

上記は編集前の対応。過去の互換保持と実測は当時の履歴として残す。

2026-11-07 document-review: food README・architecture例・findingと作業記録の変更前後を照合。現行入口と削除された旧domain、維持するGraphQL/ActiveRecord名、旧履歴の時点を明示し、記法・指示対象・公開情報・暫定性を確認。指摘なし。検証結果は新attemptへ記録する。
