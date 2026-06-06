# Proof of Concept: [Title — e.g. "Ansible Provisioning of Windows Hosts via WinRM/NTLM over Terraform-deployed VMs"]

**Author:** Tsvetoslav Shalev
**Date:** YYYY-MM-DD
**Status:** `In Progress` | `Completed` | `Abandoned`
**Repository:** [Link to associated code]

---

## Problem Statement

*What problem is this PoC trying to solve or validate? What was the trigger — a gap in capability, a tool evaluation, a compliance requirement? Keep this to one or two focused paragraphs.*

> **Example:**
> Existing VM provisioning across Azure environments relies entirely on manual configuration post-deployment. Terraform handles infrastructure provisioning, but application-layer configuration — software installation, service hardening, registry changes — requires RDP access and manual steps that are undocumented, inconsistent, and unauditable.
>
> This PoC evaluates whether Ansible can be introduced as a configuration management layer on top of Terraform-provisioned Windows VMs, using WinRM with NTLM authentication to reach hosts that are domain-joined but not publicly accessible.

---

## Objectives

*List the specific things this PoC is trying to prove or disprove. Frame as testable questions or hypotheses.*

- [ ] Can Ansible reach Windows hosts via WinRM/NTLM without installing additional agents?
- [ ] Can Terraform output VM hostnames and feed them into a dynamic Ansible inventory?
- [ ] Can an Ansible playbook idempotently install and configure a target software stack on a freshly provisioned VM?
- [ ] What is the failure mode when WinRM is blocked at the NSG level?

---

## Scope

### In Scope
- Terraform deployment of one or more Azure Windows VMs (Standard_B2s or equivalent)
- WinRM/NTLM configuration on target VMs via Custom Script Extension
- Ansible playbook execution against dynamic inventory
- Basic idempotency validation (running the playbook twice produces no changes on second run)

### Out of Scope
- Domain join configuration
- Production-grade secret management (Key Vault integration deferred)
- CI/CD pipeline integration (addressed in separate PoC)
- Linux host provisioning

---

## Architecture / Design

*Describe the approach at a high level. A simple ASCII diagram or Mermaid block is often enough.*

```
┌─────────────────────────────────────────────┐
│                Azure Subscription            │
│                                              │
│  ┌──────────┐    Terraform    ┌───────────┐  │
│  │ Control  │ ─────────────► │  Windows  │  │
│  │  Node    │                │    VM     │  │
│  │ (Ubuntu) │ ◄── WinRM/NTLM─┤  (Target) │  │
│  │          │   Ansible       │           │  │
│  └──────────┘                └───────────┘  │
│                                              │
│  NSG: Allow 5985 (WinRM HTTP) from           │
│       control node private IP only           │
└─────────────────────────────────────────────┘
```

---

## Technology Choices

| Component | Choice | Rationale |
|---|---|---|
| IaC | Terraform (HCL) | Existing team standard; HashiCorp certified |
| Configuration management | Ansible (ansible-core) | Agentless; aligns with Bulgarian market demand |
| Authentication | WinRM / NTLM | No Kerberos infrastructure required for PoC scope |
| VM OS | Windows Server 2022 | Representative of production target environment |
| Control node | Ubuntu 24.04 LTS | Local lab machine (ThinkBook 13s) |
| Inventory | Dynamic — Terraform outputs → Ansible vars | Avoids manual inventory maintenance |

---

## Implementation

*Walk through what was built and how. Reference specific files, commands, or configuration blocks where useful. This section is the technical record — be specific.*

### Step 1: Terraform — VM Provisioning and WinRM Bootstrap

- Deployed VM using `azurerm_windows_virtual_machine` resource
- Enabled WinRM via Custom Script Extension running `winrm quickconfig`
- NSG rule restricting port 5985 to control node private IP only
- Terraform `output` block exposing `vm_private_ip` for Ansible consumption

### Step 2: Ansible — Inventory and Connectivity

- Used `ansible.windows` collection (`winrm` connection plugin)
- Inventory file populated from Terraform output via shell script wrapper
- `ansible -m win_ping` used to validate connectivity before playbook execution

### Step 3: Ansible — Playbook

- Tasks: install Chocolatey, install target packages, validate service state
- Handlers used for service restart on configuration change
- `--check` mode validated idempotency without making changes

---

## Results

*What did you find? What worked, what didn't, and what surprised you?*

| Objective | Result | Notes |
|---|---|---|
| WinRM/NTLM connectivity | ✅ Achieved | Required explicit `ansible_winrm_transport: ntlm` |
| Dynamic inventory from Terraform | ✅ Achieved | Shell wrapper adds minor friction — investigate `terraform-inventory` plugin |
| Idempotent playbook | ✅ Achieved | Second run: 0 changes, 0 failures |
| NSG blocking failure mode | ✅ Validated | `unreachable` error — clear and actionable |

---

## Limitations

*What was not addressed, simplified, or left as a known gap?*

- NTLM authentication is acceptable for PoC; production should evaluate Kerberos or certificate-based auth
- WinRM over HTTP (5985) acceptable in private VNet context; HTTPS (5986) required for public-facing hosts
- No secret rotation — VM admin password stored in Terraform state (not acceptable for production)
- Tested against a single VM; dynamic inventory behaviour at scale not validated

---

## Recommendations

*What should happen next based on these findings?*

- Proceed with Ansible integration for Windows host configuration — approach is viable
- Prioritise Key Vault integration for credential management before extending to production environments
- Evaluate `ansible-lint` gate in CI pipeline to enforce playbook quality
- Document WinRM NSG requirements as a pre-requisite for any future Ansible-managed VM deployment

---

## References

- [Ansible Windows Guide](https://docs.ansible.com/ansible/latest/os_guide/windows_usage.html)
- [Terraform azurerm_windows_virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine)
- [Related ADR: ADR-001 — Configuration Management Tooling Selection]
