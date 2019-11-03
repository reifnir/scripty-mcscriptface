#!/bin/bash

#delete a 3-node cluster? about 21 min

#Users-MBP:~ jimandreasen$ az aks create --name "managed-dev" --resource-group "k8s-managed-dev" --ssh-key-value "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnZ/NHA1nhU8k/hbCTd0c+oleGF3tzkn2Bp08NIiYO14sWGP6Z/QiRNmvXj7k7zEytwp/8Wyickm54vZXGpzFhrEtx6dTeBh4yHIklQ5/sD1UsGhijfvWy7AMQR4J42LmgMzmH3vuE5S1ANDL2mTcxL3OWehQFjT+IVbuj4mQwK8DX3Fy/mN8YeM2h8E13RPozXr/3A8JGHFVCwFdc9V+NCGl0r589y56mDued78yaCoG1ObN8k5GUh47p6X8XS0iD6MgmHbUYIf9Cp4zPx3F82ui78FuztdqEevgfSLM+KcYtBEtHsVExPTeN1MfmFHbfxGlBF7mi0uKjavUi+1Qb jimandreasen@Users-MBP.fios-router.home"
defaultClusterRootName="working"
defaultSubscriptionName="Enterprise MSDN - 2"
clusterRootName=""
#'eastus,westeurope,centralus,canadacentral,canadaeast'
region="eastus"
#otherRgName="MC_${clusterRootName}_${clusterRootName}_${region}"
nodeCount=1
kubernetesVersion="1.8.6"
vmSize="Standard_B2ms"

function login() {
  read -p "Enter Username: " userName
  read -s -p "Enter Password:" password
  echo ""
  echo "Logging into Azure as $userName"
  az login -u $userName -p $password
}
function setSubscription() {
  echo "Getting list of subscriptions"
  az account list | jq 'sort_by(.name) | .[].name'
  read -p "Enter name of intended subscription (or enter for $defaultSubscriptionName): " subscriptionName
  echo "You entered $subscriptionName"
  if [ -z "$subscriptionName" ]
    then
      az account set --subscription "$defaultSubscriptionName"
  else
    az account set --subscription "$subscriptionName"
  fi
}
function setClusterName() {
  read -p "Enter alias for cluster and resources (or enter for \"$defaultClusterRootName\"): " clusterRootName
  if [ -z "$clusterRootName" ]
    then
      clusterRootName=$defaultClusterRootName
  fi
}
function removeResourceGroup() {
  rg=$(az group show --name $clusterRootName)
  echo "Checking whether resource group $clusterRootName exists"
  if [ -z "$rg" ]
    then
      echo "Does not exist"
    else
      echo "Deleting resource group $clusterRootName"
      az group delete --name $clusterRootName -y
  fi
}
function createCluster() {
  echo "Creating resource group with name $clusterRootName"
  az group create --name $clusterRootName --location $region 

  echo "Creating cluster"
  az aks create --name $clusterRootName --resource-group $clusterRootName --generate-ssh-keys --location $region --node-count $nodeCount --kubernetes-version $kubernetesVersion --node-vm-size $vmSize
}

function attachToCluster() {
  echo "Getting credentials for cluster $clusterRootName and adding context to kubectl"
  az aks get-credentials --name $clusterRootName --resource-group $clusterRootName
}
function setupHelm() {
  helm init
  helm install stable/nginx-ingress --name helm-ingress
  helm repo add azure https://kubernetescharts.blob.core.windows.net/azure
  helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
}
date
setSubscription
setClusterName
removeResourceGroup
createCluster
attachToCluster
setupHelm
date
