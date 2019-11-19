#!/bin/bash
MY_GIT_EMAIL="jim.andreasen@reifnir.com"
MY_GIT_NAME="Jim Andreasen"
MY_WINDOWS_USERNAME="reifn"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

sh "$SCRIPT_DIR/apt-install-azure-cli.sh"
sh "$SCRIPT_DIR/apt-install-kubect-cli.sh"
sh "$SCRIPT_DIR/apt-install-docker.sh"
sh "$SCRIPT_DIR/install-gofish.sh"

gofish install helm

echo "Install all the things..."
sudo apt install -y \
    python3 \
    python3-pip

sudo apt update
sudo apt upgrade -y

# Current user only. Don't sudo!
echo "pip3 installed packages..."
pip3 install awscli --upgrade --user

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
if [ -d ~/.ssh ]; then
    rm ~/.ssh
fi
ln -s "/mnt/c/Users/$MY_WINDOWS_USERNAME/.ssh" ~/.ssh
