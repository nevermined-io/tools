#!/usr/bin/env bash
set -eo pipefail

export LC_ALL=en_US.UTF-8

__PWD=$PWD
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
__PARENT_DIR=$(dirname $__DIR)


if [[ -f $__DIR/constants.rc ]]; then
    echo -e "Loading config from $__DIR/constants.rc"
    set -o allexport
    source $__DIR/constants.rc
    set +o allexport
fi

MINIKUBE_VERSION=${MINIKUBE_VERSION:-v1.27.1}
KUBERNETES_VERSION=${KUBERNETES_VERSION:-1.21.2}
ARGO_WORKFLOWS_VERSION=${ARGO_WORKFLOWS_VERSION:-3.4.1}
INSTALL_KUBECTL=${INSTALL_KUBECTL:-false}
INSTALL_MINIKUBE=${INSTALL_MINIKUBE:-true}
INSTALL_ARGO=${INSTALL_ARGO:-true}
INSTALL_HELM=${INSTALL_HELM:-true}
MINIKUBE_RECREATE=${MINIKUBE_RECREATE:-true}
START_MINIKUBE=${START_MINIKUBE:-true}
CONFIGURE_K8S_COMPUTE=${CONFIGURE_K8S_COMPUTE:-true}
COMPUTE_NAMESPACE=${COMPUTE_NAMESPACE:-nvm-disc}
KEEPER_ARTIFACTS_FOLDER="${HOME}/nevermined-contracts/artifacts"
MINIKUBE_HOME="/usr/local/bin"
MINIKUBE_CMD="$MINIKUBE_HOME/minikube start --kubernetes-version=v$KUBERNETES_VERSION --mount=true --mount-string=$__PARENT_DIR/accounts:/accounts --driver=docker --network=host"

K="kubectl"
SUDO=""

PLATFORM=$(uname)
OS_NAME=$(cat /etc/os-release | awk -F '=' '/^NAME/{print $2}' | awk '{print $1}' | tr -d '"')

if [[ $PLATFORM == $LINUX ]]; then
  if [[ $OS_NAME =~ (Ubuntu|Debian) ]]; then
    DIST_TYPE="Ubuntu"
  elif [[ $OS_NAME =~ (CentOS|Fedora|Red Hat) ]]; then
    DIST_TYPE="CentOS"
  fi
fi
remove_unnecesary_contracts() {
    rm -f "${KEEPER_ARTIFACTS_FOLDER}/!(|*.${KEEPER_NETWORK_NAME}.json|ready|)"
}

main() {

  echo -e "${COLOR_M}"waiting for artifacts migration. This script should only be started after nevermined-tools"${COLOR_RESET}"
  eval $__DIR/wait_for_migration_keeper_artifacts.sh

  if [ "$INSTALL_KUBECTL" = true ]; then
    install_kubectl
  else
    K="minikube kubectl --"
    alias K=$K
    alias kubectl=$K
  fi

  if [ "$INSTALL_MINIKUBE" = true ]; then
    install_minikube
  fi

  if [ "$INSTALL_HELM" = true ]; then
    install_helm
  fi

  if [ "$START_MINIKUBE" = true ]; then
    set_minikube_parameters
    if [ "$MINIKUBE_RECREATE" = true ]; then
      reset_minikube
    else
        echo -e "Skipping minikube re-install by MINIKUBE_RECREATE env variable"
    fi
    start_minikube
  fi

  if ! $K get namespace $COMPUTE_NAMESPACE; then
    echo -e "Creating namespace $COMPUTE_NAMESPACE"
    $K create namespace $COMPUTE_NAMESPACE
  fi

  if [ "$INSTALL_ARGO" = true ]; then
    install_argo
  fi

  if [ "$CONFIGURE_K8S_COMPUTE" = true ]; then
    configure_nevermined_compute
  fi

}


#### Functions


# Set minikube startup parameters
set_minikube_parameters() {
    MINIKUBE_CMD=$MINIKUBE_CMD
}


