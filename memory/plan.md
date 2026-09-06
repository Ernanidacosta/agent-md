# Current Plan

## Current Phase

Scale completion evidence and approval requirements through a small,
explicit, non-numeric Risk Model without judging implementation safety.

## Implementation Slices

1. [x] Establish failing evidence for Risk parsing, observable signals,
   final-state requirements, and trusted evidence verifiers.
2. [x] Add line-oriented Risk parsing and shared non-numeric evaluation.
3. [x] Reuse the evaluation from Stop, verify, pre-commit, and doctor without
   changing Safety behavior or invoking reviewers.
4. [x] Document migration, limitations, and run the complete acceptance matrix.

## Decisions Still In Force

- Risk is declared once in `progress.md`; signals only audit possible
  underrating and never rewrite the declaration.
- Risk selects evidence/review/approval requirements, not whether code is safe.
- Independent and human-approval evidence are validated only by pre-existing,
  project-configured verifier commands; free-form agent claims are never proof.
- Missing runtime applicability remains advisory when no runtime/smoke check
  is declared because agent-md cannot infer semantics safely.

## Deferred / Out of Scope

- Policy profiles, autonomy modes, numeric scoring, or decision engines.
- Reviewer/model orchestration, broad self-test, caching, and automatic risk
  classification.
- Runtime ICM dependency or a new historical-memory layer.

## Open Questions

None.
