FROM node:20-bullseye AS builder

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION
ARG NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN

ENV NODE_ENV=production
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
RUN yarn build

RUN aws s3 sync ./public s3://nanitabe-front-prod-static-files
RUN aws s3 sync .next/static s3://nanitabe-front-prod-static-files/_next/static --delete

FROM public.ecr.aws/lambda/nodejs:20
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/lambda-adapter

# これがないと`[TypeError: dispatcher.getOwner is not a function]`エラーが起きるかも
ENV NODE_ENV=production

WORKDIR /var/task

COPY --from=builder /app ./

CMD ["buildOnLambda/lambdaNextJsHandler.handle"]
