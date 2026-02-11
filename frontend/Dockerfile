FROM node:24.13.0

ARG appname=nanitabe_front
ARG apppath="/root/$appname"

WORKDIR $apppath

COPY package.json yarn.lock ./

RUN npm i -g @aikidosec/safe-chain
RUN safe-chain setup
RUN ["/bin/bash", "-c", "source ~/.bashrc"]

RUN yarn install

CMD [ "./entrypoint.sh" ]
