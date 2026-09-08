# Definition of Done

## Required Checks

- [x] `bats tests/` — 231/231 passed, including bootstrap directives and prior regressions.
- [x] ShellCheck passed for core and the reference verifier.
- [x] JSON/TOML validation and `git diff --check` passed.
- [x] `AGENT.md` and `CLAUDE.md` are identical.

## Runtime Evidence

- [x] Doctor remained diagnostic and did not execute the verifier.
- [x] Claude/Codex and third-party hook smoke tests — 10/10 passed.
- [x] Invalid local `gh` authentication remained visible without credential changes.

## Task-Specific Criteria

- [x] Normative directives define `done` as a claim, not evidence.
- [x] Root-of-Trust Bootstrap is explicitly human/out-of-band and has no generic bypass.
- [x] Green CI cannot make an introducing verifier attest its own bootstrap commit.
- [x] A verifier already in the HEAD baseline can attest a later exact-SHA commit.
- [x] Prior evidence is documented as invalid after target or trust-chain changes.

## Independent Evidence

- [ ] A trusted independent verifier attests a later reviewed checkpoint;
  impossible for this same uncommitted bootstrap change and unavailable while
  local `gh` authentication remains invalid.
