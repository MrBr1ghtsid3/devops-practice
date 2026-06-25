# PowerShell — Custom Module Toolkit

A faithful skeleton of a custom-module pattern: two generic templates, a
manifest-driven module assembled from per-function source files, and a
two-pipeline flow (review + merge). Bodies are intentionally stubbed.

## Compatibility target

Previous work targeted **Windows PowerShell 5.1** for compatibility. This
skeleton deliberately targets **PowerShell 7.4+ and is cross-platform** — the
example function and prerequisite guard are written to run on the Ubuntu host,
not just Windows. Platform divergences (cert stores, memory/disk queries,
elevation checks) are flagged inline as `TODO` where they matter.

## Layout

| Path | Role |
|---|---|
| `src/DevOpsToolkit.psd1` | Module manifest. `FunctionsToExport` is owned by the build script. |
| `src/DevOpsToolkit.psm1` | Dev-time loader — dot-sources `private/` then `public/`, exports public only. |
| `src/public/` | Exported functions, one per file. Filename = function name. |
| `src/private/` | Internal helpers (e.g. `Test-Prerequisite`), not exported. |
| `templates/Script.Template.ps1` | Standalone, non-concurrent one-shot scripts. |
| `templates/Function.Template.ps1` | Repeatable/looping, pipeline-aware functions. |
| `build/Invoke-Lint.ps1` | **Review pipeline** — PSScriptAnalyzer gate. |
| `build/Build-Module.ps1` | **Merge pipeline** — flattens source into one distributable module. |
| `tests/` | Pester tests. |

## Design notes (carried from previous work)

- **Domain-scoped modules built on existing bodies of work.** The previous
  `ActiveDirectory` module managed prerequisites then provided own takes on /
  extensions of existing functionality. The cross-platform equivalent here
  extends the core cmdlets rather than a Windows-only module.
- **Environment expectations are explicit.** Functions declare what they need
  (elevation, a certificate, MI/SP auth) via `Test-Prerequisite` rather than
  assuming it. The guard throws actionable errors when expectations aren't met.
- **Two pipelines, separate concerns.** Review (lint) gates quality; build
  (merge) produces the shippable artifact. Kept distinct so a failing lint
  never produces a build.

## Intended flow

1. Author a function from `templates/Function.Template.ps1` → drop in `src/public/`.
2. `./build/Invoke-Lint.ps1` must pass (also wired as a required CI check).
3. `Invoke-Pester ./tests` green.
4. `./build/Build-Module.ps1` merges to `dist/` and refreshes the manifest.

## Status

🚧 Skeleton only — all function bodies and both pipeline implementations are stubs.
