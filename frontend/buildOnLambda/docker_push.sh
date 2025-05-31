#!/bin/bash

script_path="$(realpath "$0")"
script_dir=$(dirname $script_path)
script_parent_dir=$(dirname $script_dir)
cd $script_parent_dir

export $(grep -v '^#' /etc/opt/app_setting_files/nanitabe/.env | xargs)

#env="deploy-test"
env="prod"
image_name_with_tag=nanitabe-front/next-js-on-lambda/${env}:latest
docker build -t ${image_name_with_tag} -f buildOnLambda/Dockerfile .

aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ${IMAGE_REGISTORY}
docker tag ${image_name_with_tag} ${IMAGE_REGISTORY}/${image_name_with_tag}
docker push ${IMAGE_REGISTORY}/${image_name_with_tag}
