#!/usr/bin/env bash

set -e # エラーが発生したらスクリプトを終了する

port=18100

if [ "$NODE_ENV" = "production" ]; then
  # なぜかテストのコードもビルドしようとするので、一旦テスト用ライブラリをいれる
  yarn install --production=false
  NODE_ENV=production yarn build
  yarn start -p ${port}

   # tail -n 1 -f package.json > /dev/null # デバッグ
else
  yarn install
  # 開発では使わないけどこれが失敗するとLambdaに載せるイメージのビルドでコケるので、成否確認
  NODE_ENV=production yarn build
  yarn dev -p ${port}
fi
