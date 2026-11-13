# Tasklist: 週カレンダーの見直しの適用と Design System の写し直し

設計の正本は同じ directory の [`design.md`](./design.md) である。
見た目の正本は、キャンバス「このリポジトリで Claude Design を試す」の「確定案」page である。

## 全 phase に共通する注意

- テストを先に書き、`docker compose exec frontend yarn test` で実行する。host では実行しない。
- `visual-inspector` の確認でデータを変える操作をしない。開発 DB を共有しているためである。
- 実データの料理名を、この tasklist と記録へ書かない。
- `yarn build` を `docker compose exec frontend` から実行しない。Tailwind の watcher と競合する（`frontend/docs/ai_guideline/development_standard/docker.local.md`）。
- 新しい Tailwind の class は watcher が `tailwind-output.css` へ反映するまで効かない。反映に十数分かかることがある。画面へ反映されない時は変更直後の一度の観測で判断せず、それでも反映されなければ `docker compose restart frontend` を行う。
- `base.css` が `div`、`span`、`p` へ `color: #333` を当てている。文字色は親から継承せず、対象の要素自身へ指定する。

## Phase 1: 週ビューを開くと、各日が枠のない行で並ぶ

### DoD（完了条件）

- 週ビューを開くと、土曜を先頭に7日が枠線のない行で並び、日の間は薄い線で区切られている。
- 全ての日の右端に「+」があり、押すと既存の食事登録モーダルが開く。
- 土曜と日曜は、日番号と曜日の両方に色が付いている。
- 今日は日番号が塗りつぶされ、行の背景が薄く、`今日` の見出しがある。
- 食事も枠もない日は `未定` と出て、点線の「+」がない。
- 移動、交換、割当の操作中は「+」が出ない。

### Tasks

- [x] `DateCard` を行の形にする
  - [x] `DateCard.spec.tsx` を先に変更する
  - [x] `DateCard.tsx` を変更する
  - [x] testのgreen確認
- [x] `Calendar` の日の一覧の余白をなくす
  - [x] `Calendar/index.tsx` を変更する
  - [x] `Calendar/index.spec.tsx` のgreen確認
- [x] 「+」を新しい形にする
  - [x] `AddMealIcon.spec.tsx` のgreen確認を変更前に行う
  - [x] `AddMealIcon.tsx` を変更し、`AddMealIcon.module.scss` を消す
  - [x] testのgreen確認
- [x] `visual-inspector` で 390×844 の週ビューを確認する
  > 確認日時: 2026-11-07 23:00
  > 総合結果: ✅ 項目1・月ビューの「未定」とも期待どおり（保存・削除等はしていない）
  > ログ: frontend/inspect/visual/tmp/20261107-week-calendar-after/result.md（measurements.json 同階層）
  >
  > 項目1: 土曜先頭・枠線なし・薄い区切り ✅
  >   期待値: 土曜が先頭、border-top 0、日の間は薄い線
  >   結果: 先頭は土曜、border-top 0px、区切りは border-bottom 1px rgb(228,228,231)
  > 項目2: 全日「+」・点線なし ✅
  >   結果: 7日全てに 44x52（中 32px、背景 rgb(244,244,245)）。点線要素 0、dateCard-emptyMealArea 0
  > 項目3: 土日の色 ✅
  >   結果: 日曜の日番号と曜日が赤（lab(48 77 61)）、土曜の曜日が青（lab(44 29 -86)）。今日が土曜のため土曜の日番号は塗りになる（設計どおり）
  > 項目4: 今日の表現 ✅
  >   結果: 日番号 26px の塗り（背景 rgb(24,24,27)）、行の背景は薄グレー（alpha 0.5）、「今日」見出しあり
  > 項目5: 未定 ⚠️ 週では観測できず
  >   結果: 今週は食事も枠もない日がない。月ビューで 14 日が「未定」表示。週での表示は DateCard.spec.tsx の dateCard-undecided の検証が担保
  > 項目6: 操作中の「+」 ✅
  >   結果: 移動モード中に「+」が 0 個、×で戻すと 7 個に復帰（Phase 6 の記録も参照）

### 各task詳細

#### `DateCard` を行の形にする

対象は `frontend/src/components/calendar/calendarComponents/DateCard.tsx` と `DateCard.spec.tsx` である。
class の値は `design.md` の「部品ごとの変更」のとおりとする。

spec の変更は次のとおりである。

- `dateCard-emptyMealArea` を使う4件（表示、非表示、モーダルを開く、3タブが出る）を消す。モーダルと3タブの確認は `AddMealIcon.spec.tsx` が持つ。
- 食事も枠もない時に `dateCard-undecided` が出ること、食事がある時と枠がある時は出ないことを足す。
- 土曜の class を `text-blue-600`、日曜を `text-red-600` へ変える。
- 今日に `dateCard-todayLabel` が出ること、今日でない日は出ないことを足す。

