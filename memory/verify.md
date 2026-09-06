# Definition of Done

## Required Checks

- [x] `bats tests/` — 146/146 passed.
- [x] ShellCheck passed for all shipped shell scripts.
- [x] JSON/TOML validation and `git diff --check` passed.
- [x] `AGENT.md` and `CLAUDE.md` are identical.

## Runtime Evidence

- [x] Claude and Codex Stop preserve block/warning host protocols.
- [x] Stop, pre-commit, doctor, and agent-md-verify resolve one contract.
- [x] Required/optional failures, unavailable commands, timeouts, and exit
  status precedence have focused CLI evidence.
- [x] Existing third-party hook merge remains idempotent.

## Task-Specific Criteria

- [x] Configured checks override inferred checks and doctor reports origin.
- [x] `done` blocks on failed required verification; `verifying` remains a
  valid pending state.
- [x] Required visual evidence remains independently fail-closed.
- [x] Legacy `[verify]` configuration remains compatible.
- [x] Doctor, smoke tests, agent-md-verify, and state enforcement passed.