install_kubectl() {

  # Installing kubectl if needed
  if ! [ -x "$(command -v kubectl)" ]; then
    echo -e "${COLOR_Y}Installing kubectl...${COLOR_RESET}"
    if [[ $PLATFORM == $OSX ]]; then

      if [ "$INSTALL_KUBECTL" = true ]; then
        brew install kubectl
      fi

    elif [[ $PLATFORM == $LINUX ]]; then

      if [[ $DIST_TYPE == "Ubuntu" ]]; then
        sudo swapoff -a
        sudo systemctl enable docker.service
        sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
        #curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
        echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
        sudo apt-get update
        sudo apt-get install -y kubectl socat conntrack kubeadm kubelet keepalived
        sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst
        sudo bash -c "echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables"
        sudo sysctl net.bridge.bridge-nf-call-iptables=1


      elif [[ $DIST_TYPE == "CentOS" ]]; then
        cp $__DIR/.kubenetes.repo /etc/yum.repos.d/kubernetes.repo
        sudo yum install -y kubectl socat conntrack kubeadm
        sudo bash -c "echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables"
      fi

      sudo addgroup libvirtd
      sudo adduser `id -un` kvm
      sudo adduser `id -un` libvirtd
      virsh list --all
    fi

    echo -e "${COLOR_G}[OK]${COLOR_RESET}"
  fi

}

install_minikube() {

  # Installing minikube if needed
  if ! [ -x "$(command -v minikube)" ] ; then
    echo -e "${COLOR_Y}Installing minikube...${COLOR_RESET}"
    if [[ $PLATFORM == $OSX ]]; then
      curl -Lo minikube https://storage.googleapis.com/minikube/releases/$MINIKUBE_VERSION/minikube-darwin-amd64 && chmod +x minikube && sudo mv minikube $MINIKUBE_HOME
    elif [[ $PLATFORM == $LINUX ]]; then
      curl -Lo minikube https://storage.googleapis.com/minikube/releases/$MINIKUBE_VERSION/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube $MINIKUBE_HOME
    fi

    minikube start

    # Temporary fix to be able to mount volumes
    $K -n kube-system patch pod storage-provisioner --patch '{"spec": {"containers": [{"name": "storage-provisioner","image": "gcr.io/k8s-minikube/storage-provisioner:latest"}]}}'
    $K apply -f $__DIR/admin-user.yaml
    $SUDO $MINIKUBE_HOME/minikube config set ShowBootstrapperDeprecationNotification false &&
    $SUDO $MINIKUBE_HOME/minikube config set WantUpdateNotification false &&
    $SUDO $MINIKUBE_HOME/minikube config set WantReportErrorPrompt false &&
    $SUDO $MINIKUBE_HOME/minikube config set WantKubectlDownloadMsg false
    echo -e "${COLOR_G}"Notice: minikube was successfully installed"${COLOR_RESET}"
  fi

}

start_minikube() {

  # start minikube with desired settings
  echo -e "${COLOR_M}"minikube will now try to start the local k8s cluster"${COLOR_RESET}"
  $MINIKUBE_CMD

  minikube_status=$($SUDO $MINIKUBE_HOME/minikube status | grep 'host:' | awk '{print $2}')

  if [[ $minikube_status == "Running" ]]; then
    echo -e "\n${COLOR_G}Minikube is up and Running!${COLOR_RESET}\n"
  else
    echo -e "${COLOR_R}Unable to start minikube. Please see errors above${COLOR_RESET}"
    return 1
  fi
}

install_argo() {
  
  if ! [ -x "$(command -v argo)" ]; then
    echo -e "${COLOR_Y}Installing Argo...${COLOR_RESET}"
    helm install -n $COMPUTE_NAMESPACE argo-workflows argo/argo-workflows 
    # $K apply -n $COMPUTE_NAMESPACE -f https://github.com/argoproj/argo-workflows/releases/download/v$ARGO_WORKFLOWS_VERSION/install.yaml

    echo -e "${COLOR_Y}Patch argo-server authentication...${COLOR_RESET}"
    # $K patch deployment argo-workflows-server -n $COMPUTE_NAMESPACE --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["server","--auth-mode=server"]}]'
      
    # Create Token
    $K create role argo-workflow --verb=list,update --resource=workflows.argoproj.io -n $COMPUTE_NAMESPACE
    $K create sa argo-workflow -n $COMPUTE_NAMESPACE
    $K create rolebinding argo-workflow --role=argo-workflows --serviceaccount=$COMPUTE_NAMESPACE:argo-workflow
    $K apply -f $__DIR/tokensecret.yaml -n $COMPUTE_NAMESPACE
    ARGO_TOKEN="Bearer $($K -n $COMPUTE_NAMESPACE get secret argo-workflow.service-account-token -o=jsonpath='{.data.token}' | base64 --decode)"
  fi

}

install_helm() {

  if ! [ -x "$(command -v helm)" ]; then
    echo -e "${COLOR_Y}Installing helm...${COLOR_RESET}"
    if [[ $PLATFORM == $OSX ]]; then
      brew install helm
    elif [[ $PLATFORM == $LINUX ]]; then
      curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
      chmod 700 /tmp/get_helm.sh
      /tmp/get_helm.sh
    fi
  fi
  
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo add stable https://charts.helm.sh/stable
  helm repo update

  helm version

}

