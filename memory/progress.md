# Progress

## Current

Status: verifying
Task: Fix the GitHub verifier ShellCheck portability defect without weakening attestation enforcement.
Risk: high

## Scope

- examples/github-actions/**
- memory/progress.md
- memory/verify.md

## Next

- Run the pre-commit boundary and commit the corrected verifier as a new trust-anchor checkpoint.
- After authorized push, require a later claim-only child so the corrected verifier does not attest its own change.
- Require exact-SHA `completed/success` CI, then run the trusted verifier and `agent-md verify`.

## Blockers

- The correction modifies a trust anchor and cannot attest its own checkpoint; a later unchanged-anchor child commit remains required.

## Recently Completed

- Replaced the SC2015-prone verifier expression with an equivalent fail-closed conditional; exact ShellCheck and Bats 231/231 pass.
- Proved the first child push triggered GitHub Actions for the exact SHA and that a failed run remains fail-closed.
- Completed the local Root-of-Trust Bootstrap implementation and verification without using self-attestation or a bypass.
- Created and pushed bootstrap checkpoint `73748bf`; doctor now reports the repo-local anchor eligible and clean against HEAD.
- Confirmed the verifier still refuses self-attestation of its introducing commit and GitHub read-only queries expose no run for that SHA.
