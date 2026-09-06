# agent-md

Portable contracts for coding agents.

`agent-md` installs one source-of-truth rules file, repo-local hooks,
bounded operational task state, and a few helper scripts so agents can
stop guessing and start proving their work.

Honest scope:

- Markdown rules are advisory. The agent has to read and follow them.
- Hooks and git hooks are enforceable where the host agent supports them.
- Tests, type-checks, screenshots, and evidence notes are stronger than
  model self-assessment.

## Quickstart

```bash
# From inside your project directory
curl -sL https://raw.githubusercontent.com/iamfakeguru/agent-md/main/install.sh | bash
```

Installs support for Claude Code, Codex, Cursor, and Windsurf by default.

## What You Get

```text
your-project/
  AGENT.md                         # source of truth
  AGENTS.md                        # Codex / Cursor / Windsurf
  CLAUDE.md                        # Claude Code
  agent-md.toml.example            # deterministic verification/state config

  .claude/
    settings.json
    hooks/                         # Claude Code enforcement

  .codex/
    hooks.json
    hooks/                         # Codex hook wrappers

  .agents/skills/                  # native Codex skills
    agent-md-verify/
    visual-evidence/

  .cursor/rules/agent-md.mdc       # Cursor project rule
  .windsurf/rules/agent-md.md      # Windsurf workspace rule

  .agent-md/
    bin/
      discover_helpers.sh
      doctor.sh
      playwright-capture.sh
      verify.sh

  memory/
    agents.md
    plan.md
    progress.md
    verify.md
    gotchas.md

  .githooks/pre-commit             # optional fallback for any agent
```

## The Core Idea

Project knowledge has three explicit authorities:

| Authority | Responsibility |
|---|---|
| `agent-md` | Governance, safety, verification, active plan, current progress, relevant gotchas, and short handoff |
| ICM (optional) | Semantic/historical memory, recall, older decisions, resolved errors, and cross-agent knowledge |
| Git | Factual truth for code and code history |

agent-md does not call ICM from hooks or runtime code. It works on its
own. Declaring ICM only tells agents where historical recall belongs and
lets `doctor.sh` report whether the optional command is available.

Agent guidance itself has two layers:

| Layer | Purpose | Reliability |
|---|---|---|
| Rules files | Judgment, planning, style, process | Advisory |
| Hooks/artifacts | Type-checks, tests, lint, state updates, visual evidence | Enforceable where supported |

If something can be forgotten or rationalized away, move it out of prose
and into a checked artifact.

## Policy Foundation

agent-md applies this normative order:

1. Safety
2. Correctness
3. Reliability
4. Maintainability
5. Minimal surface area
6. Speed

Security and reliability invariants override autonomy, speed,
convenience, and token efficiency. Optional integrations cannot weaken
enforcement; failure of a safety or integrity mechanism must be visible.
Git remains factual truth, and agent-md remains standalone and
dependency-light. The design rule is: **enforce facts; advise judgment**.

The shared internal hook result is intentionally small:

```json
{
  "status": "fail",
  "severity": "error",
  "code": "STATE_PROGRESS_STALE",
  "message": "Relevant source files changed without progress update.",
  "suggestion": "Update memory/progress.md.",
  "paths": ["src/example.py"]
}
```

Claude and Codex still receive their existing host-specific JSON
envelopes. The human-facing reason includes `[SEVERITY CODE]`; hosts do
not need to parse the internal result contract. `status` is `pass`,
`warn`, or `fail`; current hooks omit a result entirely on ordinary
success where that is what the host protocol expects.

| Severity | Meaning | Blocks? |
|---|---|---|
| `info` | Informational | Never |
| `warning` | Degraded condition or recommendation | No |
| `error` | Required correctness or integrity guarantee failed | Yes |
| `fatal` | Safety, integrity, or destructive-operation risk | Immediately |

There is no retry-based downgrade from `error` or `fatal`. Safety
violations, invalid enforcement configuration, state-integrity failures,
and failed required verification fail closed. Missing optional
integrations or diagnostics warn without blocking.

Stable codes currently emitted by controls are deliberately limited:

