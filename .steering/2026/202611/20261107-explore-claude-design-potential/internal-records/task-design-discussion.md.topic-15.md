# 内部検討記録: 論点15 — デザインの管理方針をリポジトリのどこへ残すか

**discussion:** [task-design-discussion.md](../task-design-discussion.md)

**論点:** 論点15

## 開始context

論点14でデザインの管理方針を決めた。
方針は今 `design.md` にしかなく、次のセッションから見つけにくい。
この論点で決めるのは、方針の置き場所と文書の構成である。

<a id="iteration-0"></a>

## イテレーション0: 読み込まれる経路

<a id="iteration-0-record-1"></a>

### 判断: 置き場所

#### 判断対象・必須条件・根拠

必須条件は、次のセッションが、カレンダー以外の画面を作る時にも読むことである。
根拠は次のとおりである。

- `frontend/CLAUDE.md` は `docs/ai_guideline/README.md` を `@` で参照し、その先の `development_standard/README.md` が各文書を `@` で参照している。この session で frontend を作業ディレクトリにした時、これらの本文が読み込まれたことを観測した。
- `development_standard/README.md` は、他のリポジトリでも成立する規則は plugin 側へ置くとしている。
- `frontend/README.md` は `frontend/CLAUDE.md` の参照先に含まれていない。

#### 当てた結果

`development_standard/design_management.md` の新設を推す。決め手は、読み込みの経路が既にあることである。

plugin の標準は、原則としては当てはまりそうだが、根拠が一件だけで、path はこのリポジトリ固有である。
他のリポジトリで同じ方針を使う時に移動を検討する。

#### 確認していないこと

本文はまだ書いていない。outline の合意後に書く。
