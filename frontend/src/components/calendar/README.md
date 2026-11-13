# components/calendar

## 概要
カレンダー画面の表示・操作に関するコンポーネント群。
週ビュー（WeekCalendar）と月ビュー（MonthCalendar）の両方を含む。

非責務: GraphQL クエリの定義・実行（features/meal/ が担う）

## クイックマップ

- 入口: `WeekCalendar/index.tsx`・`MonthCalendar/index.tsx`
- 共有レイアウト: `calendarComponents/Calendar/index.tsx`
  - **WeekCalendar と MonthCalendar は両方ともこのコンポーネントを使う。
    Calendar を変更すると週・月ビュー両方に影響する。**
- 操作モード管理: `calendarComponents/useCalendarMode.ts`
- 食事カード: `calendarComponents/MealCard/index.tsx`
- 食事追加: `calendarComponents/MealIcon/AddMealIcon.tsx`
- ページナビ用パス定義: `app/calendar/week/[date]/consts.ts`・`app/calendar/month/[date]/consts.ts`
  - `weekCalendarPagePathOf` / `monthCalendarPagePathOf` / `isMonthPath` はここに定義

grep キーワード: `calendar`。GraphQL の `mealsForCalender` 等と、転送だけを行う `app/calender/` には旧綴りが残る。

## 不変条件・契約

- MUST: ディレクトリ名・コンポーネント名は "calendar" で書く。
- MUST: データは `useMeal`（features/meal/）から取得した `mealsForCalender` を
  `dateMealsList` 形式に変換して `Calendar` に渡す。直接 GraphQL を呼ばない。
- MUST: `onDataChanged`（実体は `useRefreshCalendarData.tsx` の `refreshData`）は
  `apolloClient.clearStore()` を含む**全キャッシュ消去**であり、非同期である。
  この callback と並行して別の `refetch` を走らせない。
    - 並走させると in flight の query が store reset と衝突し、
      `Invariant Violation: Store reset while query was in flight` になる
    - 同じ `onCompleted` 内で他の query も更新したい場合は、
      `await onDataChanged()` を先に完了させてから `refetch` する
    - やってしまいがちな失敗: `onDataChanged` という名前から「変更を通知する軽い callback」と読み、
      中身を確認せずに他の非同期処理と並べる

## 画面の意図

表示を変える前に読む。コードからは読み取れない、見え方の理由を置く。

原則: 使う場面で必要な情報と操作の入口は、別の操作なしで見えている。全ての操作を出すという意味ではない。

| 場面 | 見えていること | 理由 |
| --- | --- | --- |
| 週ビューで、今週や数週分の献立を組む | 土曜から金曜までの全日と、各日の食事追加 | 土曜にまとめて買い物へ行くため、週は買い物の単位である。一日に副菜など二つ以上入れることがある |
| 買い出しの材料を列挙する | 料理名、レシピ元、本ならページ | そのレシピを開くため。ページが分かれば目次から探さなくてよい |
| 料理を作る | 料理名、レシピ元、本ならページ、コメント | 開きたいページを知るため。コメントは次に作る時のために残している |
| 毎日見る | 今日のクローズアップ、その週のイベント | 食事はイベントに引きずられる |
| 今日食べたものを評価する | 今日の食事の評価を始める、ワンタップの入口 | 評価はたいてい今日食べたものについて起こる |
| 月全体を眺める | 一覧性（月ビュー） | 月で表示するほうが便利な時に使う |

- MUST: 週ビューの先頭は土曜に固定し（`START_FROM_SAT`）、今日から始まる並びにしない。一番上に土日があることで、複数週を考える時も位置から土日が分かる。見るたびに見えるものも変わらない。
- MUST: レシピ元は料理の一部として扱い、操作の先へ隠さない。同じ料理名でも、どの料理かはレシピ元で決まる。
- MUST: 操作欄があることを、初見でも分かる印で示す。機能をハンバーガーメニューへ並べる形には戻さない。押しにくく、数が増えた時に破綻するためである。
- SHOULD: 開いた時に今日まで自動でスクロールしない。数週分を続けて決める時に、今週だけ動きが変わるとノイズになるためである。週の後半に今日まで届かないことが多くなったら見直す。
- SHOULD: 今日以外の日は評価の点数だけを見せ、評価は操作欄から行う。全ての行に評価のボタンを置くと、料理名の幅が減るためである。
- SHOULD: 時間帯は文字と色で一目で分かるようにし、色だけに頼らない。行の背景色は付けない。橙と青は、おひさまと夜の連想の程度である。
- SHOULD: 月ビューは週ビューと表示を共有し、専用の表示を作らない。こだわりのない所へ保守の手間をかけないためである。月ビューへの具体的な要望が出たら見直す。
- イベントは本来、食事と別の表し方にしたい。料理ではない予定を食事として登録しているのは、その代わりである。

