#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

ADDRESS=${ADDRESS:-}
PASSWORD=${PASSWORD:-}
DATADIR=${DATADIR:-/root/.ethereum}
PORT=${PORT:-30399}
BZZPORT=${BZZPORT:-8500}
KEYSTORE_PATH=${DATADIR}/keystore
ENS=${ENS:-"314159265dD8dbb310642f98f50C066173C1259b"}
EXTRA_OPTS=${EXTRA_OPTS:-}

if [ "$PASSWORD" == '' ]; then 
    if [ -z "${ADDRESS}" ]; then
        # Search for an account and a password
        while read ADDRESS; do
            if [ -f ${KEYSTORE_PATH}/.password_$ADDRESS ];then
                export ADDRESS=${ADDRESS}
                export PASSWORD_PATH=${KEYSTORE_PATH}/.password_${ADDRESS}
                break
            fi
        done <<< "$(geth account list 2>/dev/null | awk -F " " '{print $3}' | tr -d '{}')"
        # Create a new address and password
        if [ -z "${ADDRESS}" ];then
            # Create a random password
            export PASSWORD=$(echo $(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 20))
            geth account new --datadir $DATADIR --password <(echo $PASSWORD)
            PASSWORD_FILE=$(echo $(echo ".password_"$(geth account list 2>/dev/null | awk -F " " '{print $3}' | tr -d '{}' | head -1 )))
            echo $PASSWORD > ${KEYSTORE_PATH}/$PASSWORD_FILE
            while read ADDRESS; do
                if [ -f $KEYSTORE_PATH/.password_$ADDRESS ];then
                    export ADDRESS=$ADDRESS
                    export PASSWORD_PATH=$KEYSTORE_PATH/.password_$ADDRESS
                    break
                fi
            done <<< "$(geth account list 2>/dev/null | awk -F " " '{print $3}' | tr -d '{}')"
        fi
    else
        EXISTS=$(grep -qi ${ADDRESS/0x/} ${KEYSTORE_PATH}/*)
        RESULT=$?
        if [ ${RESULT} -eq 0 ] && [ -f ${KEYSTORE_PATH}/.password_${ADDRESS} ];then
            export PASSWORD_PATH=${KEYSTORE_PATH}/.password_${ADDRESS}
        else
            if [ ${RESULT} -ne 0 ];then
                echo "the account ${ADDRESS} file could not be found"
                ### TODO wait until user upload .password file
                ### add instructions or link
            elif [ ! -f ${KEYSTORE_PATH}/.password_${ADDRESS} ];then
                echo "the password file for the account ${ADDRESS} could not be found"
                ### TODO wait until user upload .password file and load parameters
                ### add instructions or link
            fi
        fi
    fi
else
    if [ -n "${ADDRESS}" ]; then
        ADDRESS=${ADDRESS,,}
        echo $PASSWORD > ${KEYSTORE_PATH}/.password_${ADDRESS/0x/}
        PASSWORD_PATH="${KEYSTORE_PATH}/.password_${ADDRESS}"
        EXISTS=$(grep -qi ${ADDRESS/0x/} ${KEYSTORE_PATH}/*)
        RESULT=$?
        if [ ${RESULT} -eq 0 ];then
            export PASSWORD_PATH=${KEYSTORE_PATH}/.password_${ADDRESS}
        else
            if [ ${RESULT} -ne 0 ];then
                echo "the account ${ADDRESS} file could not be found"
                exit 1
                ### TODO wait until user upload .password file
                ### add instructions or link
            fi
        fi
    else
        EXISTS=$(grep -i ${PASSWORD} ${KEYSTORE_PATH}/.* || echo "")
        if [ -n ${EXISTS} ];then
            geth account new --datadir $DATADIR --password <(echo $PASSWORD)
            PASSWORD_FILE=$(echo $(echo ".password_"$(geth account list 2>/dev/null | awk -F " " '{print $3}' | tr -d '{}' | head -1 )))
            echo $PASSWORD > ${KEYSTORE_PATH}/$PASSWORD_FILE
            EXISTS=$(grep -il ${PASSWORD} ${KEYSTORE_PATH}/.* )
            RESULT=$?
            if [ ${RESULT} -eq 0 ];then
                export ADDRESS=$(echo $EXISTS | awk -F "_" '{print $2}')
                export PASSWORD_PATH=$EXISTS
            fi    
        else
            export ADDRESS=$(echo $EXISTS | awk -F "_" '{print $2}')
            export PASSWORD_PATH=$EXISTS
        fi
    fi
fi

VERSION=`swarm version`
echo "Running Swarm:"
echo $VERSION

if [ "$ADDRESS" == "" ]; then echo "Could not parse $ADDRESS from keyfile." && exit 1; fi
export BZZACCOUNT="0x${ADDRESS}"

exec swarm --ens-api ${ENS}@http://fullnode.dappnode:8545 --bzzport=$BZZPORT --port=$PORT --bzzaccount=$BZZACCOUNT --password ${PASSWORD_PATH} --httpaddr 0.0.0.0 --datadir $DATADIR --corsdomain=* --ws --wsorigins="*" --wsaddr 0.0.0.0 --wsport 8546 $EXTRA_OPTS $@ 2>&1