#### 「+」を新しい形にする

対象は `MealIcon/AddMealIcon.tsx` である。
`FullScreenModalOpener` と `addMealIconOpener` は保つ。
外側を 44×52px、中を `size-8 rounded-lg bg-muted` とし、`lucide-react` の `Plus` を置く。

## Phase 2: 料理を見ると、操作なしでレシピ元とコメントが読める

### DoD（完了条件）

- 今日以外の日の料理に、枠線、背景色、左のカラーバーがない。
- 昼夜の印が文字と色で出て、区分アイコンと料理名が続く。
- レシピ元とページ、料理コメント、食事コメントが省略されずに出る。
- 評価済みの料理は、料理名の右に点数が出る。今日以外の日に評価のボタンはない。
- 「…」は 44px で、押すと操作欄が開閉する。行全体を押すと開く。常時表示の食事編集のアイコンはない。
- 操作中は「…」が出ない。

### Tasks

- [x] `MealCard` の行を変更する
  - [x] `MealCard/index.spec.tsx` を先に変更する
  - [x] `MealCard/index.tsx` を変更する
  - [x] testのgreen確認
- [x] `visual-inspector` で 390×844 の週ビューと、操作欄を開いた状態を確認する
  > 確認日時: 2026-11-07 23:00
  > 総合結果: ✅ 再確認で解消（初回はレシピ元の色が異常）
  > ログ: frontend/inspect/visual/tmp/20261107-week-calendar-after/result.md
  >
  > 項目1: 昼夜の印・枠線・背景・バー ✅（夜のみ観測）
  >   結果: 印 22x22、夜は背景 oklab(0.54 -0.03 -0.21 / 0.15)・文字 rgb(13,53,140)。border 0px、背景透明、左バーなし、常時の食事編集アイコンなし
  >   昼と朝の印は今週に個体がなく観測できず。mealConfig の class は MealCard/index.spec.tsx の昼夜の検証（昼 text-lunch-foreground、夜 text-dinner-foreground）が担保。朝は未検証
  > 項目2: 点数・評価ボタン ✅
  >   結果: 料理名の右に ★ と数値（黄）。今日以外に評価のボタンなし（今日の1個のみ）
  > 項目3: レシピ元 ✅（修正後に再確認）
  >   期待値: 省略されず折り返し、P ページが続き、色は確定案の #3f3f46
  >   結果: 計算色 rgb(113,113,122)（確定案と違う）。省略なしは月ビューで確認（P付き 3 件、最長 31 文字で 2 行折り返し）。週では P付きを観測できず
  >   対応: mealCard-source を text-zinc-700 へ変更し、MealCard/index.spec.tsx に class の検証を足した
  >   再確認(2026-11-07 23:05、frontend/inspect/visual/tmp/20261107-week-calendar-after-fix/result.md): 計算値は lab(26.8 1.35 -4.68) と返り、canvas で rgb へ変換すると [63,63,70] で一致。P ページ付き 3 件、なし個体とも同値
  > 項目4: コメント ⚠️
  >   結果: 週では 0 件。月で料理コメント 1 件（12px、省略なし、rgb(113,113,122)）。食事コメントは観測できず
  >   対応: 食事コメントの text-muted-foreground/70 を text-muted-foreground へ変更し、spec に検証を足した
  >   再確認: 月ビューの 1 件は rgb(113,113,122) で薄くないが、料理コメントか食事コメントか計測が区別しておらず、食事コメントの個体としては観測できず。MealCard/index.spec.tsx の class の検証が担保
  > 項目5: 操作欄の開閉 ✅
  >   結果: 「…」で開く→「…」で閉じる→行を押して開く→「…」で閉じる、すべて期待どおり。展開した 9 個の操作ボタンは各 68x46。操作は押していない
  > 項目6: 区分アイコンの色（不具合として扱わない）
  >   結果: svg は rgb(51,51,51)（14px）で区分色が出ない。design.md の非目標（区分ごとの色は今回活かさない）に当たり、base.css も変えない。結果にある 20px の stroke の個体は「…」やゴミ箱のアイコンを数えたものと読む

### 各task詳細

#### `MealCard` の行を変更する

class の値は `design.md` の「部品ごとの変更」のとおりとする。
`data-testid` と「その他のアクション」のラベルは保つ。

spec の変更は次のとおりである。

- `bg-lunch-bg`、`bg-dinner-bg` の検証を、昼夜の印の文字と `text-lunch-foreground`、`text-dinner-foreground` の検証へ置き換える。背景の class が root にないことも確かめる。
- 11文字以上のレシピ元が切り詰められず、`P{page}` が続くことを足す。
- `line-clamp-2` と `italic` がないことを足す。
- 今日以外の日に `評価` のラベルのボタンがないことを足す。
- 既存の「評価モーダルの★タップ」の検証は Phase 3 で扱う。このphaseでは `isToday` を渡して通す。