やってしまいがちな失敗:

- すっきりさせるために、レシピ元やコメントをタップの先へ移す。買い出しや調理のたびに操作が要り、コメントには作った後で気づくことになる。
- 今日を目立たせるために、今日から始まる一覧にする。買い物の単位と切れ目がずれ、見るたびに見えるものが変わる。
- 行を押せば開けるからと「…」を消す。初見では操作欄があることに気づけない。

## 部品の呼び名

画面について話す時と、キャンバスで画面を考える時に、次の語を使う。

| 呼び名 | 役割 | コード |
| --- | --- | --- |
| 日の行 | 一日分。左に日番号と曜日、中央に食事の行と枠の行、右に「+」。今日は「今日」の見出しが付く | `DateCard` |
| 食事の行 | 昼夜の印、区分アイコン、料理名、点数、レシピ元、コメント、「…」 | `MealCard` |
| 今日の食事の行 | 食事の行の料理名を大きくし、点数の代わりに「評価する」を出したもの | `MealCard` の `isToday` |
| 枠の行 | 料理が未定の枠。右端は削除。押すと食事を登録できる。移動などの操作中は削除を出さない | `FrameCard` |
| 昼夜の印 | 「昼」「夜」「朝」の文字を色付きの地に載せたもの。食事の行と枠の行で同じ色を使う | `MealCard`、`FrameCard` |
| 区分アイコン | 主食、主菜、副菜などを示す小さなアイコン | `CategoryIcon` |
| 「+」 | その日へ食事を追加する入口。常に出す | `AddMealIcon` |
| 「…」 | 操作欄を開く入口 | `MealCard` |
| 操作欄 | 食事編集、評価、料理編集、名前コピー、他の日へ、日付交換、食事複製、枠解除、延期、削除 | `MealCard` |
| 未定 | 食事も枠もない日の表示 | `DateCard` |

## 変更ガイド

- 操作モード（食事追加・移動・交換）を変更するなら `useCalendarMode.ts` を確認する。
  操作中は `requireDisplayingBottomBar=true` になり、操作 UI が画面下部固定バーに表示される。
- 料理カードに新しいアクション操作を追加するとき、操作の「起動レベル」で渡し方が変わる:
    - 食事（Meal）レベルの操作（例: 移動）:
        `useCalendarMode.ts` の `calendarModeChangers` に追加し、
        Calendar → DateCard → MealCard と props で伝搬させる
    - 日付（Date）レベルの操作（例: 日付交換）:
        DateCard の props として個別に追加し、MealCard に渡す
        MUST: calendarModeChangers に混ぜない（DateCard が担う操作のため）
- カレンダー上で「操作モード」を実現するとき、UIの選択方針:
    - SHOULD: 継続的な操作（移動先選択・交換対象選択など）は底部固定バー（BottomBar）を使う
        - ページ遷移は使わない（カレンダーを見ながら操作する必要があるため）
        - ドロワーも使わない（操作中に複数日付を選択する必要があるため）
    - SHOULD: 単発の入力（食事追加・編集）は `useFullScreenModal` を使う
    - 実装: `useCalendarMode.ts` でモードを管理し、`requireDisplayingBottomBar=true` のとき
      Calendar/index.tsx の底部に操作UIを固定表示する
- MonthCalendar の日付処理に `T09:00:00` の +9時間オフセットがある（暫定）。
  Rails に日付が前日として送られる問題の回避策。日付処理を変更する場合は注意。
- ナビゲーション実装時は `pushHistory` と `<Link>` を使い分ける:
  - MUST: 同じ物理ルート内の日付移動（前週/次週）は `LogicalHistory.pushHistory` を使う
  - MUST: 週ビュー↔月ビューの切替は Next.js `<Link>` を使う。
    `pushHistory` は `window.history.pushState` ベースのため物理ルート変更ができず、コンポーネントが切り替わらない。
