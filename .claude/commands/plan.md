---
description: "Spec-driven plan: steering skill を起動して steering を作る（実装はしない）"
---

# /plan

**引数:** やりたいこと
例: `/plan ユーザープロフィール編集`

## このコマンドの責務
- 受け取った引数をそのまま `steering` スキルに渡し、steering 作成を開始するだけ。
- ルール・手順・ファイル構造・レビュー運用は **すべて steering スキル側**に委譲する。

## 実行
- `Skill('steering')` を実行し、引数（やりたいこと）を渡す。
- それ以外の手順説明・ファイル生成の詳細はここには書かない。
