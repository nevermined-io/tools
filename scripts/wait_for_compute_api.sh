#!/bin/bash

RETRY_COUNT=0
HTTP_CODE=0
COMPUTE_API_URL=http://localhost:8050

printf "Waiting for compute api to be running at $COMPUTE_API_URL\n"
until [ $HTTP_CODE -eq 200 ] || [ $RETRY_COUNT -eq 120 ]; do
  HTTP_CODE=$(curl -s -o /dev/null -w ''%{http_code}'' $COMPUTE_API_URL)
  if [ $HTTP_CODE -eq 200 ]; then
    break
  fi
  printf "."
  sleep 10
  let RETRY_COUNT=RETRY_COUNT+1
done

if [ $HTTP_CODE -ne 200 ]; then
  echo "Waited for more than two minutes, but the compute api is still not running"
  exit 1
fi
