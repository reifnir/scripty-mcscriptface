#!/bin/bash
MY_WINDOWS_USERNAME="$1"

#Reminder: Terraform state is not backward compatible (even for revision changes!)
TERRAFORM_VERSION="0.12.16"

echo "MY_WINDOWS_USERNAME=$MY_WINDOWS_USERNAME"
function setup_workstation {
    echo "Starting: $(date)"
    upgrade_packages
    install_prerequisites
    install_ca_certificates
    install_keys_and_package_repos
    install_cli_tools
    setup_local_profile
    cleanup
    echo "Completed: $(date)"
}
function upgrade_packages {
    sudo apt update
    # Because otherwise Ubuntu gets cute with prompting the user about whether it's okay to restart services during this upgrade
    sudo DEBIAN_FRONTEND=noninteractive apt -qy upgrade
}

function install_prerequisites {
    # This includes pre-requisites for CA Certificate updates, Azure-CLI, kubectl, and Docker.
    sudo apt-get install -y \
        net-tools \
        ca-certificates \
        curl \
        lsb-release \
        gnupg \
        apt-transport-https \
        software-properties-common \
        unzip \
        zip \
        wget
    # net-tools has "ifconfig" which is helpful in other scripts we use (to find current ip address)
}

function install_ca_certificates {
    DEST=/usr/local/share/ca-certificates/my-trusted-certs
    sudo mkdir $DEST
    sudo cp ./ca-certs/* $DEST
    sudo chmod 755 $DEST
    sudo chmod 644 $DEST/*
    sudo update-ca-certificates
}

function install_keys_and_package_repos {
    # Add the Azure CLI software repo...
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | 
        gpg --dearmor | 
        sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null #azure-cli

    AZ_REPO=$(lsb_release -cs)
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
        sudo tee /etc/apt/sources.list.d/azure-cli.list

    # Add the Kubernetes CLI repo...
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - #kubectl

    echo "deb [arch=amd64] http://packages.cloud.google.com/apt/ kubernetes-xenial main" |
        sudo tee /etc/apt/sources.list.d/kubernetes.list

    # Add the Microsoft repo for .NET Core
    echo "Installing Microsoft debian 9 apt repo to make it easier to install dotnet-sdk-3.0, etc"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
    sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
    wget -q https://packages.microsoft.com/config/debian/9/prod.list
    sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
    sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
    sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list

    # Note: apt-get update must be run prior to apt installing from these repos
}

function install_cli_tools {
    # Finally install packages we want
    sudo apt-get update
    
    echo "Installing CLI Tools..."
    sudo apt install -y \
        azure-cli \
        kubectl \
        python3 \
        python3-pip \
        git \
        dotnet-sdk-2.1 \
        dotnet-sdk-3.1

    # Install Terraform
    wget -O terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    sudo unzip -o terraform.zip -d /usr/local/bin
    rm -f terraform.zip

    # Install NodeJS 13.x and NPM
    curl -sL https://deb.nodesource.com/setup_13.x | sudo bash -
    sudo apt-get install -y nodejs
}

function setup_local_profile {
    if [ ! -d ~/.ssh ]; then
        # Not softlinking as currently unable to set permissions correctly
        cp /mnt/c/Users/$MY_WINDOWS_USERNAME/.ssh ~/ -r
        chmod 600 ~/.ssh/id_rsa*
    fi

    echo "Make soft links to my Windows gitconfig directory..."
    if [ -f ~/.gitconfig ]; then
        rm ~/.gitconfig
    fi
    ln -s "/mnt/c/Users/$MY_WINDOWS_USERNAME/.gitconfig" ~/

    echo "Making link from for docker -> docker.exe on Windows host..."
    sed -i "/alias docker=/d" ~/.bashrc
    #echo "alias docker=docker.exe" >> ~/.bashrc && source ~/.bashrc
    #No longer using an alias (breaks docker calls frmo scripts), make softlink
    sudo ln -s "$(which docker.exe)" /usr/bin/docker

    source ~/.bashrc
}
function cleanup {
    upgrade_packages
    sudo apt -y autoremove
}

# setup all of the things
setup_workstation
