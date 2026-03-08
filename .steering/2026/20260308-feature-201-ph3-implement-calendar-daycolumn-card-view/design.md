# 要件ドキュメント

## はじめに

`.steering/2026/20260307-feature-201-apply-v0-calendar-design/tasklist.md` フェーズ3「カレンダービュー刷新（DateCard カード形式）」を実装する。

現在の `Calender/index.tsx`（table 形式）を DateCard カード形式（Tailwind CSS）に置き換え、週・月ビュー両方で新しいカード形式のカレンダーが表示されるようにする。

## 元の依頼内容

.steering/2026/20260307-feature-201-apply-v0-calendar-design/tasklist.md のフェーズ3を実装したい

## 要件

### 要件1: DateCard 形式への刷新（表示・操作両面）

**ユーザーストーリー:** ユーザーがカレンダー画面（週/月）を開いたとき、各日付がカード形式（rounded-xl border）で縦に並び、既存の食事操作が全て引き続き動作する

#### 受け入れ基準（表示）

1. WHEN 週・月ビューを表示する THEN 各日付が `rounded-xl border bg-card px-2.5 py-1.5` のカードで縦に並ぶ
2. WHEN 今日の日付を表示する THEN `ring-2 ring-primary/40` のハイライトが付く
3. WHEN 土曜日を表示する THEN 青色系の色が適用される
4. WHEN 日曜日を表示する THEN 赤色系の色が適用される
5. WHEN 各日付カードを表示する THEN 日番号（丸囲み）・曜日ラベル・追加ボタン（+）が表示される
6. WHEN 料理が登録されている THEN 料理名が日付カード内に表示される（MealIcon コンポーネントを暫定流用）
7. WHEN 料理がない日を表示する THEN 点線ボーダーの「追加」ボタンが表示される
8. WHEN GraphQL データが取得される THEN 正しく料理が表示される

#### 受け入れ基準（操作・既存機能）

9. WHEN 表示モードで追加ボタン（+）をタップする THEN 既存の AddMeal フロー（食事追加）が起動する
10. WHEN 食事の ••• ボタン（FloatModalOpener）をタップする THEN 既存の MealIcon Menu が開く
11. WHEN Menu から「食事編集」を選ぶ THEN 既存の食事編集フローが動作する
12. WHEN Menu から「評価」を選ぶ THEN 既存の evaluationScore 表示・操作が動作する
13. WHEN Menu から「他の日へ移動」を選ぶ THEN 既存の MoveMeal フローが起動する
14. WHEN 日付をタップする THEN 既存の onDateClick（日付ごとの交換モード起動）が動作する
15. WHEN SwapMeals モードで別の日付を選ぶ THEN 既存の SwapMeals フローが完了する
16. WHEN AssignDish モードの THEN 既存の AssignDish フローが底部バーに表示される

### 要件2: スペルミス修正（calender → calendar）

**ユーザーストーリー:** 開発者がコードを読んだとき、新しいコンポーネント・ルーティングに正しいスペル "calendar" が使われている

#### 受け入れ基準

1. WHEN 新規作成するコンポーネント・ディレクトリを確認する THEN "calendar"（正綴）が使われている
2. WHEN ルーティングパスを確認する THEN `/calender/...` が `/calendar/...` に変更されている
3. WHEN `features/calender/` を確認する THEN `features/calendar/` にリネームされている
4. WHEN テスト・ESLint を実行する THEN エラーがゼロ

### 要件3: 既存ビジネスロジック維持

**ユーザーストーリー:** デザイン刷新後も、既存の操作（食事追加・削除・移動・交換・料理割当）が引き続き動作する

#### 受け入れ基準

1. WHEN 既存テストを実行する THEN 全てグリーン
2. WHEN 食事追加・削除・移動・交換を操作する THEN 既存の GraphQL mutation が呼ばれる
3. WHEN 各フェーズ完了時にデプロイする THEN アプリが正常に動作する

---

# 設計ドキュメント

## TL;DR

既存の `Calender/index.tsx`（table 形式）を old/ に退避して、DateCard（各日付カード）形式の新 `Calender/index.tsx` を Tailwind CSS で実装する。
スペルミス（calender→calendar）を新規ファイル・ルーティング・features ディレクトリに対して修正する。
既存ビジネスロジック（useMeal・useCalenderMode・GraphQL）は変更せず流用する。

> **命名メモ**: v0 生成時の名称は "DateCard"（列レイアウト時代の名残）だったが、縦並びカード形式に変更後も名前が残っていた。実態に合わせて `DateCard` に変更する。

## 変更点サマリ

