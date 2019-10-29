FROM golang:1.13-alpine as build-swarm

WORKDIR /usr/src/app

# Swarm 0.5.2
ENV BRANCH v0.5.2

RUN apk add --update git go make gcc musl-dev linux-headers
RUN git clone -b ${BRANCH} https://github.com/ethersphere/swarm.git /usr/src/app && \
  make swarm            

FROM alpine:3.10

WORKDIR /usr/src/app

RUN apk add --update pwgen bash geth

COPY --from=build-swarm /usr/src/app/build/bin/swarm /usr/local/bin/swarm

COPY run.sh /usr/local/bin/

ENTRYPOINT [ "run.sh" ]