| Code | Category | Typical severity |
|---|---|---|
| `SAFETY_DESTRUCTIVE_COMMAND` | Safety | `fatal` |
| `SAFETY_PATH_VIOLATION` | Safety | `fatal` |
| `CONFIG_INVALID` | Integrity | `error` |
| `STATE_PROGRESS_INVALID` | Integrity | `error` |
| `STATE_PROGRESS_STALE` | Integrity | `error` |
| `STATE_TRANSITION_INVALID` | Quality | `warning` |
| `STATE_GOTCHA_RULE_MISSING` | Integrity | `error` |
| `STATE_GOTCHA_INVALID` | Integrity | `error` |
| `VERIFY_REQUIRED_FAILED` | Integrity | `error` |
| `VERIFY_OPTIONAL_FAILED` | Quality | `warning` |
| `VERIFY_UNAVAILABLE` | Integrity or Quality | `error` when required; otherwise `warning` |
| `VERIFY_TIMEOUT` | Integrity or Quality | `error` when required; otherwise `warning` |
| `VERIFY_NOT_CONFIGURED` | Diagnostic | `warning` |
| `VERIFY_PASSED` | Diagnostic evidence | `info` |
| `RISK_NOT_DECLARED` | Quality / migration | `warning` |
| `RISK_INVALID` | Integrity | `error` |
| `RISK_POSSIBLY_UNDERRATED` | Quality | `warning` |
| `RISK_RUNTIME_EVIDENCE_REQUIRED` | Integrity or Quality | `error` when applicable evidence fails; otherwise `warning` |
| `RISK_INDEPENDENT_VERIFICATION_REQUIRED` | Integrity | `error` |
| `RISK_HUMAN_APPROVAL_REQUIRED` | Integrity | `error` |
| `QUALITY_OUT_OF_SCOPE_CHANGE` | Quality | `warning` |
| `QUALITY_TDD_COVERAGE_RECOMMENDED` | Quality | `warning` |
| `QUALITY_VISUAL_EVIDENCE_RECOMMENDED` | Quality | `warning` |
| `DIAGNOSTIC_OUTPUT_TRUNCATED` | Diagnostic | `warning` |
| `INTEGRATION_ICM_UNAVAILABLE` | Diagnostic | `warning` |

Architectural non-goals constrain feature creep: agent-md is not
semantic memory, a multi-agent orchestrator, a model router, a background
daemon, a project-management platform, a replacement for Git or CI, or a
general-purpose agent runtime.

## Runtime Lessons Applied

The production-agent lessons that fit this repo are applied as contracts,
not as copied API boilerplate:

- **Cost/context discipline** — concise directives, helper discovery, and
  bounded operational `memory/` files instead of giant repeated prompts.
- **Reliability** — structured hook JSON, deterministic checks,
  destructive-command blocks, and explicit unverified-state warnings.
- **Performance** — bounded work slices, selective context loading, safe
  parallel tool use, and truncation warnings.
- **Tool use** — structured tool-result guidance, validation before
  execution, and clear helper boundaries.
- **Output quality** — tests, runtime evidence, visual artifacts, and
  independent/adversarial verification.

API-specific features such as prompt caching, streaming display,
provider retries, idempotency keys, temperature tuning, and batch
processing belong in the application or host runtime. `agent-md` tells
the coding agent to document and verify those choices when the project
uses them; it does not pretend to enforce provider behavior from a rules
file.

## Enforcement Matrix

| Check | Class / severity | Claude Code | Codex | Cursor / Windsurf / Other |
|---|---|---|---|---|
| Bash safety | Safety / `fatal` | Hard block via `.claude/hooks/block-destructive.sh` | Hard block via `.codex/hooks/pre-tool-use.sh` | Not covered |
| Required verification at finish | Integrity / `error` | Hard block via `stop-verify.sh` | Continuation via `.codex/hooks/stop.sh` | Optional `.githooks/pre-commit` |
| Optional verification failure | Quality / `warning` | Advisory via `stop-verify.sh` | Advisory through Codex Stop wrapper | Warning via optional pre-commit |
| Risk declaration/signals | Integrity or Quality | Block invalid; warn missing/underrated | Same through Codex Stop wrapper | Invalid blocks; signals warn |
| High/critical final evidence | Integrity / `error` | Blocks `done` via `stop-verify.sh` | Same through Codex Stop wrapper | Advisory at pre-commit |
| Operational state valid and updated | Integrity / `error` | Hard block via `state-enforcement.sh` | Continuation via `.codex/hooks/stop.sh` | Optional `.githooks/pre-commit` |
| Operational change outside task Scope | Quality / `warning` | Advisory via `state-enforcement.sh` | Advisory through Codex Stop wrapper | Warning via optional pre-commit |
| UI visual evidence | Quality / `warning`, or Integrity / `error` when required | Advisory or configured hard block | Same through Codex Stop wrapper | Advisory through rules |
| New export without nearby test | Quality / `warning` | Advisory | Advisory through rules/skills | Advisory through rules |
| Truncated Bash output | Diagnostic / `warning` | Advisory | Advisory through Codex PostToolUse | Not covered |
| Planning, context, edit safety | Judgment / advisory | Advisory | Advisory | Advisory |

