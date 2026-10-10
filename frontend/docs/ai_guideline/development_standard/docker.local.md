# Docker（ローカル開発マシン固有）

このファイルはローカルの開発マシンでのみ起きる事象を扱う。
コンテナ内実行の一般規約は @docker.md を参照。

Tailwind のビルドと watch の特性そのもの（`--watch=always` が必要な理由、
tree-shake、反映の遅延、メモリ膨張の性質）はマシンに依存しないため、
@../../troubleshooting/tailwind/build_and_watch.md が持つ。
このファイルは、それがローカルの Docker 環境でどう壊れ、どう戻すかだけを扱う。

## Tailwind watcher でコンテナが壊れたとき

開発コンテナでは `entrypoint.sh` が `yarn dev` を起動し、その中で `watch:css` が
tailwindcss の watcher プロセスを常駐させる。CI と Lambda イメージビルドでは
`yarn build` を一度実行するだけなので watcher は存在しない。
したがってこの節はローカル開発コンテナだけに当てはまる。

### 禁止事項

- **MUST**: 起動済み watcher がある状態で、Tailwind をコンパイルする操作を
  `docker compose exec frontend` から実行しない
  - `yarn build` は `build:css` を含むため該当する
  - 理由は @../../troubleshooting/tailwind/build_and_watch.md を参照

### 復旧

```sh
docker compose restart frontend
```

`entrypoint.sh` が `yarn dev` を起動し、その中で watcher が再起動する。

### restart が効かない場合

メモリ膨張が Docker VM の Total Memory（実測環境では 7.653GiB）に迫ると、
restart では戻せない状態になる。

- VM 内でプロセス生成が不能になり、`docker compose exec` が
  `error executing setns process` で失敗する
- `next-server` が zombie 化し、HTTP が無応答になる
- 一方 `docker compose ps` は `Up` と表示し続ける。表示だけでは壊れていることが分からない
- `docker compose restart` も
  `tried to kill container, but did not receive an exit event` で失敗する

復旧には Docker Desktop 本体の再起動が必要。
再起動後は全コンテナが停止するため、`docker compose up -d frontend` で起動し直す。

### 完全に壊れる前に介入する

`docker compose exec` がまだ生きているうちなら、次のどちらかで健全な状態
（450〜750MiB）へ戻せる実測がある。

- `globals.css` を編集していたなら revert する
- `docker compose stop frontend` で止める

`docker stats` で 80% を超えたら、確認作業を続けず介入する。

### メモリを空けても復旧しない

watcher が kill された後はメモリが戻る（実測 909.4MiB / 7.653GiB）。
壊れているのはメモリ残量ではなく残存プロセスであるため、
ホスト側のアプリを閉じても解決しない。

なお macOS の `PhysMem ... unused` や `Pages free` は、空きメモリをキャッシュへ回す設計上、
値が小さくても逼迫を意味しない。逼迫の判定には `memory_pressure` の
`System-wide memory free percentage` を使う。
