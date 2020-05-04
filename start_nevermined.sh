#!/usr/bin/env bash
IP="localhost"
optspec=":-:"
while getopts "$optspec" optchar; do
    case "${optchar}" in
           -)
           case "${OPTARG}" in
                exposeip)
                    IP="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                 ;;
            esac;;
    esac
done

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
export GATEWAY_ENV_FILE="${DIR}/gateway.env"

# Patch $DIR if spaces (GATEWAY_ENV_FILE does not need patch)
DIR="${DIR/ /\\ }"
COMPOSE_DIR="${DIR}/compose-files"

# Default versions of Metadata API, Gateway, Keeper Contracts and Commons
export METADATA_VERSION=${METADATA_VERSION:-latest}
export GATEWAY_VERSION=${GATEWAY_VERSION:-v0.9.5}
export EVENTS_HANDLER_VERSION=${EVENTS_HANDLER_VERSION:-v0.4.7}
export KEEPER_VERSION=${KEEPER_VERSION:-latest}
export FAUCET_VERSION=${FAUCET_VERSION:-v0.3.4}
export COMMONS_SERVER_VERSION=${COMMONS_SERVER_VERSION:-v2.3.1}
export COMMONS_CLIENT_VERSION=${COMMONS_CLIENT_VERSION:-v2.3.1}

export COMPOSE_UP_OPTIONS=${COMPOSE_UP_OPTIONS:""}


export PARITY_IMAGE="parity/parity:v2.5.7-stable"

export PROJECT_NAME="nevermined"
export FORCEPULL="false"

# Local filesystem artifacts
export NEVERMINED_HOME="${HOME}/.nevermined"

# keeper options
export KEEPER_OWNER_ROLE_ADDRESS="${KEEPER_OWNER_ROLE_ADDRESS}"
export KEEPER_DEPLOY_CONTRACTS="true"
export KEEPER_ARTIFACTS_FOLDER="${NEVERMINED_HOME}/nevermined-contracts/artifacts"
# Specify which ethereum client to run or connect to: development, integration or staging
export KEEPER_NETWORK_NAME="spree"
export NODE_COMPOSE_FILE="${COMPOSE_DIR}/nodes/spree_node.yml"

# Ganache specific option, these two options have no effect when not running ganache-cli
export GANACHE_DATABASE_PATH="${DIR}"
export GANACHE_REUSE_DATABASE="false"

# Specify the ethereum default RPC container provider
if [ ${IP} = "localhost" ]; then
    export KEEPER_RPC_HOST="keeper-node"
else
    export KEEPER_RPC_HOST=${IP}
fi
export KEEPER_RPC_PORT="8545"
export KEEPER_RPC_URL="http://"${KEEPER_RPC_HOST}:${KEEPER_RPC_PORT}
# Use this seed only on Spree! (Spree is the default.)
export KEEPER_MNEMONIC="taxi music thumb unique chat sand crew more leg another off lamp"

# Enable acl-contract validation in Secret-store
export CONFIGURE_ACL="true"
export ACL_CONTRACT_ADDRESS=""

# Default MetadataAPI parameters: use Elasticsearch
export DB_MODULE="elasticsearch"
export DB_HOSTNAME="172.15.0.11"
export DB_PORT="9200"
export DB_USERNAME="elastic"
export DB_PASSWORD="changeme"
export DB_SSL="false"
export DB_VERIFY_CERTS="false"
export DB_CA_CERTS=""
export DB_CLIENT_KEY=""
export DB_CLIENT_CERT=""
CHECK_ELASTIC_VM_COUNT=true

export GATEWAY_WORKERS=${GATEWAY_WORKERS:-5}
export GATEWAY_LOG_LEVEL="INFO"
export EVENTS_HANDLER_LOG_LEVEL="INFO"

export GATEWAY_IPFS_GATEWAY=https://ipfs.oceanprotocol.com

