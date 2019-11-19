#!/bin/bash
MY_GIT_EMAIL="jim.andreasen@reifnir.com"
MY_GIT_NAME="Jim Andreasen"

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

echo "Initialize Git properties"
git config --global user.email "$MY_GIT_EMAIL"
git config --global user.name "$MY_GIT_NAME"

echo "Connect Docker CLI to Windows docker daemon port"
# First clear any previous statement that begins with 'export DOCKER_HOST=' from ~/.bashrc
sed -i "/export DOCKER_HOST=/d" ~/.bashrc
echo "export DOCKER_HOST=tcp://localhost:23750" >> ~/.bashrc && source ~/.bashrc
export DOCKER_HOST=tcp://localhost:23750

# DOCKER HELP!: I keep seeing: ERROR: Cannot connect to the Docker daemon at tcp://localhost:23750. Is the docker daemon running?
# (thanks to this: https://forums.docker.com/t/wsl-and-docker-for-windows-cannot-connect-to-the-docker-daemon-at-tcp-localhost-2375-is-the-docker-daemon-running/63571/13)
# Run the following FROM WINDOWS once and you're perpetually GTG
# docker run -d --restart=always -p 127.0.0.1:23750:2375 -v /var/run/docker.sock:/var/run/docker.sock alpine/socat tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock

echo "Make soft links to my Windows profile directories..."
# TODO: finish it
