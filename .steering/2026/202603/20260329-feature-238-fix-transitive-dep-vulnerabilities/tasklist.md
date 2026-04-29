# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### tasklistの更新タイミング（必須）
- **フェーズが完了したら即座に `[x]` に更新する**
- 最後にまとめて更新することは禁止

---

## フェーズ1: resolutions 追加 → yarn.lock 更新

### DoD（完了条件）
- `frontend/yarn.lock` 内の picomatch が `4.0.4`、minimatch が `9.0.7`、immutable が `3.8.3` に更新されている
- 安全系列（picomatch 2.3.1・minimatch 3.1.2・immutable 5.1.4）が変化していない

### タスク

- [x] `frontend/package.json` に `resolutions` フィールドを追加する
    - 追加内容:
      ```json
      "resolutions": {
        "picomatch@^4.0.0": "4.0.4",
        "minimatch@^9.0.0": "9.0.7",
        "immutable@^3.0.0": "3.8.3"
      }
      ```
    - ベアキーは禁止（複数バージョン系列が共存しているため安全系列を破損するリスクがある）

- [x] `docker compose exec frontend yarn install` を実行する
    - lock が更新されない場合は `yarn install --force` を試みる

- [x] yarn.lock を確認してDoDを満たしているか検証する
    - `grep -A 2 "^picomatch@\^4" frontend/yarn.lock` → version "4.0.4" であること
    - `grep -A 2 "^minimatch@\^9" frontend/yarn.lock` → version "9.0.7" であること
    - `grep -A 2 "^immutable@" frontend/yarn.lock` で 3.x 系が "3.8.3" であること
    - 安全系列（picomatch 2.x・minimatch 3.x・immutable 5.x）が変化していないこと

---

## フェーズ2: 動作確認

### DoD（完了条件）
- 自動テストが全グリーン
- カレンダー画面・料理検索画面でデータが正常に表示されている

### タスク

- [x] 自動テストを実行する
    - `docker compose exec frontend yarn test`
    - 失敗したら原因を分析して修正し再実行する

- [x] カレンダー画面のスクリーンショットを撮って目視確認する
    - `visual-inspector` サブエージェント（`Agent(subagent_type="visual-inspector")`）を使用する
    - 確認観点: データ（食事・枠情報）が表示されているか、クラッシュしていないか
  > 確認日時: 2026-03-29 17:25
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260329-feature-238-vuln-fix/result.md
  >
  > 項目1: カレンダー画面 ✅
  >   期待値: 食事・枠情報が表示されているか、クラッシュしていないか
  >   結果: 正常。カレンダーに食事データが表示されている。クラッシュなし。

- [x] 料理検索画面のスクリーンショットを撮って目視確認する
    - `visual-inspector` サブエージェントを使用する
    - 確認観点: 料理一覧が表示されているか、クラッシュしていないか
  > 確認日時: 2026-03-29 17:25
  > 総合結果: ✅ 全項目正常
  > ログ: frontend/inspect/visual/tmp/20260329-feature-238-vuln-fix/result.md
  >
  > 項目1: 料理検索画面 ✅
  >   期待値: 料理一覧が表示されているか、クラッシュしていないか
  >   結果: 正常。料理一覧（891件）が表示されている。クラッシュなし。

---

## フェーズ3: 品質チェック

### DoD（完了条件）
- lint エラーがない（フロントエンド全体）

### タスク

- [x] lint 実行（フロントエンド全体）
    - `docker compose exec frontend yarn lint`
    - エラーがあれば `yarn lint --fix` で自動修正して再実行
    - エラーゼロ確認
    - ※ `yarn lint` は「No files matching the pattern "src/**/*.{ts,tsx}"」というエラーで終了するが、
      これは今回の変更（package.json の resolutions 追加・yarn.lock 更新）とは無関係の既存問題であることを確認済み。
      git stash で変更前の状態でも同じエラーが再現することを確認した。
      今回追加したコードは TypeScript ファイルではないため lint 対象外。

---

## 完了後のアクション

> ⚠️ 動作確認フェーズが完了するまでコミットを促すことは禁止。

- [x] コミット
    - `frontend/package.json` と `frontend/yarn.lock` をセットで 1 コミット

- [x] push して PR を作成する
    - `git push -u origin feature-238`
    - `bash scripts/github/create_pr_from_branch_name.sh`
