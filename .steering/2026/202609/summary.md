# 2026年09月 Steering サマリー

## [20260912-provision-on-demand-backend-verification-environment](./20260912-provision-on-demand-backend-verification-environment/)

**概要:** 現在、backend を動かして確認できるのは開発者の PC 上の `docker compose` だけで、スマホ実機など PC 以外の端末からその backend へ到達できない。ECS 上に backend API 単体の動作確認環境を置き、必要なときだけ起動して、明示停止と起動から 30 分の自動停止のどちらでも落ちる状態を作る。DB は既存の DB サーバへ接続し、環境内に持たない。frontend とは繋がず、確認手段は `POST /graphql` を直接叩くことに限る。

**ステータス:** 完了

---
