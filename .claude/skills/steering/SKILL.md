---
name: steering
description: "Spec-driven plan を steering に落とす。Design合意→Tasklist合意で終了。実装は別コマンド。"
allowed-tools: Read, Grep, Write, Edit, Bash
---

# Steering Skill

## 入力
- ユーザー入力（/plan の引数）: **やりたいこと**

---

## ゴール
`.steering/.../design.md` を作って合意し、その後 `.steering/.../tasklist.md`（詳細タスク）を作って合意して終了する。  
**このスキルは実装しない**（コード変更・テスト実行・タスク遂行は別コマンド）。

---

## 命名規則（固定）
ディレクトリ名:
- `.steering/[YYYYM]/[YYYYMMDD]-[branch]-[slug]/`

### YYYYMMDD
- 実行日

### branch
- **現在のブランチをそのまま使う**
    - `git rev-parse --abbrev-ref HEAD`
    - 取得できない場合は `unknown-branch`

### slug
- ユーザー入力（やりたいこと）を **英語要約**し、`kebab-case` にする（英数+ハイフン）
- ルール:
    - 3〜8語程度を目安に短く
    - 冠詞は落としてよい（a/the）
    - 動詞＋目的語の形を優先（例: `edit-user-profile`, `add-payment-webhook`）
    - あいまいなら「何をするか」が伝わる最小まで（例: `profile-edit` ではなく `edit-user-profile`）

※ slug は最初に提案し、以降は **同じものを固定して使う**（途中で変えない）

---

## 成果物
- `design.md`（requirements相当を内包）
- `requirements.md`（必要時のみ。design から切り出し）
- `tasklist.md`（詳細タスク。実行はしない）

---

## フロー（順序固定）

### 1) steering ディレクトリ作成
1. `[YYYYMMDD]`, `[branch]`, `[slug]` を決める
2. `.steering/[YYYYM]/[YYYYMMDD]-[branch]-[slug]/` を作成
3. `.claude/skills/steering/templates/design.md`を元に`design.md` を作成

> この時点では tasklist は作らない

---

### 2) 読み取り調査（Designの根拠を集める）
- `CLAUDE.md` があれば読む
- `docs/` があれば読む
- Grep で類似実装を探す
    - 類似機能
    - 命名
    - 例外処理
    - テスト方針
    - レイヤ/責務境界

---

### 3) design.md を埋める（requirements相当をここに含める）
design.md は最低限、以下を含む（短くてもよい、ただし空洞化は禁止）:

- TL;DR（2〜4文）
- Requirements（MUST/SHOULD/MAY、非目標、受け入れ基準）
- Design
    - 変更点サマリ（どこに何を足す/変える）
    - 設計選択と理由（既存パターン適合）
    - 代替案（最低1つ）と棄却理由
    - リスクと対策
    - テスト方針

---

### 4) Designレビュー（自然言語 yes/no）
- design.md を保存したら、チャットで要点を短く示してレビュー依頼
- ユーザーが OK/はい/進めて 等なら次へ
- 修正なら design.md を更新して再レビュー（OKまで繰り返し）
- **承認キーワード強制は禁止**

---

### 5) requirements.md の切り出し（必要時のみ）
- design.md 内の Requirements セクションが「長くて独立させた方がレビューしやすい」と判断した場合のみ:
    1. `requirements.md` を作成
    2. design.md から Requirements を移し、design.md 側は参照リンクにする

※ Requirements が短い/軽いなら切り出さない（design.md に置いたまま）

---

### 6) tasklist.md（詳細）を作る（Design合意後のみ）
- `.claude/skills/steering/templates/tasklist.md`を元に`tasklist.md` を作成し、**詳細タスクまで**記載する（ただし実行はしない）
- 要件:
    - フェーズ分割（実装 / テスト / 移行 / リリース / ドキュメント など）
    - 各タスクは “着手可能な粒度”
    - 順序・依存が分かる
    - 主要タスク or フェーズに DoD（完了条件）
    - 不確実なものは `TBD` で残し、前提・調査項目を明記

---

### 7) Tasklistレビュー（自然言語 yes/no）して終了
- tasklist.md の要点（フェーズと主要タスク）を短く示してレビュー依頼
- OK/はい/進めて 等なら **ここで終了**
- 修正なら tasklist.md を更新して再レビュー（OKまで）

---

### 8) 振り返り：doc_enricher を起動（提案のみ → 承認があれば適用）
- tasklist 合意後、`Skill('doc_enricher')` を **Phase 1（提案のみ）**として実行する
- doc_enricher には以下を渡す前提で実行する:
  - 対象ディレクトリ（今回読み/触りが発生した範囲）
  - 関連ファイル（調査で読んだ/参照したファイル）
  - steering パス（`.steering/.../`）

- doc_enricher の提案を提示し、ユーザーに自然言語で確認する:
  - OK/はい/適用して → doc_enricher を Phase 2（適用）で再実行（承認された変更だけ）
  - いいえ/やめて/あとで → 提案のみで終了

---

## このスキルが “絶対にやらないこと”
- tasklist の実行
- コード変更
- テスト/CI 実行
- 自動で次工程に突入（勝手に実装開始）
