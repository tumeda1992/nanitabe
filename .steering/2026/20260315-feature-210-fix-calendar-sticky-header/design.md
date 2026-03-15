# 要件ドキュメント

## はじめに
カレンダー画面のヘッダを固定ヘッダ（スクロールしても常に画面上部に表示される）にする。

## 元の依頼内容
カレンダー画面のヘッダを固定ヘッダにしたい

## 要件
### 要件1: カレンダーヘッダの固定表示
**ユーザーストーリー:** カレンダー画面をスクロールしても、ヘッダ（ナビゲーション・日付ラベル・ビュー切替）が常に画面上部に表示されることで、どこからでも週/月の移動やビュー切替が行える。

#### 受け入れ基準
1. WHEN カレンダー画面を下にスクロールしたとき THEN ヘッダ（CalendarHeader）が画面上部に固定表示されたまま、コンテンツだけがスクロールされる
2. WHEN 週間ビュー・月間ビューどちらでも THEN ヘッダが固定表示される
3. WHEN ヘッダが固定表示されるとき THEN ヘッダの下に本文コンテンツが隠れない（コンテンツ領域に適切なオフセットが設定される）

--

# 設計ドキュメント

## TL;DR
`CalendarHeader` はすでに `sticky top-0 z-10` クラスを持っているが、Playwright での実測で**機能していないことを確認**。スクロール後に `top: -391px` となりヘッダが画面外へ消える。まず根本原因を調査し、その結果に応じて対応方針を決める。

## 現状の調査（Playwright 実測済み）

### 実測結果
- スクロール前: ヘッダが画面上部に表示
- 500px スクロール後: ヘッダが画面外に消え、`top: -391px` になっている
- `position: sticky` は記述されているが**機能していない**

### コード上の現状
`CalendarHeader/index.tsx:57` の `<header>` は `sticky top-0 z-10` クラスを持っている:
```tsx
<header className="sticky top-0 z-10 border-b border-border bg-background/95 backdrop-blur ...">
```

`Calendar/index.tsx` の DOM 構造:
```
<div>                              ← 外側コンテナ（overflow 指定なし）
  <div>                            ← ヘッダラッパー
    <header class="sticky top-0">  ← CalendarHeader
  </div>
  <div class="flex flex-col ...">  ← DateCards（コンテンツ）
</div>
```

### sticky が機能しない原因の仮説
祖先要素のいずれかに `overflow: hidden/auto/scroll` が設定されており、そこに対して sticky が吸着しているが viewport には固定されていない状態と考えられる。ただし根本原因は調査フェーズで確定する。

## 対応方針（調査結果次第）

### 方針A: 根本原因を修正して sticky を機能させる
sticky が効かない原因（親要素の overflow 等）を特定して除去する。

**採用条件:** 原因が自プロジェクト内の制御可能なコードにある場合
**メリット:** 変更最小。CSS の自然な流れを維持
**リスク:** Next.js 内部や LogicalHistoryProvider 等の制御困難な場所が原因の場合は適用不可

### 方針B: `position: fixed` + コンテンツオフセット
`sticky top-0` → `fixed top-0 left-0 right-0 w-full` に変更し、コンテンツ領域にヘッダ高さ分のオフセットを設定する。

**採用条件:** 方針Aが適用不可の場合、または根本原因修正より明確に適切な場合
**メリット:** viewport 絶対固定なので親要素の影響を受けない
**オフセット方針:** Tailwind 固定値（`h-12` + `pt-12`）は避ける。ヘッダ高さが変わったときにコンテンツが隠れるメンテナンストラップになるため、`useMeasureHeight`（既存フック）で動的計測する

## この steering の役割
大ブロック分解のみ。各フェーズの詳細は子 steering に委ねる。
