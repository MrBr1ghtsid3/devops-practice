# CLAUDE.md

Operating context for Claude Code working in the `devops-practice` repository.
Keep this file short and operational — it is loaded as context on every session.

## Repository facts

- **Default branch is `master`** (not `main`). Use `master` in all branch, PR, and
  protection commands.
- This is a personal learning + portfolio repo. Maintainer and sole reviewer: Tsvetoslav Shalev.
- Language conventions: **British English** throughout — spelling, comments, generated docs.

## Environment (do not re-derive; assume these versions)

- Host OS: Ubuntu 24.04.4 LTS
- ansible-core 2.16.3 · Python 3.12.3
- Terraform 1.15.6
- PowerShell (pwsh) 7.6.2
- Claude Code 2.x (terminal & VS Code)

## Conventions

- **Lint before declaring work done:** `ansible-lint` and `yamllint` for Ansible/YAML;
  `terraform fmt -check` and `terraform validate` for Terraform. Do not call a task
  complete until these pass.
- **Idempotency:** Ansible playbooks must pass a second `--check` run with 0 changes.
- **Documentation:** ADRs, PoCs, and SoWs use the blanks in `docs/templates/`.
  Completed records go in `docs/adr/`, `docs/poc/`, `docs/sow/`.
- **Prompts:** reusable prompts are captured in `prompts/` following the existing
  format (purpose, model, validated-on, the prompt, caveats).

## Boundaries

- **Never commit secrets or state.** `.env`, `*.pem`, `*.key`, and Terraform state are
  git-ignored — keep it that way; never inline credentials, subscription IDs, or
  endpoint URLs into committed files.
- **Do not hand-edit `.claude/`** — it is Claude Code working state.
- **Settings vs code:** repository settings (branch protection, Actions permissions,
  auto-delete) are applied by the maintainer's authenticated session. Generate the
  `gh`/UI steps; do not assume they can be committed as code.

## Working style

- Surface trade-offs and flag anything that cannot be done as asked, rather than
  silently picking a default.
- Prefer minimal, runnable artifacts over described intentions.
