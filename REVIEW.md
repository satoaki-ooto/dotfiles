# Review guidelines for this repository

This is a mise-bootstrap dotfiles repository checked out at `~/.config/mise`. Reviewed changes deploy to real hosts: `[dotfiles]` entries become symlinks, copies, merges, or deletions; role `[dotfiles]` entries that symlink `packages/*.toml` into `~/.config/mise/conf.d/` install tools; zsh fragments run at shell startup. Configuration, templates, package declares, and documentation commands are reviewed as code that changes machine state.

## Scope and workflow

- Inspect the changed files, then trace what each feeds: `[dotfiles]` sources and targets in `config.toml`, `config.personal.toml`, and `config.work.toml`; role package entries (`conf.d/` symlinks and their `absent` counterparts); Tera templates expanded at deployment (e.g. `{{ env.HOME }}` in `agents/pi/settings.json.tera`); merge entries; and zsh fragments loaded by `zsh/zshrc`, which sources common `zsh/lib` before role dirs (`~/.zsh` then `~/.zsh.*`) — order matters for overrides.
- Report only defects introduced or worsened by the change. Read surrounding code to verify reachability and assumptions before reporting; known but unrelated existing defects are context, not findings.
- Deduplicate and rank. One shared source deployed to many targets (`agents/shared/AGENTS.md` and `agents/shared/rules/` go to pi, pig, and omp) is one finding with its blast radius stated. Git is the authoritative change record; do not recommend `mise dot track` / `sync` / `pull` / `origin` workflows — `mise dot` exists only for inspecting deployments and copying edited targets back into sources.

## Reporting threshold

- Report concrete, actionable correctness or security problems with an evidenced trigger and impact: the change does X, which happens when Y, with effect Z (`file:line`).
- Do not report naming, formatting, stylistic refactors, speculative hardening, or missing tests by themselves. There is no CI, lint, or typecheck suite here; do not assume such checks catch anything.
- Do not blanket-ignore configuration, templates, documentation commands, or dependency declarations as "not code": a shell command written in README, docs, or a task definition is reviewed the same way it would execute on a host.

## Severity and output

- Calibrate urgency to impact — credential disclosure, destructive host changes, shell or bootstrap failure, broken role-specific functionality — not file type.
- Respect each review tool's native severity scale and output schema; never force another tool's labels onto it.
- Each finding states trigger, impact, and a minimal corrective direction, anchored to precise `file:line` evidence on valid changed lines. Use English and list findings by severity. State which validations could not be performed in the review environment.
- "No actionable issues found" is not a safety guarantee. Never fabricate tool runs or confidence scores.

## Deployment correctness

