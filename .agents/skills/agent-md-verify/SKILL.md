---
name: agent-md-verify
description: Use when finishing work in a repository that has agent-md installed; executes its required/optional verification contract, updates operational progress, and reports concrete evidence instead of self-grading.
---

# agent-md Verification

Use this skill before claiming work is complete in an agent-md repository.

1. Read `memory/verify.md` for task-specific evidence and definition of done.
2. Read the single `Risk:` declaration in `memory/progress.md`. Do not infer low or rewrite the value from heuristics; observed signals are review warnings, not classifications.
3. Run `./.agent-md/bin/verify.sh`. It displays the resolved verification and Risk contracts, executes base checks, and applies additional completion requirements only when `Status: done`.
4. Do not skip a required failure, unavailable command, timeout, missing high-risk independent verifier, or missing critical human-approval verifier. Fix the problem and rerun the same entry point. Optional failures remain visible warnings.
5. Execute evidence-specific checks not represented by the generic contract when applicable, such as required visual evidence. Medium/high/critical runtime applicability is advisory only when neither runtime nor smoke is declared.
6. For operationally relevant changes, keep `memory/progress.md` in `verifying` while checks are pending. Move it to `done` only after applicable base and Risk requirements pass; keep one current Task when required, one declared Risk, immediate Next, explicit Blockers, and no more than five recent outcomes.
7. If no checks are configured or inferred, report the work as unverified and add a follow-up to define checks. Never convert “not verified” into “pass.”
8. Report concrete evidence: check name, command, exit status, and concise result. Do not infer success from output wording or code inspection.
9. Independent and approval evidence may be validated by pre-existing trusted project commands, but this skill never writes approval, treats prose as approval, or invokes a reviewer/model automatically.
10. Keep historical detail out of `memory/`. Git is factual code history; when `[integrations.icm] enabled = true`, ICM is the optional semantic/historical store.

Useful helper:

```bash
./.agent-md/bin/verify.sh
```
