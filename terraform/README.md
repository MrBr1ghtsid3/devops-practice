# Terraform — Azure Infrastructure

DRY module/environment structure. Modules are environment-agnostic; environments
are thin wrappers that call modules with different variable values.

## Structure

```
terraform/
├── versions.tf          # reference: provider version constraints (not executed directly)
├── .tflint.hcl          # tflint azurerm ruleset config
├── modules/             # reusable, environment-agnostic modules
│   ├── foundation/      # resource group
│   ├── identity/        # managed identities, OIDC federation, RBAC
│   ├── networking/      # VNet, subnets, NSGs
│   ├── compute/         # NICs, Linux VMs
│   ├── storage/         # storage accounts, containers
│   ├── data/            # databases (Azure SQL, Cosmos DB)
│   ├── security/        # Key Vault, secrets
│   ├── observability/   # Log Analytics, Application Insights
│   └── ai/              # Azure AI / OpenAI
└── environments/
    ├── sbox/            # sandbox — small SKUs, 10.10.x address space
    └── prod/            # production — larger SKUs, 10.20.x address space
```

## Local validation

Run from the repo root:

```sh
# Format check across all Terraform files
terraform fmt -check -recursive terraform/

# Sbox
terraform -chdir=terraform/environments/sbox init -backend=false
terraform -chdir=terraform/environments/sbox validate

# Prod
terraform -chdir=terraform/environments/prod init -backend=false
terraform -chdir=terraform/environments/prod validate
```

For a local plan (requires Azure credentials):

```sh
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"

terraform -chdir=terraform/environments/sbox init
terraform -chdir=terraform/environments/sbox plan -var-file=sbox.tfvars
```

## Before first apply

1. Uncomment and populate `backend.tf` in each environment (separate containers).
2. Create Azure Storage containers for state — sbox and prod **must** be isolated.
3. Set up OIDC workload identity federation in Azure for each environment principal.
4. Configure GitHub repository variables and secrets (see table below).
5. Create a GitHub Environment named `production` and add a required reviewer.

## CI/CD pipelines

| Workflow | Trigger | What it does |
|---|---|---|
| `tf-1-validate` | PR touching `terraform/**` | fmt, init, validate, tflint, checkov — matrix over sbox + prod |
| `tf-2-deploy-sbox` | Push to `master` | OIDC → init / plan / apply (sbox) |
| `tf-3-deploy-prod` | `workflow_dispatch` only | Plan job then gated apply (`environment: production`) |

### Required GitHub repository variables (`vars.*`)

| Name | Description |
|---|---|
| `ARM_TENANT_ID` | Azure tenant GUID |
| `ARM_SUBSCRIPTION_ID_SBOX` | Sandbox subscription GUID |
| `ARM_CLIENT_ID_SBOX` | Sandbox managed identity / app registration client ID |
| `ARM_SUBSCRIPTION_ID_PROD` | Production subscription GUID |
| `ARM_CLIENT_ID_PROD` | Production managed identity / app registration client ID |

### Required GitHub repository secrets (`secrets.*`)

| Name | Description |
|---|---|
| `ADMIN_SSH_PUBLIC_KEY` | SSH public key deployed to VM admin user |
