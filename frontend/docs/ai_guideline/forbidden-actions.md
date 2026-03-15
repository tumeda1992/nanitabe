## 副作用ルール（Prohibited）
- 許可範囲外の副作用操作は禁止。
- 許容：
    - ファイル作成・書き込み
    - 許可された削除
    - dockerコマンド
      - 読み取り
      - コンテナ(再)起動・停止・削除
      - イメージ作成・削除
      - コンテナへのコマンド実行
    - gitの参照系コマンド
      - `git status` や `git diff` などの読み取り
- 禁止：
    - 許可のない副作用（例：`git add` 等の副作用のあるGit操作、環境設定変更）

## Playwright 使用ルール（Prohibited）
- **MUST**: ブラウザ操作・スクリーンショット取得は必ず `visual-inspector` サブエージェント（`Agent(subagent_type="visual-inspector")`）経由で行うこと
- **禁止**: `npx playwright`・`mcp__playwright__*` ツールの直接呼び出し、playwright バイナリの直接実行
- **禁止**: playwright バイナリを `find` や `which` で検索すること（visual-inspector に委譲すれば不要）

