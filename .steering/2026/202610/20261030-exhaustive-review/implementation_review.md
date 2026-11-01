# 指摘反映後の検証とfeedback

## CR-003: 旧Repository specの成功契約

最初のbackend全体回帰は936 examples / 1 failureだった。失敗は旧Repository specが関連済みの出典を本からYouTubeへ変更して成功することを前提にしていたためで、CR-003の合意済み拒否契約と一致しない。model validationを外したり、fixtureで保存を迂回する対処はしない。

元操作を拒否してsource/関連の全属性が不変となる期待へ更新した。Repository自体が古い詳細列を消してURLを保存できることは、最初からYouTube型のsourceに残る旧データの修復ケースとして別に検証した。関連26 examples / 0 failures、変更specのRuboCop成功。全体回帰をこの後に再実行する。

## 公開前の確認

個別の採否・commit・検証はapplication.mdと各findingを正本とする。全体結果・baseline lint・公開結果は確定後に追記する。実環境へのapply/migration/Webhook呼出しは行わない。
