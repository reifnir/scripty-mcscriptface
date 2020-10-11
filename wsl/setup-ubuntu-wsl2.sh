#!/bin/bash
set -e # stop immediately on error
export MY_WINDOWS_USERNAME="$1"

#Reminder: Terraform state is not backward compatible (even for revision changes!)
TERRAFORM_VERSION="0.13.4"

echo "MY_WINDOWS_USERNAME=$MY_WINDOWS_USERNAME"
function setup_workstation {
    echo "Starting: $(date)"
    upgrade_packages
    install_node_and_npm
    install_dotnet_core_sdk
    install_misc_tools
    install_cli_tools
    setup_local_profile
    cleanup
    echo "Completed: $(date)"
}

function upgrade_packages {
    sudo apt update
    # Because otherwise Ubuntu gets cute with prompting the user about whether it's okay to restart services during this upgrade
    sudo apt -qy upgrade
}

function install_node_and_npm {
    echo "Installing Nodejs..."
    sudo apt install -y nodejs
    
    echo "Installing npm... (this blows up when installed in the same apt install statement as nodejs)"
    sudo apt install -y npm

    # Set NPM to install global backages using the path in NPM_CONFIG_PREFIX
    mkdir -p ~/.npm-global
    sed -i "/export NPM_CONFIG_PREFIX=/d" ~/.bashrc
    export NPM_CONFIG_PREFIX=~/.npm-global
    echo "export NPM_CONFIG_PREFIX=~/.npm-global" >> ~/.bashrc && source ~/.bashrc
}

function install_dotnet_core_sdk {
    echo "Adding Microsoft repository key and feed..."
    PKG=/tmp/packages-microsoft-prod.deb
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O $PKG
    sudo dpkg -i $PKG
    rm $PKG

    echo "Installing the .NET Core SDK..."
    sudo apt update
    sudo apt install apt-transport-https
    sudo apt update
    sudo apt install -y dotnet-sdk-3.1
}

function install_misc_tools {
    # This includes pre-requisites for CA Certificate updates, Azure-CLI, kubectl, and Docker.
    # net-tools has "ifconfig" which is helpful in other scripts we use (to find current ip address)
    echo "installing pre-reqs"
    sudo apt install -y \
        net-tools \
        unzip \
        zip \
        jq \
        direnv \
        azure-functions-core-tools
}

function install_cli_tools {

    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

    echo "Installing AWS CLI..."
    sudo apt install -y awscli

    # Install Kubectl
    # If we wanted a specific version, example URL: https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
    echo "Installing kubectl..."
    URL="https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl"
    wget -O /tmp/kubectl $URL
    sudo mv /tmp/kubectl /usr/local/bin

    echo "Installing Terraform..."
    wget -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    sudo unzip -o /tmp/terraform.zip -d /usr/local/bin
    rm -f terraform.zip

    echo "Installing Yarn..."
    sudo apt install -y yarnpkg

    echo "Installing Azure Functions Core Tools..."
    # npm i -g azure-functions-core-tools@3 --unsafe-perm true
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


    sed -i '/eval "$(direnv hook bash)"/d' ~/.bashrc
    echo 'eval "$(direnv hook bash)"' | tee -a ~/.bashrc > /dev/null
    source ~/.bashrc
}

function cleanup {
    upgrade_packages
    sudo apt -y autoremove
}

# setup all of the things
setup_workstation
