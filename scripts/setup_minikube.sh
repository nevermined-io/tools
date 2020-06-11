#!/usr/bin/env bash
set -euo pipefail

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

MINIKUBE_HOME="/usr/local/bin"
MINIKUBE_CMD="$MINIKUBE_HOME/minikube start"
MINIKUBE_DRIVER=${MINIKUBE_DRIVER:-kvm2}
MINIKUBE_RECREATE=${MINIKUBE_RECREATE:-true}
DEPLOY_MINIKUBE=${DEPLOY_MINIKUBE:-true}
CONFIGURE_K8S_COMPUTE=${CONFIGURE_K8S_COMPUTE:-true}
COMPUTE_NAMESPACE=${COMPUTE_NAMESPACE:-nevermined-compute}
INSTALL_KUBECTL=${INSTALL_KUBECTL:-true}
INSTALL_HELM=${INSTALL_HELM:-false}

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



main() {

  if [ "$INSTALL_KUBECTL" = true ]; then
    install_kubectl_minikube_others
  fi

  if [ "$INSTALL_HELM" = true ]; then
    install_helm
  fi

  if [ "$DEPLOY_MINIKUBE" = true ]; then
    set_minikube_parameters
    if [ "$MINIKUBE_RECREATE" = true ]; then
      reset_minikube
    else
        echo -e "Skipping minikube re-install by MINIKUBE_RECREATE env variable"
    fi
    deploy_minikube
  fi

  if [ "$CONFIGURE_K8S_COMPUTE" = true ]; then
    configure_nevermined_compute
  fi

}


#### Functions


# Set minikube startup parameters
set_minikube_parameters() {
    MINIKUBE_CMD=$MINIKUBE_CMD" --vm-driver="$MINIKUBE_DRIVER
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

deploy_minikube() {

  # start minikube with desired settings
  echo -e "${COLOR_M}"minikube will now try to start the local k8s cluster"${COLOR_RESET}"
  $SUDO $MINIKUBE_CMD

  minikube_status=$($SUDO $MINIKUBE_HOME/minikube status | grep 'host:' | awk '{print $2}')

  if [[ $minikube_status == "Running" ]]; then
    echo -e "\n${COLOR_G}Minikube is up and Running!${COLOR_RESET}\n"
  else
    echo -e "${COLOR_R}Unable to start minikube. Please see errors above${COLOR_RESET}"
    return 1
  fi
}


install_helm() {

  echo -e "${COLOR_Y}Installing helm...${COLOR_RESET}"
  if [[ $PLATFORM == $OSX ]]; then
    brew install helm
  elif [[ $PLATFORM == $LINUX ]]; then
    curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 /tmp/get_helm.sh
    /tmp/get_helm.sh
  fi

}

install_kubectl_minikube_others() {

# Installing kubectl if needed
  if ! [ -x "$(command -v kubectl)" ]; then
    echo -e "${COLOR_Y}Installing kubectl...${COLOR_RESET}"
    if [[ $PLATFORM == $OSX ]]; then

      if [ "$INSTALL_KUBECTL" = true ]; then
        brew install kubectl
      fi

    elif [[ $PLATFORM == $LINUX ]]; then

      if [[ $DIST_TYPE == "Ubuntu" ]]; then
        $SUDO apt-get update && $SUDO apt-get install -y apt-transport-https
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | $SUDO apt-key add -
        echo "deb https://apt.kubernetes.io/ kubernetes-focal main" | $SUDO tee -a /etc/apt/sources.list.d/kubernetes.list
        $SUDO apt-get update
        $SUDO apt-get install -y kubectl socat conntrack kubeadm
        $SUDO apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst
        $SUDO bash -c "echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables"

      elif [[ $DIST_TYPE == "CentOS" ]]; then
        cp $__DIR/.kubenetes.repo /etc/yum.repos.d/kubernetes.repo
        $SUDO yum install -y kubectl socat conntrack kubeadm
        $SUDO bash -c "echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables"
      fi

      sudo adduser `id -un` kvm
      sudo adduser `id -un` libvirtd
      virsh list --all
    fi

    echo -e "${COLOR_G}[OK]${COLOR_RESET}"
  fi



# Installing minikube if needed
  if ! [ -x "$(command -v minikube)" ] ; then
    echo -e "${COLOR_Y}Installing minikube...${COLOR_RESET}"
    if [[ $PLATFORM == $OSX ]]; then
      curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64 && chmod +x minikube && sudo mv minikube $MINIKUBE_HOME
    elif [[ $PLATFORM == $LINUX ]]; then
      curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube $MINIKUBE_HOME
    fi
    $SUDO $MINIKUBE_HOME/minikube config set ShowBootstrapperDeprecationNotification false &&
    $SUDO $MINIKUBE_HOME/minikube config set WantUpdateNotification false &&
    $SUDO $MINIKUBE_HOME/minikube config set WantReportErrorPrompt false &&
    $SUDO $MINIKUBE_HOME/minikube config set WantKubectlDownloadMsg false
    echo -e "${COLOR_G}"Notice: minikube was successfully installed"${COLOR_RESET}"
  fi

  # Installing argo if needed
  if ! [ -x "$(command -v argo)" ] ; then
    echo -e "${COLOR_Y}Installing argo...${COLOR_RESET}"

    if [[ $PLATFORM == $OSX ]]; then
      brew install argoproj/tap/argo

    elif [[ $PLATFORM == $LINUX ]]; then
      # Download the binary
      curl -sLO https://github.com/argoproj/argo/releases/download/v2.8.1/argo-linux-amd64
      # Make binary executable
      chmod +x argo-linux-amd64
      # Move binary to path
      sudo mv ./argo-linux-amd64 /usr/local/bin/argo
      # Test installation
      argo version
      echo -e "${COLOR_G}"Notice: argo was successfully installed"${COLOR_RESET}"

    fi
  fi

}


configure_nevermined_compute() {

  echo -e "${COLOR_B}Configuring Nevermined Compute...${COLOR_RESET}"

  if ! $K get namespace $COMPUTE_NAMESPACE; then
    echo -e "Creating namespace $COMPUTE_NAMESPACE"
    $K create namespace $COMPUTE_NAMESPACE
  fi

  $K apply -n $COMPUTE_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo/stable/manifests/install.yaml

  if ! $K get  -n $COMPUTE_NAMESPACE  rolebinding default-admin; then
    echo -e "Granting admin privileges"
    $K create -n $COMPUTE_NAMESPACE clusterrolebinding cluster-argo-admin --clusterrole=admin --serviceaccount=$COMPUTE_NAMESPACE:argo
    $K create -n $COMPUTE_NAMESPACE rolebinding default-admin --clusterrole=admin --serviceaccount=$COMPUTE_NAMESPACE:default
#    $K create -n $COMPUTE_NAMESPACE rolebinding argo-admin --clusterrole=admin --serviceaccount=$COMPUTE_NAMESPACE:argo
    $K create -n $COMPUTE_NAMESPACE rolebinding argo-server --clusterrole=admin --serviceaccount=$COMPUTE_NAMESPACE:argo-server

  fi

  $K -n $COMPUTE_NAMESPACE port-forward deployment/argo-server 2746:2746 &
  
  echo -e "${COLOR_G}Point your browser at: http://localhost:2746/$COMPUTE_NAMESPACE/ ${COLOR_RESET}\n"

}

main "$@"

