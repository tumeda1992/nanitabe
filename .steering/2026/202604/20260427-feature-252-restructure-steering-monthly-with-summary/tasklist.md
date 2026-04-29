# Tasklist: .steering ディレクトリを月単位に再編 + summary.md 導入

## フェーズ概要

| フェーズ | 内容 | DoD |
|---------|------|-----|
| Phase 1 | 既存ディレクトリを月別に移行 + summary.md 作成 | `.steering/2026/202602/` `202603/` `202604/` に全 steering が集約され、各月に summary.md がある |
| Phase 2 | `summary_entry.md` テンプレート追加 | `.claude/skills/steering/templates/summary_entry.md` に両バリアントが記載されている |
| Phase 3 | steering スキル（SKILL.md）更新 | steering スキルが新フォーマットのパスで動作し、summary.md を作成・更新するステップが含まれている |
| Phase 4 | tasklist テンプレート更新 | `templates/tasklist.md` の「完了後のアクション」に summary.md 更新タスクが含まれている |
| Phase 5 | 品質チェック | ディレクトリ構造と SKILL.md 記述の目視確認 |

---

## Phase 1: 既存ディレクトリを月別に移行 + summary.md 作成

**DoD:** `.steering/2026/202602/`, `202603/`, `202604/` が存在し、全 steering ディレクトリがいずれかの月フォルダに収まっており、各月に `summary.md` がある

- [x] 月別ディレクトリを作成する
  - [x] `.steering/2026/202602/` を作成
  - [x] `.steering/2026/202603/` を作成
  - [x] `.steering/2026/202604/` を作成

- [x] 既存 steering ディレクトリを月別フォルダへ移動する
  - **202602 (4件)**
    - [x] `20260211-feature-178-add-meal-dish-comments/` → `202602/`
    - [x] `20260215-feature-183-create-normalize-word-admin/` → `202602/`
    - [x] `20260215-feature-70-create-graphql-add-dish-word/` → `202602/`
    - [x] `20260215-feature-70-list-normalize-words-query/` → `202602/`
  - **202603 (19件)**
    - [x] `20260307-feature-201-apply-v0-calendar-design/` → `202603/`
    - [x] `20260307-feature-201-ph1-setup-tailwind-shadcn-ui/` → `202603/`
    - [x] `20260307-feature-201-ph2-redesign-calendar-app-shell/` → `202603/`
    - [x] `20260307-feature-201-remove-bootstrap-migrate-tailwind/` → `202603/`
    - [x] `20260308-feature-201-cleanup-unused-components-and-typo/` → `202603/`
    - [x] `20260308-feature-201-ph3-implement-calendar-daycolumn-card-view/` → `202603/`
    - [x] `20260308-feature-201-ph4-implement-dishcard-meal-display/` → `202603/`
    - [x] `20260308-feature-202-build-dish-search-page-and-components/` → `202603/`
    - [x] `20260308-feature-202-convert-meal-form-dish-picker-to-drawer/` → `202603/`
    - [x] `20260314-feature-74-bulk-add-tag-to-dishes/` → `202603/`
    - [x] `20260314-feature-74-bulk-tag-dishes-frontend/` → `202603/`
    - [x] `20260315-feature-210-fix-calendar-sticky-header/` → `202603/`
    - [x] `20260315-feature-210-fix-dish-selection-edit-modal-bugs/` → `202603/`
    - [x] `20260315-feature-210-refactor-dish-search-component/` → `202603/`
    - [x] `20260320-feature-211-add-cook-count-last-date-to-dish-search/` → `202603/`
    - [x] `20260320-feature-64-add-dish-effort-field/` → `202603/`
    - [x] `20260321-feature-232-add-meal-frame-phase1/` → `202603/`
    - [x] `20260321-feature-234-assign-meal-to-frame-entry/` → `202603/`
    - [x] `20260321-feature-64-add-meal-frame/` → `202603/`（ロードマップ）
    - [x] `20260329-feature-238-fix-transitive-dep-vulnerabilities/` → `202603/`
  - **202604 (3件)**
    - [x] `20260425-feature-233-register-meal-frame-template/` → `202604/`
    - [x] `20260426-feature-252-meal-frame-assign-unlink/` → `202604/`
    - [x] `20260427-feature-252-restructure-steering-monthly-with-summary/`（本 steering）→ `202604/`

- [x] `.steering/2026/` 直下に steering ディレクトリが残っていないことを確認する

