# Statement of Work: [Project Title — e.g. "Azure APIM LLM Gateway — Phase 1 Implementation"]

**Author:** Tsvetoslav Shalev
**Date:** YYYY-MM-DD
**Version:** 1.0
**Status:** `Draft` | `Under Review` | `Approved` | `Superseded`
**Related ADR(s):** [e.g. ADR-003]
**Related PoC(s):** [e.g. PoC — APIM Policy Validation]

---

## 1. Project Overview

*A brief, non-technical summary of what is being built and why. Should be readable by a non-technical stakeholder.*

> **Example:**
> This work delivers Phase 1 of a centralised LLM access gateway, placing Azure API Management (APIM) in front of all Azure AI Foundry / Azure OpenAI endpoints. The gateway enforces authentication, applies per-consumer rate limiting, and routes all LLM traffic through a single, auditable layer. Phase 1 covers core gateway provisioning, authentication policy, and observability instrumentation. Consumer onboarding and prompt lifecycle management are deferred to Phase 2.

---

## 2. Objectives

*The specific goals this work is intended to achieve. Should be measurable where possible.*

- Deploy APIM instance in the target Azure subscription with VNet integration
- Implement JWT-based authentication for all API consumers
- Apply per-subscription rate limiting (configurable per consumer tier)
- Route all AI Foundry / OpenAI backend calls through APIM
- Instrument request logging to Log Analytics workspace
- Deliver all infrastructure as Terraform-managed IaC, committed to version control with CI pipeline validation

---

## 3. Scope

### 3.1 In Scope

- APIM instance provisioning (Developer or Standard tier based on cost/requirements review)
- Backend configuration for Azure AI Foundry endpoints
- Inbound policy: JWT validation via Azure AD
- Inbound policy: rate limiting by subscription key
- Outbound policy: response header sanitisation
- Log Analytics workspace integration via Diagnostic Settings
- Terraform modules for all provisioned resources
- Azure DevOps YAML pipeline: validate → plan → apply
- README documentation for each module

### 3.2 Out of Scope

- Developer Portal customisation and consumer self-service onboarding
- Prompt flow management or model lifecycle tooling
- Multi-region APIM deployment or availability zone redundancy
- Custom domain configuration
- APIM backup and disaster recovery configuration
- Consumer application code changes

---

## 4. Deliverables

| Deliverable | Description | Format |
|---|---|---|
| Terraform module — APIM core | Provisions APIM instance, VNet integration, Diagnostic Settings | HCL |
| Terraform module — Backend | Configures AI Foundry backend endpoints | HCL |
| Policy files | JWT validation, rate limiting, response sanitisation | XML (APIM policy) |
| Azure DevOps pipeline | validate / plan / apply pipeline with approvals gate | YAML |
| ADR | Documents APIM selection rationale and policy decisions | Markdown |
| PoC report | Findings from policy validation PoC | Markdown |
| README | Module usage, prerequisites, configuration reference | Markdown |

---

## 5. Technical Approach

*How the work will be executed. Describe the architecture, tooling, and methodology at enough detail for a technical reviewer.*

### 5.1 Infrastructure as Code

All resources provisioned via Terraform. Module structure:

```
/terraform
  /modules
    /apim-core         # APIM instance, VNet, Diagnostic Settings
    /apim-backend      # Backend configurations per AI Foundry endpoint
    /apim-policy       # Policy assignments
  /environments
    /dev
    /prod
```

### 5.2 Policy Design

Policies applied at the API level (not product or operation level) to ensure consistent enforcement. Policy execution order:

1. **Inbound:** Validate JWT → Extract consumer identity → Apply rate limit
2. **Backend:** Route to AI Foundry endpoint → Set backend credentials via Named Values
3. **Outbound:** Strip internal response headers → Log to Event Hub
4. **Error:** Return standardised error schema

### 5.3 CI/CD Pipeline

Three-stage Azure DevOps pipeline:

```yaml
stages:
  - Validate   # terraform fmt, validate, tflint, policy XML lint
  - Plan       # terraform plan with artifact output
  - Apply      # Manual approval gate → terraform apply
```

### 5.4 Observability

- Diagnostic Settings → Log Analytics workspace
- Log categories: GatewayLogs, WebSocketConnectionLogs
- KQL query library for per-consumer request volume, error rates, latency percentiles
- Azure Monitor alert rule: >10% 5xx error rate over 5-minute window

---

## 6. Dependencies and Assumptions

| Item | Detail |
|---|---|
| Azure subscription | Target subscription with Contributor access for deployment |
| Azure AD tenant | Application registration for JWT authority |
| Existing Log Analytics workspace | If none exists, provisioning included in scope |
| VNet with available subnet | /27 minimum for APIM subnet; NSG pre-configured |
| AI Foundry deployment | Assumes existing Azure AI Foundry resource with deployed model |
| Terraform state backend | Azure Storage account + container for remote state |
| Azure DevOps project | Pipeline service connection with appropriate RBAC |

---

## 7. Success Criteria

*How will we know this work is complete and correct?*

- [ ] APIM instance provisioned and accessible within VNet
- [ ] JWT validation policy rejects requests with invalid or expired tokens (tested via `curl`)
- [ ] Rate limiting enforced — confirmed by exceeding limit and observing 429 response
- [ ] AI Foundry backend returning responses through APIM proxy
- [ ] GatewayLogs appearing in Log Analytics within 5 minutes of request
- [ ] `terraform plan` on unchanged infrastructure returns 0 changes to add, change, or destroy
- [ ] CI pipeline passes on main branch with no manual intervention
- [ ] All resources tagged per organisational tagging standard
- [ ] README sufficient for a new team member to deploy to a new environment without assistance

---

## 8. Timeline and Milestones

| Milestone | Target Date | Dependencies |
|---|---|---|
| VNet subnet and NSG confirmed | DD/MM/YYYY | Platform team |
| APIM core module complete | DD/MM/YYYY | — |
| Policy files validated via PoC | DD/MM/YYYY | APIM core |
| CI pipeline operational | DD/MM/YYYY | Azure DevOps service connection |
| End-to-end test passing | DD/MM/YYYY | All above |
| Documentation complete | DD/MM/YYYY | Implementation complete |

---

## 9. Resources Required

| Resource | Detail |
|---|---|
| Engineer | Tsvetoslav Shalev — sole implementer |
| Azure subscription | Contributor access |
| Azure DevOps | Project with pipeline and service connection access |
| APIM tier | Developer (PoC/lab) or Standard (production) |
| Estimated Azure cost | ~€40–300/month depending on APIM tier and traffic volume |

---

## 10. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| APIM subnet size insufficient | Low | High | Confirm /27 minimum before provisioning |
| JWT authority misconfiguration passes unauthorised requests | Medium | High | Integration test suite in CI validates reject behaviour |
| AI Foundry endpoint quota exhausted during testing | Medium | Low | Use separate dev deployment with rate limit headroom |
| Policy XML errors not caught until apply | Low | Medium | XML lint step in validate stage of pipeline |

---

## 11. References

- [Azure API Management documentation](https://learn.microsoft.com/en-us/azure/api-management/)
- [Azure AI Foundry documentation](https://learn.microsoft.com/en-us/azure/ai-studio/)
- [Terraform azurerm_api_management](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management)
- [Related ADR — link]
- [Related PoC — link]
