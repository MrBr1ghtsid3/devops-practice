# ADR-002: Azure Terraform — Module/Environment Structure, Auth, and Pipeline Model

**Status:** `Accepted`
**Date:** 2026-06-25
**Author:** Tsvetoslav Shalev
**Deciders:** Solo

---

## Context

The repository needs a maintainable Infrastructure-as-Code structure for Azure
(AWS/GCP explicitly out of scope). Requirements: distinct sandbox (SBOX) and
production (PROD) environments; organisation around the main Azure service domains
(Compute, Networking, Storage, Data, AI, plus foundational concerns); reusable VM
and Network modules; and a working pattern where a Compute resource references
networking values (e.g. subnet IDs) at a variable/output level rather than
hardcoding them. Three CI pipelines are required: plan validation, sandbox
deployment, and production deployment.

The initial sketch placed full service-folder copies inside both PROD and SBOX.
This forces the core decision below, because that layout duplicates every resource
definition across environments and invites drift.

---

## Decision

Adopt a **DRY module/environment split**: service logic lives once in
environment-agnostic modules under `modules/`; environments under `environments/`
are thin composition roots that call those modules with environment-specific
`.tfvars`. Authenticate CI to Azure via **OIDC / workload identity federation**
(no stored secrets). Use a **three-pipeline model**: validate (PR gate, no auth),
deploy-sbox (auto on merge, OIDC), deploy-prod (manual dispatch + required-reviewer
gate, OIDC). Remote state is Azure blob with **separate state per environment**;
the backend is wired by the maintainer, not committed.

---

## Options Considered

| Option | Summary | Reason Accepted / Rejected |
|---|---|---|
| **Thin environments + shared modules** | Modules written once; sbox/prod call them with tfvars | ✅ Accepted — eliminates duplication, single source of truth per service |
| **Full service-folder copies per env** | PROD/ and SBOX/ each contain complete configs | ❌ Rejected — duplicates every resource, guarantees drift over time |
| **Terragrunt wrapper** | DRY tooling layer over Terraform | ❌ Rejected (for now) — adds a dependency and hides fundamentals; plain Terraform is clearer for a portfolio piece |
| **OIDC federation** | Pipeline auth via federated identity | ✅ Accepted — no long-lived secrets, current best practice |
| **Service Principal + client secret** | Stored secret in CI | ❌ Rejected — secret lifecycle/rotation burden, weaker posture |

---

## Consequences

### Positive

- Single definition per service; environments differ only in data (tfvars).
- No secrets in source or CI; OIDC tokens are short-lived and repo-scoped.
- Production protected by a manual approval gate distinct from sandbox auto-deploy.
- State isolation prevents a sandbox plan from showing production drift.

### Negative / Trade-offs

- Some boilerplate remains between sbox and prod composition roots (accepted in
  exchange for readability; Terragrunt/workspaces deferred).
- OIDC requires up-front Azure (app registration, federated credentials, RBAC) and
  GitHub (environment variables, required reviewer) configuration that is not code.
- azurerm 4.x requires explicit `subscription_id` for local runs.

### Risks

- Misconfigured required-reviewer gate could allow unapproved prod apply — mitigated
  by treating the GitHub Environment setting as part of setup, documented in README.
- Shared-state corruption — mitigated by azurerm blob lease-based locking and
  per-environment state separation.

---

## Implementation Notes

- Modules added beyond the original five (Compute, Networking, Storage, Data, AI):
  Foundation (RG/naming/tags), Identity (MI/RBAC), Security (Key Vault),
  Observability (Log Analytics) — these are cross-cutting dependencies of the rest.
- Cross-module reference pattern: `compute` takes `subnet_id` as input; environment
  `main.tf` supplies it from `module.networking.subnet_ids[...]`.
- Pipelines live in `.github/workflows/` (not `terraform/`) so they execute.
- Scaffold prompt: `prompts/scaffold-azure-terraform.md`

---

## References

- Related ADR: ADR-001 — PowerShell Module Structure and Compatibility Target
- Azure provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest
- OIDC for Azure in GitHub Actions:
  https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect
