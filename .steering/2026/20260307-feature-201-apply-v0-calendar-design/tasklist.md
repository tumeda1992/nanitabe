# タスクリスト: v0 カレンダーデザイン移行

## 概要

このタスクリストは「でかすぎるタスクを1段階細かい粒度に落とした」大ブロック一覧。
各フェーズは独立して別途 tasklist を作り実装する。
各フェーズ完了時点でアプリが正常動作する状態を保つこと。

---

## 🚨 タスク完全完了の原則

**このファイルの全フェーズが完了するまで作業を継続すること**

- 各フェーズは独立した実装単位。完了後に次フェーズへ進む。
- 各フェーズ完了時に全テストがグリーンであること（`docker compose exec frontend yarn test`）
- 各フェーズ完了時に ESLint エラーがゼロであること（`docker compose exec frontend yarn lint`）

---

## フェーズ1: 技術基盤整備（Tailwind + shadcn/ui 導入）

### DoD（完了条件）
- Tailwind CSS のユーティリティクラスが Next.js フロント上で動作する
- 必要な shadcn/ui コンポーネントが使える
- 既存の Bootstrap/SCSS 画面が壊れていない
- 既存テストが全てグリーン

### タスク

- [ ] Tailwind CSS を Next.js フロントエンドに追加
    - `tailwind.config.ts` + `postcss.config.mjs` の設定
    - 既存 Bootstrap/SCSS との共存：`preflight` を無効化して CSS リセット競合を防ぐ
    - `globals.css`（または既存の CSS エントリポイント）に Tailwind ディレクティブを追加

- [ ] shadcn/ui に必要なパッケージを追加
    - lucide-react
    - clsx, tailwind-merge（`cn` ユーティリティ用）
    - @radix-ui/react-dropdown-menu（DropdownMenu 用）
    - @radix-ui/react-slot（Button/asChild 用）
    - vaul（Drawer 用）
    - class-variance-authority

- [ ] shadcn/ui コンポーネントを `frontend/src/components/ui/` に追加
    - Button
    - DropdownMenu
    - Drawer（後フェーズで使用。先行追加しておく）

- [ ] 既存画面の動作確認・テスト実行

---

## フェーズ2: アプリシェル・ヘッダーの刷新

### DoD（完了条件）
- 新ヘッダーが表示される（前後ナビ・今週/今月・週月切替・ドロップダウンメニュー）
- 週/月ビューがタブで切替可能
- カレンダーの中身（コンテンツ部分）は既存の WeekCalender/MonthCalender をそのまま内包しており正常動作する
- 既存テストが全てグリーン

### タスク

- [ ] `/calender/week` と `/calender/month` を統合した単一ページに変更
    - `/calender` ルートに新しい統合ページを作る（または既存ルートを統合画面にリダイレクト）
    - 週/月タブの状態を URL パラメータ or ステートで管理

- [ ] 新ヘッダーコンポーネントの実装（`calenderComponents/CalenderHeader/` など）
    - 前後ナビボタン（ChevronLeft/Right アイコン）
    - 今週/今月ボタン
    - 週月切替ボタン（週: CalendarRange、月: CalendarDays）
    - ドロップダウンメニュー（料理一覧リンクのみ。料理検索はスコープ外）
    - 期間ラベル表示（週: 「XX年X月X日〜X日」、月: 「XX年X月」）

- [ ] 新ヘッダーの配下に既存 WeekCalender/MonthCalender を接続

- [ ] 既存画面の動作確認・テスト実行

---

## フェーズ3: カレンダービュー刷新（DayColumn カード形式）

### DoD（完了条件）
- 週ビュー・月ビューともに各日付がカード形式（rounded-xl border）で縦に並ぶ
- 今日の日付にハイライト（ring-2 ring-primary/40）が付く
- 土曜=青・日曜=赤の色分けが適用される
- 各日付カードに料理名が表示される（料理カード自体は次フェーズで刷新）
- GraphQL データが正しく表示される
- 既存テストが全てグリーン

