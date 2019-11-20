#!/bin/bash
MY_GIT_EMAIL="jandreasen@kbra.com"
MY_GIT_NAME="Jim Andreasen"
MY_WINDOWS_USERNAME="jandreasen"

function setup_workstation {
    echo "Starting: $(date)"
    upgrade_packages
    install_prerequisites
    install_kbra_certificates
    install_keys_and_package_repos
    install_cli_tools
    setup_docker_cli
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
        ca-certificates \
        curl \
        lsb-release \
        gnupg \
        apt-transport-https
}

function install_kbra_certificates {
    sudo mkdir /usr/local/share/ca-certificates/kbra
    sudo cp /mnt/c/dev/kbra-certificate-authorities/* /usr/local/share/ca-certificates/kbra
    sudo chmod 755 /usr/local/share/ca-certificates/kbra
    sudo chmod 644 /usr/local/share/ca-certificates/kbra/*
    sudo update-ca-certificates
}

function install_keys_and_package_repos {
    # Download and install the Microsoft signing key
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | 
        gpg --dearmor | 
        sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null #azure-cli

    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - #kubectl

    # Add the Azure CLI software repository...
    AZ_REPO=$(lsb_release -cs)
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
        sudo tee /etc/apt/sources.list.d/azure-cli.list

    echo "deb [arch=amd64] http://packages.cloud.google.com/apt/ kubernetes-xenial main" |
        sudo tee /etc/apt/sources.list.d/kubernetes.list
}

function install_cli_tools {
    # Finally install packages we want
    sudo apt-get update
    sudo apt install -y \
        azure-cli \
        kubectl \
        docker.io \
        python3 \
        python3-pip \
        git
}

function setup_docker_cli {
    # DOCKER HELP!: I keep seeing: ERROR: Cannot connect to the Docker daemon at tcp://localhost:23750. Is the docker daemon running?
    # (thanks to this: https://forums.docker.com/t/wsl-and-docker-for-windows-cannot-connect-to-the-docker-daemon-at-tcp-localhost-2375-is-the-docker-daemon-running/63571/13)
    # Run the following FROM WINDOWS once and you're perpetually GTG
    # docker run -d --restart=always -p 127.0.0.1:23750:2375 -v /var/run/docker.sock:/var/run/docker.sock alpine/socat tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock
    echo "Connect Docker CLI to Windows docker daemon port"
    # First clear any previous statement that begins with 'export DOCKER_HOST=' from ~/.bashrc
    sed -i "/export DOCKER_HOST=/d" ~/.bashrc
    echo "export DOCKER_HOST=tcp://localhost:23750" >> ~/.bashrc && source ~/.bashrc
    source ~/.bashrc
}

function setup_local_profile {
    echo "Initialize Git properties"
    git config --global user.email "$MY_GIT_EMAIL"
    git config --global user.name "$MY_GIT_NAME"

    echo "Make soft links to my Windows profile directories..."
    if [ -d ~/.ssh ]; then
        rm ~/.ssh -d
    fi
    ln -s "/mnt/c/Users/$MY_WINDOWS_USERNAME/.ssh" ~/
}
function cleanup {
    upgrade_packages
    sudo apt -y autoremove
    echo "Almost done! Just execute 'source ~/.bashrc' in your current shell in order to connect Docker CLI to your Windows Docker service (or just open a new shell)"
}

# setup all of the thigns
setup_workstation
