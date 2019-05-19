FROM alpine:3.9 as build

RUN apk add --update git go make gcc musl-dev linux-headers bash pwgen
RUN git clone https://github.com/ethereum/go-ethereum.git

# Swarm 0.4.0
ENV COMMIT c3b317a4 

RUN \
  (cd go-ethereum &&  git checkout ${COMMIT} && make geth && make swarm)  && \
  cp go-ethereum/build/bin/geth /usr/local/bin/                          && \
  cp go-ethereum/build/bin/swarm /usr/local/bin/                         && \
  apk del git go make gcc musl-dev linux-headers                         && \
  rm -rf /go-ethereum && rm -rf /var/cache/apk/*

FROM alpine:3.9 

WORKDIR /usr/src/app

RUN apk add --update pwgen bash

COPY --from=build /usr/local/bin/swarm /usr/local/bin/swarm
COPY --from=build /usr/local/bin/geth /usr/local/bin/geth

COPY ./run.sh /usr/local/bin/
COPY swarm-gateways /usr/src/app

ENTRYPOINT [ "run.sh" ]