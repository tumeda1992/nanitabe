#!/bin/bash
set -e  # エラー検出したら即終了する設定

script_path="$(realpath "$0")"
script_dir=$(dirname $script_path)
script_parent_dir=$(dirname $script_dir)
cd $script_parent_dir

export $(grep -v '^#' /etc/opt/app_setting_files/nanitabe/.env | xargs)

# env="deploy-test"
env="prod"
image_name_with_tag=nanitabe-front/next-js-on-lambda/${env}:latest
IMAGE_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com

docker build \
  --build-arg AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
  --build-arg AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
  --build-arg AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
  --build-arg NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN=${NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN} \
 -t ${image_name_with_tag} \
 -f buildOnLambda/Dockerfile \
 .

aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ${IMAGE_REGISTRY}
docker tag ${image_name_with_tag} ${IMAGE_REGISTRY}/${image_name_with_tag}
docker push ${IMAGE_REGISTRY}/${image_name_with_tag}
