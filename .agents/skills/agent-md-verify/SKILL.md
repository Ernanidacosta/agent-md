---
name: agent-md-verify
description: Use when finishing work in a repository that has agent-md installed; executes its required/optional verification contract, updates operational progress, and reports concrete evidence instead of self-grading.
---

# agent-md Verification

Use this skill before claiming work is complete in an agent-md repository.

1. Read `memory/verify.md` for task-specific evidence and definition of done.
2. Run `./.agent-md/bin/verify.sh`. It displays the resolved contract before execution, uses explicit commands before heuristic fallbacks, executes required and configured optional checks, and exits non-zero when required verification fails.
3. Do not skip a required failure, unavailable command, or timeout. Fix the problem and rerun the same entry point. Optional failures remain visible warnings.
4. Execute evidence-specific checks not represented by the generic contract when applicable, such as required visual evidence or a narrowly scoped runtime flow documented in `memory/verify.md`.
5. For operationally relevant changes, keep `memory/progress.md` in `verifying` while checks are pending. Move it to `done` only after the applicable required contract passes; keep one current Task when required, immediate Next, explicit Blockers, and no more than five recent outcomes.
6. If no checks are configured or inferred, report the work as unverified and add a follow-up to define checks. Never convert “not verified” into “pass.”
7. Report concrete evidence: check name, command, exit status, and concise result. Do not infer success from output wording or code inspection.
8. Independent evidence may come from CI, a reviewer, human, other agent, or separate harness, but this skill does not invoke one automatically.
9. Keep historical detail out of `memory/`. Git is factual code history; when `[integrations.icm] enabled = true`, ICM is the optional semantic/historical store.

Useful helper:

```bash
./.agent-md/bin/verify.sh
```
