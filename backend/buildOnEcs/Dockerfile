FROM ruby:3.3.8

ENV LANG C.UTF-8

RUN gem install bundler -v 2.4.10

ARG appname=nanitabe_back
ARG apppath="/root/$appname"
WORKDIR $apppath

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN chmod +x buildOnEcs/entrypoint.sh

CMD ["./buildOnEcs/entrypoint.sh"]
