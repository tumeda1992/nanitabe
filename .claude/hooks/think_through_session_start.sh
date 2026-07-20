#!/usr/bin/env bash

read -r -d '' CTX <<'EOF'
think-through skill 適用中（毎ターン常時注入）。
本体: tumeda-dev:think-through

主要原則:
- 唯々諾々禁止: 自分で考えてから問う・反論
- 修正前合意: ファイル変更前に方針合意
- 事象→原因（なぜ多段）→提案（総論+各論）→検証
- ロジックツリー上位から再帰
- 抽象と具体ワンショット
- 型更新前に今のファイルで合意
- エラーは消す前に原因特定

詳細はshared plugin skillを参照。
EOF

jq -nc --arg ctx "$CTX" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
