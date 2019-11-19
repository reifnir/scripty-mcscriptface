# Get packages needed for the Azure-CLI install process
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    lsb-release \
    gnupg \
    apt-transport-https


#apt-transport-https 
# Download and install the Microsoft signing key
curl -sL https://packages.microsoft.com/keys/microsoft.asc | 
    gpg --dearmor | 
    sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

# Add the Azure CLI software repository...
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | 
    sudo tee /etc/apt/sources.list.d/azure-cli.list

# Finally install Azure CLI
sudo apt-get update
sudo apt-get install azure-cli