| 対象 | 現状 | 変更後 |
|------|------|--------|
| `Calender/index.tsx` | table 形式（SCSS modules） | DateCard カード形式（Tailwind CSS）に置換 |
| `Calender/old/index.tsx` | 存在しない | 既存 `Calender/index.tsx` を退避 |
| 新コンポーネント: `DateCard.tsx` | 存在しない | 各日付カードを担当する新コンポーネント（旧称 DayColumn） |
| ルーティング | `/calender/week`, `/calender/month` | `/calendar/week`, `/calendar/month` |
| `features/calender/` | スペルミスあり | `features/calendar/` にリネーム |
| import パス | `calender` スペル | `calendar` に統一（old/ 内はそのまま） |

## 設計選択と理由

### old/ ディレクトリ運用
上位 design.md の方針に従い、既存 `Calender/index.tsx` を `Calender/old/index.tsx` に移動する。
WeekCalender・MonthCalender のインポートパスを修正してテストが通ることを確認してから、新コンポーネントを作成する。

### 新 Calender コンポーネントの構成

```
Calender/
├── old/              ← 既存 index.tsx を退避
│   └── index.tsx
├── DateCard.tsx     ← 各日付カードコンポーネント（新規）
└── index.tsx         ← DateCard を並べる新コンポーネント（新規）
```

新 `Calender/index.tsx` は以下の責務を持つ:
- `flex flex-col gap-1.5` で DateCard を縦並び
- useCalenderMode・useRefreshCalenderData の呼び出しは old と同じ
- BottomBar（AssignDish/MoveDish/SwapMeals）も引き継ぐ
- CalendarHeader は WeekCalender/MonthCalender 側が渡す（children パターン維持）

`DateCard.tsx` は以下を担当:
- `rounded-xl border bg-card px-2.5 py-1.5` のカード
- 日付ヘッダー: 日番号（丸囲み）+ 曜日ラベル + 追加ボタン（+）
- 今日ハイライト: `ring-2 ring-primary/40`
- 土曜=青・日曜=赤
- 料理一覧: 既存 MealIcon コンポーネントを暫定流用
- 空日付: 点線ボーダーの「追加」ボタン

### スペルミス修正の範囲と順序

スペルミス修正は「new code only」方針:
1. 新規作成するコンポーネント・ディレクトリ名は "calendar" 正綴で作る
2. `features/calender/` → `features/calendar/` リネーム（import 一括置換）
3. ルーティング `/calender/...` → `/calendar/...`（ファイル移動 + 古いパスはリダイレクト不要）
4. old/ に移動した既存コンポーネントは "calender" スペルのまま残す

**スペル修正の順序（リスク低減のため）:**
1. まず old/ 退避と新 Calender 実装を行い、テストグリーンを確認
2. その後 features/calender/ → features/calendar/ リネーム
3. 最後にルーティング修正

### データフロー（変更なし）
- `useMeal` hook + Apollo GraphQL はそのまま使用
- props 経由で `dateMealsList`（`{ date, dayLabel, meals }[]`）を受け取る設計は維持
- `useCalenderMode` の各モード切替も維持

## 代替案と棄却理由

### 代替案1: スペルミス修正をこのフェーズのスコープ外にする
スコープを絞れて安全だが、上位 tasklist でフェーズ3のタスクとして明記されており、先送りすると次フェーズの新規コンポーネント（DishCard）でも混在が続く。採用しない。

### 代替案2: `Calender/index.tsx` をインプレースで修正する（old/ 不使用）
上位 design.md の「oldディレクトリ運用」方針に反する。採用しない。

### 代替案3: DateCard を Calender/index.tsx に直書き（サブコンポーネントに切り出さない）
シンプルだが、次フェーズ（DishCard 刷新）でのメンテが難しくなる。`DateCard.tsx` に切り出す。

## リスクと対策

| リスク | 対策 |
|--------|------|
| old/ 退避後の import パス修正漏れ | 退避直後にテスト・ESLint で検出 |
| features/calender/ リネームで import 漏れ | grep で全件確認後、一括置換 |
| ルーティング変更でリンク切れ | NextJS の Link/href を一括確認。旧パスへのアクセスは 404 になるが、ブックマークなどは現状ないため許容 |
| Tailwind クラスが old/ の SCSS と競合 | 新コンポーネントは Tailwind のみ使用。old/ の SCSS は触らない |
| isSameDay での今日判定 | `date-fns/isSameDay` を利用（既存パターン） |

## テスト方針

- old/ 退避後: `docker compose exec frontend yarn test` で全テストグリーン確認
- 新 Calender 実装後: 同上
- スペルミス修正後: 同上 + `docker compose exec frontend yarn lint`
- 新規コンポーネント（DateCard）に最小限のユニットテスト追加（表示確認レベル）
