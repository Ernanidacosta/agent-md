# Current Plan

## Current Phase

Policy Foundation is implemented and verified. This phase adds shared
policy vocabulary and documentation, not a policy engine.

## Implementation Slices

1. [x] Make normative priorities and architectural non-goals explicit.
2. [x] Add the shared structured result, severity model, and stable codes.
3. [x] Adapt existing controls without changing Claude/Codex envelopes.
4. [x] Add policy and adversarial classifier coverage; document known
   TOML, glob, and mtime limitations.
5. [x] Complete the full acceptance matrix and operational handoff.

## Deferred / Out of Scope

- Policy profiles, autonomy modes, risk or decision engines.
- Task-scope enforcement and a new progress state machine.
- Broad self-test or new independent-verification machinery.
- ICM daemon/API coupling, semantic change detection, or new historical
  memory storage.

## Open Questions

None.
