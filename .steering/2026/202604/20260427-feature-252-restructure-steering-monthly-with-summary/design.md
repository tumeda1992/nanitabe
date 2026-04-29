# Design: .steering ディレクトリを月単位に再編 + summary.md 導入

## 元の依頼内容

.steering ディレクトリについて、年単位にしていたけど、月単位にしたい。
これは、今のディレクトリ構造を変えるのもそうだけど、.steeringディレクトリを使う steering スキルにもその方針を展開したい。

あと、各月に summary.md を置いて、全部を読まなくても状況をわかるようにしてほしい。
これもsteeingスキルで更新するようにしてほしい

---

## 1. TL;DR

`.steering/YYYY/` 直下にあった steering ディレクトリを `.steering/YYYY/YYYYMM/` 単位に整理し、
各月に `summary.md` を置いて全ステアリングを一覧できるようにする。
steering スキルを更新して「作成時に summary.md へ未完了エントリを追加」「完了後のアクションで完了に更新」を自動化する。

---

## 前提とする既存仕様

- 現在の構造: `.steering/2026/[YYYYMMDD]-[branch]-[slug]/`
- 配下に `design.md`, `tasklist.md`, `discussion.md` など
- steering スキルのディレクトリ命名規則: `.steering/[YYYY]/[YYYYMMDD]-[branch]-[slug]/`
- 現在 summary.md は存在しない
- 既存 steering ディレクトリ数: 計 29 ディレクトリ（202602: 4件、202603: 21件、202604: 4件）

---

## 2. 要件（Requirements）

### MUST（必達）
- `.steering/YYYY/YYYYMM/` 単位でディレクトリを管理する
- 各月ディレクトリに `summary.md` を置き、その月の全 steering を一覧できる
- steering スキルが新規作成時に `summary.md` へエントリを追加する（ステータス: 未完了）
- steering スキルが作成する tasklist の「完了後のアクション」に `summary.md` 更新タスクを含める
- 既存の 29 ディレクトリを月単位に移行し、各月の `summary.md` を作成する

### SHOULD（できれば）
- summary.md は Claude が機械的に読み書きできる構造にする（ステータス値が1行で確定）

### 非目標
- summary.md の自動生成ツール（CI/GitHub Actions 等）の導入
- steering 以外のドキュメント管理の変更

### 受け入れ基準
- `.steering/2026/202602/`, `202603/`, `202604/` が存在し、各月に steering ディレクトリが集約されている
- 各月に `summary.md` があり、その月の全 steering のエントリが記載されている
- 新しく steering を作成したとき、`summary.md` に自動でエントリが追加される
- tasklist.md の完了後のアクションに `summary.md` 更新が含まれている

---

## 3. 完成後の姿

### 3-1. 操作フロー（steering スキル実行時）

**ケース A: 新しいタスク steering を作成するとき**
```
① steering スキルを起動
② [YYYYMM] ディレクトリが存在しなければ作成する
   例: .steering/2026/202604/
③ steering ディレクトリを作成する
   例: .steering/2026/202604/20260427-feature-252-my-task/
④ summary.md が存在しなければ新規作成、存在すれば末尾に追記
   → 種別: タスク、ステータス: 未完了 のエントリを追加
   → 親ロードマップがある場合は「関連」に親パスを記載
⑤ design.md を作成して設計フローへ
```

**ケース B: ロードマップ steering を作成するとき（パターンA）**
```
① steering スキルを起動
② [YYYYMM] ディレクトリが存在しなければ作成する
③ steering ディレクトリを作成し、roadmap.md を作成
④ summary.md に追記
   → 種別: ロードマップ、ステータス: 未完了 のエントリを追加
   → 「関連（子 steering）」セクションは空欄（子 steering 作成時に追記）
⑤ roadmap.md の設計フローへ
```

**ケース C: ロードマップの子 steering を作成するとき**
```
① steering スキルを起動（ロードマップの1フェーズを実装するため）
② [YYYYMM] ディレクトリを確認・作成
③ 子 steering ディレクトリを作成
④ 子 steering の summary.md エントリを追加（種別: タスク、ステータス: 未完了、関連に親ロードマップパスを記載）
⑤ 親ロードマップの summary.md エントリを更新
   → 「関連（子 steering）」に子のパスを追記
⑥ design.md を作成して設計フローへ
```

