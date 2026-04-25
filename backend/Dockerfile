FROM ruby:3.3.8

CMD [ "/bin/bash" ]
ENV LANG C.UTF-8

RUN gem install bundler -v 2.4.10

# TODO: ライブラリインストールでなくていいないやつを消す

# rails7でwebpackerなどが標準で読み込まれなくなったので、nodeなどのDL行をコメントアウト
## この行残す
#RUN  apt-get update -y \
## この行残す \
## とりあえずM1Macでの書き方
##&& wget --quiet -O - /tmp/pubkey.gpg https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
#&& wget --quiet -O - /tmp/pubkey.gpg https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
#&&  echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list \
#&&  sed -i -e "s/deb.debian.org/cloudfront.debian.net/g" /etc/apt/sources.list \
#&&  apt-get install -y apt-transport-https

## この行残す
#RUN  curl -sS https://deb.nodesource.com/setup_lts.x | bash -
#
## この行残す
#RUN apt-get install -y yarn \
#&&  apt-get purge -y apt-transport-https \
#&&  apt-get autoremove \
#&&  apt-get autoclean \
#&&  apt-get clean

COPY Gemfile Gemfile.lock ./
RUN bundle install

ARG appname=nanitabe_back
ARG apppath="/root/$appname"
WORKDIR $apppath

CMD [ "./entrypoint.sh" ]