#!/bin/bash

# Don't sudo this script... there are pip3 installs in there
sh ./setup-base.sh

echo "Connect Docker CLI to Windows docker daemon port"
# First clear any previous statement that begins with 'export DOCKER_HOST=' from ~/.bashrc
sed -i "/export DOCKER_HOST=/d" ~/.bashrc
echo "export DOCKER_HOST=tcp://localhost:23750" >> ~/.bashrc && source ~/.bashrc
export DOCKER_HOST=tcp://localhost:23750

# DOCKER HELP!: I keep seeing: ERROR: Cannot connect to the Docker daemon at tcp://localhost:23750. Is the docker daemon running?
# (thanks to this: https://forums.docker.com/t/wsl-and-docker-for-windows-cannot-connect-to-the-docker-daemon-at-tcp-localhost-2375-is-the-docker-daemon-running/63571/13)
# Run the following FROM WINDOWS once and you're perpetually GTG
# docker run -d --restart=always -p 127.0.0.1:23750:2375 -v /var/run/docker.sock:/var/run/docker.sock alpine/socat tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock
