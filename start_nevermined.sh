#!/usr/bin/env bash
set -emo pipefail

export LC_ALL=en_US.UTF-8

__PWD=$PWD
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
__PARENT_DIR=$(dirname $__DIR)


if [[ -f $__DIR/scripts/constants.rc ]]; then
    echo -e "Loading config from $__DIR/scripts/constants.rc"
    set -o allexport
    source $__DIR/scripts/constants.rc
    set +o allexport
fi



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

# Default versions of Metadata API, Gateway, Keeper Contracts and Marketplace
export METADATA_VERSION=${METADATA_VERSION:-v0.4.0}
export CONTROL_CENTER_BACKEND_VERSION=${CONTROL_CENTER_BACKEND_VERSION:-latest}
export CONTROL_CENTER_UI_VERSION=${CONTROL_CENTER_UI_VERSION:-latest}
export GATEWAY_VERSION=${GATEWAY_VERSION:-v0.9.1}
export EVENTS_HANDLER_VERSION=${EVENTS_HANDLER_VERSION:-v0.2.3}
export KEEPER_VERSION=${KEEPER_VERSION:-v1.3.0}
export FAUCET_VERSION=${FAUCET_VERSION:-v0.2.2}
export MARKETPLACE_SERVER_VERSION=${MARKETPLACE_SERVER_VERSION:-latest}
export MARKETPLACE_CLIENT_VERSION=${MARKETPLACE_CLIENT_VERSION:-latest}
export BAZAART_SERVER_VERSION=${BAZAART_SERVER_VERSION:-latest}
export BAZAART_CLIENT_VERSION=${BAZAART_CLIENT_VERSION:-latest}
export COMPUTE_API_VERSION=${COMPUTE_API_VERSION:-v0.3.0}
export OPENETH_IMAGE=${OPENETH_IMAGE:-openethereum/openethereum}
export OPENETH_VERSION=${OPENETH_VERSION:-v3.2.6}
export SS_VERSION=${SS_VERSION:-latest}
export SS_IMAGE=${SS_IMAGE:-neverminedio/secret-store}
export MINIO_VERSION=${MINIO_VERSION:-latest}
export KEEPER_PATH=${KEEPER_PATH:-/usr/local/nevermined-contracts}

export COMPOSE_UP_OPTIONS=${COMPOSE_UP_OPTIONS:""}

export PROJECT_NAME="nevermined"
export FORCEPULL="false"
export COMPUTE_START="false"
export CONTROL_CENTER="false"
export LDAP_START="false"


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
export KEEPER_MNEMONIC="${KEEPER_MNEMONIC:-taxi music thumb unique chat sand crew more leg another off lamp}"

# Enable acl-contract validation in Secret-store
export CONFIGURE_ACL="true"
export ACL_CONTRACT_ADDRESS=""

# Default MetadataAPI parameters: use Elasticsearch
export DB_MODULE="elasticsearch"
export DB_HOSTNAME="elasticsearch"
export DB_PORT="9200"
export DB_URI="http://$DB_HOSTNAME:$DB_PORT/"
export DB_USERNAME="elastic"
export DB_PASSWORD="changeme"
export DB_FAUCET="faucetdb"
export DB_SSL="false"
export DB_VERIFY_CERTS="false"
export DB_CA_CERTS=""
export DB_CLIENT_KEY=""
export DB_CLIENT_CERT=""
CHECK_ELASTIC_VM_COUNT=true

# TODO: Disable this when work on arweave is done
# Default external MetadataDB parameters with arweave
# export DB_MODULE_EXTERNAL="arweave"
# export DB_HOSTNAME_EXTERNAL="https://arweave.net"
# export DB_PORT_EXTERNAL="443"
# export DB_WALLET_FILE_PATH_EXTERNAL="./tests/resources/arweave-key-A1t0391IV20zpoKjhftup1ROdWBjBRGZrhx8pe55Uwc.json"

# S3 integration
export AWS_ACCESS_KEY="minioadmin"
export AWS_SECRET_ACCESS_KEY="minioadmin"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_ENDPOINT_URL="http://nevermined-minio:9000"

# minio

export MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY:-minioadmin}
export MINIO_SECRET_KEY=${MINIO_SECRET_KEY:-minioadmin}

export GATEWAY_WORKERS=${GATEWAY_WORKERS:-5}
export GATEWAY_LOG_LEVEL="INFO"
# allow oauth without https
export AUTHLIB_INSECURE_TRANSPORT=true

export EVENTS_HANDLER_LOG_LEVEL="INFO"
export COMPUTE_API_LOG_LEVEL="ERROR"
export COMPUTE_NAMESPACE="nevermined-compute"

