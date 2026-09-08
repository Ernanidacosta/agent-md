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

## Attestation trust chain

**Rule:** Accept high/critical evidence only from an eligible preexisting verifier that emits structured kind/origin and binds to the exact clean operational HEAD; establish a new or changed root out-of-band and never let it attest its own bootstrap commit.
**Why:** Mutable verifier code, weakened workflows, undeclared dependencies, stale targets, worktree prose, or auto-baselining let an executor manufacture its own independence or approval.
**Scope:** .claude/hooks/_lib.sh, examples/github-actions/**, agent-md.toml
**Evidence:** attestation-trust and GitHub Actions verifier adversarial Bats coverage
**Added:** 2026-09
