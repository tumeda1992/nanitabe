#!/usr/bin/env bash

CTX="think-through 適用。本体: tumeda-dev:think-through。唯々諾々禁止 / 修正前合意 / 事象→原因→提案→検証 / 上位から再帰 / 抽象と具体ワンショット / 型更新前に今のファイルで合意 / エラー消す前に原因特定。"

jq -nc --arg ctx "$CTX" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
