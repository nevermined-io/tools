#!/bin/bash

RETRY_COUNT=0
COMMAND_STATUS=1
NEVERMINED_HOME=${NEVERMINED_HOME:-"${HOME}/.nevermined"}
KEEPER_ARTIFACTS_FOLDER=${KEEPER_ARTIFACTS_FOLDER:-"${NEVERMINED_HOME}/nevermined-contracts/artifacts"}

until [ $COMMAND_STATUS -eq 0 ] || [ $RETRY_COUNT -eq 120 ]; do
  cat $KEEPER_ARTIFACTS_FOLDER/ready
  COMMAND_STATUS=$?
  if [ $COMMAND_STATUS -eq 0 ]; then
    rm -f "${KEEPER_ARTIFACTS_FOLDER}/!(|*.${KEEPER_NETWORK_NAME}.json|ready|)"
    break
  fi
  sleep 5
  let RETRY_COUNT=RETRY_COUNT+1
done

if [ $COMMAND_STATUS -ne 0 ]; then
  echo "Waited for more than two minutes, but contracts have not been migrated yet. Did you run an Ethereum RPC client and the migration script?"
  exit 1
fi
