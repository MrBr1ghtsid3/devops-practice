# HerdLog — Customer Identity with Microsoft Entra External ID

A small, made-up livestock service used to learn customer identity (CIAM) on Azure:
farmers see their herds, vets also see health-check details. Customers sign themselves
up in a separate **external tenant** (Microsoft Entra External ID, the successor to
Azure AD B2C), and an API decides what to show from the role in their token.

Write-up and results: [`docs/poc-001-herdlog-external-id.md`](../docs/poc-001-herdlog-external-id.md).

![HerdLog at a glance](../docs/images/herdlog-c-at-a-glance.png)

## Layout

```
herdlog/
├── infra/                     Terraform: logs, App Insights, storage, Flex Function, APIM
│   ├── versions.tf            providers + which resource providers to register
│   ├── variables.tf
│   ├── terraform.tfvars.example   copy to terraform.tfvars (git-ignored)
│   ├── main.tf                Function App and what it needs
│   ├── apim.tf                API Management: the front door
│   ├── policies/              API policy (rate limit, validate-jwt, function key)
│   │                          + global policy (HSTS)
│   └── outputs.tf
├── api/GetHerds.cs            the C# Function (.NET 10 isolated worker)
├── tests/test-apim.sh         seven tests through APIM
└── pipelines/azure-pipelines.yml   Azure DevOps: SonarQube Cloud gate → deploy → ZAP scan
```

## What is code and what is not

| Part | How it is built |
|---|---|
| External tenant, app registrations, user flow, users | **By hand in the Entra admin centre** (steps below) |
| Function, APIM, storage, logs | Terraform (`infra/`) |
| Function code | `api/` (project generated with `func init`, see step 3) |
| Build, quality gate, deploy, scan | Azure DevOps pipeline (`pipelines/`) |

## Prerequisites

- Azure subscription with a budget alert (everything here fits free allowances)
- Terraform ≥ 1.9, Azure CLI, .NET 10 SDK, Azure Functions Core Tools 4
- For the pipeline: an Azure DevOps project, a SonarQube Cloud (free plan) organisation

## 1. External tenant (by hand)

1. Entra admin centre → **Manage tenants → Create → External**. The wizard also
   creates a resource group in your subscription; note its name.
2. In the external tenant, register **herdlog-api**:
   - *Expose an API* → add scope `Herds.Read`
   - *App roles* → add role `Vet` (allowed member types: Users/Groups)
3. Register **herdlog-web**:
   - *API permissions* → herdlog-api → `Herds.Read` (delegated) → grant admin consent
   - *Authentication* → Web redirect URI `https://jwt.ms`, tick access and ID tokens.
     **Testing only** — remove both when not testing.
4. **User flows** → *Sign up and sign in* (email + password) → add herdlog-web to it.
5. Run the user flow twice to create a farmer and a vet. Assign the vet the `Vet`
   role: *Enterprise applications* → herdlog-api → *Users and groups*.
6. To get a token: *Run user flow* → response type **access token**, scope
   herdlog-api `Herds.Read` → copy the encoded token from jwt.ms.

## 2. Azure resources (Terraform)

```bash
az login --tenant <your-workforce-tenant>
az account set --subscription <your-subscription-id>

# Register the resource providers first; Terraform may not wait for them.
for ns in Microsoft.Web Microsoft.Storage Microsoft.Insights \
          Microsoft.OperationalInsights Microsoft.ApiManagement; do
  az provider register --namespace "$ns" --wait
done

cd herdlog/infra
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## 3. The Function

```bash
cd herdlog
func init api --worker-runtime dotnet-isolated --target-framework net10.0
cd api
func new --template "HTTP trigger" --name GetHerds --authlevel function
# replace the generated GetHerds.cs with the one in this folder
dotnet build
func azure functionapp publish "$(terraform -chdir=../infra output -raw function_app_name)"
```

`func init` generates `Program.cs`, `api.csproj` and `host.json`; they are not
committed here.

## 4. Tests

```bash
cd herdlog
export FARMER='<farmer access token>' VET='<vet access token>'   # under 1 hour old
bash tests/test-apim.sh
```

| # | Call | Expected |
|---|---|---|
| 1 | No subscription key | 401 |
| 2 | Key, no token | 401 |
| 3 | Key + forged "vet" token (right claims, fake signature) | 401 |
| 4 | Key + farmer token | 200, basic fields |
| 5 | Key + vet token | 200, plus health-check fields |
| 6 | HSTS header on a 401 and on an unknown URL | `present` twice |
| 7 | 12 fast calls | 200s, then 429 |

## 5. Pipeline (Azure DevOps)

`pipelines/azure-pipelines.yml` runs in Azure DevOps, not GitHub Actions. Fill in the
`<your-…>` variables and create two service connections:

- `sonarcloud-herdlog` — SonarQube Cloud
- `azure-herdlog` — Azure Resource Manager, workload identity federation, scoped to
  the resource group only

| Stage | What it does | Stops the run? |
|---|---|---|
| Quality + Build | SonarQube Cloud wraps `dotnet build`; "Sonar way" quality gate | Yes |
| Deploy | `AzureFunctionApp@2` to the Flex Function App | Yes, on error |
| Scan | ZAP baseline against the APIM URL; report kept as an artifact | No |

Tasks are pinned to full versions (`@4.2.6`): SonarQube Cloud flags `@4` as a
supply-chain risk.

## Known limits

- The Function can still be called directly with its function key, bypassing APIM.
  Fix: Easy Auth on the Function, accepting only APIM's managed identity.
- The Function reaches its storage with an account key, not a managed identity.
- `https://jwt.ms` and implicit tokens on herdlog-web are test-only settings.
- Terraform state holds the function key in plain text: never commit state.
- The ZAP baseline only ever sees 4xx answers, because it holds no key or token.

## Pausing and clean-up

- **Pause:** `az functionapp stop -g <rg> -n <function>`, suspend the APIM
  subscription key, remove herdlog-web from the user flow, disable the pipeline.
- **Remove the Azure side:** `terraform destroy` in `infra/`. The resource group and
  the external tenant stay; a rebuild gets a new random name suffix.
