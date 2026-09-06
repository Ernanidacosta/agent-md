# Active Gotchas

## Operational source classification

**Rule:** Use the shared configurable source/ignore classifier for Stop and pre-commit.
**Why:** Broad negative filtering misclassified metadata and duplicated enforcement logic.
**Scope:** .claude/hooks/**, .githooks/**
**Evidence:** state-enforcement Bats coverage
**Added:** 2026-09

## Executable tooling directories

**Rule:** Never ignore scripts/** or tools/** by default.
**Why:** Those directories frequently contain executable product code.
**Scope:** default source and ignore globs
**Evidence:** scripts/tools state-enforcement cases
**Added:** 2026-09

## Blocking result ownership

**Rule:** Keep error and fatal results fail-closed until their recovery condition is satisfied.
**Why:** Retry releases and optional integrations can silently weaken real guarantees.
**Scope:** .claude/hooks/**, .githooks/**
**Evidence:** policy-contract and stop-verify Bats coverage
**Added:** 2026-09