## Phase 3: 今日の料理は大きく出て、評価をワンタップで始められる

### DoD（完了条件）

- 今日の料理名が 20px の太字で出る。
- 未評価の今日の料理に「評価する」が出て、押すと既存の評価モーダルが開く。
- 評価済みの今日の料理は「★{score} 評価を変更」と出る。
- 押しても行の操作欄は開かない。
- 操作中は評価のボタンが出ない。

### Tasks

- [x] `DateCard` から `MealCard` へ `isToday` を渡す
  - [x] `DateCard.spec.tsx` へ受渡しの検証を足す
  - [x] `DateCard.tsx` を変更する
- [x] `MealCard` の今日の形を足す
  - [x] `MealCard/index.spec.tsx` を先に変更する
  - [x] `MealCard/index.tsx` を変更する
  - [x] testのgreen確認
- [x] `visual-inspector` で今日の行を確認する
  > 確認日時: 2026-11-07 23:00
  > 総合結果: ✅ 未評価の今日の行は期待どおり。評価済み表示のみ観測できず
  > ログ: frontend/inspect/visual/tmp/20261107-week-calendar-after/result.md
  >
  > 項目1: 料理名と評価ボタン ✅
  >   結果: 料理名 20px / 700。「評価する」80x44
  > 項目2: 押下の挙動 ✅
  >   結果: 押すと「食事評価」モーダルが開き、操作欄は開かない（actionsOpen=false）。登録せず × で閉じ、閉じた後も操作欄は閉じたまま
  > 項目3: 「★n 評価を変更」⚠️ 観測できず
  >   結果: 今日の料理が未評価のため。MealCard/index.spec.tsx の「★4 評価を変更」の検証が担保（データを変える操作はしない方針のため実機では未確認）

### 各task詳細

#### `MealCard` の今日の形を足す

`aria-label="評価"` を保つ。
spec は、`isToday` が真の時の表示の文字、評価モーダルが開くこと、押しても `削除` が出ないこと、`canAnythingExceptDisplayDishName=false` の時に出ないことを足す。
既存の「評価モーダルの★タップ」の3件は `isToday` を渡す形へ変える。

## Phase 4: 枠の行が食事の行と同じ形で並ぶ

### DoD（完了条件）

- 枠の行に枠線、背景色、左のカラーバーがなく、昼夜の印と `枠` の表示、枠名が並ぶ。
- 右端のゴミ箱は 44px で、押すと既存の確認の後に削除される。
- 行を押すと既存の登録モーダルが開く。
- 操作中はゴミ箱が出ない。

### Tasks

- [x] `FrameCard` を変更する
  - [x] `FrameCard/index.spec.tsx` を先に変更または追加する
  - [x] `FrameCard/index.tsx` を変更する
  - [x] testのgreen確認
- [x] `visual-inspector` で枠の行を確認する。実データに枠の行がない週は、他の週を見る。削除は押さない
  > 確認日時: 2026-11-07 23:00
  > 総合結果: ✅ 全項目正常（今週に枠 1 件。削除は押していない）
  > ログ: frontend/inspect/visual/tmp/20261107-week-calendar-after/result.md
  >
  > 項目1: 見た目 ✅
  >   結果: 枠線・背景・左バーなし。印 22x22（夜、背景 rgb(244,244,245)）、「枠」は紫（lab(41 69 -92)）、枠名 rgb(113,113,122)
  > 項目2: ゴミ箱 ✅
  >   結果: 44x44（svg 20px）。押していない。確認の後に削除されることは FrameCard の既存 spec が担保
  > 項目3: 行を押す ✅
  >   結果: 「食事登録」モーダルが開き、保存せず × で閉じた
  > 項目4: 操作中のゴミ箱 ✅
  >   結果: 移動モード中に枠の削除が 0 個、×で戻すと 1 個に復帰

### 各task詳細

#### `FrameCard` を変更する

操作中の判定のため、`DateCard` から `isDisplayCalendarMode` を新しい prop `canDelete` として渡す。省略時は `true` とする。
現状の `FrameCard` は操作中も削除のボタンを出しているため、これは挙動の変更である。
spec は `canDelete={false}` の時にボタンが出ないことを足す。

## Phase 5: ヘッダーのボタンが押しやすく、青と下線がない

### DoD（完了条件）

- 前後、今週（今月）、週間、月間、メニューのボタンが 44px である。
- 「今週」と月間のアイコンに青と下線がない。
- 週ビューと月ビューの切替は既存のとおり動く。

### Tasks

