# ADR-003: AVD Session Host Identity and Domain-Join Model

**Status:** `Proposed`  <!-- set to Accepted once you confirm the choice below -->
**Date:** 2026-06-25
**Author:** Tsvetoslav Shalev
**Deciders:** Solo

---

## Context

The `avd` module (added per the AVD scaffolding work) provisions an Azure Virtual
Desktop host pool, application group, workspace, and Windows session-host VMs. Before
session hosts can be joined to the pool and made usable, an identity model must be
chosen: how the session-host VMs authenticate users and where profiles live.

This decision is required because it materially changes the VM configuration
(join extension, required infrastructure, profile storage) and cannot be deferred
without leaving the module non-deployable. The choice also has cost and operational
consequences disproportionate to its apparent size.

The three viable models for session-host identity:

- **Entra-joined** — VMs joined directly to Microsoft Entra ID. No domain controllers
  required. Simplest infrastructure; some legacy app and SSO scenarios are constrained.
- **AD DS domain-joined** — VMs joined to self-managed Active Directory Domain Services
  (domain controllers running as VMs, or on-prem via hybrid connectivity). Maximum
  compatibility; maximum operational overhead.
- **Microsoft Entra Domain Services (Entra DS) joined** — managed domain service.
  Middle ground: traditional domain-join semantics without running DCs, at a standing
  monthly cost for the managed domain.

Profile management (FSLogix) typically pairs with this decision, usually backed by an
Azure Files share whose authentication method depends on the join model chosen.

---

## Decision

> **[TO CONFIRM]** For the sandbox/portfolio scope, adopt **Entra-joined** session
> hosts — the simplest path to a working, connectable desktop, with no domain
> controllers or managed-domain cost. FSLogix profile storage deferred until past the
> sandbox proof. Revisit for any scenario requiring legacy AD-dependent applications.

*(Leave as Proposed until confirmed. If the target scenario needs AD DS app
compatibility, the decision flips to Entra DS — and the consequences below change.)*

---

## Options Considered

| Option | Summary | Reason Accepted / Rejected |
|---|---|---|
| **Entra-joined** | Direct Entra ID join, no DCs | ✅ Proposed — lowest infrastructure and cost; sufficient for sandbox + most modern apps |
| **Entra DS-joined** | Managed domain, classic semantics | ◻️ Fallback — choose if legacy AD-dependent apps are required; adds standing managed-domain cost |
| **AD DS domain-joined** | Self-managed domain controllers | ❌ Rejected for this scope — operational overhead of running DCs unjustified for a portfolio/sandbox deployment |

---

## Consequences

### Positive (Entra-joined)

- No domain controllers or managed domain to provision, secure, or pay for.
- Fastest path to a connectable desktop; minimal moving parts in the module.
- Aligns with current Microsoft direction for cloud-native AVD.

### Negative / Trade-offs

- Some legacy applications and certain SSO/Kerberos scenarios are constrained or need
  extra configuration under Entra-join.
- FSLogix on Azure Files with Entra-join has specific auth requirements that must be
  set up before profile roaming works — deferred, so sandbox profiles are local/non-roaming.

### Risks

- If a future requirement needs AD DS compatibility, migrating join model is disruptive
  — mitigated by treating this as a sandbox-scope decision, explicitly revisitable.

---

## Implementation Notes

- Session-host VM config in `modules/avd/main.tf` must set the join type and the AVD
  registration extension accordingly (currently TODO).
- Registration token consumed via the module's `registration_token` (sensitive) output.
- If/when FSLogix is added, it likely warrants its own ADR (profile storage + auth).

---

## References

- Related ADR: ADR-002 — Azure Terraform Structure
- Scaffold prompt: `prompts/add-avd-hostpool.md`
- AVD identities (Entra / Entra DS / AD DS):
  https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites
