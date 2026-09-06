# Definition of Done

## Required Checks

- [x] `bats tests/` — 170/170 passed.
- [x] ShellCheck passed for all shipped shell scripts.
- [x] JSON/TOML validation and `git diff --check` passed.
- [x] `AGENT.md` and `CLAUDE.md` are identical.

## Runtime Evidence

- [x] Claude/Codex Stop and pre-commit preserve their host responsibilities.
- [x] verify.sh applies additional requirements only to `Status: done`.
- [x] Doctor reports Risk/signals/requirements without executing checks.
- [x] Existing third-party hook merge remains idempotent.

## Task-Specific Criteria

- [x] Low/medium/high/critical mappings and absence/invalid Risk are tested.
- [x] Observable signals warn without rewriting declared Risk.
- [x] High requires trusted independent evidence; critical additionally
  requires a trusted human-approval verifier.
- [x] Safety fatal cannot be bypassed by Risk or approval.
- [x] Legacy progress without Risk remains compatible with warning semantics.