- [x] `CalendarHeader` を変更する
  - [x] `CalendarHeader/index.spec.tsx` を変更前にgreen確認する
  - [x] `CalendarHeader/index.tsx` を変更する
  - [x] testのgreen確認
- [x] `visual-inspector` でヘッダーの上部を確認する
  > 確認日時: 2026-11-07 23:00
  > 総合結果: ✅ 再確認で解消（初回は「今週」「今月」の幅が 40px）
  > ログ: frontend/inspect/visual/tmp/20261107-week-calendar-after/result.md
  >
  > 項目1: ボタンの寸法 ✅（修正後に再確認）
  >   期待値: 全て 44px
  >   結果: 前後・週間・月間・メニューは 44x44。「今週」「今月」は 40x44
  >   対応: 該当ボタンへ min-w-11 を足した（class のみの変更。既存の CalendarHeader の spec が green）
  >   再確認(2026-11-07 23:05、frontend/inspect/visual/tmp/20261107-week-calendar-after-fix/result.md): 週ビューの「今週」60x44、月ビューの「今月」60x44。前後・週間・月間・メニューは全て 44x44
  > 項目2: 青と下線 ✅
  >   結果: 「今週」の色 rgb(9,9,11)、下線なし。月間アイコンも青なし・下線なし。現在のビューは secondary の背景で示される
  > 項目3: 週と月の切替 ✅
  >   結果: 週→月→週が動作（/calendar/week/2026-11-01 と /calendar/month/2026-10-31 へ遷移）

### 各task詳細

#### `CalendarHeader` を変更する

ボタンを `size-11`、「今週」を `h-11` とし、リンクへ `text-foreground no-underline` を足す。
見た目の class の変更であり、spec の新しい検証は足さない。既存のラベルとリンク先の検証を担保とする。

## Phase 6: 品質checkと修正

### DoD（完了条件）

- 全testがgreen
- `docker compose exec frontend yarn lint` にerrorがない
- `visual-inspector` で週ビュー、月ビュー、操作欄を開いた状態、移動の操作中を実測し、`design.md` の受け入れ基準を満たす

### Tasks

- [x] 全test実行
  - [x] `docker compose exec frontend yarn test` がすべてgreenであることを確認する
- [x] lint実行
  - [x] `docker compose exec frontend yarn lint` を実行する
  - [x] errorがあれば修正して再実行する
  - [x] error zeroを確認する