export GATEWAY_IPFS_GATEWAY=https://ipfs.nevermined.io

# Set a valid parity address and password to have seamless interaction with the `keeper`
# it has to exist on the secret store signing node and as well on the keeper node
export PROVIDER_ADDRESS=0x068ed00cf0441e4829d9784fcbe7b9e26d4bd8d0
export PROVIDER_PASSWORD=secret
# GATEWAY Wallet
export PROVIDER_KEYFILE="/accounts/provider.json"
# GATEWAY RSA KEY FILES
export RSA_PRIVKEY_FILE="/accounts/rsa_priv_key.pem"
export RSA_PUBKEY_FILE="/accounts/rsa_pub_key.pem"

export LDAP_PREPOPULATE_FOLDER="${DIR}/${LDAP_DATA_FOLDER}"

export ACCOUNTS_FOLDER="../accounts"
if [ ${IP} = "localhost" ]; then
    export SECRET_STORE_URL=http://secret-store:12001
    export SIGNING_NODE_URL=http://secret-store-signing-node:8545
    export METADATA_URI=http://172.17.0.1:5000
    export CONTROL_CENTER_BACKEND_URI=http://localhost:3020
    export CONTROL_CENTER_UI_URI=http://localhost:3021
    export FAUCET_URL=http://faucet:3001
    export MARKETPLACE_SERVER_URL=http://localhost:4000
    export MARKETPLACE_CLIENT_URL=http://localhost:3000
    export MARKETPLACE_KEEPER_RPC_HOST=http://localhost:8545
    export MARKETPLACE_SECRET_STORE_URL=http://localhost:12001
    export BAZAART_SERVER_URL=http://localhost:4002
    export BAZAART_CLIENT_URL=http://localhost:3002
    export BAZAART_KEEPER_RPC_HOST=http://172.17.0.1:8545
    export BAZAART_SECRET_STORE_URL=http://localhost:12001
    export GATEWAY_URL=http://172.17.0.1:8030
    export COMPUTE_API_URL=http://172.17.0.1:8050
    export MINIO_URL=http://172.17.0.1:9000

else
    export SECRET_STORE_URL=http://${IP}:12001
    export SIGNING_NODE_URL=http://${IP}:8545
    export METADATA_URI=http://${IP}:5000
    export CONTROL_CENTER_BACKEND_URI=http://${IP}:3020
    export CONTROL_CENTER_UI_URI=http://${IP}:3021
    export FAUCET_URL=http://${IP}:3001
    export MARKETPLACE_SERVER_URL=http://${IP}:4000
    export MARKETPLACE_CLIENT_URL=http://${IP}:3000
    export MARKETPLACE_KEEPER_RPC_HOST=http://${IP}:8545
    export MARKETPLACE_SECRET_STORE_URL=http://${IP}:12001
    export BAZAART_SERVER_URL=http://${IP}:4002
    export BAZAART_CLIENT_URL=http://${IP}:3002
    export BAZAART_KEEPER_RPC_HOST=http://${IP}:8545
    export BAZAART_SECRET_STORE_URL=http://${IP}:12001
    export GATEWAY_URL=http://${IP}:8030
    export COMPUTE_API_URL=http://${IP}:8050
    export MINIO_URL=http://${IP}:9000

fi

# Default Faucet options
export FAUCET_TIMESPAN=${FAUCET_TIMESPAN:-24}
export FAUCET_PRIVATE_KEY=${FAUCET_PRIVATE_KEY:-dcb15ba5d2caf586c22f0414f527201d2fb2424c92ced3efacd742a34e5b0db2}

# Marketplace
export MARKETPLACE_GATEWAY_URL=${GATEWAY_URL}
export MARKETPLACE_METADATA_URI=${METADATA_URI}
export MARKETPLACE_FAUCET_URL=${FAUCET_URL}
export MARKETPLACE_IPFS_GATEWAY_URI=https://ipfs.ipdb.com
export MARKETPLACE_IPFS_NODE_URI=https://ipfs.ipdb.com:443


# Bazaart
export BAZAART_GATEWAY_URL=${GATEWAY_URL}
export BAZAART_METADATA_URI=${METADATA_URI}
export BAZAART_FAUCET_URL=${FAUCET_URL}
export BAZAART_IPFS_GATEWAY_URI=https://ipfs.ipdb.com
export BAZAART_IPFS_NODE_URI=https://ipfs.ipdb.com:443
export BAZAART_S3_ACCESS_KEY_ID='minioadmin'
export BAZAART_S3_SECRET_ACCESS_KEY='minioadmin'
export BAZAART_S3_ENDPOINT=${MINIO_URL}

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

function print_log() {
    title=$1
    while read line
    do
        printf "$FORMAT_LOG" $title "$line"
    done
}


