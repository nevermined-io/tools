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
MINIKUBE_RECREATE=${MINIKUBE_RECREATE:-false}
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
  set_minikube_parameters
  if [ "$MINIKUBE_RECREATE" = true ]; then
    reset_minikube
  else
      echo -e "Skipping minikube re-install by MINIKUBE_RECREATE env variable"
  fi
  if deploy_minikube; then
    sleep 1 #
    #deploy_nevermined_compute
  fi
}


#### Functions


# Set minikube startup parameters
set_minikube_parameters() {
  # Assuming driver none by default
    MINIKUBE_CMD=$MINIKUBE_CMD" --vm-driver="$MINIKUBE_DRIVER
}


reset_minikube() {

  echo -e "Stop and delete previous minikube instance"

  if [ -x "$(command -v minikube)" ] ; then
    minikube_status=$($SUDO $MINIKUBE_HOME/minikube status | grep 'host:' | awk '{print $2}')

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

  install_kubectl_minikube_others

  # start minikube with desired settings
  echo -e "${COLOR_M}"minikube will now try to start the local k8s cluster"${COLOR_RESET}"
  $SUDO $MINIKUBE_CMD

  minikube_status=$($SUDO $MINIKUBE_HOME/minikube status | grep 'host:' | awk '{print $2}')

  #if [ ! $($SUDO $MINIKUBE_HOME/minikube status) ] ; then
  if [[ $minikube_status == "Running" ]]; then
    echo -e "\n${COLOR_G}Minikube is up and Running!${COLOR_RESET}\n"
  else
    echo -e "${COLOR_R}Unable to start minikube. Please see errors above${COLOR_RESET}"
    return 1
  fi
}


install_kubectl_minikube_others() {
# Installing kubectl if needed
  if ! [ -x "$(command -v kubectl)" ]; then
    echo -e "${COLOR_Y}Installing kubectl...${COLOR_RESET}"
    if [[ $PLATFORM == $OSX ]]; then
      brew install kubectl
    elif [[ $PLATFORM == $LINUX ]]; then

      if [[ $DIST_TYPE == "Ubuntu" ]]; then
        $SUDO apt-get update && $SUDO apt-get install -y apt-transport-https
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | $SUDO apt-key add -
        echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | $SUDO tee -a /etc/apt/sources.list.d/kubernetes.list
        $SUDO apt-get update
        $SUDO apt-get install -y kubectl socat conntrack kubeadm
        $SUDO apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
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
      curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64 && chmod +x minikube && $SUDO mv minikube $MINIKUBE_HOME
    elif [[ $PLATFORM == $LINUX ]]; then
      curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && $SUDO mv minikube $MINIKUBE_HOME
    fi
    $SUDO $MINIKUBE_HOME/minikube config set ShowBootstrapperDeprecationNotification false &&
    $SUDO $MINIKUBE_HOME/minikube config set WantUpdateNotification false &&
    $SUDO $MINIKUBE_HOME/minikube config set WantReportErrorPrompt false &&
    $SUDO $MINIKUBE_HOME/minikube config set WantKubectlDownloadMsg false
    echo -e "${COLOR_G}"Notice: minikube was successfully installed"${COLOR_RESET}"
  fi
}


deploy_nevermined_compute() {

  echo -e "${COLOR_B}Starting Nevermined Compute Stack...${COLOR_RESET}"
  $K create ns nevermined-operator
  $K create ns nevermined-compute
  

  $K -n nevermined-operator create -f nevermined/compute-api/deploy_on_k8s/postgres-configmap.yaml
  $K -n nevermined-operator create -f nevermined/compute-api/deploy_on_k8s/postgres-storage.yaml
  $K -n nevermined-operator create -f nevermined/compute-api/deploy_on_k8s/postgres-deployment.yaml
  $K -n nevermined-operator create -f nevermined/compute-api/deploy_on_k8s/postgresql-service.yaml
  $K -n nevermined-operator apply -f nevermined/compute-api/deploy_on_k8s/deployment.yaml
  $K -n nevermined-operator apply -f nevermined/compute-api/deploy_on_k8s/role_binding.yaml
  $K -n nevermined-operator apply -f nevermined/compute-api/deploy_on_k8s/service_account.yaml
  
  $K -n nevermined-operator expose deployment operator-api --port=8050
  
  $K -n nevermined-compute apply -f nevermined/compute-engine/k8s_install/sa.yml
  $K -n nevermined-compute apply -f nevermined/compute-engine/k8s_install/binding.yml
  $K -n nevermined-compute apply -f nevermined/compute-engine/k8s_install/operator.yml
  $K -n nevermined-compute apply -f nevermined/compute-engine/k8s_install/computejob-crd.yaml
  $K -n nevermined-compute apply -f nevermined/compute-engine/k8s_install/workflow-crd.yaml
  $K -n nevermined-compute create -f nevermined/compute-api/deploy_on_k8s/postgres-configmap.yaml
  
  $K -n nevermined-operator wait --timeout=60s --for=condition=Available  deployment/postgres
  $K -n nevermined-operator wait --timeout=60s --for=condition=Available  deployment/operator-api
  
  echo -e "${COLOR_G}Forwarding connection to localhost port 8050${COLOR_RESET}"
  $K -n nevermined-operator port-forward svc/nevermined-compute-api 8050 &
  
  echo -e "${COLOR_G}Point your browser at: http://localhost:8050/api/v1/docs/${COLOR_RESET}\n"

}

main "$@"

