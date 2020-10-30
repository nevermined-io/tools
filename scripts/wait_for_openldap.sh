#!/usr/bin/env bash
set -emo pipefail

export LC_ALL=en_US.UTF-8
SLAPD_READY=0
RETRY_COUNT=0

__PWD=$PWD
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
__PARENT_DIR=$(dirname $__DIR)


if [[ -f $__PARENT_DIR/scripts/constants.rc ]]; then
    echo -e "Loading config from $__PARENT_DIR/scripts/constants.rc"
    set -o allexport
    source $__PARENT_DIR/scripts/constants.rc
    set +o allexport
fi

set +e
until [ $SLAPD_READY -eq 1 ] || [ $RETRY_COUNT -eq 60 ]; do
  nc -z localhost $SLAPD_LOCAL_PORT
  if [ $? -eq 0 ]; then
    echo "OpenLdap ready!"
    SLAPD_READY=1
    break
  fi
  printf "Waiting for slapd to be running at port $SLAPD_LOCAL_PORT\n"
  sleep 30
  let RETRY_COUNT=RETRY_COUNT+1
done
set -e

if [ $SLAPD_READY -ne 1 ]; then
  echo "Waited for more than three minutes, but openldap is still not running"
  exit 1
fi

if [ "$LDAP_PRELOAD_DATA" = "true" ]; then
  for file_path in $(docker exec openldap bash -c "ls /etc/ldap.dist/data-preloading/*.ldif" | tr -d '\r'); do
    sleep 10
    printf "Preloading OpenLdap data $file_path\n"
    docker exec openldap ldapadd -h localhost -p 389 -x -w $SLAPD_PASSWORD  -D "$SLAPD_ADMIN" -f $file_path
  done

fi