Codex hooks are repo-local. Use `codex features list` to confirm hook
support in the installed Codex version.

## Install Options

```bash
# All supported agents
./install.sh .

# Specific agents
./install.sh --agent=claude .
./install.sh --agent=codex,cursor .

# Git hook fallback
./install.sh --githooks .
./install.sh --no-githooks .

# Claude settings handling
./install.sh --claude-settings=skip .
./install.sh --claude-settings=merge .
./install.sh --claude-settings=replace .

# Codex hook-config handling
./install.sh --codex-hooks=skip .
./install.sh --codex-hooks=merge .
./install.sh --codex-hooks=replace .
```

The installer backs up existing top-level rule files before replacing
them. Existing `memory/*.md` files are never overwritten. Existing
Claude and Codex hook configs are merged by default. Merge preserves
third-party events and handlers, refreshes only commands owned by
agent-md, and is idempotent across reinstalls. `skip` and `replace`
remain explicit options.

## Deterministic Verification

The completion question is: **what evidence proves this task is complete?**
agent-md resolves one verification contract for Claude Stop, Codex Stop,
pre-commit, doctor, and `agent-md-verify`. Explicit commands take precedence;
heuristics remain a labeled fallback.

Copy the example config and declare project checks:

```bash
cp agent-md.toml.example agent-md.toml
```

```toml
[verify]
typecheck = "npx --no-install tsc --noEmit"
lint      = "npx --no-install eslint ."
test      = "pnpm test"
integration = "pnpm test:integration"
smoke       = "./scripts/smoke.sh"
runtime     = "node dist/cli.js --version"
lint_file = "npx --no-install eslint {file}"

[verify.policy]
required = ["lint", "test", "smoke"]
timeout_seconds = 300

[visual]
required          = true
artifacts_dir     = ".agent/visual"
freshness_seconds = 3600

[integrations.icm]
enabled = true
```

Supported base completion checks are `typecheck`, `lint`, `test`,
`integration`, `smoke`, and `runtime`. `independent` and `approval` are
conditional Risk evidence verifiers. `lint_file` remains the fast PostToolUse
check and is not part of the completion contract.

When `[verify.policy].required` exists, listed checks are required and all
other configured or inferred checks are optional. A listed check with no
configured or inferred command is unavailable and blocks. When the array is
absent, every configured or inferred check preserves legacy required
behavior. This makes existing configurations compatible while allowing new
projects to mark optional diagnostics explicitly. An empty `required = []`
is valid.

| Result | Required | Optional |
|---|---|---|
| exit `0` | pass | pass |
| exit non-zero | `VERIFY_REQUIRED_FAILED`, blocks | `VERIFY_OPTIONAL_FAILED`, warns |
| exit `126`/`127` or no required command | `VERIFY_UNAVAILABLE`, blocks | `VERIFY_UNAVAILABLE`, warns |
| configured timeout exceeded | `VERIFY_TIMEOUT`, blocks | `VERIFY_TIMEOUT`, warns |

Exit status is the primary evidence. Output containing `PASS` cannot rescue
exit 1, and output containing `FAIL` does not override exit 0. Output is
captured only for concise diagnosis and is never evaluated as a command.
`agent-md.toml` is trusted project configuration containing executable shell
commands; do not populate it from untrusted external or natural-language
output.

`timeout_seconds` is a simple per-check bound and requires `timeout` or
`gtimeout`. If the utility is unavailable, a required bounded check fails
closed and an optional one warns. If no timeout is declared, agent-md reports
that host limits are the only bound; it does not invent a scheduler.

Verification evidence has distinct classes:

- **static** — typecheck and lint;
- **automated** — unit and integration tests;
- **runtime** — the changed CLI, endpoint, service, script, or flow runs;
- **smoke** — a short end-to-end wiring check;
- **visual** — fresh structured UI evidence when applicable;
- **independent** — CI, another reviewer/agent, a human, or separate harness.

One category does not automatically prove another: lint is not behavior,
tests do not prove a CLI starts, and a screenshot does not prove backend
correctness. Independent verification is representable in the handoff but
is not required by default and never launches another model or orchestrator.

