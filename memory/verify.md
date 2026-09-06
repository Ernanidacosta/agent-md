# Definition of Done

## Required Checks

- [x] `bats tests/` — 123/123 passed.
- [x] ShellCheck passed for all shipped shell scripts.
- [x] JSON/TOML validation and `git diff --check` passed.
- [x] `AGENT.md` and `CLAUDE.md` are identical.

## Runtime Evidence

- [x] Claude and Codex Stop preserve block/warning host protocols.
- [x] Pre-commit shares state validation and does not block scope warnings.
- [x] Installer produces valid clean progress/gotcha templates.
- [x] Existing third-party hook merge remains idempotent.

## Task-Specific Criteria

- [x] Progress structure, required fields, item limit, and transitions are tested.
- [x] Scope warnings reuse operational classification and ignore metadata.
- [x] Structured gotchas require Rule and Why.
- [x] Evidence-first, pruning, handoff, and edit-safety directives are synchronized.
- [x] Doctor, smoke tests, agent-md-verify, and state enforcement passed.
