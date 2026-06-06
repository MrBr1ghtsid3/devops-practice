# ADR-[NUMBER]: [Short Title — e.g. "Use APIM as the LLM Gateway Layer"]

**Status:** `Proposed` | `Accepted` | `Deprecated` | `Superseded by ADR-[NUMBER]`
**Date:** YYYY-MM-DD
**Author:** Tsvetoslav Shalev
**Deciders:** [Who was involved in this decision — e.g. Platform Team, Architect, Solo]

---

## Context

*What is the situation forcing this decision? Describe the problem, the constraints, and the forces at play. Be specific about the environment — cloud platform, compliance requirements, team size, existing tooling.*

> **Example:**
> The organisation requires a centralised, auditable access layer for all LLM API calls across multiple Azure subscriptions. Calls are currently made directly from application code to Azure OpenAI endpoints with no rate limiting, authentication enforcement, or request logging. This creates compliance gaps and makes it impossible to attribute costs or audit prompt activity per consumer.

---

## Decision

*State the decision clearly and directly. One paragraph, no hedging.*

> **Example:**
> We will deploy Azure API Management (APIM) in front of all Azure AI Foundry / Azure OpenAI endpoints. All consumer applications will route LLM requests through APIM. APIM will enforce JWT-based authentication, apply per-consumer rate limiting, and log all requests to a centralised Log Analytics workspace.

---

## Options Considered

*List the alternatives evaluated. For each, note the key trade-off that ruled it in or out.*

| Option | Summary | Reason Accepted / Rejected |
|---|---|---|
| **Azure APIM** | Managed API gateway, native Azure integration, policy engine | ✅ Accepted — native auth, logging, and rate limiting with minimal operational overhead |
| **Custom Python proxy** | FastAPI service acting as a pass-through with logging | ❌ Rejected — high maintenance burden, no built-in policy engine, requires dedicated compute |
| **Azure Front Door** | CDN/load balancer with WAF capabilities | ❌ Rejected — not designed for API management semantics; lacks subscription and product model |
| **Kong Gateway** | Open-source API gateway | ❌ Rejected — infrastructure overhead and operational complexity unjustified for Azure-native workload |

---

## Consequences

### Positive
- Centralised rate limiting and authentication enforcement
- Full request/response audit trail in Log Analytics
- Consumer-level attribution for cost management
- Reduced risk of prompt injection reaching backend directly

### Negative / Trade-offs
- APIM introduces latency (~20–50ms per request depending on policy complexity)
- Requires APIM provisioning and ongoing policy maintenance
- Developer Portal onboarding needed for new API consumers
- Premium tier required for VNet integration; cost implication

### Risks
- Policy misconfiguration could silently pass unauthorised requests — mitigated by integration tests in CI pipeline
- APIM regional availability affects resilience — mitigated by deploying in the same region as AI Foundry endpoints

---

## Implementation Notes

*Optional: any specific configuration decisions, links to related resources, or follow-up actions.*

- Policy template repo: `[link]`
- Related PoC: `[link]`
- Azure APIM documentation: https://learn.microsoft.com/en-us/azure/api-management/

---

## References

- [Link to relevant RFC, ticket, or design document]
- [Link to any prior ADR this supersedes or relates to]