- [x] 最終screenshotで見た目を確認する
  > 確認日時: 2026-11-07 23:00（初回）、23:05（3点の修正後の再確認）
  > 総合結果: ✅ 全項目正常（食事コメントの個体のみ観測できず）
  > ログ: frontend/inspect/visual/tmp/20261107-week-calendar-after/result.md、frontend/inspect/visual/tmp/20261107-week-calendar-after-fix/result.md
  > 再確認の全体: 週 body 674px、月 document 2807px（初回と同じ）。横スクロールなし、はみ出し 0。日の区切りは全行 border-bottom 1px rgb(228,228,231)・border-top 0、食事・枠の枠線 0px、点線 0。操作欄の開閉・評価モーダル・「+」モーダル・枠モーダル・移動の操作中は初回と同じ挙動
  > 未解決だが不具合として扱わないもの: 区分アイコン svg の色が区分色にならない（design.md の非目標）
  - [x] 週ビュー、月ビュー、操作欄を開いた状態を撮る（01, 02, 03, 04, 15, 16.png）。修正後の撮り直しは再確認で行う
  - [x] 移動の操作中は、モードへ入った後に日付を押さず、×で戻す
    > 結果: 「+」「…」「評価する」「枠の削除」が全て 0 個。底部バー（高さ 45px）が出る。×（.fa-xmark）で戻すと「+」7、「…」8、「評価する」1、枠削除 1 が復帰。底部バーの左端が Next.js 開発用インジケータに隠れるのは開発環境の表示で、不具合として扱わない
  - [x] 押せる範囲の実寸、枠線の色、レシピ元の文字色を実測する
    > 実寸: 「…」44x44、「+」外側 44x52（中 32x32）、「評価する」80x44、ゴミ箱 44x44、前後・週間・月間・メニュー 44x44、「今週」「今月」は 40x44 だったが、修正後の再確認で 60x44。展開した操作ボタンは各 68x46
    > 枠線: 食事・枠・日の行いずれも 0px。日の区切りは 1px rgb(228,228,231)
    > レシピ元の文字色: rgb(113,113,122) で確定案の #3f3f46 と違った。text-zinc-700 へ修正し、再確認で rgb(63,63,70)（= #3f3f46）に一致
  - [x] `frontend/inspect/visual/tmp/20261107-week-calendar-baseline/` の現状と比べる
    > 週の全高: document 989px → body 674px（-315px。document は viewport 下限 844）。月: 4320px → 2807px（-1513px）
    > 枠線: rgb(51,51,51) 1px → なし。食事の高さ: 42px（補助行ありで 60px）→ 44px（レシピ元ありで約 49px）
    > 「…」: 28x28 → 44x44。「+」: 34.5x36 → 44x52。レシピ元の色: rgb(51,51,51) → rgb(113,113,122) → 修正後 rgb(63,63,70)
    > 今日: ring 2px で数字に塗りなし → 数字の塗り・行の薄い背景・「今日」見出し。ヘッダー: 未計測 → 44px（今週・今月のみ幅 40px、修正後は 60x44）
  - [x] 確定案のボードとの差を記録する
    > 差1: 「今週」「今月」の幅が 40px だった。min-w-11 で修正（再確認で 60x44）
    > 差2: レシピ元の色が rgb(113,113,122) で、確定案の #3f3f46 と違った。text-zinc-700 で修正（再確認で rgb(63,63,70)）
    > 差3: 食事コメントが /70 の薄さだった。確定案に合わせ text-muted-foreground へ修正（実機では食事コメントの個体を観測できず、spec が担保）
    > 差4: 区分アイコンに区分色が出ない。ボードでは付いて見えるが、非目標（区分ごとの色は今回活かさない）に当たるためそのまま
    > 親が画面とコードで見つけた差6点（検査の報告にはなかった）。修正済み。実機の再確認は親が visual-inspector で行う（未実施）
    > 差5: ヘッダーの期間ラベルが切れる（週「11/7 -…」、月「2026…」）。原因は外側の余白と、`<a>` が content-box で `min-w-11` に `px-2` が足され 60px になること。外側を `px-1.5 py-1`、「今週」「今月」を `box-border min-w-11 px-1` に修正（class のみ。spec は既存 green）
    > 差6: 「評価する」が灰色の面で星なし。`border border-border bg-background` にし、未評価は線の `Star`（size-4）と「評価する」、評価済みは文字のみ。MealCard の spec で検証
    > 差7: 枠の行の昼夜の印が灰色。`mealType` に応じた `bg-*/15` と `text-*-foreground` へ。FrameCard の spec で昼・夜を検証
    > 差8: 料理名の行の配置。行を `items-start`、料理名を `min-w-0 flex-1 break-words`、区分アイコンは 1 行目に揃え（`mt-0.5`）、点数は右端。長い文字列で「…」と重ならないようにした
    > 差9: 点数の色 `text-amber-500` は白地でコントラスト不足。Design System の rating-text に合わせ `text-amber-700`。spec で検証
    > 差10: 操作欄が上線だけで面がない。`mb-2 rounded-lg bg-muted p-1` にし `border-t` を廃止。`ActionBtn` の通常色を `text-zinc-700`（削除の赤は据え置き）。spec で検証
    > 修正後の確認: `docker compose exec frontend yarn test` は 46 suites・301 tests が green、`yarn lint` は error なし
    > 差5〜10 の再確認（2026-11-07 23:11、frontend/inspect/visual/tmp/20261107-week-calendar-after-fix2/result.md）: 「評価する」、操作欄、枠の夜の印、点数の交差なし、全体の崩れなし（週 body 666px、月 799px 差 -8、横スクロールなし、移動の操作中の復帰）は正常。以下の異常が出た
    > 差11: 週ビューの期間ラベルが切れる。「11/7 - 11/13」は 99px 必要で幅は 90px（月の「2026年11月」は 88px で切れない）。最長は「11/14 - 11/20」でさらに 1 字長い。ヘッダーの外側の `gap-2` と左右のボタン群の `gap-0.5` を外し、幅を 378 - 264 = 114px にした。`truncate` は 390px より狭い端末の逃げ道として残す。class のみの変更で spec は既存 green（修正済み。再確認で解消: 390px で「11/7 - 11/13」99/99、「11/14 - 11/20」109/109、月「2026年11月」88/88。ただし 390px より狭い端末は制約として下に記録）
    > 差12: 区分アイコンが料理名の 1 行目に揃わない。原因は svg が `display: inline` で baseline に載ることと、448 幅の svg が 14px の枠から 2px はみ出すこと。`CategoryIcon.tsx` の内側 span に `[&>svg]:block [&>svg]:size-full` を足し（`dish/DishSearchCard` でも使うため影響あり）、`MealCard` の `mt-0.5` を `isToday ? 'mt-[7px]' : 'mt-[3px]'` にした（行の高さ 19.25px / 27.5px で、14px のアイコンの中心が 0.4px 以内）。MealCard の spec と新設の CategoryIcon.spec.tsx で検証（修正済み。再確認で解消: 線ボックス基準でアイコン枠と1行目の中心差は通常 0.38px、今日 0.25px で 0.4px 以内。Range 基準（字の content area）では全行 +1.00px。日本語フォントの content area が線ボックス中心と約 0.6〜0.75px ずれることによる値で、依頼の基準ではないが記録に残す。目視ではずれは判別できない）
    > 差13（修正しない）: 点数の色は計算値が rgb(187,77,0)。`text-amber-700` は Tailwind v4 でこの値であり、#b45309 = rgb(180,83,9) は v3 の値。不具合ではない。白地のコントラストは約 5.0:1 で足りる。Design System の `rating-text` は #b45309 でコードと違うため、Phase 7 で v4 の値へ直す
    > 差14（修正しない）: Phase 7 で Design System をコードと照合して見つけた。文字の大きさが確定案のボードと4か所違う（料理名 ボード15px/コード14px、今日のレシピ元とコメント 13px/12px、曜日 11px/12px、操作欄の文字 11px/10px）。実装で Tailwind の近い段へ寄せた結果であり、検査の項目に含めていなかった。差は 1px で、本人が実際の画面を確かめて ok としていること、ボードに合わせると段にない値が増えることから、本人の承認（2026-11-13「ok」）を受けてコードのままとする
    > 観測できなかったもの（追加）: 枠の行の「昼」の印（実データになく比較できず。`bg-lunch/15` と `text-lunch-foreground` は FrameCard の spec が担保）
    > 再確認(fix3、frontend/inspect/visual/tmp/20261107-week-calendar-after-fix3/result.md、390x844 主、375x667・360x800 補助): 
    > 制約: 390px より狭い端末で期間ラベルが切れる。375px は「11/14 - 11/20」のみ切れ（109 > 99）、360px は 3 つとも切れる（99・109・88 > 84。「11/14 - …」と表示）。ボタンは 44px 以上を保ち、右端は画面内、横スクロールなし。設計の受け入れ基準は 390×844。この扱いは本人へ報告する
    > DishSearchCard（/dishes）: 40 件中 39 件が区分アイコン付きで、14x14・display: block・枠に収まり、欠け・拡大・縦ずれなし。左端のチェック枠が画面左端で切れて見えるが、今回の変更と関係がなさそうで、既存の見え方かは未確認
    > 全体: 週 body 666px、月 2799px（前回と差 0）。横スクロール・はみ出し・点線なし。「評価する」102x44、操作欄の開閉、移動の操作中（「+」「…」「評価する」「枠の削除」が 0、×で復帰）は正常。下部バーの左端が dev の「N」バッジに重なるのは開発環境の表示
    > 観測できなかったもの: 今日の「★n 評価を変更」、昼と朝の印、週ビューの「未定」（月で 14 日観測）、週での P ページ付きレシピ元（月で 3 件観測）、週でのコメント（月で料理コメント 1 件のみ）、食事コメントの色
  - ⚠️ `npx playwright`またはPlaywright toolを直接呼ばない。必ずpluginの`visual-inspector` skillを使う。

