# UIデザインの管理

画面の見た目と操作のデザインをどこに残し、Claude Design をどう使うかを定める。

## 正本と作業場

正本はこのリポジトリに、ツールに依存しない形で持つ。
Claude Design のキャンバスと Design System は、Claude と考える時の作業場であり、思考キャッシュである。
消えても失うものがない状態を保つ。

Claude で継続的に保守しなくても通用し、他のデザイン管理の仕組みへも載せられるようにするためである。
Design System の `tokens.json` とキャンバスの `.dc.html` は Claude Design 独自の形式であるため、正本にしない。

## 正本の置き場所

| 内容 | 正本 |
| --- | --- |
| 色などの値 | `src/app/globals.css` の CSS 変数 |
| 見た目と動き | コード |
| 画面の意図 | 各画面の README。例: `src/components/calendar/README.md` の「画面の意図」 |

## Claude Design を使う時の進め方

- MUST: 決まったことはリポジトリへ戻す。キャンバス上の変更は、戻すまで確定ではない。
- 作業場はリポジトリから作る。古くなっていたら、Design System の README に書いた commit から `git log` を見て最新化する。常に同期する努力はしない。
- Claude Design でこのリポジトリの画面を作る時と考える時は、Design System として「なにたべ Design System」（https://claude.ai/artifact/THxSKecmzSyaDHnycbDAAy）を使う。何を置くかは、その README に従う。
- 他のデザイン管理の仕組みへ移る時は、リポジトリを入力にする。変換の仕方は、移ることが決まった時に検討する。

## やってしまいがちな失敗

- キャンバス上の変更だけで確定と扱う。作業場が消えると決定も消え、コードを読む人にも届かない。
- `tokens.json` を正本として直す。コードとずれ、次の最新化で失われる。
- 作業場で使うためにコードの部品を共通化する。保守の手間が増えるのはコード側であり、目的が逆である。部品の共通化は、コードの都合で判断する。
