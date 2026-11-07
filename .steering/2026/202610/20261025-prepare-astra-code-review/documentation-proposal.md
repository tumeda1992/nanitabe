# 再発防止の文書更新案

2026-10-27。以下は提案であり、標準文書への追記はまだ行っていない。RV-025の文書矛盾修正は実施済み。

## 1. 料理出典の入力変換を変更するときの参照先を明示する

対象: `frontend/src/features/dish/README.md` のクイックマップと変更ガイド。

追記案:

> 料理・食事の登録更新で使う出典入力の変換はnormalizeFunctions.tsのnormalizeDishInputWithExistingSource / normalizeDishInputWithNewSourceが担当する。既存出典を選ぶ料理更新は入力構造が異なり、別の変換を維持する。変換変更時はdishInputConversion.spec.tsと料理・食事フォームのspecを実行し、入力の非破壊性、meal/frameEntryIdとタグの保持、NO_VALUEのnullを確認する。

狙い: 新しいmutationへ同じ変換をコピーすることと、入力構造の異なる更新を一律に統合することを防ぐ。

## 2. パターン一覧の取得経路とSQL検証を変更ガイドへ記す

対象: `backend/app/domain/business/food/meal/README.md` の変更ガイド。

追記案:

> パターン一覧のentriesと枠名はGraphQL層のSources::MealFramePatternEntries / Sources::MealFramesでまとめて取得する。出力型へ関連情報を追加するときはmeal_frame_patterns_spec.rbで複数パターン・共有枠の応答とSQL数を確認する。欠落枠の空文字とエントリの並びを維持する。

狙い: field resolverへ個別findを追加してN+1を再導入することを防ぐ。

## 3. パターン入力・日付・モードの変更入口をfrontendにまとめる

対象: `frontend/src/components/calendar/README.md` の新設を提案する。

追記する内容:

- モードの有限集合とsetter型の正本はcalendarComponents/calendarMode.ts。旧hookからの再exportは互換入口である。
- 週/月ページ共通の日付解釈はfeatures/calendar/calendarDateFromPath.ts。09:00生成とquery付きURLのfallbackを修正する場合は、挙動変更として別途判断する。
- パターン作成/編集の共通入力はcomponents/meal/frame/pattern/MealFramePatternFields.tsx。wrapperは初期値とAPI操作を担当する。変更時は作成/編集両方のspecで初期復元・削除後の番号・payload・成功callbackを確認する。

狙い: 入口が複数あるコードの正本と、回帰テストの場所を判断できるようにする。

## 標準の配置

上記はこのリポジトリの具体的な参照先と変更契約であり、利用先のREADMEへ置く案である。
一般的な「同じ理由で変わる処理を抽出する」原則は既存の開発標準にあるため複製しない。汎用的な新ルールが必要になった場合はplugin正本への別提案とする。