# Set a valid parity address and password to have seamless interaction with the `keeper`
# it has to exist on the secret store signing node and as well on the keeper node
export PROVIDER_ADDRESS=0x068ed00cf0441e4829d9784fcbe7b9e26d4bd8d0
export PROVIDER_PASSWORD=secret
export PROVIDER_KEYFILE="/accounts/provider.json"
export ACCOUNTS_FOLDER="../accounts"
if [ ${IP} = "localhost" ]; then
    export SECRET_STORE_URL=http://secret-store:12001
    export SIGNING_NODE_URL=http://secret-store-signing-node:8545
    export METADATA_URI=http://metadata:5000
    export FAUCET_URL=http://localhost:3001
    export COMMONS_SERVER_URL=http://localhost:4000
    export COMMONS_CLIENT_URL=http://localhost:3000
    export COMMONS_KEEPER_RPC_HOST=http://localhost:8545
    export COMMONS_SECRET_STORE_URL=http://localhost:12001
    export GATEWAY_URL=http://localhost:8030
else
    export SECRET_STORE_URL=http://${IP}:12001
    export SIGNING_NODE_URL=http://${IP}:8545
    export METADATA_URI=http://${IP}:5000
    export FAUCET_URL=http://${IP}:3001
    export COMMONS_SERVER_URL=http://${IP}:4000
    export COMMONS_CLIENT_URL=http://${IP}:3000
    export COMMONS_KEEPER_RPC_HOST=http://${IP}:8545
    export COMMONS_SECRET_STORE_URL=http://${IP}:12001
    export GATEWAY_URL=http://${IP}:8030
fi
# Default Faucet options
export FAUCET_TIMESPAN=${FAUCET_TIMESPAN:-24}

#commons
export COMMONS_GATEWAY_URL=${GATEWAY_URL}
export COMMONS_METADATA_URI=${METADATA_URI}
export COMMONS_FAUCET_URL=${FAUCET_URL}
export COMMONS_IPFS_GATEWAY_URI=https://ipfs.oceanprotocol.com
export COMMONS_IPFS_NODE_URI=https://ipfs.oceanprotocol.com:443

#export OPERATOR_SERVICE_URL=http://127.0.0.1:8050
export OPERATOR_SERVICE_URL=https://operator-api.operator.dev-ocean.com

# Export User UID and GID
export LOCAL_USER_ID=$(id -u)
export LOCAL_GROUP_ID=$(id -g)


#add metadata to /etc/hosts

if [ ${IP} = "localhost" ]; then
	if grep -q "metadata" /etc/hosts; then
    		echo "metadata exists"
	else
    		echo "127.0.0.1 metadata" | sudo tee -a /etc/hosts
	fi
fi

# colors
COLOR_R="\033[0;31m"    # red
COLOR_G="\033[0;32m"    # green
COLOR_Y="\033[0;33m"    # yellow
COLOR_B="\033[0;34m"    # blue
COLOR_M="\033[0;35m"    # magenta
COLOR_C="\033[0;36m"    # cyan

# reset
COLOR_RESET="\033[00m"

function get_acl_address {
    # detect keeper version
    local version="${1:-latest}"

    # sesarch in the file for the keeper version
    line=$(grep "^${version}=" "${DIR}/ACL/${KEEPER_NETWORK_NAME}_addresses.txt")
    # set address
    address="${line##*=}"

    # if address is still empty
    if [ -z "${address}" ]; then
      # fetch from latest line
      line=$(grep "^latest=" "${DIR}/ACL/${KEEPER_NETWORK_NAME}_addresses.txt")
      # set address
      address="${line##*=}"
    fi

    echo "${address}"
}

function show_banner {
    local output=$(cat .banner)
    echo -e "$COLOR_B$output$COLOR_RESET"
    echo ""
}

function configure_secret_store {
    # restore default secret store config (Issue #126)
    if [ -e "$DIR/networks/secret-store/config/config.toml.save" ]; then
        cp "$DIR/networks/secret-store/config/config.toml.save" \
           "$DIR/networks/secret-store/config/config.toml"
    fi
}

