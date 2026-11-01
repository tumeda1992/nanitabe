# Playwright MCP 設定

`config.json` は `.mcp.json` から `@playwright/mcp` に渡す browser 設定。

- 自動テスト通過済みの前提で画面スクショを確認する用途のため、ログイン状態を保持できるよう `isolated: false` + `userDataDir` を使用する。
- `@playwright/mcp` は設定を `JSON.parse` で読むため、`config.json` にコメントを書けない。設定の補足はこのファイルに書く。
