#FROM alpine:3.9 as build-swarm

#WORKDIR /usr/src/app

# Swarm 0.4.3
#ENV BRANCH v0.4.3 

#RUN apk add --update git go make gcc musl-dev linux-headers bash pwgen
#RUN git clone -b ${BRANCH} https://github.com/ethersphere/swarm.git /usr/src/app && \
#  make swarm            


FROM ethersphere/swarm:0.5.4 as swarm-docker

FROM alpine:3.9 

WORKDIR /usr/src/app

RUN apk add --update pwgen bash geth

COPY --from=swarm-docker /usr/local/bin/swarm /usr/local/bin/swarm

COPY run.sh /usr/local/bin/
 
ENTRYPOINT [ "run.sh" ]