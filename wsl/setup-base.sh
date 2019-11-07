#!/bin/bash
echo "Adding Azure RPM Repo..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

echo "Adding Kubernetes RPM Repo..."
sudo sh -c 'echo -e "[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" > /etc/yum.repos.d/kubernetes.repo'

echo "Adding Docker CE CentOS repo..."
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "Adding CentOS 7 IUS repo..."
sudo dnf install  https://centos7.iuscommunity.org/ius-release.rpm -y

# Uninstall legacy versions of Docker and Git... we'll pull from other repos
sudo dnf remove \
    docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine \
    git \
    -y

# Expects to be run on a CentOS 7 machine (until I check out Pengwin next month)
echo "Install all the things..."
sudo dnf install \
    git2u-all \
    azure-cli \
    python3 \
    kubectl \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    -y

# Current user only. Don't sudo!
echo "pip3 installed packages..."
pip3 install awscli --upgrade --user

# Current user only. Don't sudo!
echo "Install Helm..."
curl https://git.io/get_helm.sh -L | sh

echo "Grant plebs like us access to the Docker CLI without sudo..."
sudo usermod -aG docker $USER

echo "Upgrade all RPM packages..."
sudo dnf updateinfo
sudo dnf check-update
sudo dnf upgrade -y

echo "Make soft links to my Windows profile directories..."
