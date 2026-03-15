---
name: steering
description: "Spec-driven plan を steering に落とす。Design合意→Tasklist合意で終了。実装は別コマンド。明示的に指定されたときはもちろん、軽度の修正でない場合（複数ファイルの編集、ステップを持つ修正）にはこのスキルを起動する"
allowed-tools: Read, Grep, Write, Edit, Bash
---

# Steering Skill

## 入力
- ユーザー入力（/plan の引数）: **やりたいこと**

---

## ゴール
`.steering/.../design.md` を作って合意し、その後 `.steering/.../tasklist.md`（詳細タスク）を作って合意して終了する。  
**このスキルはtasklistが完全に出来上がり合意できるまで実装しない**。

## 注意事項
会話は日本語で行うこと。

---

## 命名規則（固定）
ディレクトリ名:
- `.steering/[YYYY]/[YYYYMMDD]-[branch]-[slug]/`

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
2. `.steering/[YYYY]/[YYYYMMDD]-[branch]-[slug]/` を作成
3. `.claude/skills/steering/templates/design.md`を元に`design.md` を作成

> この時点では tasklist は作らない

---

### 2) 読み取り調査（Designの根拠を集める）
- `CLAUDE.md` があれば読む
- `docs/` があれば読む
- **プロジェクトのコーディング規約を読む**:
    - `backend/docs/ai_guideline/development_standard/formatting.md` (Rubocop実行方針)
    - `frontend/docs/ai_guideline/development_standard/formatting.md` (ESLint/Prettier実行方針)
- Grep で類似実装を探す
    - 類似機能
    - 命名
    - 例外処理
    - テスト方針
    - レイヤ/責務境界
- **UI挙動・表示に関するタスクの場合（MUST）**:
    - `visual-inspector` サブエージェントを使ってスクリーンショットを撮り、現状の実際の動作をファクトとして確認する
    - 「コードを読んだ推測」ではなく「実際に見た事実」を design.md の根拠にする
    - 例: ヘッダが固定されているか、スクロール時の挙動、レイアウト崩れ等
    - ⚠️ Playwright ツールを直接呼び出すことは禁止。必ず `Agent(subagent_type="visual-inspector")` を使うこと

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

> ⚠️ tasklist を作る前に、以下の2パターンのどちらに該当するか判断すること。

#### パターンA: タスクが大きすぎる場合（親子 steering）
- タスクが大きすぎて1つの steering で詳細タスクまで落とせない場合
- `.claude/skills/steering/templates/roadmap.md` を元に `roadmap.md` を作成する（`tasklist.md` は作らない）
- roadmap.md はチェックボックスを持たず、フェーズと子 steering パスの一覧のみ
- 各子 steering は独立して実施し、完了時に親の roadmap.md の対応箇所を更新する
- **`tasklist.md` という名前にしない**（tasklist-executor が誤って拾わないよう）
- 例: `.steering/2026/20260307-feature-201-apply-v0-calendar-design/tasklist.md`（過去実績）

#### パターンB: 調査結果によって方針が変わる場合（investigation + tasklist）
- 調査しないと実装方針が決まらない場合
- `investigation.md` を steering ディレクトリ内に作成し、調査方針を合意してから調査を進める
- 調査完了後に `investigation.md` に結果を記録し、方針を確定させてから `tasklist.md` を作る
- 通常の `tasklist.md`（下記）を使う。親子 steering は不要

