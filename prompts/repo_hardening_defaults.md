# Prompt: Repository Hardening — Branch Protection & Workflow Setup

**Purpose:** Standard prompt for configuring a new (or auditing an existing) GitHub
repository so that `main` is protected, merges are clean, and automated workflows
are permitted to run. In this specific case, `main` is actually called `master`.

**Model used:** Claude Opus 4.8 via Claude Code
**Last validated** 2026-06-17 - `gh` CLI 2.95.0 / GitHub REST API 2022-11-28
**Scope note:** Branch protection, auto-delete, and Actions permissions are repository
*settings*, not code. The assistant can generate the commands; applying them requires
the repo owner's authenticated session (`gh auth login` or the web UI).

---

## The Prompt

> Help me harden the GitHub repository `OWNER/REPO`. I am the sole maintainer and the
> only approved reviewer. Produce the exact `gh` CLI commands (and the equivalent web-UI
> steps as a fallback) to achieve the following, and explain any trade-off where a choice
> exists:
>
> 1. **Protect `master`:**
>    - Require a pull request before merging — no direct pushes to `master`.
>    - Require at least one approving review.
>    - Require status checks to pass before merging (name them: [list your CI check names]).
>    - Block force-pushes and deletion of `master`.
> 2. **Clean merges:** Enable "automatically delete head branches" so branches merged
>    into `master` are removed.
> 3. **Actions permissions:** Confirm Actions are enabled, allow workflows to run on PRs,
>    and set the minimum workflow permission scope needed (read-only `GITHUB_TOKEN` by
>    default; note where write scope is required).
> 4. **PR approval workflow:** If I want a CI workflow that runs on every PR to `master`,
>    give me a minimal `.github/workflows/` YAML scaffold that runs [lint / validate /
>    test] and reports status back as a required check.
>
> Before giving commands, tell me whether classic **branch protection** or the newer
> **rulesets** is the better fit for a solo-maintainer repo, and why. Flag anything that
> cannot be done by command and must be clicked in the UI.

---

## Caveats / things to check by hand

- A solo maintainer requiring "approval from me" is slightly awkward: GitHub blocks you
  from approving your own PR in some configurations. Decide whether you want
  `enforce_admins` on (you cannot bypass your own rule) or off (you can self-merge).
  For a learning repo, **off** is usually the pragmatic choice; for portfolio signal,
  **on** demonstrates discipline. This is a judgement call, not a default.
- Required status checks only become selectable *after* the check has run at least once
  on the repo — you may need to push a workflow, let it run, then add it as required.
- Rulesets and classic branch protection can both be active and will *both* be enforced;
  don't configure the same rule in both places.