reset_minikube() {

  echo -e "Stop and delete previous minikube instance"

  if [ -x "$(command -v minikube)" ] ; then
    minikube_status=$($SUDO $MINIKUBE_HOME/minikube status | grep 'host:' | awk '{print $2}') || echo -e "Minikube is not running"

    if [[ $minikube_status == "Running" ]]; then
  	  echo -e "${COLOR_C}First, we need to stop existing minikube...${COLOR_RESET}"
      $SUDO $MINIKUBE_HOME/minikube stop
      $SUDO minikube delete
    fi

    echo -e "${COLOR_C}Delete existing k8s cluster...${COLOR_RESET}"
    $SUDO $MINIKUBE_HOME/minikube delete

  fi
}


configure_nevermined_compute() {

  echo -e "${COLOR_B}Configuring Nevermined Compute...${COLOR_RESET}"


  if ! $K get namespace $COMPUTE_NAMESPACE; then
    echo -e "Creating namespace $COMPUTE_NAMESPACE"
    $K create namespace $COMPUTE_NAMESPACE
  fi

  #mount local directory to minikube vm
#  minikube mount  ${KEEPER_ARTIFACTS_FOLDER}:/tmp/hostpath-provisioner/nvm-disc/argo-artifacts &

  #echo -e "${COLOR_B}Creating configmap with artifacts from folder ${KEEPER_ARTIFACTS_FOLDER} ...${COLOR_RESET}"
  #$K create -n $COMPUTE_NAMESPACE configmap artifacts --from-file=${KEEPER_ARTIFACTS_FOLDER}  

  # Install argo artifacts
  helm install -n $COMPUTE_NAMESPACE argo-artifacts bitnami/minio --version 11.10.13   --set fullnameOverride=argo-artifacts --set resources.requests.memory=1Gi
  $K -n $COMPUTE_NAMESPACE get services -o wide | grep argo-artifacts
  echo -e "${COLOR_G}"Notice: argo-artifacts was successfully installed"${COLOR_RESET}"

  if ! $K get  -n $COMPUTE_NAMESPACE  rolebinding default-admin; then
    echo -e "Granting admin privileges"
    $K create -n $COMPUTE_NAMESPACE clusterrolebinding cluster-argo-admin --clusterrole=admin --serviceaccount=$COMPUTE_NAMESPACE:argo
    $K create -n $COMPUTE_NAMESPACE rolebinding default-admin --clusterrole=admin --serviceaccount=$COMPUTE_NAMESPACE:default
    $K create -n $COMPUTE_NAMESPACE rolebinding argo-server --clusterrole=admin --serviceaccount=$COMPUTE_NAMESPACE:argo-server
    $K create -n $COMPUTE_NAMESPACE clusterrolebinding cluster-admin-argo --clusterrole=cluster-admin --serviceaccount=$COMPUTE_NAMESPACE:argo-server
  fi

  # create a secret with host docker credentials
  $K -n $COMPUTE_NAMESPACE create secret generic regcred \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson

  # make sure the service account exists
  $K -n $COMPUTE_NAMESPACE create serviceaccount default || true

  sleep 10

  # set secret as default for downloading docker images on the default serviceaccount
  $K -n $COMPUTE_NAMESPACE patch serviceaccount default -p '{"imagePullSecrets": [{"name": "regcred"}]}'


  # Update Minio deployment to use default bucket artifacts
  # The json files will be loaded into the folder but are not accessible via ui
  $K -n $COMPUTE_NAMESPACE set env deployment/argo-artifacts MINIO_DEFAULT_BUCKETS="artifacts:public,default:private" 


  $K -n $COMPUTE_NAMESPACE wait --for=condition=ready pod -l app.kubernetes.io/name=argo-workflows-server --timeout=300s
  $K -n $COMPUTE_NAMESPACE port-forward deployment/argo-workflows-server 2746:2746 &

  $K -n $COMPUTE_NAMESPACE wait --for=condition=ready pod -l app=minio --timeout=300s
  $K -n $COMPUTE_NAMESPACE port-forward --address 0.0.0.0 deployment/argo-artifacts 8060:9000 &
  echo "Use this token to login to argo workflows"
  echo $ARGO_TOKEN
  
  echo -e "${COLOR_G}Argo Workflows at: http://localhost:2746/workflows/ ${COLOR_RESET}\n"
  echo -e "${COLOR_G}Minio at: http://localhost:8060 ${COLOR_RESET}\n"

}

main "$@"
