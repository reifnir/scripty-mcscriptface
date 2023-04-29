#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export NONINTERACTIVE=1

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
  echo "Ansible not found. Installing Ansible..."
  sudo apt-get update
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository --yes --update ppa:ansible/ansible
  sudo apt-get install -y ansible
fi

pushd "$SCRIPT_DIR/ansible"

# Install required Ansible collection
echo "Installing required Ansible collection..."
ansible-galaxy collection install -r requirements.yml

# Run Ansible playbook to install tools
echo "Running Ansible playbook to install tools..."
ansible-playbook -i hosts install_tools.yml

# Clean up
popd

echo "Installation complete."
