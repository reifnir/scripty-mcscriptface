#!/bin/bash

echo "==INSTALL CURL=="
sudo apt -y install curl

echo "==INSTALL JQ (for querying json)=="
sudo apt -y install jq

echo "==INSTALL AZURE-CLI=="
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "==INSTALL KUBECTL=="
#newest...
#curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl

#AKS highest-non-preview version is 14.x, never be more than one ahead or behind...
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client=true

echo "==INSTALL HELM=="
curl -LO https://git.io/get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
helm init --client-only