#### 通常パターン（上記に該当しない場合）
- `.claude/skills/steering/templates/tasklist.md`を元に`tasklist.md` を作成し、**詳細タスクまで**記載する（ただし実行はしない）
- 要件:
    - **フェーズ分割の方針**:
        - **MUST**: インクリメンタル開発（機能単位の縦切り）を基本とする
        - 各機能を完全に完成させてから次の機能に進む
        - 例: 「準備 → 一覧機能（完結） → 新規作成機能（完結） → 編集機能（完結） → 品質チェック → ドキュメント」
        - 横切り（レイヤ別: 実装 / テスト / 移行 など）は、機能が少ない場合や特殊なケースのみ
    - 各タスクは "着手可能な粒度"
    - 順序・依存が分かる
    - 主要タスク or フェーズに DoD（完了条件）
    - **品質チェックフェーズの要件**:
        - **MUST**: プロジェクト全体のスタイルチェック（Rubocop/ESLint）を含める
        - 特定ファイルのみでなく、全体への影響を確認すること
        - これにより、新規コードが既存コードに与える影響を早期発見する
    - **デザイン変更を含むタスクの追加要件**:
        - **MUST**: UI の見た目に関わる変更（コンポーネント新規作成・スタイル変更）がある場合、
          **そのフェーズのDoDにスクリーンショット確認タスクを含める**
        - 品質チェックフェーズにまとめるのではなく、変更を加えたフェーズで都度確認する
        - 品質チェックフェーズでは最終確認として改めてスクショを撮る
        - `visual-inspector` サブエージェント（`Agent(subagent_type="visual-inspector")`）を使ってスクショを撮り、実際の見た目を目視確認すること
        - ⚠️ `npx playwright` や Playwright ツールの直接呼び出しは禁止。必ず visual-inspector サブエージェントを使うこと
        - 確認項目の例: カラーバーの色・レイアウト・今日ハイライト・レスポンシブ崩れ
    - 不確実なものは `TBD` で残し、前提・調査項目を明記
- 大きすぎるタスクとわかった場合、このsteeringではタスク分解にとどめて、個々のタスクの詳細は別のsteeringで作る
  - 過去やった実績: .steering/2026/20260307-feature-201-apply-v0-calendar-design のタスク

---

### 7) Tasklistレビュー（自然言語 yes/no）して終了
- tasklist.md の要点（フェーズと主要タスク）を短く示してレビュー依頼
- OK/はい/進めて 等なら 次へ
- 修正なら tasklist.md を更新して再レビュー（OKまで）

---

### 8) 振り返り：doc_enricher を起動（提案のみ → 承認があれば適用）【必須・スキップ禁止】

> ⚠️ tasklist が承認されたら、実装確認（step 9）より**必ず先に**このステップを実行すること。
> 「実装に早く進みたい」という理由でスキップしてはならない。
- tasklist 合意後、`Skill('doc_enricher')` を **Phase 1（提案のみ）**として実行する
- doc_enricher には以下を渡す前提で実行する:
  - 対象ディレクトリ（今回読み/触りが発生した範囲）
  - 関連ファイル（調査で読んだ/参照したファイル）
  - steering パス（`.steering/.../`）

- doc_enricher の提案を提示し、ユーザーに自然言語で確認する:
  - OK/はい/適用して → doc_enricher を Phase 2（適用）で再実行（承認された変更だけ）
  - いいえ/やめて/あとで → 提案のみで終了

- このスキル定義ファイルについて、変更の必要があるか確認
  - 不要であれば、修正は禁止


---

### 9) （必要があれば）tasklistに沿って実装

> ⚠️ このステップは step 1〜8 が**すべて完了している場合にのみ**提案してよい。
> 未完了のステップがある場合は、実装を推奨してはならない。急かすことも禁止。

- ユーザに tasklistに沿って実装するか問いかける
- OK/はい/進めて 等なら 次へ
  - そうでないならここで終了
- tasklist-executor エージェントに tasklist.md を渡して実装開始
  - **MUST**: 各フェーズ・各タスク完了のたびに tasklist.md の `[ ]` を `[x]` に即座に更新すること
  - 最後にまとめて更新することは禁止


---

## このスキルが “絶対にやらないこと”
- 許可なくtasklist の実行
- コード変更
- テスト/CI 実行
- 自動で次工程に突入（勝手に実装開始）
