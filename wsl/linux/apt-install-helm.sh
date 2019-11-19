# installing GoFish...
curl -fsSL https://raw.githubusercontent.com/fishworks/gofish/master/scripts/install.sh | bash
gofish init
gofish upgrade gofish

# install Helm
gofish install helm
gofish upgrade helm
