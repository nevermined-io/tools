#!/usr/bin/env bash
set -emo pipefail

RETRIES=60
DURATION=10
RETRY_COUNT=0
READY=0

function usage() {
echo "
USAGE: $0 URL [OPTIONS]

OPTIONS:
    -r   The number of times to retry. Defaults to 60
    -d   The number of seconds to wait between retries. Defaults to 10
"
}

if [ "$#" -lt 1 ]; then
  echo "URL parameter missing"
  usage
  exit 0
else
  URL=$1
fi

OPTIND=2
while getopts "r:d:" opt; do
  case "$opt" in
  r|retries)
    RETRIES=$OPTARG
    ;;
  d|duration)
    DURATION=$OPTARG
    ;;
  esac
done

set +e
until [ $RETRY_COUNT -eq $RETRIES ]; do
  curl $URL -s -o /dev/null
  if [ $? -eq 0 ]; then
    READY=1
    break
  fi
  echo "Waiting for $URL to be online"
  sleep $DURATION
  let RETRY_COUNT=RETRY_COUNT+1
done
set -e

if [ $READY -ne 1 ]; then
  echo "Waited for more than $((DURATION*RETRIES))s for $URL to be running. Failing..."
  exit 1
fi

echo "$URL online..."