function check_if_owned_by_root {
    if [ -d "$NEVERMINED_HOME" ]; then
        uid=$(ls -nd "$NEVERMINED_HOME" | awk '{print $3;}')
        if [ "$uid" = "0" ]; then
            printf $COLOR_R"WARN: $NEVERMINED_HOME is owned by root\n"$COLOR_RESET >&2
        else
            uid=$(ls -nd "$KEEPER_ARTIFACTS_FOLDER" | awk '{print $3;}')
            if [ "$uid" = "0" ]; then
                printf $COLOR_R"WARN: $KEEPER_ARTIFACTS_FOLDER is owned by root\n"$COLOR_RESET >&2
            fi
        fi
    fi
}

function clean_local_contracts {
    rm -f "${KEEPER_ARTIFACTS_FOLDER}/ready"
    rm -f "${KEEPER_ARTIFACTS_FOLDER}/*.spree.json"
    rm -f "${KEEPER_ARTIFACTS_FOLDER}/*.development.json"
}

function check_max_map_count {
  vm_max_map_count=$(docker run --rm busybox sysctl -q vm.max_map_count)
  vm_max_map_count=${vm_max_map_count##* }
  vm_max_map_count=262144
  if [ $vm_max_map_count -lt 262144 ]; then
    printf $COLOR_R'vm.max_map_count current kernel value ($vm_max_map_count) is too low for Elasticsearch\n'$COLOR_RESET
    printf $COLOR_R'You must update vm.max_map_count to at least 262144\n'$COLOR_RESET
    printf $COLOR_R'Please refer to https://www.elastic.co/guide/en/elasticsearch/reference/6.6/vm-max-map-count.html\n'$COLOR_RESET
    exit 1
  fi
}

check_if_owned_by_root
show_banner

COMPOSE_FILES=""
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/dashboard.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/nevermined_contracts.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/network_volumes.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/commons.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/metadata_elasticsearch.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/gateway.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/events_handler.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/secret_store.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/secret_store_signing_node.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/faucet.yml"
DOCKER_COMPOSE_EXTRA_OPTS="${DOCKER_COMPOSE_EXTRA_OPTS:-}"

while :; do
    case $1 in
        --exposeip)
	   ;;
        #################################################
        # Log level
        #################################################
        --debug)
            export GATEWAY_LOG_LEVEL="DEBUG"
            export EVENTS_HANDLER_LOG_LEVEL="DEBUG"
            ;;
        #################################################
        # Log level
        #################################################
        --deattached)
            echo -e "Running containers in de-attached mode"
            export COMPOSE_UP_OPTIONS="$COMPOSE_UP_OPTIONS -d"
            ;;
        #################################################
        # Disable color
        #################################################
        --no-ansi)
            DOCKER_COMPOSE_EXTRA_OPTS+=" --no-ansi"
            unset COLOR_R COLOR_G COLOR_Y COLOR_B COLOR_M COLOR_C COLOR_RESET
            ;;
        #################################################
        # Version switches
        #################################################
        --latest)
            export METADATA_VERSION="latest"
            export GATEWAY_VERSION="latest"
            export EVENTS_HANDLER_VERSION="latest"
            export KEEPER_VERSION="latest"
            # TODO: Change label on Docker to refer `latest` to `master`
            export FAUCET_VERSION="latest"
	          export COMMONS_SERVER_VERSION="latest"
	          export COMMONS_CLIENT_VERSION="latest"
            printf $COLOR_Y'Switched to latest components...\n\n'$COLOR_RESET
            ;;
        --force-pull)
            export FORCEPULL="true"
            printf $COLOR_Y'Pulling the latest revision of the used Docker images...\n\n'$COLOR_RESET
            ;;
        #################################################
        # Exclude switches
        #################################################
	    --no-commons)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/commons.yml/}"
            printf $COLOR_Y'Starting without Commons...\n\n'$COLOR_RESET
            ;;
        --no-events-handler)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/events_handler.yml/}"
            printf $COLOR_Y'Starting without Events Handler...\n\n'$COLOR_RESET
            ;;
        --no-gateway)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/gateway.yml/}"
            printf $COLOR_Y'Starting without Gateway...\n\n'$COLOR_RESET
            ;;
        --no-metadata)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/metadata_elasticsearch.yml/}"
            printf $COLOR_Y'Starting without Metadata API...\n\n'$COLOR_RESET
            ;;
        --no-secret-store)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/secret_store.yml/}"
            printf $COLOR_Y'Starting without Secret Store...\n\n'$COLOR_RESET
            ;;
        --no-faucet)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/faucet.yml/}"
            printf $COLOR_Y'Starting without Faucet...\n\n'$COLOR_RESET
            ;;
        --no-dashboard)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/dashboard.yml/}"
            printf $COLOR_Y'Starting without Dashboard ...\n\n'$COLOR_RESET
            ;;
        --no-acl-contract)
            export CONFIGURE_ACL="false"
            printf $COLOR_Y'Disabling acl validation in secret-store...\n\n'$COLOR_RESET
            ;;
        #################################################
        # Only Secret Store
        #################################################
        --only-secret-store)
            COMPOSE_FILES=""
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/network_volumes.yml"
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/secret_store.yml"
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/secret_store_signing_node.yml"
            NODE_COMPOSE_FILE=""
            printf $COLOR_Y'Starting only Secret Store...\n\n'$COLOR_RESET
            ;;
        #################################################
        # MongoDB
        #################################################
        --mongodb)
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/metadata_mongodb.yml"
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/metadata_elasticsearch.yml/}"
            CHECK_ELASTIC_VM_COUNT=false
            export DB_MODULE="mongodb"
            export DB_HOSTNAME="mongodb"
            export DB_PORT="27017"
            printf $COLOR_Y'Starting with MongoDB...\n\n'$COLOR_RESET
            ;;
        #################################################
        # Contract/Storage switches
        #################################################
        --reuse-ganache-database)
            export GANACHE_REUSE_DATABASE="true"
            printf $COLOR_Y'Starting and reusing the database...\n\n'$COLOR_RESET
            ;;
        #################################################
        # Node type switches
        #################################################
        # spins up a new ganache blockchain
        --local-ganache-node)
            export NODE_COMPOSE_FILE="${COMPOSE_DIR}/nodes/ganache_node.yml"
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/secret_store.yml/}"
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/secret_store_signing_node.yml/}"
            export KEEPER_MNEMONIC=''
            export KEEPER_NETWORK_NAME="development"
            printf $COLOR_Y'Starting with local Ganache node...\n\n'$COLOR_RESET
            printf $COLOR_Y'Starting without Secret Store...\n\n'$COLOR_RESET
            printf $COLOR_Y'Starting without Secret Store signing node...\n\n'$COLOR_RESET
            ;;
        # connects you to staging network
        --local-staging-node)
            export NODE_COMPOSE_FILE="${COMPOSE_DIR}/nodes/staging_node.yml"
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/nevermined_contracts.yml/}"
            export KEEPER_MNEMONIC=''
            export KEEPER_NETWORK_NAME="staging"
            export KEEPER_DEPLOY_CONTRACTS="false"
            export ACL_CONTRACT_ADDRESS="$(get_acl_address ${KEEPER_VERSION})"
            printf $COLOR_Y'Starting with local Staging node...\n\n'$COLOR_RESET
            ;;
        # connects you to integration network
        --local-integration-node)
            export NODE_COMPOSE_FILE="${COMPOSE_DIR}/nodes/integration.yml"
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/nevermined_contracts.yml/}"
            export KEEPER_MNEMONIC=''
            export KEEPER_NETWORK_NAME="integration"
            export KEEPER_DEPLOY_CONTRACTS="false"
            export ACL_CONTRACT_ADDRESS="$(get_acl_address ${KEEPER_VERSION})"
            printf $COLOR_Y'Starting with local Integration node...\n\n'$COLOR_RESET
            ;;
        # connects you to production network
        --local-production-node)
            export NODE_COMPOSE_FILE="${COMPOSE_DIR}/nodes/production_node.yml"
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/nevermined_contracts.yml/}"
            export KEEPER_MNEMONIC=''
            export KEEPER_NETWORK_NAME="production"
            export KEEPER_DEPLOY_CONTRACTS="false"
            export ACL_CONTRACT_ADDRESS="$(get_acl_address ${KEEPER_VERSION})"
            printf $COLOR_Y'Starting with local Production node...\n\n'$COLOR_RESET
            printf $COLOR_Y'Starting without Secret Store...\n\n'$COLOR_RESET
            ;;
        # spins up spree local testnet
        --local-spree-node)
            export NODE_COMPOSE_FILE="${COMPOSE_DIR}/nodes/spree_node.yml"
            # use this seed only on spree!
            export KEEPER_MNEMONIC="taxi music thumb unique chat sand crew more leg another off lamp"
            export KEEPER_NETWORK_NAME="spree"
            printf $COLOR_Y'Starting with local Spree node...\n\n'$COLOR_RESET
            ;;
        --local-spree-no-deploy)
            export NODE_COMPOSE_FILE="${COMPOSE_DIR}/nodes/spree_node.yml"
            # use this seed only on spree!
            export KEEPER_MNEMONIC="taxi music thumb unique chat sand crew more leg another off lamp"
            export KEEPER_NETWORK_NAME="spree"
            export KEEPER_DEPLOY_CONTRACTS="false"
	    printf $COLOR_Y'Starting with local Spree node, and keeping existing contracts (no deployment)...\n\n'$COLOR_RESET
            ;;
        #################################################
        # Cleaning switches
        #################################################
        --purge)
            printf $COLOR_R'Doing a deep clean ...\n\n'$COLOR_RESET
            eval docker-compose --project-name=$PROJECT_NAME "$COMPOSE_FILES" -f "${NODE_COMPOSE_FILE}" down
            docker network rm ${PROJECT_NAME}_default || true
            docker network rm ${PROJECT_NAME}_backend || true
            docker network rm ${PROJECT_NAME}_secretstore || true
            docker volume rm ${PROJECT_NAME}_secret-store || true
            docker volume rm ${PROJECT_NAME}_keeper-node-integration || true
            docker volume rm ${PROJECT_NAME}_keeper-node-staging || true
            docker volume rm ${PROJECT_NAME}_keeper-node-production || true
            docker volume rm ${PROJECT_NAME}_faucet || true
            read -p "Are you sure you want to delete $KEEPER_ARTIFACTS_FOLDER? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                rm -rf "${KEEPER_ARTIFACTS_FOLDER}"
            fi
            ;;
        --) # End of all options.
            shift
            break
            ;;
        -?*)
            printf $COLOR_R'WARN: Unknown option (ignored): %s\n'$COLOR_RESET "$1" >&2
            break
            ;;
        *)
            [ ${CHECK_ELASTIC_VM_COUNT} = "true" ] && check_max_map_count
            printf $COLOR_Y'Starting Nevermined...\n\n'$COLOR_RESET
            configure_secret_store
            [ -n "${NODE_COMPOSE_FILE}" ] && COMPOSE_FILES+=" -f ${NODE_COMPOSE_FILE}"
            [ ${KEEPER_DEPLOY_CONTRACTS} = "true" ] && clean_local_contracts
            [ ${FORCEPULL} = "true" ] && eval docker-compose "$DOCKER_COMPOSE_EXTRA_OPTS" --project-name=$PROJECT_NAME "$COMPOSE_FILES" pull
            eval docker-compose "$DOCKER_COMPOSE_EXTRA_OPTS" --project-name=$PROJECT_NAME "$COMPOSE_FILES" up $COMPOSE_UP_OPTIONS --remove-orphans
            break
    esac
    shift
done