- Preserve source paths and target ownership: symlink targets are edited in `zsh/`; `copy` targets are edited in `agents/`; `merge = true` entries manage only repo-owned keys while the application owns the rest; `merge = "missing"` fills defaults only when absent; `mode = "absent"` removes a stale target (e.g. `~/.config/pig/agent/models.jsonc`). Flag changes that flip or weaken these semantics without explanation.
- Protect the runcom boundaries: `~/.zprofile` is written by mise shell activation (the repo only adds a block sourcing prezto's `runcoms/zprofile`); `~/.zlogin` and `~/.zlogout` symlink into `~/.zprezto/runcoms`; `~/.zshrc`, `~/.zpreztorc`, `~/.zshenv` are repo-owned. Flag edits that clobber the mise- or prezto-owned parts or that edit `~/.zprezto` runcoms directly (this makes `mise bootstrap repos update` fail on a dirty tree).
- Role package entries are explicit allowlists: nothing in `packages/` is installed until `config.personal.toml` or `config.work.toml` symlinks it into `~/.config/mise/conf.d/` (gitignored). A package used by only one role must be `mode = "absent"` in the other role, and removing a package means switching its entry to `absent` rather than deleting it; otherwise the deployed symlink stays in `conf.d/` and keeps loading. Do not reintroduce local `include`: paranoid's `config` category rejects it and fails the whole config file. Check personal/work isolation and repeatability: deployments must stay idempotent and non-destructive. Documented supply-chain exceptions (trimmed paranoid categories, `AUBE_ALLOWED_UNPOPULAR_PACKAGES`, `minimum_release_age`) are deliberate; flag them only with a demonstrated deployment or security impact.

## Shell and secrets

- Check zsh compatibility and quoting in changed fragments, that common-before-role sourcing preserves the documented override order, and that missing optional dependencies degrade gracefully: the loaders skip absent mise/brew binaries, unmatched agent sockets, missing sops/jq, and unreadable secret files rather than failing startup.
- Examine shell-evaluation boundaries: any `eval "$(...)"` or generated `export` line must validate identifiers and never interpolate untrusted names into shell code. The secrets loader quotes values but takes key names from the YAML; a change that interpolates keys without validating them as identifiers executes code hidden in a secret-file key.
- Never let decrypted values, age keys, `*.local.*` content, or work-confidential identifiers and URLs enter tracked files or review output. Describe findings without reproducing secret material.
- Check login and noninteractive startup only where touched: `zsh/zshenv` sources `~/.zprofile` for a non-login, non-interactive shell at `SHLVL` 1.
- Verify SSH-agent selection when touched: an existing `SSH_AUTH_SOCK` is kept only when it is an sshd-forwarded socket (`SSH_CONNECTION` set and the path matches `/tmp/ssh-*/agent.*` or `~/.ssh/agent/s.*.sshd.*`). Otherwise the Keeper/Bitwarden candidates win over any inherited socket (macOS launchd, gcr-agent, herdr, a manually started ssh-agent) by design — do not reintroduce a per-socket exclusion list. Each candidate must answer `ssh-add -l` (exit 0 or 1) before it is selected, and if none answers the existing value is left as is. Candidate order: macOS Bitwarden then Keeper App Store (`~/Library/Containers/com.callpod.keepermac.lite/Data/tmp/keeper-ssh-agent.sock`); on Linux, snap first on Ubuntu and flatpak first elsewhere. The legacy `~/.keeper/*.ssh_agent` path was dropped intentionally.

## Tools and agent boundaries

- For package changes, check provenance and role placement instead of flagging intentional `latest` pins on principle; flag only verifiable regressions.
- Template inputs stay deployable: keep `agents/pi/settings.json.tera` valid Tera with its `merge = true` core entry, and `settings.defaults.json` as the `merge = "missing"` defaults.
- For `agents/ags/config.toml`, check that `passthrough_env` limits itself to needed credentials (`ANTHROPIC_API_KEY`, `RUNINFRA_GATEWAY_KEY`), mounts keep read-only mode where intended, and sandbox permissions match documented intent.
- For `agents/pi/extensions/guard-git-push.ts`, verify the cases a diff touches: force refspecs (`+src:dst`), deletions (`:dst`), bare `HEAD` or empty destinations (fail closed on unknown branch), wildcards, `--all`/`--mirror`, option handling, branch resolution. The guard is a heuristic: it splits on characters, resolves no variables or aliases, does not parse user-entered bash (`!`-invoked shells are excluded), and complements GitHub branch protection. Findings must name a concrete bypassed or newly broken case, not present it as a complete security boundary.
- Shared instruction files change behavior for every deployed agent; state that blast radius explicitly.

## Safe validation

- Review is read-only. Prefer source analysis plus non-executing checks, for example `zsh -n <changed shell file>`. If a tool such as zsh, jq, or node is absent in the review environment, say so honestly.
- Never bootstrap, apply, install, update, decrypt secrets, launch startup files, contact remote hosts, or alter home configuration merely to review. A documented `--dry-run` — including remote bootstrap dry-runs, which still connect to and inspect hosts — is optional human validation, not an automatic review step, and is not inherently side-effect-free.
- No lint/typecheck commands exist here; do not invent any or add a test-framework requirement.

## Sub-agents (where supported)

- Zero sub-agents for simple, focused changes. One or two read-only targeted reviewers may cover independent high-risk domains — deployment/roles, shell/secrets, agents/supply-chain — sharded so ownership does not overlap. Expand scope only for a large cross-cutting diff, never merely because several config files changed.
- Sub-agents return location, severity, evidence, and a confidence rationale; they do not post comments across tools or modify files. The main reviewer verifies every candidate finding. Tool safety and output constraints take priority over speed.

---

Applicability note: this file expresses review policy; it does not activate any service. Kilo cloud applies it only when "Use REVIEW.md" is enabled and reads the copy on the base branch; Devin supports `REVIEW.md`; Claude cloud supports it, while Claude's local `/code-review` command does not read it automatically. Loading behavior in Kilo CLI sessions is not identical to these cloud services. This file does not change platform settings or branch protection.