**ケース D: タスク steering の実装が完了するとき**
```
① tasklist の「完了後のアクション」にある summary.md 更新タスクを実行
② .steering/YYYY/YYYYMM/summary.md を開く
③ 該当 steering のエントリのステータスを「未完了」→「完了」に更新
④ 親ロードマップがある場合:
   → 親ロードマップの summary.md エントリの「詳細」に「フェーズ X 完了」を追記
   → 全フェーズ完了なら親ロードマップのステータスも「完了」に更新
```

### 3-2. ディレクトリ構造（完成後）

```
.steering/
└── 2026/
    ├── 202602/
    │   ├── summary.md                          ← この月の全 steering を一覧
    │   ├── 20260211-feature-178-add-meal-dish-comments/
    │   ├── 20260215-feature-183-create-normalize-word-admin/
    │   ├── 20260215-feature-70-create-graphql-add-dish-word/
    │   └── 20260215-feature-70-list-normalize-words-query/
    ├── 202603/
    │   ├── summary.md
    │   ├── 20260307-feature-201-apply-v0-calendar-design/
    │   ├── ... (21件)
    │   └── 20260329-feature-238-fix-transitive-dep-vulnerabilities/
    └── 202604/
        ├── summary.md
        ├── 20260425-feature-233-register-meal-frame-template/
        ├── 20260426-feature-252-meal-frame-assign-unlink/
        └── 20260427-feature-252-restructure-steering-monthly-with-summary/
```

### 3-3. summary.md フォーマット

`summary.md` は1ファイル1ヶ月。月の見出しを h1、各 steering エントリを h2 とする。

```markdown
# 2026年3月 Steering サマリー

## 20260321-feature-64-add-meal-frame

**概要:** 食事の枠（MealFrame）機能 - 段階的追加のロードマップ

**種別:** ロードマップ  
**ステータス:** 未完了

**詳細:** Phase 1 完了。Phase 2・3 は未着手。

**関連（子 steering）:**
- Phase 1（完了）: `.steering/2026/202603/20260321-feature-232-add-meal-frame-phase1/`
- Phase 2: TBD
- Phase 3: TBD

---

## 20260321-feature-232-add-meal-frame-phase1

**概要:** MealFrame 機能 Phase 1（CRUD + カレンダー枠表示）

**種別:** タスク  
**ステータス:** 完了

**関連:** 親ロードマップ: `.steering/2026/202603/20260321-feature-64-add-meal-frame/`

---
```

```markdown
# 2026年4月 Steering サマリー

## 20260425-feature-233-register-meal-frame-template

**概要:** 食事枠パターン（テンプレート）の登録・適用機能

**種別:** タスク  
**ステータス:** 完了

**関連:** 親ロードマップ: `.steering/2026/202603/20260321-feature-64-add-meal-frame/`

---

## 20260426-feature-252-meal-frame-assign-unlink

**概要:** 食事枠の解除・既存食事との紐付け・+ボタン挙動統一

**種別:** タスク  
**ステータス:** 未完了

**詳細:** Phase 6（品質チェック）まで完了。ユーザー動作確認待ち。

---

## 20260427-feature-252-restructure-steering-monthly-with-summary

**概要:** .steering を月単位に再編、summary.md を導入

**種別:** タスク  
**ステータス:** 未完了

---
```

**フィールド定義:**

| フィールド | 必須 | 説明 |
|---|---|---|
| `**概要:**` | MUST | 1行。何をするステアリングか |
| `**種別:**` | MUST | `タスク` または `ロードマップ` |
| `**ステータス:**` | MUST | `未完了` / `完了` / `保留` の1語のみ |
| `**詳細:**` | 任意 | 未完了・保留時の状況。保留時は再着手条件を明記 |
| `**関連:**` | 任意 | 親ロードマップのパス or 子タスクのパス群 |
| `**備考:**` | 任意 | フリーテキスト |

