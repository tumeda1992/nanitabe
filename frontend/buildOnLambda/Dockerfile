# マルチステージビルドをまたいでARGを定義
# TODO: マルチステージで読み取られない値があったから一律外で定義して、暫定的に中にも全て渡したが、不要なものもあると思うので消す
# 野良Dockerでマルチステージビルド時に各ステージにどのように値が渡されるか調べる
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION
ARG NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN
ARG DEPLOY_ENV
ARG NEXT_PUBLIC_ASSET_ORIGIN

FROM node:24.11.1-bullseye AS builder

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION
ARG NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN
ARG DEPLOY_ENV
ARG NEXT_PUBLIC_ASSET_ORIGIN

ENV NODE_ENV=production
ENV NODE_ENV=${NEXT_PUBLIC_ASSET_ORIGIN}
ENV NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN=${NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN}

WORKDIR /app

RUN apt-get update && apt-get install -y curl unzip

# ARM64版AWS CLI v2をダウンロードしてインストール
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

RUN corepack enable yarn

COPY . .

# なぜかテストのコードもビルドしようとするので、一旦テスト用ライブラリをいれる
RUN yarn install --production=false
RUN node_modules/.bin/tailwindcss -i src/app/globals.css -o src/app/tailwind-output.css
RUN yarn build

RUN aws s3 sync .next/static s3://nanitabe-front-${DEPLOY_ENV}-static-files/_next/static --delete
RUN aws s3 sync ./public s3://nanitabe-front-${DEPLOY_ENV}-static-files

FROM public.ecr.aws/lambda/nodejs:20

# デプロイされた環境で利用する環境変数群
ARG NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN
# これがないと`[TypeError: dispatcher.getOwner is not a function]`エラーが起きるかも
ENV NODE_ENV=production
# この行を消したときに、環境変数がセットされないのかどうか、ローカルで確認
ENV NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN=${NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN}

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/lambda-adapter

WORKDIR /var/task

COPY --from=builder /app ./

CMD ["buildOnLambda/lambdaNextJsHandler.handle"]
