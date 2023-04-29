# Ansible Mac Dev Tools

This Ansible project installs a set of development tools on a Mac machine using Homebrew.

The following tools will be installed:
- Azure CLI
- Node.js
- Terraform
- Kubernetes CLI (kubectl)
- Docker and Docker Compose
- AWS CLI

## Requirements

- macOS
- Ansible
- Homebrew

## Usage

1. Clone this repository to your local machine:

```bash
git clone https://github.com/your_username/ansible-mac-dev-tools.git
cd ansible-mac-dev-tools
```

2. Open the `inventory.ini` file and modify it if needed to specify the hosts where you want to install the tools.

3. Run the Ansible playbook:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

4. Wait for the playbook to finish executing. Once it's done, all the tools should be installed on your Mac machine.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