**ステータス更新の機械的ルール:**
- Claude は `**ステータス:** 未完了` の行を `**ステータス:** 完了` に1行置換することで更新する
- ステータス値は1行目に1語のみ（値と詳細を混在させない）

---

## 4. なぜこの姿か（設計判断）

### 月フォルダ名を `YYYYMM` にした理由
既存の日付フォルダが `YYYYMMDD` 形式のため、同じ数字形式で統一。
`YYYY-MM` でも良いが、ハイフンは slug との混在で読みにくい。

### ステータスを1行1語に限定した理由
Claude が summary.md を更新するとき、`未完了` → `完了` の1行置換で済む。
ステータス値と状況詳細が同じ行にある場合、どこまでが値でどこからが詳細かが曖昧になり、
更新ロジックが複雑になる。

### summary.md 更新のタイミングを「作成時」と「tasklist 完了後アクション」に分けた理由
- 作成時: steering スキルが直接管理するため自動化できる
- 完了時: tasklist-executor が最後のタスクとして実行する形にすることで、
  「完了のシグナル」を tasklist の完了と連動させられる
- step 9（振り返りフェーズ）での更新は設計の意図から外れる（実装前だから）

### 代替案と棄却理由
- **案A: tasklist-executor が自動で summary.md を更新する（完了検知を内蔵）**
  → tasklist-executor が summary.md のパスを知る必要があり、steering の文脈を tasklist-executor に渡す仕組みが必要。複雑になる。
  → 棄却: tasklist に明示タスクを置く方がシンプル

- **案B: 月フォルダを `YYYY-MM` 形式にする**
  → YYYYMMDD との視覚的な区別が付きやすいが、ハイフンが slug のハイフンと混在する
  → 棄却: YYYYMM 形式の方が一貫性が高い

---

## 5. リスクと対策

| リスク | 対策 |
|--------|------|
| 既存 steering への参照パスが壊れる（他ドキュメントからのリンク） | grep で参照箇所を確認してから移動 |
| 移行後に steering スキルが旧パス形式でディレクトリを作成する | 移行と同時にスキル更新を行い、旧形式が残らないようにする |
| summary.md の更新を忘れて古い情報が残る | tasklist テンプレートに更新タスクを固定追加することで担保 |

---

## 6. テスト方針

- 目視確認: 移行後の `.steering/` ディレクトリツリーが期待通りになっている
- 各月の `summary.md` に全ステアリングのエントリが含まれている
- steering スキルの動作確認: このステアリング自体が移行後の正しいパスに存在している

---

## （付録）変更点一覧

### .steering/ ディレクトリ（移行）
- `.steering/2026/202602/` を作成し、202602 の4件を移動
- `.steering/2026/202603/` を作成し、202603 の21件を移動
- `.steering/2026/202604/` を作成し、202604 の4件（本 steering を含む）を移動
- 各月の `summary.md` を新規作成

### steering スキル（`.claude/skills/steering/SKILL.md`）
- 命名規則のディレクトリパスを `.steering/[YYYY]/[YYYYMM]/[YYYYMMDD]-[branch]-[slug]/` に更新
- Step 1 に `summary.md` への未完了エントリ追加手順を追記（タスク・ロードマップ共通）
- パターンA（ロードマップ作成）: summary.md に ロードマップエントリを追加する手順を追記
- パターンA から生まれる子 steering 作成時: 子エントリ追加 + 親ロードマップエントリの関連セクションに追記する手順を追記
- tasklist テンプレートの「完了後のアクション」に `summary.md` 更新タスクを追加
  - タスク steering: ステータスを完了に更新
  - 親ロードマップがある場合: 親の詳細にフェーズ進捗を追記、全完了なら親もステータス更新

### tasklist テンプレート（`.claude/skills/steering/templates/tasklist.md`）
- 「完了後のアクション」に `summary.md` の該当エントリを完了に更新するタスクを追加

### テンプレート追加
- `.claude/skills/steering/templates/summary_entry.md`
  → 月次 summary.md に追記する1エントリの書式見本（タスク・ロードマップ両バリアントを記載）
  → `discussion_entry.md` と同じ位置づけ。コピーではなく書式参照用
