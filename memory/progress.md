# Progress

## Current

Status: verifying
Task: Finalize Root-of-Trust Bootstrap semantics and its out-of-band checkpoint handoff.
Risk: high

## Scope

- .claude/hooks/**
- .agent-md/bin/**
- .agents/skills/agent-md-verify/**
- .githooks/**
- .agent-md/templates/memory/**
- examples/github-actions/**
- .github/workflows/ci.yml
- AGENT.md
- CLAUDE.md
- README.md
- agent-md.toml.example
- tests/**

## Next

- Obtain external human/operational review and create the checkpoint commit only when explicitly authorized.
- After that commit is HEAD, confirm doctor sees a clean eligible anchor and let GitHub Actions run as information for the bootstrap SHA.
- Use the preexisting unchanged trust chain only on a future commit; never autoattest this bootstrap change.

## Blockers

- The bootstrap is not committed or externally attested, local `gh` authentication is invalid, and the new verifier cannot bootstrap trust for the change that introduces it.

## Recently Completed

- Formalized `done` as a completion claim accepted only by all applicable guarantees.
- Named and documented the out-of-band Root-of-Trust Bootstrap and first future high-risk cycle.
- Added a GitHub Actions reference verifier with exact-SHA binding, deterministic newest-run selection, and bootstrap/workflow-integrity refusal.
- Added generic attestation capability diagnostics without putting GitHub or `gh` in core.
- Hardened attestations with explicit trust anchors, structured origin/kind, and exact commit binding.
