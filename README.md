# DevOps Practice

Personal learning repository for DevOps tooling and skills in Linux.

## Stack
- **Ansible** — configuration management and automation
- **Vagrant + VirtualBox** — local multi-VM practice environments
- **Python** — scripting and Ansible module development
- **Docker / Kubernetes** — containerisation (upcoming)
- **Git** — version control for all infrastructure-as-code

## Structure
- `playbooks/` — Ansible playbooks
- `roles/` — reusable Ansible roles
- `inventories/` — inventory files (hosts, groups, variables)
- `challenges/` — structured exercises and labs

## Challenges
### 1. Flask App with Load Balancing
Deploy a multi-server Flask + MySQL application behind an HTTP load balancer.
- Deploy 3 servers via Vagrant
- Install Python dependencies
- Install Flask application from GitHub
- Configure MySQL
- Configure HTTP load balancing
- Set up notification email

## Environment
- Host OS: Ubuntu 24.04.4 LTS
- Ansible: core 2.16.3
- Python: 3.12.3
- VirtualBox + Vagrant
