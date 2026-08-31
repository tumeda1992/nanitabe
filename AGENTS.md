# nanitabe

- `backend/`: バックエンドアプリケーション。詳細な指示は `backend/CLAUDE.md`。
- `frontend/`: フロントエンドアプリケーション。詳細な指示は `frontend/CLAUDE.md`。

## 常用する plugin

### genshijin

[genshijin plugin](https://github.com/InterfaceX-co-jp/genshijin) を会話口調に使う。詳細は「会話方針」の口調を参照。

### tumeda-dev

`tumeda-dev` は shared skill の正本である。

- 正本repository: `~/src/github.com/tumeda1992/ai_agent_dev_skill_plugin`
- local開発時は `.agents/plugins/marketplace.json` のsourceを確認し、local pathならsymlinkを辿ったcheckoutだけを更新する。
- source更新後は同じmarketplace経由でpluginを再インストールまたはreloadする。install cacheを直接編集しない。

## 毎ターン適用する思考の作法

`tumeda-dev:think-through` を、議論・修正前の合意・選択肢提示・抽象化・型更新・エラー対処を含む全思考プロセスに適用する。詳細な手順はplugin skillを読み、ここへ複製しない。

## 会話方針

ユーザーの発言を即断で変更に反映せず、事象、原因、提案、検証の順で吟味する。変更前には問題、変更先、変更理由を具体的に揃える。複数ファイルまたは複数stepの変更は、shared `steering` で設計とtasklistを合意してから実行する。

### 口調

**適用範囲: ユーザーとの会話（チャット）のみ。ファイルへの書き込み内容には適用しない。**

`genshijin` skill を利用した口調で話す。

ただし、端的に話すことと、AGENTS.md や skill の指示を無視・失念することや、脊髄反射で場当たり的に反応することは別である。守るべき指示は折に触れて思い出して守りつつ、回答は一度受け取った後に `tumeda-dev:think-through` の作法で吟味してから返す。

この口調ができているかを、AGENTS.md の指示を失念していないかのリトマス試験紙として使う。できていない場合はセッションを開き直すことを推奨する。

## instruction の配置

| 内容 | 正本 |
| --- | --- |
| 思考の作法・メタ認知 | `tumeda-dev:think-through` |
| 設計・命名・アーキテクチャ判断 | backend / frontend の専用文書 |
| task workflow | `tumeda-dev:<name>` plugin skill |

詳細手順をこのファイルに重複させない。repository固有factが必要なshared skillは、`.agents/skills/tumeda-dev-plugin-context.md` の許可範囲だけを使う。
