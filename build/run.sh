#!/bin/sh

set -o errexit
set -o pipefail
set -o nounset

PASSWORD=${PASSWORD:-}
DATADIR=${DATADIR:-/root/.ethereum/}
PORT=${PORT:-30399}
BZZPORT=${BZZPORT:-8500}

if [ "$PASSWORD" == "" && ! -f /password ]; then 
  PASSWORD=$(echo $(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 20))
  echo $PASSWORD | tee /password
fi

KEYFILE=`find $DATADIR | grep UTC | head -n 1` || true
if [ ! -f "$KEYFILE" ]; then echo "No keyfile found. Generating..." && geth --datadir $DATADIR --password /password account new; fi
KEYFILE=`find $DATADIR | grep UTC | head -n 1` || true
if [ ! -f "$KEYFILE" ]; then echo "Could not find nor generate a BZZ keyfile." && exit 1; else echo "Found keyfile $KEYFILE"; fi

VERSION=`swarm version`
echo "Running Swarm:"
echo $VERSION

export BZZACCOUNT="`echo -n $KEYFILE | tail -c 40`" || true
if [ "$BZZACCOUNT" == "" ]; then echo "Could not parse BZZACCOUNT from keyfile." && exit 1; fi

exec swarm --ens-api 314159265dD8dbb310642f98f50C066173C1259b@http://my.ethchain.dnp.dappnode.eth:8545 --bzzport=$BZZPORT --port=$PORT --bzzaccount=$BZZACCOUNT --password /password --httpaddr 0.0.0.0 --datadir $DATADIR --corsdomain=* $@ 2>&1