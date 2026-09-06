# Agents & Tooling

## Active Agents

- Codex — implementation, repository verification, and handoff.

## Integrations

- ICM — optional semantic/historical recall; enabled declaratively for
  this fork and never required by agent-md hooks or runtime.
- Git — factual source of truth for code and code history.

## Tech Stack

- Runtime: Bash plus standard Unix tools, Git, and jq.
- Tests: Bats.
- Lint: ShellCheck.
- Static checks: JSON validation, directive alias comparison, policy
  grep, and installer smoke tests.

## Constraints

- Apply the normative order: Safety, Correctness, Reliability,
  Maintainability, Minimal surface area, then Speed.
- Enforce deterministic facts and invariants; keep subjective judgment
  advisory.
- Never downgrade an `error` or `fatal` result to release execution.
- Keep shell hooks dependency-light and deterministic.
- Preserve third-party Claude and Codex hooks during installation.
- Keep root `memory/` operational; installation templates live only in
  `.agent-md/templates/memory/`.