### タスク

- [ ] `Calender/index.tsx`（table 形式）を `Calender/old/` に移動し、インポートパスを修正して動作維持

- [ ] 新しい `Calender/index.tsx` を DayColumn カード形式で実装
    - table → `flex flex-col gap-1.5` の縦リストに変更
    - 各日付を `rounded-xl border bg-card px-2.5 py-1.5` のカードで表示
    - 日付ヘッダー: 日番号（丸囲み）+ 曜日ラベル + 追加ボタン（+）
    - 料理一覧エリア: 既存の MealIcon コンポーネントを暫定で流用（次フェーズで DishCard に置換）
    - 空日付: 点線ボーダーの「追加」ボタン
    - 今日ハイライト・土曜青・日曜赤 の色分け

- [ ] "calender" スペルミスを "calendar" に修正
    - 新規作成するコンポーネント・ディレクトリ名は "calendar" 正綴で作る
    - 既存の old/ に移動したコンポーネントはスペルミスのまま残してよい（参照が切れないように）
    - ルーティングパス（`/calender/week`, `/calender/month`）も `/calendar/...` に変更
    - `features/calender/` ディレクトリも `features/calendar/` にリネーム
    - import パスを一括置換し、テスト・ESLint でエラーがないことを確認

- [ ] 週・月ビュー（WeekCalender/MonthCalender）が新 Calender を正しく使えるよう接続確認

- [ ] 既存画面の動作確認・テスト実行

---

## フェーズ4: 料理カードの刷新（DishCard）

### DoD（完了条件）
- 料理が左カラーバー付きカード（昼=lunch色、夜=dinner色）で表示される
- MoreHorizontal ボタンでアクションパネルが展開する
- 既存の全操作（削除・移動・交換・料理割当・評価表示）が動作する
- 未実装機能（料理複製・料理検索）は disabled で表示
- 既存テストが全てグリーン、ESLint エラーゼロ

### タスク

- [ ] `MealIcon/index.tsx` と `MealIcon/Menu.tsx` を `MealIcon/old/` に移動し、インポートパスを修正して動作維持
    - `MealIcon/Menu.spec.tsx` も old/ に移動してテスト継続

- [ ] 新しい DishCard コンポーネントを実装（`calenderComponents/DishCard/` など）
    - 左カラーバー（昼: lunch色、夜: dinner色）
    - 1行目: カテゴリアイコン + 料理名 + 昼夜ラベル + クイックアイコン（UtensilsCrossed / Star / MoreHorizontal）
    - 2行目: 評価（dish.evaluationScore）+ レシピ元（dishSourceRelation）
    - 3行目: コメント（meal.comment + dish.comment）
    - MoreHorizontal タップでアクションパネル展開:
        - 食事編集（UtensilsCrossed）
        - 評価（Star）→ 既存 evaluationScore を表示
        - 料理編集（Pencil）
        - 名前コピー（Type）
        - 他の日へ移動（CalendarArrowUp）→ 既存 MoveMeal フロー
        - 日付交換（ArrowLeftRight）→ 既存 SwapMeals フロー
        - 料理複製（CopyPlus）→ disabled（未実装）
        - 削除（Trash2）→ 既存 removeMeal mutation

- [ ] DayColumn の料理一覧に DishCard を接続（MealIcon の代替として）

- [ ] + ボタンから既存の AddMeal / AssignDish フローを起動するよう接続

- [ ] 新コンポーネントにユニットテストを追加（最低限：表示確認・アクションパネル開閉）

- [ ] 品質チェック
    - `docker compose exec frontend yarn test`（全テストグリーン）
    - `docker compose exec frontend yarn lint`（プロジェクト全体）

---

## 実装後の振り返り

### 実装完了日
{YYYY-MM-DD}

### 計画と実績の差分

**計画と異なった点**:
-

**新たに必要になったタスク**:
-

**技術的理由でスキップしたタスク**（該当する場合のみ）:
-
