# DevOps Practice | 🚧 in progress

Personal learning repository for DevOps tooling and skills. All work happening in Linux.

## Tech Stack

- **Ansible**: configuration management and automation
- **Vagrant + VirtualBox**: local multi-VM practice environments
- **Python**: scripting and Ansible module development
- **Docker / Kubernetes**: containerisation (upcoming)
- **Git**: version control for all infrastructure-as-code
- **Terraform**: also for deployments via IaC
- **PowerShell**: scripting for Windows and hybrid administrative tasks
- **Claude Code**: for prompt engineering

## Environment

- **Host OS**: Ubuntu 24.04.4 LTS
- **Ansible**: core 2.16.3
- **Python**: 3.12.3
- **VirtualBox + Vagrant**
- **PowerShell**: core 7.6.2
- **Terraform**: v1.15.6
- **Claude Code in terminal & VSCode**: v2.1.183

## Directory Structure

### Ansible

- [`playbooks/`](playbooks/) - Ansible playbooks
- [`roles/`](roles/) - reusable Ansible roles
- [`inventories/`](inventories/) - inventory files (hosts, groups, variables)
- [`collections/`](collections/) - where automation modules and plugins live

### PowerShell

- [`powershell/`](powershell/) - a collection of custom PS modules

### Documentation

- [`docs/templates/`](docs/templates/) - ADR, PoC, and SoW templates

### AI Prompts

- [`prompts/`](prompts/) - capture some of the prompts used to assist with these efforts (the real value here is entirely in the careful curation).

## Challenges

A set of structured exercises and labs.

### 1. Flask App with Load Balancing

Deploy a multi-server Flask + MySQL application behind an HTTP load balancer.

- Deploy 3 servers via Vagrant
- Install Python dependencies
- Install Flask application from GitHub
- Configure MySQL
- Configure HTTP load balancing
- Set up notification email

### 2. Custom PowerShell Repository

A concept on how to handle certain administrative tasks in a Hybrid Environment (AAD/Entra).

### 3. Deploying Azure Resource using Terraform

My take on how to separate Live (prod) from Sandbox (dev) environments via Terraform.
