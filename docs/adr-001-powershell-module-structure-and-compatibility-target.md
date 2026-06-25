# ADR-001: PowerShell Module Structure and Compatibility Target

**Status:** `Proposed`
**Date:** 2026-06-22
**Author:** Tsvetoslav Shalev
**Deciders:** Solo

---

## Context

*What is the situation forcing this decision? Describe the problem, the constraints, and the forces at play. Be specific about the environment — cloud platform, compliance requirements, team size, existing tooling.*

Previous PowerShell work (the `ActiveDirectory` module referenced in `powershell/README.md`) targeted **Windows PowerShell 5.1** and assumed a Windows-only environment: `Cert:` drive for certificate lookups, CIM/WMI for memory and disk queries, `WindowsPrincipal` for elevation checks. That body of work managed prerequisites then layered domain-specific functions on top of existing AD cmdlets.

The current environment (this repo's primary host) is Ubuntu, and the goal is a reusable toolkit rather than a one-off script collection. A skeleton now exists at `powershell/` (commit `b9390ad`) that carries forward the same *shape* of the previous module — manifest-driven, prerequisite-guarded, own-takes-on-existing-cmdlets — but re-targets it cross-platform. All function bodies and both build-pipeline scripts are currently stubs (`TODO` markers), so the structural decisions are made but several environment-divergence and process decisions are still open.

This corner if the DevOps pratise repository will serve as a means for me to continue to think about custom powershell modules' role in the world of automation. Of the time of compiling it all I haven't yet decided if I'll go ahead and publish something officially on PSGallery.

---

## Decision

*State the decision clearly and directly. One paragraph, no hedging.*

The module (`DevOpsToolkit`) targets **PowerShell 7.4+, `CompatiblePSEditions = Core`, cross-platform**. Windows PowerShell 5.1 support will be minimal. Source is organized as a manifest-driven module (`src/DevOpsToolkit.psd1` + `.psm1`) with one function per file under `src/public/` (exported) and `src/private/` (internal helpers, e.g. `Test-Prerequisite`). Two distinct build pipelines are kept separate: a **review** gate (`build/Invoke-Lint.ps1`, PSScriptAnalyzer) and a **merge** gate (`build/Build-Module.ps1`, flattens source into a single distributable `.psm1` under `dist/`), so a failing lint can never produce a build artifact. Two authoring templates exist — `Function.Template.ps1` for pipeline-aware, repeatable logic shipped inside the module, and `Script.Template.ps1` for standalone one-shot scripts that are not expected to run concurrently. Environment expectations (elevation, certificate presence, MI/SP auth) are declared per-function via the centralized `Test-Prerequisite` guard rather than re-implemented or assumed in each function body.

---

## Options Considered

*List the alternatives evaluated. For each, note the key trade-off that ruled it in or out.*

| Option | Summary | Reason Accepted / Rejected |
|---|---|---|
| **PS 7.4+, Core, cross-platform** | Single codebase runs on the Ubuntu host and Windows alike | ✅ Accepted — matches the actual host, avoids maintaining Windows-only branches for functionality this toolkit needs |
| **Stay on Windows PowerShell 5.1** | Continue the previous module's target | ❌ Rejected — host environment is Ubuntu; 5.1 has no presence here and is in extended-support-only mode upstream |
| **Dual-target 5.1 and 7.4+ via `#requires` branching** | One module, conditional logic per edition | ❌ Rejected (for now) — doubles the surface for every platform-divergent check (cert store, elevation, memory/disk) for a benefit (legacy Windows support) the current environment doesn't need |
| **Per-function standalone scripts (no module)** | Drop the manifest/module wrapper entirely | ❌ Rejected — loses single-import discoverability, `FunctionsToExport` control, and the dev/dist separation the build pipeline depends on |
| **One flat `src/` directory (no public/private split)** | Simpler layout, fewer conventions to hold in your head | ❌ Rejected — the export boundary (`Export-ModuleMember -Function $public.BaseName`) needs an unambiguous way to tell "exported" from "internal" apart per-file; filename-as-function-name plus a folder split gives that for free |
| **Single-file module** | Not yet configured as there is no current need for it. |
| **Building on more of existing modules** | While the bulk of the practise work will involve the creation of mostly individual scripts/functions as their need arises, an example of an almost-complete custom modules take on `Az.Accounts` is still under consideration. |

---

## Consequences

### Positive

- One codebase, one CI matrix — no Windows-PowerShell-5.1 compatibility shims to maintain or test against.
- Public/private split plus filename-as-function-name gives an unambiguous, automatable export boundary (`Build-Module.ps1` derives `FunctionsToExport` from `src/public/*.ps1` rather than a hand-maintained list).
- Centralizing environment checks in `Test-Prerequisite` means platform-divergent logic (cert store, elevation, memory/disk source) lives in one place instead of being duplicated per function.
- Lint-then-merge as separate pipelines guarantees a lint failure can't silently ship in a build artifact.

### Negative / Trade-offs

- Anyone still on Windows PowerShell 5.1 (or constrained to it by an old environment) cannot use this module at all — no fallback path.
- Cross-platform parity has a real cost: every "own take" function that touches memory, disk, certificates, or elevation needs a Linux *and* a Windows implementation (see `Get-SystemHealth`'s `TODO`s) rather than one Windows-only path.
- The `Test-Prerequisite` guard is currently all stubs (`throw [NotImplementedException]`) for every check — elevation, cert, and auth context. No public function can yet declare and pass a real prerequisite check.
- `Build-Module.ps1`'s concatenation and manifest-update logic, and `Invoke-Lint.ps1`'s CI wiring, are stubs — the "two pipelines" decision is structurally in place but neither pipeline does real work yet.
- `tests/` is referenced in `README.md` as part of the intended flow (`Invoke-Pester ./tests`) but the directory doesn't exist yet — no test scaffold to validate any of this against.

### Risks

- Implementing the Linux side of memory/disk/elevation checks incorrectly (e.g. parsing `/proc/meminfo` wrong, or a root check that's right on Linux but doesn't account for macOS) would silently produce wrong `Get-SystemHealth` data rather than a loud failure — mitigated by Pester tests once `tests/` exists, run against both platforms in CI if multi-OS runners are in scope.
- `enforce_admins`-style "no exceptions" thinking applied to `Test-Prerequisite`: if every check just `throw`s with no override, a single misconfigured prerequisite (e.g. a cert thumbprint that's right but on a different store) blocks all functionality with no escape hatch — worth deciding now whether any checks should warn-and-continue instead of hard-throw.

Key takeaway is, it all depends on scope. A larger function might have places where an error isn't necessarily show-stopping. Additionally, at v1, verbosity will be the key to spotting erros/quirks during runtime. Polish comes afterwards, but never at the expense of useful detail.

---

## Implementation Notes

*Optional: any specific configuration decisions, links to related resources, or follow-up actions.*

- Module manifest: `powershell/src/DevOpsToolkit.psd1` — `PowerShellVersion = '7.4'`, `CompatiblePSEditions = @('Core')`.
- Build pipelines: `powershell/build/Invoke-Lint.ps1` (review gate, PSScriptAnalyzer, intended as a required CI status check) and `powershell/build/Build-Module.ps1` (merge gate, currently a no-op stub printing a summary).
- Open implementation gaps tracked as inline `TODO`s in the skeleton:
  - `Test-Prerequisite`: elevation check, cert-thumbprint resolution (no `Cert:` drive on Linux — needs `X509Store` or file-path resolution), MI/SP auth acquisition.
  - `Get-SystemHealth`: hostname/OS/uptime/memory/disk collection, with an explicit Linux-vs-Windows branch for memory (`/proc/meminfo` vs CIM) and disk.
  - `Build-Module.ps1`: actual concatenation of `private/` + `public/` into `dist/$ModuleName.psm1`, and `Update-ModuleManifest -FunctionsToExport`.
- `tests/` does not exist yet — needs creating before the "Intended flow" step 3 in `README.md` (`Invoke-Pester ./tests`) is real.

In effect, this body of work is a demo of how a custom PowerShell collection of modules could be written and organised. Additional configuration decisions to be made based on specific requirements/constraints.

---

## References

- `powershell/README.md` — design notes and intended flow this ADR formalizes.
- `powershell/src/DevOpsToolkit.psd1`, `powershell/src/DevOpsToolkit.psm1` — manifest and dev-time loader.
- `powershell/src/private/Test-Prerequisite.ps1`, `powershell/src/public/Get-SystemHealth.ps1` — prerequisite guard and example "own take" function.
- `powershell/build/Invoke-Lint.ps1`, `powershell/build/Build-Module.ps1` — review and merge pipelines.
- Commit `b9390ad` — "create design and direction" (skeleton introduced).
