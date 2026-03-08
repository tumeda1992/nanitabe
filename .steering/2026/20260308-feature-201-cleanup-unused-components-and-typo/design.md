# 要件ドキュメント

## はじめに
DishCard 実装後の後片付け。不要コンポーネントの削除と `calender` タイポ修正が主軸。
調査結果をもとに追加の後片付け候補も含めて整理する。

## 元の依頼内容
使わなくなったコンポーネントの削除と、calendarのタイポがあるところを直すところくらいだけど、他思いつくところある？

## 要件

### 要件1: 不要コンポーネント削除

**ユーザーストーリー:** DishCard 実装で不要になったファイルを削除し、コードベースをすっきりさせる

#### 削除対象（確定）
| パス | 理由 |
|------|------|
| `components/calender/calenderComponents/MealIcon/old/` | フェーズ1で退避したが、参照元の `Calender/old/` ごと削除 |
| `components/calender/calenderComponents/MealIcon/index.tsx` | `Calender/old/` からのみ参照 → 削除 |
| `components/calender/calenderComponents/MealIcon/Menu.tsx` | 同上 |
| `components/calender/calenderComponents/MealIcon/Menu.spec.tsx` | 同上 |
| `components/calender/calenderComponents/MealIcon/index.module.scss` | 同上 |
| `components/calender/calenderComponents/MealIcon/Menu.module.scss` | `Calender/old/` と `Date.tsx`（削除対象）からのみ参照 |
| `components/calender/calenderComponents/Calender/old/` | 旧 Calender コンポーネント、誰も参照していない |
| `components/calender/calenderComponents/Date.tsx` | `Calender/old/` からのみ参照 |

#### 残すもの（現役）
- `MealIcon/AddMealIcon.tsx` / `AddMealIcon.module.scss` → `DateCard.tsx` から参照中

#### 受け入れ基準
1. WHEN 削除対象ファイルを消したとき THEN テスト全グリーン・ESLintエラーゼロ
2. WHEN `DateCard.tsx` をレンダリングしたとき THEN AddMealIcon が正常に表示される

---

### 要件2: `calender` タイポ修正

**ユーザーストーリー:** `calender` という typo を `calendar` に統一し、コードの可読性を上げる

#### 現状の把握
タイポが存在する箇所は大きく3カテゴリ:

**A) ディレクトリ/ファイル名（リネーム必要）**
- `components/calender/` → `components/calendar/`
- `calenderComponents/` → `calendarComponents/`
- `WeekCalender/`, `MonthCalender/` など
- `useCalenderMode.ts`, `useCalenderArrowComponent.tsx` など

**B) コンポーネント名・変数名・export 名（リネーム必要）**
- `WeekCalender`, `MonthCalender`, `Calender`
- `useCalenderMode`, `useCalenderArrowComponent` 等
- `isDisplayCalenderMode`, `calenderModeChangers` 等（42ファイルにわたる）

**C) URL ルーティング**
- `src/app/calender/` （旧URLページが残存）
- `src/app/calendar/` （新URL、こちらが正規）
- 旧URLページは現在リダイレクト処理なし（旧URLとして独立している）

#### 修正範囲

**全修正（A + B + C）** を採用。

ただし以下は対象外:
- `graphql.ts`: 自動生成ファイル（手動編集不可）
- `fetchMealQuery.ts` 内の `mealsForCalender`/`MealForCalender`: GraphQL クエリ/型名（バックエンドスキーマ由来）

削除後に残る修正対象は約 **28 ファイル**（自動生成除く）。

#### 受け入れ基準
1. WHEN `calender`/`Calender` でgrepしたとき THEN 修正対象ファイルにヒットしない
2. WHEN 旧URL `/calender/` にアクセスしたとき THEN 新URL `/calendar/` にリダイレクトされる（または404）
3. WHEN 全テストを実行したとき THEN グリーン

---

## 追加後片付け候補（ユーザーへの提案）

調査で見つけた追加候補。今回やるかどうかはご判断を:

| 候補 | 内容 | 優先度 |
|------|------|--------|
| `Date.tsx` の TODO コメント解消 | 削除対象なので自動解消 | - |
| `src/app/calender/` の整理 | 旧URLページが実装のまま残存している | 中 |
| `DateCard.tsx` の `calenderModeChangers: any` | 型を適切につける | 低 |
| `moveMeal.spec.tsx` の変更内容確認 | git status で M マーク、意図した変更か確認 | 中 |

---

# 設計ドキュメント

## TL;DR
DishCard 実装後の後片付け。`MealIcon/old/`・`Calender/old/` などを削除してコードをきれいにする。
`calender` タイポは42ファイルに及ぶため、修正範囲をユーザーと合意してから進める。

## 変更点サマリ

### フェーズ1: 不要コンポーネント削除（確定）
- `MealIcon/old/`、`MealIcon/{index,Menu}.*`、`Calender/old/`、`Date.tsx` を削除
- 影響範囲: DateCard.tsx の AddMealIcon インポートは残す

### フェーズ2: タイポ修正（範囲は要確認）
- 選択肢によって変更ファイル数が大きく変わる

## 設計選択と理由

### 削除の順序
`Calender/old/` を先に消すことで、`MealIcon/index.tsx` 等の参照が切れる →
その後 `MealIcon/old/` と `MealIcon/{index,Menu}.*` を安全に削除できる。

### タイポ修正は一括 vs 段階的
一括で直すのが最も整合性が高い。42ファイルだが、多くはファイル/ディレクトリ名と
変数名のリネームなので、一度やりきれば後は残らない。

## 代替案

### 代替案: タイポは変数名のみ修正、ディレクトリ名はそのまま
ディレクトリ名変更は git の追跡に問題が出ることがある（特に大文字小文字）が、
`calender` → `calendar` は文字数が違うのでシンプルなリネームで対応可能。
ディレクトリリネームを省くと残り続ける技術的負債になるので棄却。

## リスクと対策

| リスク | 対策 |
|--------|------|
| ディレクトリリネームで import パスが壊れる | リネーム後に tsc --noEmit で型チェック + yarn test |
| 旧 `/calender/` URLへのブックマークが壊れる | 旧URLからリダイレクトを設置 |
| テスト内の文字列が `/calender/` を参照している | grep で確認してから削除 |

## テスト方針
- 削除後に `docker compose exec frontend yarn test`
- タイポ修正後に `docker compose exec frontend yarn test` + `yarn lint`
- UI変更なし → スクリーンショット確認は任意
