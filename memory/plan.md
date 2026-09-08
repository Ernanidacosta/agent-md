# Current Plan

## Current Phase

Close the Root-of-Trust Bootstrap contract semantically and operationally while
keeping the current high-risk task in `verifying` until external human review.

## Implementation Slices

1. [x] Establish failing directive evidence for the complete `done claim` and
   named out-of-band Root-of-Trust Bootstrap semantics.
2. [x] Document bootstrap flow, future high-risk cycle, evidence invalidation,
   and the absence of generic trust bypasses.
3. [x] Re-run the complete acceptance contract and preserve `verifying` for the
   external checkpoint handoff.

## Decisions Still In Force

- GitHub-specific repository/workflow selection lives beside the example,
  never in the generic core schema.
- `done` is only a claim until state, verification, Risk, attestation, and
  approval requirements accept it.
- Human/operational review outside the executor establishes the initial root;
  no current-change autoattestation can substitute for that checkpoint.
- A new target commit or a changed verifier, dependency, config, or workflow
  invalidates earlier evidence; commit binding is primary over timestamps.
- `gh` remains a provider capability, not a core dependency.

## Deferred / Out of Scope

- Policy profiles, autonomy modes, numeric scoring, or decision engines.
- Reviewer/model orchestration, PKI, signatures, trust stores, or daemons.
- GitHub-specific logic inside core, remote writes, branch-policy mutation, or
  support for every fork/PR topology.
- A shell dependency resolver or worktree-attestation fingerprint.
- Runtime ICM dependency or a new historical-memory layer.

## Open Questions

None.
