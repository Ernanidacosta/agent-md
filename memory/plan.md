# Current Plan

## Current Phase

Harden completion verification so `done` is backed by fresh, objective
evidence without turning agent-md into a CI runner.

## Implementation Slices

1. [x] Establish failing evidence for required/optional checks, timeout,
   exit-code precedence, origin reporting, and completion boundaries.
2. [x] Add one small shared verification resolver and runner.
3. [x] Reuse the contract from Stop, pre-commit, doctor, and the verification
   helper/skill while preserving host protocols.
4. [x] Document evidence classes and run the complete acceptance matrix.

## Decisions Still In Force

- Explicit commands take precedence over heuristics; legacy configured or
  inferred checks remain required when no policy is declared.
- A small `[verify.policy]` quoted-string array declares required checks;
  the existing partial TOML parser remains sufficient.
- Verification results are executed fresh at enforcement boundaries rather
  than persisted as agent-authored pass claims in progress.md.
- Exit status is authoritative; output is diagnostic only.

## Deferred / Out of Scope

- Policy profiles, autonomy modes, risk or decision engines.
- Risk-driven independent-verification machinery, broad self-test, caching,
  and verification orchestration.
- Runtime ICM dependency or a new historical-memory layer.

## Open Questions

None.
