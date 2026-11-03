# 指摘反映後の検証とfeedback

## CR-003: 旧Repository specの成功契約

最初のbackend全体回帰は936 examples / 1 failureだった。失敗は旧Repository specが関連済みの出典を本からYouTubeへ変更して成功することを前提にしていたためで、CR-003の合意済み拒否契約と一致しない。model validationを外したり、fixtureで保存を迂回する対処はしない。

元操作を拒否してsource/関連の全属性が不変となる期待へ更新した。Repository自体が古い詳細列を消してURLを保存できることは、最初からYouTube型のsourceに残る旧データの修復ケースとして別に検証した。関連26 examples / 0 failures、変更specのRuboCop成功。再実行は937 examples / 0 failuresだった。

## 公開前の確認

個別の採否・commit・検証はapplication.mdと各findingを正本とする。全体結果・baseline lintは下記coverage、[公開結果](../20261027-full-repository-review/application.md#公開結果2026-11-02)は後続の適用記録に集約する。実環境へのapply/migration/Webhook呼出しは行わない。


## 全体検証への参照（2026-11-02）

backend937件、frontend283件、MySQL6件、運用系68件が成功。最終Next production build・型検査・lintの条件と、保留FR-001の既存lint2件を含む限界は[coverageの最終検証](../20261027-full-repository-review/coverage.md#最終検証2026-11-02)を正本とする。

## 公開後のCI環境障害

backend2jobはRSpec/RuboCop実行前のSetup Rubyで停止した。既存のubuntu-latest/Ruby3.3.8指定とUbuntu26.04の組合せが原因で、アプリ修正の回帰失敗と区別する。詳細とrunは[coverage](../20261027-full-repository-review/coverage.md#公開後のci2026-11-02)へ集約した。今回の公開にrunner/Ruby変更は含めない。