## Documentation reviewと実装後振り返り

- [x] code readingまたは実装で永続化候補を得た場合、その場でdoc-enricherを提案modeで適用する
  - [x] 提案がある場合だけユーザー承認後に既存READMEまたは既存docsへ反映する
  - [x] 提案・承認判断を別taskへ先送りしない
  > 候補: preflight を読み込まないことと `base.css` の要素指定が、Tailwind の class の書き方へ与える影響。差5・差12、ヘッダーのリンクの青と下線、区分アイコンの色で実際に起きた。既存の docs には preflight を使わないことだけがあり、その帰結はなかった。
  > 本人の承認（2026-11-13「ok」）を受け、`frontend/docs/ai_guideline/development_standard/global_css.md` を新設し、同じ directory の `README.md` から `@` で参照した。`frontend/README.md` の preflight の行からも参照した。
  > `globals.css` へリセットを足して根本から直すことは、全画面の見た目が変わるため対象外とし、文書の「全体のリセットで直さない理由」に書いた。
- [x] 実装、review、validationからfeedbackまたは実装とのずれが生じた場合、直接受領したworkflow ownerがpluginの`facilitate-discussion`を`implementation_review.md`へ適用する
  - [x] `discussion_directory=<working_dir>`と`discussion_file_name=implementation_review.md`を渡す
  - [x] 原文、関連する実装・design・plan、原因、採用方針、決定を渡し、修正済みでも記録を省略しない
  - [x] 「共有されていなかった知識の前提は何か」を確認する
  - [x] 「codeを読めば分かるか、設計意図か、process不足か」を確認する
  - [x] 「どこに書けば次回この議論が不要になるか」を確認し、合意後だけ反映する
  - [x] decisionをcallerへ返し、designまたはplan構造が変わる場合は同じworking directoryでtask-designへ戻す
  - [x] review後に実装を自動再開しない
  > 対象: 確定案のボードとの差11点と、Tailwind v3 の色の値で書いた食い違い（差13 と Design System の `rating-text`）。
  > 論点1（確定案をコードへ移す時に、ボードの値をどう渡すか）と論点2（Tailwind の色名の値をどこから取るか）を本人が受諾し（2026-11-13）、`ui_design_management.md` へ反映した。
  > design と plan の構造は変わらない。

