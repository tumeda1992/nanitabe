# RV-029: 週・月カレンダーのURL日付解釈が二重実装されている

- 観点: 保守性・性能・契約
- 優先度: 低
- 採否: 採用
- 対応状況: 完了
- 今回の適用対象: 対象
- 対象コミット: 46ad16a84c2d4c0cc82d23136573ac139493215e
- 対象: frontend/src/app/calendar/week/[date]/page.tsx; frontend/src/app/calendar/month/[date]/page.tsx
- 依存する指摘: なし

## 問題と根拠

両pageはURLから日付文字列を抽出し、isISODateFormatStringで検証し、未指定時は今日を使い、T09:00:00を付ける同じロジックを持つ。違いはpath定数と描画するCalendarだけで、URL日付契約の変更時に片方が取り残される。

## 改善案

共通のpathと日付を扱う純粋関数を抽出し、path prefixとフォールバックの現在日時を引数として渡す。各pageは論理URLの取得とCalendarの選択を担当する。

## 振る舞いを維持する条件

正規表現の範囲、query付きURLのフォールバック、形式だけを検証する現状、09:00生成を維持する。存在しない日付の検証やtimezone修正は別の挙動変更として扱う。

## 検証方法

週・月、日付あり/なし、query付き、不正形式について旧実装と生成されるDateの値を比較する。現在日時は固定して試験する。

## 採否・対応記録

- 2026-10-26: ユーザーの適用指示により採用・実装済み。
- 検証: 週/月ページのURL日付処理をcalendarDateFromPathへ抽出。09:00、query付きURLのfallback、形式のみ検査、非anchor正規表現を維持。Jest: 日付8ケースとCalendar統合3ケース、計2 suites/11 tests成功。
- 適用コミット: 本ファイルの完了記録と同じコミット（git logで参照可能）
