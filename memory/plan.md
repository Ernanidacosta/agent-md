# Current Plan

## Current Phase

Formalize current operational truth for deterministic validation and
cross-agent handoff without creating historical memory.

## Implementation Slices

1. [x] Establish failing evidence for progress, transition, scope, gotcha,
   and directive contracts.
2. [x] Add the small Markdown state validator and shared scope analysis.
3. [x] Migrate directives, templates, and operational memory.
4. [x] Run the complete acceptance matrix and close the handoff.

## Decisions Still In Force

- Git supplies the previous factual state when transition validation is
  possible; no sidecar persistence is introduced.
- Scope is a non-blocking focus signal, never a safety boundary.
- The TOML schema and existing source classifier remain unchanged.

## Deferred / Out of Scope

- Policy profiles, autonomy modes, risk or decision engines.
- New independent-verification machinery or broad self-test.
- Runtime ICM dependency or a new historical-memory layer.

## Open Questions

None.
