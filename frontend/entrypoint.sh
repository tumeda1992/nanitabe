#!/usr/bin/env bash

set -e # エラーが発生したらスクリプトを終了する

port=18100

# Tailwind CSS を globals.css からコンパイルして tailwind-output.css を生成
# @tailwindcss/postcss を PostCSS に統合するとTurbopackのコンパイルが2分以上かかるため、
# Tailwind CLI を独立プロセスで実行する方式に変更
build_tailwind() {
  node_modules/.bin/tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css
}

if [ "$NODE_ENV" = "production" ]; then
  # なぜかテストのコードもビルドしようとするので、一旦テスト用ライブラリをいれる
  yarn install --production=false
  build_tailwind
  NODE_ENV=production yarn build
  yarn start -p ${port}

   # tail -n 1 -f package.json > /dev/null # デバッグ
else
  yarn install
  build_tailwind
  # 開発時は Tailwind を watch モードでバックグラウンド起動（ファイル変更を検知してCSS再生成）
  node_modules/.bin/tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css --watch &
  NODE_ENV=production yarn build # 開発では使わないけどこれが失敗するとLambdaに載せるイメージのビルドでコケるので、成否確認
  yarn dev -p ${port}
fi
