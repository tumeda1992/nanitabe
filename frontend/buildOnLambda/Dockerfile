FROM public.ecr.aws/lambda/nodejs:20
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/lambda-adapter

# これがないと`[TypeError: dispatcher.getOwner is not a function]`エラーが起きるかも
ENV NODE_ENV=production
WORKDIR /var/task

COPY . .
RUN corepack enable yarn
# なぜかテストのコードもビルドしようとするので、一旦テスト用ライブラリをいれる
RUN yarn install --production=false
RUN yarn build

CMD ["buildOnLambda/lambdaNextJsHandler.handle"]
