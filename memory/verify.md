# Definition of Done

## Required Checks

- [x] `bats tests/` — 103/103 passed.
- [x] ShellCheck passed for all shipped shell scripts.
- [x] JSON/TOML validation and `git diff --check` passed.
- [x] `AGENT.md` and `CLAUDE.md` are identical.
- [x] CI policy grep passed.

## Installer Acceptance

- [x] All-agent and agent-specific smoke installs passed.
- [x] Claude and Codex preserve third-party hooks across repeated installs.
- [x] Codex-only install contains and executes all shared dependencies.
- [x] Cursor-only pre-commit uses the shared state classifier.
- [x] Installed memory comes from clean templates.
- [x] ICM absence remains a non-fatal warning.

## Task-Specific Criteria

- [x] Safety violations emit `fatal` and remain blocking.
- [x] Required verification/config/state failures emit `error` and remain
  blocking without retry downgrade.
- [x] Optional ICM and quality/diagnostic notices remain warnings.
- [x] Stable codes appear in compatible human-facing hook output.
- [x] Paths with spaces, dotfiles, and nested package paths classify
  correctly without changing the shared glob architecture.
- [x] Normal doctor and configured `agent-md-verify` passed.
