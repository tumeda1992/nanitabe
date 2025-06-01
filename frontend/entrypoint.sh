#!/usr/bin/env bash

port=18100

if [ "$NODE_ENV" = "production" ]; then
  # なぜかテストのコードもビルドしようとするので、一旦テスト用ライブラリをいれる
  yarn install --production=false
  yarn build
  yarn start -p ${port}

   # tail -n 1 -f package.json > /dev/null # デバッグ
else
  yarn install
  yarn dev -p ${port}
fi
