# Prompt: Scaffold Azure Terraform — DRY Module/Environment Structure

**Purpose:** Reusable Claude Code prompt to scaffold (or re-scaffold) the Azure
Terraform body of work in this repo with the correct nested directory structure,
avoiding flattening on creation.

**Model used:** Claude Opus 4.8 via Claude Code
**Last validated:** [YYYY-MM-DD] — Terraform [version] / azurerm provider 4.x
**Scope note:** Azure only (AWS/GCP out of scope). Generates skeleton with stubbed
resource bodies — not deployable infrastructure until modules are implemented and
the state backend + OIDC are wired by the maintainer.

---

## The Prompt

> Scaffold an Azure Terraform structure under `terraform/` in this repo. Create the
> files directly in their final nested paths — do NOT create them flat and move them.
> After creating, run `find terraform -type f | sort` and `terraform fmt -recursive`
> to confirm the tree and formatting.
>
> **Design constraints (do not deviate):**
> - Azure only. Provider `hashicorp/azurerm ~> 4.0`, `hashicorp/azuread ~> 3.0`.
> - DRY: modules are written ONCE and environment-agnostic. Environments are THIN —
>   they call modules with different `.tfvars`, never duplicate resource definitions.
> - No hardcoded values in modules. Everything via variables. Cross-module references
>   use outputs (e.g. compute reads `module.networking.subnet_ids[...]`), never literals.
> - Auth: OIDC / workload identity federation. No client secrets anywhere.
> - State backend: leave `backend.tf` as a commented placeholder per environment, with
>   SBOX and PROD state isolated (separate containers). I wire this myself.
>
> **Create this structure:**
> ```
> terraform/
> ├── README.md
> ├── versions.tf                      # core >= 1.9, azurerm ~>4, azuread ~>3
> ├── modules/                         # each: main.tf + variables.tf + outputs.tf
> │   ├── foundation/  identity/  networking/  compute/
> │   ├── storage/  data/  security/  observability/  ai/
> ├── environments/
> │   ├── sbox/   (main.tf, variables.tf, providers.tf, backend.tf, sbox.tfvars)
> │   └── prod/   (main.tf, variables.tf, providers.tf, backend.tf, prod.tfvars)
> └── .github/workflows/               # pipelines go HERE so they actually run
>     ├── tf-1-validate.yml
>     ├── tf-2-deploy-sbox.yml
>     └── tf-3-deploy-prod.yml
> ```
>
> **Implement with working skeletons (not just stubs):** `networking` (vnet, subnets
> via for_each, NSGs + associations, outputs exposing `subnet_ids`) and `compute`
> (NICs + linux VMs via for_each, `subnet_id` as an input variable). All other modules:
> standard main/variables/outputs trilogy with TODO bodies but real variable contracts
> (`name_prefix`, `resource_group_name`, `location`, `tags`).
>
> **Environments:** `sbox/main.tf` and `prod/main.tf` are structurally identical —
> both call foundation → networking → compute, wiring `subnet_id` from the networking
> output. Difference lives only in tfvars: sbox uses small SKUs (Standard_B1s) and
> 10.10.x address space; prod uses larger SKUs (Standard_D2s_v5), two VMs, 10.20.x.
>
> **Pipelines (in `.github/workflows/`):**
> 1. Validate — on PR touching `terraform/**`: `fmt -check`, `init -backend=false`,
>    `validate`, `tflint`, `checkov`. No Azure auth. Matrix over [sbox, prod].
> 2. Deploy sbox — on push to `master`: OIDC auth (`id-token: write`,
>    `ARM_USE_OIDC=true`), init/plan/apply with `sbox.tfvars`.
> 3. Deploy prod — `workflow_dispatch` only: OIDC, plan job + separate apply job
>    gated on `environment: production` (required-reviewer gate). Never auto-apply.
>
> Before finishing, tell me: (a) anything that must be configured in Azure or GitHub
> that cannot be expressed as code, and (b) the local validation commands to run.

---

## Caveats / things to check by hand

- **Pipelines must live in `.github/workflows/` to run.** GitHub Actions does not
  execute YAML from arbitrary folders. If kept under `terraform/` they are inert
  reference only. No spaces in folder names.
- **azurerm 4.x needs an explicit `subscription_id`** for local runs — export
  `ARM_SUBSCRIPTION_ID` or the provider errors. CI gets it from OIDC env vars.
- **The required-reviewer gate is a GitHub Environment setting,** not YAML. The
  pipeline references `environment: production`; the gate only exists once you add a
  reviewer in repo settings. (Same pattern as branch-protection: code declares intent,
  settings enforce it.)
- **State isolation is non-negotiable** — sbox and prod must use separate containers
  or a sbox plan can show prod drift.
- **Validate locally before commit:** `terraform fmt -recursive`, then per environment
  `terraform init -backend=false && terraform validate`. The `for`-expression wiring
  subnet_ids in environment `main.tf` is the most syntax-fragile part.