---

## 動作確認

### DoD

Tasks に挙げた確認をユーザーが行い、期待どおりであることを確認した。

### Tasks

- [x] ユーザーに動作確認を依頼する（`http://localhost:18100` の週ビューで次を確かめる。今日の「評価する」から星を付けられる。「…」で操作欄が開く。「+」で食事登録が開く。他の日へ移動できる。月ビューも崩れていない）
  > 2026-11-13 本人「確認してokだった」
- [x] ~~feedback収集~~（画面へのfeedbackなし。同じ返答の Claude Design についての問いは `task-design-discussion.md` の論点17・18で扱った）

---

## 完了後のaction

> ⚠️ 動作確認phaseが完了するまでcommit、push、PRを促したり実行したりしない。急かすことも禁止する。

- [x] commit（phase単位かつ意味単位で分割）
  > 2026-11-13 本人が計画を承認（「ok」）。`plan-commits` で決めた10本を commit した（a3acfbe〜414dfcd）。README の古い記述、区分アイコン、ヘッダー、週カレンダーの表示、画面の意図、UIデザインの管理方針（本体、確定案を移す手順、色の値の取り方）、グローバル CSS の前提、`.steering/` の記録に分けた。
  - 境界は、実差分へ`plan-commits`を当てて決める
  - MUST: まとめて一commitにしない
  - README の古い記述の修正、画面の意図と管理方針の文書、画面の変更、`.steering/` の記録は別の commit にする
  - ユーザーが一部だけ承認した場合は承認範囲だけをcommitし、残りは待つ
  - ユーザーが不要と回答した場合は`[x] ~~commit~~（ユーザーが不要と回答）`の形式で完了扱いにする

---

## Phase 7: 次のキャンバスを作る時に、適用後の Design System を読める

この phase の変更は claude.ai 上に残り、作業を破棄しても戻らない。
`.agents/skills/tumeda-dev-plugin-context.md` の `task-design` 節に、作業の外へ残る action の差し込みの宣言はないため、既定の停止と確認だけを置く。

### DoD（完了条件）

- 「なにたべ Design System」の `tokens.json` が適用後のコードの値と一致している。
- README の適用前の注意が消え、写した commit と日付が適用後のものになっている。
- README の手順だけを読んで、`git log` で差分を確かめられる。
- キャンバスの `project/ds/nanitabe/tokens.json` と `designSystems` の記録が新しい版を指している。

### Tasks

- [x] `tokens.json` を適用後のコードと照合して更新する
  > 色: `rating-text` を v4 の amber-700（`oklch(55.5% 0.163 48.998)`）、`foreground-soft` を v4 の zinc-700 へ。`globals.css` の CSS 変数の値は一致していた。用途の説明を実装に合わせた（「枠」の破線はない、`rating-star` は操作欄の評価済みの星）。
  > 文字: 確定案のボードの値からコードの class の値へ直した。料理名 15px → 14px（`text-sm`）、曜日 11px → 12px（`text-xs`）、操作欄の文字 11px → 10px。今日のレシピ元とコメントの 13px はコードにないため外した（12px のまま）。枠名、点数、「今日」、「未定」、「評価する」、「今週」の文字を足した。
  > 間隔: 食事の行の上下の余白 8px → 6px（`py-1.5`）。「+」の列、日番号の丸、印の大きさ、区分アイコンとの間を足した。
- [x] README を更新する
  - [x] 適用前の注意を消す
  - [x] 写した commit と日付を更新する（2026-11-13 22:32 JST、`feature-297@414dfcd`）
  - [x] リポジトリ名を `setsumaru1992/nanitabe` へ直す（「これは何か」と「写した元と最新化」で `tumeda1992/nanitabe` と誤記している）
    > 訂正（2026-11-14）: この task は誤りだった。リポジトリの今の名前は `tumeda1992/nanitabe` であり（`gh repo view`、PR #304 の URL）、origin の URL `setsumaru1992/nanitabe` は GitHub が今の名前へ転送している古い名前である。Design System の README と `tokens.json`、キャンバスの `tokens.json` の写しを `tumeda1992/nanitabe` に戻した。原因は `internal-records/task-design-discussion.md.topic-18.md` の記録4。
  - [x] 最新化の command を、squash merge の後も使える形へ変える
    > `git log --since="2026-11-13 22:32 +0900" -- …` とした。日付だけ（`--since=2026-11-13`）では git が今の時刻を補い、当日の commit が出ないことを実行して確かめたため、時刻まで書いた。
    > これに合わせ、`ui_design_management.md` の「README に書いた commit から」を「README に書いた写した日時から」へ直した（一意に導ける変更として報告）。
  - [x] 「画面の意図」を `frontend/src/components/calendar/README.md` と照合する
    > リポジトリの節を写し直した（`START_FROM_SAT` の記述が足りなかった）。
- [x] 表示の説明と部品の呼び名を、実装の結果と照合する
  > 枠の行の削除を操作中に出さないこと、昼夜の印を枠の行でも使うこと、操作欄の色、点数と星の色を足した。「置かないもの」に、論点17の正本の写しを足した。
- [x] キャンバスの Design System の写しを更新する
  > `copy_file` で `project/ds/nanitabe/tokens.json` を写し、sha256 が Design System の `tokens.json` と一致することを確かめた。`canvas.json` の `designSystems` の `version` を `1794576981-f062`、`copiedAt` を 2026-11-13T13:36:37Z にした。
- [x] README の手順の command を実行し、差分を確かめられることを確認する
  > 写した日時より後の変更は 0 件。当日の 0 時からにすると、今回の5件の commit が出ることも確かめた。
- [x] ここで作業を停止し、Design System の結果をユーザーに確認する。次へは進まない
  > 本人の指摘で、overview とトークンが一画面の仕様の写しになっていたと分かった（`task-design-discussion.md` 論点19）。
  > overview を画面をまたぐ内容だけにし、トークンを色の役割と段に絞った。画面ごとの内容は Design System の範囲から外し、部品の呼び名を `frontend/src/components/calendar/README.md` へ移し、`ui_design_management.md` に画面の意図を読む先を足した。
  > キャンバスの写しは 1794577546-ce00 の `tokens.json` を写した。その後の版で変わったのは README と index だけである。
  > 確定案のボードと今のコードの文字の大きさが4か所違う件は、本人の承認を受けてコードのままとした（差14）。

### 各task詳細

#### `rating-text` の値

Design System の `rating-text` は `#b45309`（Tailwind v3 の amber-700）で、コードの `text-amber-700`（Tailwind v4 で rgb(187,77,0)）と違う。`tokens.json` を照合する時に、`rating-text` を v4 の amber-700 の値へ直す。

#### 最新化の command

`main` への squash merge で commit の hash は変わる。
`git log --since=<写した日> -- frontend/src/app/globals.css frontend/src/components/calendar` の形へ変え、hash は参考として残す。

#### キャンバスの Design System の写しを更新する

`copy_file` で `project/tokens.json` を `project/ds/nanitabe/tokens.json` へ写し、`canvas.json` の `designSystems` の `version` と `copiedAt` を更新する。
他の board と note は変えない。

---

## Phase 8: Claude Design で分かったことを残す

### DoD（完了条件）

- `design.md` の「調査・比較・技術検証によるfindings」を読むと、Claude Design で何ができ、今回どこまで確かめたか、キャンバスの案がどこまでそのままコードへ移ったかが分かる。

### Tasks

- [x] findings の確認状況を実測へ更新する
  - [x] キャンバスの案とコードの差、差が出た理由を書く
    > 「キャンバスの案からコードへ移した結果」を足し、「まだ言えないこと」から外した。
  - [x] 資料の記述のみの項目のうち、使ったものを更新する
    > デザインシステム化、コードからのデザインシステム作成を実施済みへ更新し、Design System の範囲と版の扱いの行を足した。
  - [x] 実データの料理名と artifact の URL を書かない

---

## 完了後のaction（公開）

- [x] current branchをpushしてPRを作成する
  - [x] commit taskの結果としてlocal commitが実際に一件以上あることを確認する。一件もなければpush・PRを実行しない
  - [x] Phase 7 と Phase 8 で増えた `.steering/` の記録を commit する
  - [x] current branch が `feature-297` であることを確認する
  - [x] `git push -u origin feature-297`を実行する
  - [x] pluginのskills directory配下にある `scripts/github/create_or_get_pr.sh` を実行する
    > PR #304 を作った。本文に `Closes #297`、変更の要約、既知の制約（390px より狭い端末で期間ラベルが切れる）、確認していないこと（`/dishes` のチェック枠）を書いた。
    - issue #297 の作業が終わる merge であるため、PR は `Closes #297` を持つ
    - merge はユーザーが判断する。`main` への merge で本番へ適用される

---

## 参照

- 設計の正本: 同じdirectoryの `./design.md`
- 完了条件、取消完了、subtask分割、checkbox更新timingの規則の正本: `tasklist-executor/SKILL.md`
- tasklistへ載せるtaskの範囲の正本: `task-design/tasklist-design.md`
