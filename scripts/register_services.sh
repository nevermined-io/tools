#!/usr/bin/env bash

RETRY_COUNT=0
HTTP_CODE=0
CONTROL_CENTER_URL=http://localhost:3020

until [ $HTTP_CODE -eq 200 ] || [ $RETRY_COUNT -eq 240 ]; do
  HTTP_CODE=$(curl -s -o /dev/null -w ''%{http_code}'' $CONTROL_CENTER_URL)
  if [ $HTTP_CODE -eq 200 ]; then
    TOKEN=$(curl -X POST "${CONTROL_CENTER_URL}/api/auth/login" -H  "accept: text/html" -H  "Content-Type: application/x-www-form-urlencoded" -d "username=admin&password=admin")
    curl -X POST "${CONTROL_CENTER_URL}/api/system/service" -H  "accept: */*" -H  "auth: ${TOKEN}" -H  "Content-Type: application/x-www-form-urlencoded" -d "url=http%3A%2F%2Flocalhost%3A5000&serviceType=Metadata&description=Metadata%20tools"
    curl -X POST "${CONTROL_CENTER_URL}/api/system/service" -H  "accept: */*" -H  "auth: ${TOKEN}" -H  "Content-Type: application/x-www-form-urlencoded" -d "url=http%3A%2F%2Flocalhost%3A8030&serviceType=Gateway&description=Gateway%20tools"
    curl -X POST "${CONTROL_CENTER_URL}/api/system/service" -H  "accept: */*" -H  "auth: ${TOKEN}" -H  "Content-Type: application/x-www-form-urlencoded" -d "url=http%3A%2F%2Flocalhost%3A3001&serviceType=Faucet&description=Faucet%20tools"
    break
  fi
  printf "Waiting for control center api to be running at $CONTROL_CENTER_URL\n"
  sleep 10
  let RETRY_COUNT=RETRY_COUNT+1
done

if [ $HTTP_CODE -ne 200 ]; then
  echo "Waited for more than two minutes, but the control center api is still not running"
  exit 1
fi