function start_compute_api {
    eval ./scripts/setup_minikube.sh

    # start the compute-api
    COMPUTE_API_DEPLOYMENT="${DIR}/scripts/compute-api-deployment.yaml"
    envsubst < $COMPUTE_API_DEPLOYMENT | kubectl apply -n $COMPUTE_NAMESPACE -f -

    # wait for service and setup port forwarding
    kubectl -n $COMPUTE_NAMESPACE wait --for=condition=ready pod -l app=compute-api-pod --timeout=180s
    kubectl -n $COMPUTE_NAMESPACE port-forward --address 0.0.0.0 deployment/compute-api-deployment 8050:8050 &
    echo -e "${COLOR_G}Compute API running at: http://localhost:8050 ${COLOR_RESET}\n"

    # show logs for the compute-api pod
    kubectl -n $COMPUTE_NAMESPACE logs -f -l app=compute-api-pod &
}

function initialize_openldap {
    eval ./scripts/wait_for_openldap.sh
}

function register_services_control_center {
    eval ./scripts/register_services.sh
}

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

function cleanup_processes {
    list_descendants ()
    {
        local children=$(ps -o pid= --ppid "$1")

        for pid in $children
        do
            list_descendants "$pid"
        done

        echo "$children"
    }

    kill $(list_descendants $$)
}

check_if_owned_by_root
show_banner

