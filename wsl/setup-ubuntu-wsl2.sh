#!/bin/bash -e
TEMP_DIR="$(mktemp -d)"

export MY_WINDOWS_USERNAME="$1"
echo "MY_WINDOWS_USERNAME=$MY_WINDOWS_USERNAME"

if [ -z "$1" ]; then
    echo "Pass in the directory name of your Windows user."
    exit 1
elif [ ! -d "/mnt/c/Users/$MY_WINDOWS_USERNAME" ]; then
    echo "You passed in '$MY_WINDOWS_USERNAME', but no directory was accessible at /mnt/c/Users/$MY_WINDOWS_USERNAME."
    exit 1
else
    echo "Setting up WSL2 for Windows User '$MY_WINDOWS_USERNAME'..."
fi

function setup_workstation {
    echo "Starting: $(date)"
    let_sudo_without_password
    upgrade_packages
    install_node_and_npm
    install_dotnet_core_sdk
    install_misc_tools
    install_cli_tools
    install_kubernetes_tools
    install_latest_terraform
    install_strongdm_script
    install_powershell
    setup_local_profile
    cleanup
    echo "Completed: $(date)"
}

function replace-line-in-file-containing() {
    FILE_PATH="$1"
    STARTS_WITH="$2"
    REPLACEMENT="$3"

    >&2 echo "Removing all lines that begin with '$STARTS_WITH' from file '$FILE_PATH'..."
    sudo sed -i "/$STARTS_WITH/d" "$FILE_PATH"

    >&2 echo "Appending '$REPLACEMENT' to the end of file '$FILE_PATH'..."
    echo "$REPLACEMENT" | sudo tee --append "$FILE_PATH" > /dev/null
}

function let_sudo_without_password {
    replace-line-in-file-containing /etc/sudoers "$MY_WINDOWS_USERNAME " "$MY_WINDOWS_USERNAME ALL=(ALL) NOPASSWD:ALL"
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
    PKG=packages-microsoft-prod.deb
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O $PKG
    sudo dpkg -i $PKG
    rm $PKG

    echo "Installing the .NET Core SDK..."
    sudo apt update
    sudo apt install -y apt-transport-https
    sudo apt update
    sudo apt install -y dotnet-sdk-3.1
    sudo apt install -y dotnet-sdk-6.0
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
        python3 \
        python3-pip
}

function install_cli_tools {

    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

    echo "Installing AWS CLI..."
    # Ubuntu package manager is still on awscli v1
    # sudo apt install -y awscli
    AWS_CLI_ZIP="$TEMP_DIR/awscliv2.zip"
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$AWS_CLI_ZIP"
    unzip "$AWS_CLI_ZIP" -d "$TEMP_DIR"
    if [ ! -z "`which aws`" ]; then
        UPDATE_FLAG="--update"
    else
        UPDATE_FLAG=""
    fi
    sudo "$TEMP_DIR/aws/install" $UPDATE_FLAG
    rm -rf "$TEMP_DIR"

    echo "Installing Azure Functions Core Tools..."
    sudo apt install -y azure-functions-core-tools-3

    echo "Downloading jiq to '/usr/local/bin'..."
    # https://github.com/fiatjaf/jiq
    JIQ_URL="`curl https://api.github.com/repos/fiatjaf/jiq/releases/latest | jq '.assets | .[] | select(.name == "jiq_linux_amd64").browser_download_url' -r`"
    sudo curl "$JIQ_URL" -L -o /usr/local/bin/jiq
    sudo chmod +x /usr/local/bin/jiq

    echo "Installing yq (like jq for yaml)..."
    sudo pip3 install yq

    echo "Installing dive (docker image inspection program)..."
    wget https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb
    sudo apt install ./dive_0.9.2_linux_amd64.deb
    rm ./dive_0.9.2_linux_amd64.deb
}

function install_latest_terraform {
    echo "Installing Terraform..."
    if [ -f /usr/local/bin/terraform ]
    then
      echo "  Removing manual terraform installation..."
      sudo rm -f /usr/local/bin/terraform
    fi
    echo "  Installing HashiCorp key..."
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    echo "  Adding HashiCorp Linux repo..."
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    echo "  Updating packages..."
    sudo apt update
    echo "  Finally installing terraform..."
    sudo apt install -y terraform

    # echo "Installing CDK for Terraform (cdktf-cli)"
    # sudo npm install -g cdktf-cli
}

function install_powershell {
    # Update the list of packages
    sudo apt-get update
    # Install pre-requisite packages.
    sudo apt-get install -y wget apt-transport-https software-properties-common
    # Download the Microsoft repository GPG keys
    wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
    # Register the Microsoft repository GPG keys
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    # Update the list of products
    sudo apt-get update
    # Enable the "universe" repositories
    sudo add-apt-repository universe
    # Install PowerShell
    sudo apt-get install -y powershell
}
    
function install_strongdm_script {
    cp ./install-sdm.sh ~
    chmod +x ~/install-sdm.sh
}

function install_kubernetes_tools {

    # Install Kubectl
    # If we wanted a specific version, example URL: https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
    echo "Installing kubectl..."
    curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    sudo mv kubectl /usr/local/bin

    curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
    sudo apt-get install apt-transport-https --yes
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm
}

function setup_local_profile {
    if [ ! -d ~/.ssh ]; then
        # Not softlinking as currently unable to set permissions correctly
        cp /mnt/c/Users/$MY_WINDOWS_USERNAME/.ssh ~/ -r
        chmod 600 ~/.ssh/id_rsa*
    fi

    echo "Wiring up direnv to bash..."
    DIRENV_CMD='eval "$(direnv hook bash)"'
    sed -i "/$DIRENV_CMD/d" ~/.bashrc
    echo "$DIRENV_CMD" >> ~/.bashrc

    source ~/.bashrc
}

function cleanup {
    upgrade_packages
    sudo apt -y autoremove
}

# setup all of the things
setup_workstation
