# Prompt: Add AVD Host Pool to the Azure Terraform Structure

**Purpose:** Reusable Claude Code prompt that (a) generates a new `avd` module and
(b) updates the existing environment files to wire it in — matching the established
DRY module/environment structure. Deploys an Azure Virtual Desktop host pool.

**Model used:** Claude Opus 4.8 via Claude Code
**Last validated:** [YYYY-MM-DD] — Terraform [version] / azurerm provider 4.x
**Scope note:** Azure only. Generates a working skeleton with boilerplate bodies;
session-host registration and the identity/domain-join model are deliberately left
as TODO (see ADR-003). Not deployable until those are completed and state/OIDC wired.

---

## The Prompt

> In this repo's existing Terraform structure under `terraform/`, add Azure Virtual
> Desktop support as a NEW module and wire it into the environments. Match the existing
> conventions exactly — do not invent a different pattern. Create files in their final
> nested paths; afterwards run `terraform fmt -recursive` and
> `cd terraform/environments/sbox && terraform init -backend=false && terraform validate`.
>
> **Respect the existing structure:**

> - Modules are environment-agnostic, written once under `terraform/modules/`.
> - Environments under `terraform/environments/{sbox,prod}` are thin — they call modules
>   with tfvars. No resource definitions in environment files.
> - No hardcoded values in the module. Cross-module references use outputs — the AVD
>   session-host NICs take `subnet_id` from `module.networking.subnet_ids[...]`.
> - Module convention: `main.tf` + `variables.tf` + `outputs.tf`, with the standard
>   inputs `name_prefix`, `resource_group_name`, `location`, `tags`.
>
> **1. CREATE `terraform/modules/avd/` with:**

> - `main.tf`: host pool (`azurerm_virtual_desktop_host_pool`), registration info/token
>   (`..._host_pool_registration_info`), desktop application group
>   (`..._application_group`), workspace (`..._workspace`) + workspace-to-app-group
>   association, session-host NICs (`for_each`), and Windows session-host VMs
>   (`azurerm_windows_virtual_machine`, `for_each`). Leave as TODO: os_disk,
>   source_image_reference, admin password via Key Vault (never inline), MI identity
>   block, and the AVD agent + registration VM extension that consumes the token.
> - `variables.tf`: the four standard inputs plus `subnet_id`, `host_pool_type`
>   (default "Pooled"), `load_balancer_type` (default "BreadthFirst"),
>   `max_sessions_allowed`, `start_vm_on_connect`, `validate_environment`,
>   `registration_expiration` (RFC3339), `application_group_type` (default "Desktop"),
>   and `session_hosts` (map of name => {size, admin_username}).
> - `outputs.tf`: `host_pool_id`, `host_pool_name`, `workspace_id`,
>   `application_group_id`, `registration_token` (marked `sensitive = true`),
>   `session_host_ids`.
>
> **2. UPDATE the existing environment files (do not recreate them — edit in place):**

> - `environments/sbox/main.tf` and `environments/prod/main.tf`: add a `module "avd"`
>   block calling `../../modules/avd`, passing `subnet_id =
>   module.networking.subnet_ids[var.avd_subnet_key]` and
>   `registration_expiration = timeadd(timestamp(), "4h")`.
> - `environments/sbox/variables.tf` and `environments/prod/variables.tf`: add
>   `avd_subnet_key`, `avd_host_pool_type`, `avd_max_sessions`, and `avd_session_hosts`.
> - `environments/sbox/sbox.tfvars`: SANDBOX values — one small session host
>   (Standard_B2ms), `avd_max_sessions = 2`, subnet key "app".
> - `environments/prod/prod.tfvars`: PROD values — two larger hosts
>   (Standard_D4s_v5), `avd_max_sessions = 10`, subnet key "app".
>
> **3. Do NOT add a new pipeline** — AVD flows through the existing validate / sbox /
> prod pipelines unchanged.
>
> Before finishing, report: (a) which TODOs block an actual `apply` (registration
> extension, identity/domain-join — point me at ADR-003), and (b) the validation
> commands run and their result.

---

## Caveats / things to check by hand

- **Session-host registration is the hard part** and is intentionally left TODO. The
  AVD agent + DSC/VM extension that joins a host to the pool needs the *current*
  Microsoft-published artifact — check the registry/docs at build time rather than
  trusting boilerplate.
- **Identity model is a real decision (ADR-003):** Entra-joined vs AD DS / Entra DS
  domain-joined materially changes the VM config. Do not let the scaffold silently
  assume one.
- **`registration_expiration` uses `timestamp()`** which changes every plan — expect
  perpetual diffs on that field unless you pin it. Acceptable for sandbox; revisit for
  prod (e.g. set explicitly or use `ignore_changes`).
- **`registration_token` is sensitive** — ensure it is never written to logs or
  non-sensitive outputs.
- **Validate locally** — `terraform validate` in the sbox env after wiring. The
  `timeadd`/`timestamp` expression and the for_each session-host map are the most
  fragile parts.
