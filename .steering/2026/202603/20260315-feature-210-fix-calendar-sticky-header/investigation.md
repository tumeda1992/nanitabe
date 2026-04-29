# 調査: sticky が機能しない原因の特定

## 調査目的
`CalendarHeader` の `sticky top-0` が機能していない原因を特定し、対応方針（A or B）を決定する。

## 背景（実測済みファクト）
- Playwright でスクロール後に `top: -391px` となりヘッダが画面外へ消えることを確認済み
- `position: sticky` は記述されているが機能していない

## 調査方法
Playwright または ブラウザ DevTools で、`<header>` から `<html>` までの祖先要素を辿り、
`overflow: hidden / auto / scroll` が設定されている要素を特定する。

## 調査対象
- `Calendar/index.tsx` の外側 `<div>`
- `WeekCalendar/index.tsx` / `MonthCalendar/index.tsx`
- `app/calendar/week/[date]/page.tsx`
- `app/layout.tsx`（`<html>`, `<body>`）
- `LogicalHistoryProvider`（何らかのラッパー要素を持つ場合）

## 記録すべきこと
- [ ] overflow が設定されている祖先要素（なければ「なし」と記録）
- [ ] その要素の overflow の値
- [ ] 自プロジェクト内の制御可能なコードか否か

## 方針決定基準
| 調査結果 | 採用方針 |
|---|---|
| 自プロジェクト内の要素が原因、かつ修正が副作用小さい | 方針A: overflow を除去して sticky を機能させる |
| フレームワーク内部（Next.js 等）が原因、または修正が困難 | 方針B: `fixed` + `useMeasureHeight` に切り替え |
| overflow が見当たらない（原因不明） | 方針B を採用して確実に対処 |

## 調査結果

### overflow による阻害
**なし。** header から html までの全祖先要素の overflow / overflowX / overflowY はすべて `visible`。

### 本当の原因
`Calendar/index.tsx` の DOM 構造が問題。`<header>` を包む `<div>` が header 自身と同じ高さ（49px）しかなく、sticky が機能する「親要素の範囲内」がほぼゼロ。

```
DIV (外側コンテナ)
├── DIV (height: 49px)  ← header だけを包む div（これが問題）
│   └── HEADER.sticky.top-0 (48px)
└── DIV.flex.flex-col (1186px)  ← DateCards（別の兄弟要素）
```

`sticky` の仕様上、「包含ブロック（親要素）の範囲内でのみ sticky として振る舞う」ため、
親が 49px しかなければスクロール直後に親の外へ出てしまい機能しない。

### 採用方針
**方針A: header を包む `<div>` を削除して sticky を機能させる**

`Calendar/index.tsx` の header ラッパー `<div>` を取り除き、
header と DateCards を同じ親 `<div>` の直接の子にする。

```tsx
// 修正前
<div>
  <div>                     {/* ← これを削除 */}
    {children(...)}
  </div>
  <div className="flex flex-col ...">...</div>
</div>

// 修正後
<div>
  {children(...)}            {/* header を直接ここに */}
  <div className="flex flex-col ...">...</div>
</div>
```

### 方針の根拠
- overflow による阻害ではないため、`fixed` に切り替える必要がない
- 1行削除（ラッパー div の除去）で解決できる最小変更
- sticky の CSS はすでに正しく書かれており、DOM 構造を直すだけでよい
