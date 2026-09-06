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
| `STATE_PROGRESS_STALE` | Integrity | `error` |
| `STATE_GOTCHA_RULE_MISSING` | Integrity | `error` |
| `VERIFY_REQUIRED_FAILED` | Integrity | `error` |
| `VERIFY_NOT_CONFIGURED` | Diagnostic | `warning` |
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
| Type-check/lint/tests at finish | Integrity / `error` | Hard block via `stop-verify.sh` | Continuation via `.codex/hooks/stop.sh` | Optional `.githooks/pre-commit` |
| `memory/progress.md` updated | Integrity / `error` | Hard block via `state-enforcement.sh` | Continuation via `.codex/hooks/stop.sh` | Optional `.githooks/pre-commit` |
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

Heuristics are useful, but explicit commands are better. Copy the example
config and declare your project checks:

```bash
cp agent-md.toml.example agent-md.toml
```

```toml
[verify]
typecheck = "npx --no-install tsc --noEmit"
lint      = "npx --no-install eslint ."
test      = "pnpm test"
lint_file = "npx --no-install eslint {file}"

[visual]
required          = true
artifacts_dir     = ".agent/visual"
freshness_seconds = 3600

[integrations.icm]
enabled = true
```

When no checks are detected, hooks allow completion but warn that the
work is unverified.

## Operational State Enforcement

The Stop and pre-commit hooks share one deterministic path classifier.
They require `memory/progress.md` to change only when an operationally
relevant file changed. The classifier sees tracked, staged, and untracked
files at Stop; pre-commit evaluates staged files only.

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
fields.

## Operational Memory

`memory/` is a small handoff surface for the current work:

- `agents.md` — active agents, MCPs, tech stack, tooling
- `plan.md` — current direction and active implementation slices
- `progress.md` — current task, next steps, blockers, and at most five
  recent verified outcomes
- `verify.md` — current definition of done
- `gotchas.md` — prevention rules for traps that still apply

Do not turn these files into a development journal. Prune superseded
plans, old completions, and irrelevant gotchas. Git retains factual code
history; ICM, when enabled, retains semantic and cross-agent history.

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

## Development

```bash
bats tests/
shellcheck .claude/hooks/*.sh .codex/hooks/*.sh .agent-md/bin/*.sh .githooks/pre-commit install.sh
```

CI runs Bats, ShellCheck, JSON validation, alias-sync checks, and
installer smoke tests.

## License

MIT.
