#!/bin/bash
echo "Showing all file extensions..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true; # show all file extensions

echo "Installing Ruby..."
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install \
  git \
  python \
  docker \
  xhyve \
  docker-machine-driver-xhyve \
  node \
  azure-cli \
;

brew tap caskroom/versions;

brew cask install \
  firefox \
  google-chrome \
  kindle \
  mactracker \
  microsoft-office \
  sublime-text \
  vagrant \
  virtualbox \
  vlc \
  calibre \
  discord \
  gimp \
  private-internet-access \
  github \
  docker \
  iterm2 \
  dotnet-sdk \
  visual-studio-code \
  minishift \
  minikube \
  filezilla \
  mysqlworkbench \
  keystore-explorer \
;

echo "Setting appropriate permissions for xhyve driver..."
sudo chown root:wheel /usr/local/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
sudo chmod u+s /usr/local/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve

