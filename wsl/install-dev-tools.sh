#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export NONINTERACTIVE=1

GIT_NAME=""
GIT_EMAIL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --git-name)
      GIT_NAME="$2"
      shift 2
      ;;
    --git-email)
      GIT_EMAIL="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 --git-name 'Your Name' --git-email 'your@email.com'"
      exit 1
      ;;
  esac
done

if [[ -z "$GIT_NAME" ]]; then
  echo "Error: --git-name is required"
  echo "Usage: $0 --git-name 'Your Name' --git-email 'your@email.com'"
  exit 1
fi

if [[ -z "$GIT_EMAIL" ]]; then
  echo "Error: --git-email is required"
  echo "Usage: $0 --git-name 'Your Name' --git-email 'your@email.com'"
  exit 1
fi

# Bootstrap passwordless sudo before Ansible runs.
# Ansible's become mechanism on WSL local connections uses pexpect to detect
# the sudo prompt and send the password, but WSL's PTY handling causes it to
# time out even when the prompt appears. We create the sudoers entry here via
# a direct terminal sudo call so all subsequent Ansible become tasks run
# without needing any password interaction.
SUDOERS_FILE="/etc/sudoers.d/$(whoami)-nopasswd"
if [[ ! -f "$SUDOERS_FILE" ]]; then
  echo "Configuring passwordless sudo (you will be prompted for your password once)..."
  echo "$(whoami) ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
  sudo chmod 440 "$SUDOERS_FILE"
  echo "Done."
fi

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
  echo "Ansible not found. Please install Ansible."
  exit 1
fi

pushd "$SCRIPT_DIR/ansible"

# Install required Ansible collection
echo "Installing required Ansible collection..."
ansible-galaxy collection install -r requirements.yml

# Run Ansible playbook to install tools
echo "Running Ansible playbook to install tools..."
ansible-playbook install_tools.yml -e "git_name=$GIT_NAME" -e "git_email=$GIT_EMAIL"

# Clean up
popd

echo "Installation complete."
