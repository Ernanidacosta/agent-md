# Definition of Done

## Required Checks

- [x] `bats tests/` — 231/231 passed, including provider, trust, Risk, and prior regressions.
- [x] The exact CI ShellCheck target set passed locally with the explicit conditional fix.
- [x] Pre-commit verification passed with the modified-anchor condition visible as a non-final `verifying` warning.

## Runtime Evidence

- [x] GitHub Actions run `34279255376` was bound to child SHA `28ca69a` and exposed the SC2015 portability defect.
- [x] The verifier rejected that failed run with exit 1 and emitted no passing attestation.
- [ ] A later claim-only child commit receives `completed/success` CI for its exact SHA.

## Task-Specific Criteria

- [x] Replaced the SC2015-prone boolean chain with an equivalent explicit conditional.
- [x] Missing or `null` workflow references remain fail-closed.
- [x] No workflow, provider contract, Risk, or trust policy was weakened.
- [ ] Commit the corrected verifier as a new checkpoint before any later attestation attempt.

## Independent Evidence

- [ ] A trusted verifier from the corrected HEAD baseline attests a later
  claim-only child commit; the checkpoint that modifies the verifier cannot
  attest itself.