COMPOSE_FILES=""
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/nevermined_contracts.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/network_volumes.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/marketplace.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/elasticsearch.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/metadata.yml"
COMPOSE_FILES+=" -f ${COMPOSE_DIR}/gateway.yml"
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
            export CONTROL_CENTER_BACKEND_VERSION="latest"
            export CONTROL_CENTER_UI_VERSION="latest"
            export GATEWAY_VERSION="latest"
            export EVENTS_HANDLER_VERSION="latest"
            export KEEPER_VERSION="latest"
            # TODO: Change label on Docker to refer `latest` to `master`
            export FAUCET_VERSION="latest"
	          export MARKETPLACE_SERVER_VERSION="latest"
	          export MARKETPLACE_CLIENT_VERSION="latest"
	          export COMPUTE_API_VERSION="latest"
            printf $COLOR_Y'Switched to latest components...\n\n'$COLOR_RESET
            ;;
        --force-pull)
            export FORCEPULL="true"
            printf $COLOR_Y'Pulling the latest revision of the used Docker images...\n\n'$COLOR_RESET
            ;;
        #################################################
        # Exclude switches
        #################################################
	    --no-marketplace)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/marketplace.yml/}"
            printf $COLOR_Y'Starting without Marketplace...\n\n'$COLOR_RESET
            ;;
        --no-gateway)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/gateway.yml/}"
            printf $COLOR_Y'Starting without Gateway...\n\n'$COLOR_RESET
            ;;
        --no-metadata)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/metadata.yml/}"
            printf $COLOR_Y'Starting without Metadata API...\n\n'$COLOR_RESET
            ;;
        --no-faucet)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/faucet.yml/}"
            printf $COLOR_Y'Starting without Faucet...\n\n'$COLOR_RESET
            ;;
        --no-elastic)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/elasticsearch.yml/}"
            printf $COLOR_Y'Starting without ElasticSearch...\n\n'$COLOR_RESET
            ;;
        --no-acl-contract)
            export CONFIGURE_ACL="false"
            printf $COLOR_Y'Disabling acl validation in secret-store...\n\n'$COLOR_RESET
            ;;
        --spree-embedded-contracts)
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/nevermined_contracts.yml/}"
            export OPENETH_IMAGE="neverminedio/contracts-spree"
            export OPENETH_VERSION=${KEEPER_VERSION}
            printf $COLOR_Y'Using embedded spree contracts...\n\n'$COLOR_RESET
            ;;
        --minio)
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/minio.yml"
            printf $COLOR_Y'Using minio...\n\n'$COLOR_RESET
            ;;
        --graph)
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/graph.yml"
            printf $COLOR_Y'Using The Graph...\n\n'$COLOR_RESET
            ;;
        --secret-store)
            # Enable Secret store
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/secret_store.yml"
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/secret_store_signing_node.yml"
            configure_secret_store
            printf $COLOR_Y'Starting with Secret Store...\n\n'$COLOR_RESET
            ;;
        --only-secret-store)
            COMPOSE_FILES=""
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/network_volumes.yml"
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/secret_store.yml"
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/secret_store_signing_node.yml"
            NODE_COMPOSE_FILE=""
            printf $COLOR_Y'Starting only Secret Store...\n\n'$COLOR_RESET
            ;;
        --bazaart)
            # Enable bazaart
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/bazaart.yml"
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/minio.yml"
            printf $COLOR_Y'Starting with Bazaart...\n\n'$COLOR_RESET
            ;;
        #################################################
        # MongoDB
        #################################################
        --mongodb)
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/metadata_mongodb.yml"
            COMPOSE_FILES="${COMPOSE_FILES/ -f ${COMPOSE_DIR}\/metadata.yml/}"
            CHECK_ELASTIC_VM_COUNT=false
            export DB_MODULE="mongodb"
            export DB_HOSTNAME="mongodb"
            export DB_PORT="27017"
            printf $COLOR_Y'Starting with MongoDB...\n\n'$COLOR_RESET
            ;;
        #################################################
        # Nevermined Compute
        #################################################
        --compute)
            printf $COLOR_Y'Starting with Compute stack...\n\n'$COLOR_RESET
            export COMPUTE_START="true"
            export COMPUTE_API_URL=http://172.17.0.1:8050
            ;;
        #################################################
        # OpenLdap
        #################################################
        --ldap)
            COMPOSE_FILES+=" -f ${COMPOSE_DIR}/openldap.yml"
            printf $COLOR_Y'Starting OpenLdap...\n\n'$COLOR_RESET
            echo "Loading LDIF from ${LDAP_PREPOPULATE_FOLDER}...\n\n"
            export LDAP_START="true"
            ;;
        #################################################
        # Events Handler
        #################################################
        --events-handler)
			COMPOSE_FILES+=" -f ${COMPOSE_DIR}/events_handler.yml"
            printf $COLOR_Y'Starting with Events Handler...\n\n'$COLOR_RESET
            ;;
        #################################################
        # Dashboard
        #################################################
        --dashboard)
			COMPOSE_FILES+=" -f ${COMPOSE_DIR}/dashboard.yml"
            printf $COLOR_Y'Starting with Dashboard ...\n\n'$COLOR_RESET
            ;;
        #################################################
        # Control center
        #################################################
        --control-center)
			COMPOSE_FILES+=" -f ${COMPOSE_DIR}/control_center_backend.yml"
			COMPOSE_FILES+=" -f ${COMPOSE_DIR}/control_center_ui.yml"
            export CONTROL_CENTER="true"
            printf $COLOR_Y'Starting with Control center ...\n\n'$COLOR_RESET
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
        # connects you to rinkeby testnet
        --local-rinkeby-node)
            export NODE_COMPOSE_FILE="${COMPOSE_DIR}/nodes/rinkeby_node.yml"
            # No contracts deployment, secret store & faucet
            export KEEPER_MNEMONIC=''
            export KEEPER_NETWORK_NAME="rinkeby"
            export KEEPER_DEPLOY_CONTRACTS="false"
            export ACL_CONTRACT_ADDRESS="$(get_acl_address ${KEEPER_VERSION})"
            printf $COLOR_Y'Starting with local Rinkeby node...\n\n'$COLOR_RESET
            printf $COLOR_Y'Starting without Secret Store ...\n\n'$COLOR_RESET
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
        --polygon)
            export KEEPER_NETWORK_NAME="polygon-localnet"
            export KEEPER_DEPLOY_CONTRACTS="false"
            export NODE_COMPOSE_FILE="${COMPOSE_DIR}/nodes/polygon_localnet.yml"
            printf $COLOR_Y'Starting with local Polygon node...\n\n'$COLOR_RESET
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
            docker volume rm ${PROJECT_NAME}_keeper-node-rinkeby || true
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
            [ -n "${NODE_COMPOSE_FILE}" ] && COMPOSE_FILES+=" -f ${NODE_COMPOSE_FILE}"
            [ ${KEEPER_DEPLOY_CONTRACTS} = "true" ] && clean_local_contracts
            [ ${FORCEPULL} = "true" ] && eval docker-compose "$DOCKER_COMPOSE_EXTRA_OPTS" --project-name=$PROJECT_NAME "$COMPOSE_FILES" pull
            eval docker-compose "$DOCKER_COMPOSE_EXTRA_OPTS" --project-name=$PROJECT_NAME "$COMPOSE_FILES" up $COMPOSE_UP_OPTIONS --remove-orphans &
            [ ${LDAP_START} = "true" ] && initialize_openldap 2>&1 | print_log "openldap" &
            [ ${CONTROL_CENTER} = "true" ] && register_services_control_center 2>&1 | print_log "services registered" &
            [ ${COMPUTE_START} = "true" ] && start_compute_api 2>&1 | print_log "minikube" &
            # give control back to docker-compose
            %1

            # kill all background jobs after docker-compose exits
            cleanup_processes

            break
    esac
    shift
done
