#!/bin/bash -e
# wsl --set-default Ubuntu-22.04
# apt list -a awscli

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMP_DIR="$(mktemp -d)"

NODE_VERSION="16"

if [ `whoami` == "root" ]; then
    echo "Don't run this script as root. B'bye!"
    exit 1
fi

# Seems overcomplicated, but we need to trim control characters from the end of the username that's returned
function setup-workstation {
    echo "Starting: $(date +"%Y-%m-%dT%H:%M:%S%:z")"

    check-username
    let-sudo-without-password
    upgrade-packages
    install-prereqs-and-misc-tools
    install-node-npm-and-yarn
    install-dotnet-core-sdk
    install-cli-tools
    install-kubernetes-tools
    install-latest-terraform
    install-powershell
    # setup-git
    cleanup
    echo "Completed: $(date)"
}

function check-username() {
    export WINDOWS_USERNAME="$(powershell.exe \$env:username | sed 's/[[:space:]]*$//')"
    echo "Windows username: $WINDOWS_USERNAME"
    echo "  Linux username: `whoami`"

    if [ "`whoami`" != "$WINDOWS_USERNAME" ]; then
        echo "Warning: user Windows and Linux usernames aren't the same. If you use any scripts that assume your shell username is your AD username, you're going to have a bad time (looking at you, fleet-management project at KBRA)..."
        while true; do
            read -p "Are you sure you want to contine installing dependencies? " yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

function replace-line-in-file-containing() {
    FILE_PATH="$1"
    STARTS_WITH="$2"
    REPLACEMENT="$3"

    sudo sed -i "/$STARTS_WITH/d" "$FILE_PATH"
    echo "$REPLACEMENT" | sudo tee --append "$FILE_PATH" > /dev/null
}

function let-sudo-without-password() {
    echo "Setting up"
    replace-line-in-file-containing /etc/sudoers "`whoami` " "`whoami` ALL=(ALL) NOPASSWD:ALL"
}

function upgrade-packages() {
    sudo apt-get update
    sudo apt-get -qy upgrade
}

function install-prereqs-and-misc-tools() {
    # This includes pre-requisites for CA Certificate updates, Azure-CLI, kubectl, Docker, and NodeJS.
    echo "Installing pre-reqs"

    # net-tools has "ifconfig" which is helpful in other scripts we use (to find current ip address)
    # Hey Chris Breish, did you know that curling ifconfig.co gives you your public IP address :themoreyouknow:
    sudo apt-get install -y \
        net-tools \
        unzip \
        zip \
        jq \
        direnv \
        python3 \
        python3-pip \
        ncdu \
        gcc \
        g++ \
        make \
        apt-transport-https \
        lsb \
        wget \
        apt-transport-https \
        software-properties-common
}

function install-node-npm-and-yarn {
    # Look here for different versions: https://github.com/nodesource/distributions#debinstall
    echo "Installing Nodejs version $NODE_VERSION..."
    curl -fsSL "https://deb.nodesource.com/setup_$NODE_VERSION.x" | sudo -E bash -
    sudo apt-get install -y nodejs

    echo "Installing Yarn package manager..."
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update && sudo apt-get install -y yarn

    # Set NPM to install global packages using the path in NPM_CONFIG_PREFIX
    echo "Setting-up a global directory for this user..."
    mkdir -p ~/.npm-global
    replace-line-in-file-containing ~/.bashrc "export NPM_CONFIG_PREFIX=" "export NPM_CONFIG_PREFIX=~/.npm-global"
}

function install-dotnet-core-sdk {
    echo "Adding Microsoft repository key and feed..."
    PKG=packages-microsoft-prod.deb
    wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O $PKG
    sudo dpkg -i $PKG
    rm $PKG

    echo "Installing the .NET SDKs..."
    sudo apt-get update
    #sudo apt-get install -y apt-transport-https
    sudo apt-get install -y dotnet-sdk-6.0
}

function install-cli-tools {

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
    rm -rf "$TEMP_DIR/aws"

    # echo "Installing Azure Functions Core Tools..."
    sudo apt-get install -y azure-functions-core-tools-4

    echo "Downloading jiq (visual jq tool) to '/usr/local/bin'..."
    # https://github.com/fiatjaf/jiq
    JIQ_URL="`curl -s https://api.github.com/repos/fiatjaf/jiq/releases/latest | jq '.assets | .[] | select(.name == "jiq_linux_amd64").browser_download_url' -r`"
    sudo curl -s "$JIQ_URL" -L -o /usr/local/bin/jiq
    sudo chmod +x /usr/local/bin/jiq

    # Since I've never used yq, let's not actually install it
    # echo "Installing yq (like jq for yaml)..."
    # sudo pip3 install yq

    echo "Installing latest version of dive (docker image inspection program)..."
    DIVE_URL="$(curl -s https://api.github.com/repos/wagoodman/dive/releases/latest | jq '.assets[] | select(.content_type == "application/x-debian-package") | .browser_download_url' -r)"
    curl -s -L "$DIVE_URL" -o "$TEMP_DIR/dive.deb"
    sudo apt-get install "$TEMP_DIR/dive.deb"
    echo "\$?=$?"
}

function install-kubernetes-tools {
    # Install Kubectl
    # If we wanted a specific version, example URL: https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
    echo "Installing kubectl..."
    curl -sLO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    sudo mv kubectl /usr/local/bin
    sudo chmod +x /usr/local/bin/kubectl

    curl -s https://baltocdn.com/helm/signing.asc | sudo apt-key add -
    # sudo apt-get install apt-transport-https --yes
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install -y helm
}

function install-latest-terraform {
    echo "Installing Terraform..."
    echo "  Installing HashiCorp key..."
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    echo "  Adding HashiCorp Linux repo..."
    sudo apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    echo "  Updating packages..."
    sudo apt-get update
    echo "  Finally installing terraform..."
    sudo apt install -y terraform

    # echo "Installing CDK for Terraform (cdktf-cli)"
    # sudo npm install -g cdktf-cli
}

function install-powershell {
    # Download the Microsoft repository GPG keys
    curl -sL https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -o "$TEMP_DIR/packages-microsoft-prod.deb"
    # Register the Microsoft repository GPG keys
    sudo dpkg -i "$TEMP_DIR/packages-microsoft-prod.deb"
    rm "$TEMP_DIR/packages-microsoft-prod.deb"
    # Update the list of products
    sudo apt-get update
    # Enable the "universe" repositories
    sudo add-apt-repository -y universe
    # Install PowerShell
    sudo apt-get install -y powershell
}
    
# function setup-local-profile {
#     if [ ! -d ~/.ssh ]; then
#         # Not softlinking as currently unable to set permissions correctly
#         cp /mnt/c/Users/$WINDOWS_USERNAME/.ssh ~/ -r
#         chmod 600 ~/.ssh/id_rsa*
#     fi

#     echo "Wiring up direnv to bash..."
#     DIRENV_CMD='eval "$(direnv hook bash)"'
#     sed -i "/$DIRENV_CMD/d" ~/.bashrc
#     echo "$DIRENV_CMD" >> ~/.bashrc

#     source ~/.bashrc
# }

# function setup-git {
#     CURRENT_GIT_NAME=""
#     CURRENT_GIT_EMAIL=""

#     echo "Setting up Git global config..."

#     if [ -z "$CURRENT_GIT_NAME" ]; then
#         read -p "Enter the name for your Git commits: " DESIRED_GIT_USERNAME
#         echo "Setting Git user name to '$DESIRED_GIT_USERNAME'..."
#         git config --global user.name "$DESIRED_GIT_USERNAME"
#     else
#         echo "Name for Git commits set to '$CURRENT_GIT_NAME'. If you want to change this, execute 'git config --global user.name \"My Desired Name\"'"
#     fi
    
#     if [ -z "$CURRENT_GIT_EMAIL" ]; then
#         read -p "Enter the email for your Git commits: " DESIRED_GIT_EMAIL
#         echo "Setting Git user email to '$DESIRED_GIT_EMAIL'..."
#         git config --global user.email "$DESIRED_GIT_EMAIL"
#     else
#         echo "Email for Git commits set to '$CURRENT_GIT_EMAIL'. If you want to change this, execute 'git config --global user.email \"some.email@domain.com\"'"
#     fi
# }

function cleanup {
    sudo apt -y autoremove
    rm -rf "$TEMP_DIR"
}

# setup all of the things
time setup-workstation