- [x] `202602/summary.md` を作成する
  - 各 steering の tasklist.md を確認してステータスを判定（全タスク [x] なら完了、そうでなければ未完了）
  - ロードマップ有無を roadmap.md の存在で判定
  - design.md の TL;DR または元の依頼内容から概要を1行で作成

- [x] `202603/summary.md` を作成する
  - 同上。ロードマップ `20260321-feature-64-add-meal-frame/` のエントリは「ロードマップ」種別で作成
  - 子 steering との関連（関連フィールド）を記載する

- [x] `202604/summary.md` を作成する
  - 同上

---

## Phase 2: `summary_entry.md` テンプレート追加

**DoD:** `.claude/skills/steering/templates/summary_entry.md` が存在し、タスクエントリ・ロードマップエントリの両バリアントが記載されている

- [x] `.claude/skills/steering/templates/summary_entry.md` を作成する
  - タスクバリアント（全フィールド）
  - ロードマップバリアント（子 steering 関連の記載例を含む）
  - 各フィールドの説明コメント

---

## Phase 3: steering スキル（SKILL.md）更新

**DoD:** SKILL.md の命名規則・Step 1・パターンA が新フォーマットに沿って記述されており、summary.md の作成・更新ステップが含まれている

- [x] `命名規則（固定）` セクションのディレクトリパスを更新する
  - 変更前: `.steering/[YYYY]/[YYYYMMDD]-[branch]-[slug]/`
  - 変更後: `.steering/[YYYY]/[YYYYMM]/[YYYYMMDD]-[branch]-[slug]/`

- [x] `### 1) steering ディレクトリ作成` を更新する
  - `[YYYYMM]` ディレクトリの作成手順を追加
  - `summary_entry.md` テンプレートを参照して summary.md にエントリを追記するステップを追加（ステータス: 未完了）

- [x] `#### パターンA: 複数のMVPに分かれる場合（親子 steering）` を更新する
  - ロードマップ steering 作成時に summary.md にロードマップエントリを追加するステップを追記
  - 子 steering 作成時に以下を行うステップを追記:
    - 子 steering の summary.md エントリを追加（種別: タスク、関連に親パスを記載）
    - 親ロードマップの summary.md エントリの「関連（子 steering）」に子パスを追記

---

## Phase 4: tasklist テンプレート更新

**DoD:** `templates/tasklist.md` の「完了後のアクション」に summary.md 更新タスクが含まれている

- [x] `## 完了後のアクション` セクションに summary.md 更新タスクを追加する
  - コミット・push の前に summary.md 更新タスクを置く
  - 親ロードマップがある場合の更新（詳細追記・全完了なら親ステータス更新）も記載

---

## Phase 5: 品質チェック

**DoD:** ディレクトリ構造が期待通りであり、SKILL.md の記述に矛盾がない

- [x] ディレクトリ構造を目視確認する
  - [x] `.steering/2026/` 直下に steering ディレクトリがないこと
  - [x] 各月フォルダに対応する steering が集約されていること
  - [x] 各月フォルダに `summary.md` が存在すること

- [x] 各 summary.md の内容を目視確認する
  - [x] 全 steering のエントリが含まれていること
  - [x] ロードマップエントリに関連（子 steering）が記載されていること
  - [x] 子 steering エントリに関連（親ロードマップ）が記載されていること

- [x] SKILL.md の記述を確認する
  - [x] 命名規則のパスが新形式になっていること
  - [x] Step 1 に summary.md 追加手順があること
  - [x] パターンA にロードマップ・子 steering の summary.md 処理があること

---

## 動作確認

### DoD
ユーザーが `.steering/` ディレクトリ構造と summary.md の内容を確認し、意図通りであることを確認した

### タスク

- [x] ユーザーに動作確認を依頼する
- [ ] フィードバックがあれば `implementation_review.md` を作成して収集する
    - フィードバックなしの場合は `~~フィードバック収集~~（フィードバックなし）` で完了扱い

---

## 完了後のアクション

> ⚠️ 動作確認フェーズが完了するまでコミットを促すことは禁止。

- [ ] `202604/summary.md` の本 steering エントリのステータスを「完了」に更新する
  - `**ステータス:** 未完了` → `**ステータス:** 完了`

- [ ] コミット（フェーズ単位で分割）
  - [ ] Phase 1: `refactor: .steering を月単位に再編、各月 summary.md を作成`
  - [ ] Phase 2-4: `feat: steering スキルに summary.md 管理フローを追加`

- [ ] push して PR を作成する
  - `git push -u origin feature-252`
  - `bash scripts/github/create_pr_from_branch_name.sh`