Run the complete declared contract with:

```bash
./.agent-md/bin/verify.sh
```

The helper first prints every check, requirement, origin, and command, then
reports name, status, exit code, command, summarized evidence, and recovery.
It exits non-zero only for invalid configuration or blocking required
results. Optional failures remain visible warnings. Results are fresh; this
phase adds no cache.

`doctor.sh` validates contract configuration and wiring without executing
the suite. It distinguishes `configured`, `inferred`, and `not configured`
checks, reports required/optional policy and obvious command availability,
and diagnoses timeout support. Complex shell commands may be labeled “not
preflighted”; the real runner remains authoritative.

When no checks are configured or inferred, hooks allow completion but emit
`VERIFY_NOT_CONFIGURED`: the work is explicitly unverified, never silently
treated as verified.

## Risk Model

Risk controls the amount of evidence, review, and approval required for a
task. It does not decide whether code is safe and does not assign a numeric
score. The explicit task declaration is primary:

```markdown
## Current

Status: verifying
Task: Harden auth token rotation
Risk: high
```

Exactly one `Risk:` is expected for new operational tasks. Allowed values are
`low`, `medium`, `high`, and `critical`. Existing progress files without Risk
remain readable; when relevant work changes they emit `RISK_NOT_DECLARED`
instead of silently becoming low. Invalid or duplicate declarations emit
`RISK_INVALID` and fail closed. Upgrades never overwrite existing progress.

| Risk | Additional completion requirement |
|---|---|
| `low` | Current required verification contract |
| `medium` | Required checks plus a passing configured runtime or smoke check when applicability is declared |
| `high` | Medium requirements plus trusted independent verification |
| `critical` | High requirements plus trusted explicit human approval |

When neither runtime nor smoke is configured for medium/high/critical,
agent-md cannot determine semantic applicability. It emits an advisory
`RISK_RUNTIME_EVIDENCE_REQUIRED` warning and does not invent a command. When
either check is configured, at least one must pass before `done` is accepted.

Risk-sensitive evidence uses two conditional commands in the existing
verification section:

```toml
[verify]
test = "bats tests/"
runtime = "./scripts/runtime-smoke.sh"
independent = "./scripts/verify-ci-attestation.sh"
approval = "./scripts/verify-human-approval.sh"

[verify.policy]
required = ["test"]
```

`independent` and `approval` do not belong in `verify.policy.required`; Risk
activates them only for a final `Status: done`. To prevent same-task
self-attestation, their exact command must already exist unchanged in the
committed `agent-md.toml` at `HEAD`. The command must validate its own trusted
external source: CI, a separate reviewer/harness, signed human approval, or a
host approval workflow. agent-md trusts its exit code, not natural-language
output. Adding `approval = "true"` in the current worktree, writing
`By: human`, or claiming approval in chat is never accepted. Without a
reliable configured approval verifier, critical remains blocked.

The defensive signal audit recognizes explicit path/content indicators for:

- authentication/authorization and permissions;
- credentials, secrets, and vaults;
- production/deployment and infrastructure/Terraform;
- migrations/schema and newly added destructive SQL;
- payments/billing;
- explicit OpenAPI/Swagger/public-API surfaces.

Signals can produce `RISK_POSSIBLY_UNDERRATED`, with signal names and paths,
but never rewrite Risk or prove a classification. Examples are guidance, not
an automatic safety verdict.

Final evidence requirements apply only to `done`. `active`, `blocked`, and
`verifying` remain usable while evidence is pending. Fatal Safety controls
always remain independent: critical Risk and valid approval cannot bypass a
destructive-command block. Stop and `verify.sh` enforce final Risk evidence;
pre-commit validates Risk syntax and reports signals but deliberately does not
require final independent/human approval.

Doctor reports the declaration, status, observed signals, consistency, and
whether runtime/independent/approval wiring exists. It does not run checks,
approve work, or call a reviewer. `verify.sh` performs the full sequence:
validate progress/Risk, run the base verification contract, apply final Risk
requirements, execute applicable trusted evidence verifiers, and return
non-zero for a blocking result.

## Operational State Enforcement

The Stop and pre-commit hooks share one deterministic path classifier.
They require `memory/progress.md` to change only when an operationally
relevant file changed. The classifier sees tracked, staged, and untracked
files at Stop; pre-commit evaluates staged files only.

`progress.md` has a deliberately small line-oriented format:

```markdown
# Progress

## Current

Status: verifying
Task: Preserve third-party Codex hooks
Risk: medium

## Scope

- install.sh
- .codex/hooks/**
- tests/**

## Next

- Run the Codex-only smoke test
- Verify reinstall idempotency

## Blockers

None

## Recently Completed

- Shared classifier
- TOML arrays
```

The required sections are `Current`, `Next`, `Blockers`, and
`Recently Completed`, in that order; `Scope` is optional between Current
and Next. There must be exactly one status, at most one task, at most one
legacy-compatible Risk declaration, explicit Next/Blockers content, and no
more than five recent completions. A task is required for `active`, `blocked`,
and `verifying`. New work declares one valid Risk; legacy absence warns when
relevant files change. Malformed progress
blocks when it is itself changed or when relevant source changes depend
on it; an absent progress file preserves the existing opt-out behavior.

`verifying` means implementation is ready while applicable checks are still
pending or being evaluated. `done` is a completion claim, not evidence:
Stop/pre-commit/`verify.sh` execute the current required contract freshly.
agent-md does not persist agent-authored `pass` lines in `progress.md`, which
would duplicate CI and could not prove that a command actually ran.

The installer still never overwrites an existing `memory/progress.md`.
A legacy file without this structure remains untouched, but the next
operational change reports `STATE_PROGRESS_INVALID` with migration
guidance. Migration is deliberate and manual; hooks do not silently
rewrite project state.

Allowed statuses and transitions are:

```text
planned -> active
active -> blocked
active -> verifying
blocked -> active
verifying -> active
verifying -> done
done -> planned
done -> active
```

An unchanged status is allowed. When Git has a valid previous
`progress.md`, the hook compares it with the current worktree or staged
snapshot. It does not infer semantic intent or persist a hidden state
history. An observed change outside the direct transition list warns
rather than blocks because Git cannot prove that no uncommitted
intermediate state existed.

`Scope` contains shell-style path globs. Relevant files inside it are
normal; relevant files outside it produce
`QUALITY_OUT_OF_SCOPE_CHANGE` with `warning` severity and their paths.
No Scope means no scope analysis. Files ignored by the existing source
classifier never enter scope analysis.

Scope is focus control, not a sandbox. It does not replace destructive
command protection, path protection, Git permissions, the host sandbox,
or human approval. No TOML keys were added for this feature.

Defaults cover conventional source/test directories and common code
extensions. Clear metadata and infrastructure such as `docs/**`,
`*.md`, `.gitignore`, `.ai-memory.toml`, `.github/**`, and agent runtime
directories are ignored. `scripts/**` and `tools/**` are deliberately
not ignored: executable code in them is relevant when it matches a
source glob.

Both keys are optional. Declaring a key replaces that key's defaults;
`ignore_globs` always wins. An empty array is valid. Values use
case-sensitive shell-style path globs relative to the Git root.

### Python

```toml
[state]
source_globs = ["src/**", "tests/**", "*.py", "*.pyi"]
ignore_globs = ["docs/**", ".ai-memory.toml", ".gitignore"]
```

### Node / TypeScript

```toml
[state]
source_globs = [
  "src/**",
  "app/**",
  "packages/**",
  "tests/**",
  "*.js",
  "*.jsx",
  "*.ts",
  "*.tsx",
]
ignore_globs = ["docs/**", ".github/**", "*.md"]
```

### Hybrid project

```toml
[state]
source_globs = [
  "backend/**",
  "frontend/**",
  "scripts/**",
  "tools/**",
  "tests/**",
  "*.py",
  "*.ts",
  "*.tsx",
  "*.sh",
]
ignore_globs = ["docs/**", "generated/**", ".ai-memory.toml"]

[integrations.icm]
enabled = true
```

Projects that consider all of `scripts/**` or `tools/**` non-operational
can add those paths to their own `ignore_globs`.

## Evidence-First Workflow

Before behavior changes, establish reproducible evidence of the current
or failing behavior. Appropriate evidence includes unit/integration
tests, CLI exit codes, HTTP responses, smoke tests, log assertions,
snapshots, and visual artifacts. Observe it, make the smallest change,
repeat the same evidence, then run regression checks. TDD remains the
preferred form when it is cheap and applicable; inspection alone is not
completion evidence.

## Visual Evidence

UI work needs more than passing tests. Capture a screenshot:

```bash
./.agent-md/bin/playwright-capture.sh http://localhost:3000 .agent/visual/home.png
```

Then write `.agent/visual/home.md`:

```markdown
# Visual Check

Changed files:
- src/app/page.tsx

Route: /
Viewport: 1280x800
Artifact: home.png
Observed result: layout renders without overlap at desktop width.
```

The strict visual hook requires a fresh non-empty markdown file that
references a fresh non-empty image by filename and includes the required
fields. `visual.required = true` remains fail-closed. Optional evidence only
warns, and visual evidence never substitutes for required static, automated,
runtime, or smoke checks.

## Operational Memory

`memory/` is a small handoff surface for the current work:

- `agents.md` — active agents, MCPs, tech stack, tooling
- `plan.md` — current direction, current phase, and decisions still in
  force; remove superseded decisions
- `progress.md` — one current task/status, optional scope, immediate next
  steps, explicit blockers, and at most five recent outcomes
- `verify.md` — current executable checks and definition of done
- `gotchas.md` — only reusable invariants and recurring, non-obvious
  failure modes that still apply

Do not turn these files into a development journal. Prune superseded
plans, old completions, and irrelevant gotchas. Git retains factual code
history; ICM, when enabled, retains semantic and cross-agent history.

Each gotcha uses a `##` title and requires non-empty `**Rule:**` and
`**Why:**` fields. `**Scope:**`, `**Evidence:**`, and `**Added:**` are
recommended. Do not record every correction; remove obsolete entries.

Operational handoff relies first on `progress.md`, `plan.md`,
`verify.md`, `gotchas.md`, and Git. ICM can provide older context, but it
is not needed to determine where work stands, what remains, blockers, or
the next action.

Installation templates live separately under
`.agent-md/templates/memory/`, so this repository's own operational state
is never copied into a new project.

## Helper Scripts vs Codex Skills

`agent-md` intentionally separates plain helper scripts from Codex-native
skills.

- `.agent-md/bin/*` are shell helpers any agent can run.
- `.agents/skills/<name>/SKILL.md` are native Codex skills.

Discover helpers:

```bash
./.agent-md/bin/discover_helpers.sh
./.agent-md/bin/doctor.sh
./.agent-md/bin/verify.sh
```

Use Codex skills with `$agent-md-verify` or `$visual-evidence`.

## What This Does Not Fix

- A rules file cannot force judgment by itself.
- Hooks only cover events exposed by the host agent.
- Pre-commit hooks can be bypassed with `git commit --no-verify`.
- Bash safety hooks are guardrails, not a sandbox.
- Cursor and Windsurf get rules plus optional git-hook fallback, not
  native runtime enforcement from this repo.
- Path globs are a conservative heuristic, not semantic analysis. Task
  completion without a matching file change remains an advisory agent
  responsibility.
- The TOML reader implements only the scalar and quoted string-array
  subset used by agent-md. It is intentionally not a general TOML parser.
- State globs use the shell's case-sensitive matching rather than a
  custom glob engine. Tests cover spaces, dotfiles, and nested package
  paths, but classification remains path-based.
- When `memory/progress.md` is gitignored, state enforcement falls back
  to file mtimes. That is a lower-reliability approximation than Git
  state and can be affected by clocks or file-copy tooling.
- Transition validation can compare only states captured by Git or its
  index. Uncaptured intermediate edits are not factual history and cannot
  be reconstructed without adding persistence, which this phase avoids.
- Command availability preflight is intentionally conservative. Doctor can
  prove a simple executable is present but may label compound shell commands
  “not preflighted”; actual exit status remains authoritative.
- Per-check timeout depends on the portable environment providing `timeout`
  or `gtimeout`. Without an explicit timeout, only host/process limits apply.
- Risk signals are keyword/path/diff heuristics. They can flag possible
  underrating but cannot determine safety, intent, reversibility, or blast
  radius.
- A committed evidence-verifier command is a trust anchor, not proof about its
  downstream implementation. Projects remain responsible for making that
  command validate genuine external CI/reviewer/human provenance.
- Runtime applicability cannot be inferred generally. No configured
  runtime/smoke command produces a warning rather than false enforcement.
- Independent evidence is conditional enforcement, not orchestration.
  Reviewer selection, automatic reviewer/model calls, profiles, and autonomy
  remain deferred.

## Development

```bash
bats tests/
shellcheck .claude/hooks/*.sh .codex/hooks/*.sh .agent-md/bin/*.sh .githooks/pre-commit install.sh
```

CI runs Bats, ShellCheck, JSON validation, alias-sync checks, and
installer smoke tests.

## License

MIT.
