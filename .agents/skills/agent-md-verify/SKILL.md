---
name: agent-md-verify
description: Use when finishing work in a repository that has agent-md installed; runs the declared checks, updates memory/progress.md, and reports concrete verification evidence instead of self-grading.
---

# agent-md Verification

Use this skill before claiming work is complete in an agent-md repository.

1. Read `memory/verify.md` and identify the checks required for this task.
2. Run the project verification commands declared in `agent-md.toml` when present.
3. If `agent-md.toml` is absent, use the repository's existing test/lint/typecheck scripts or the hook heuristics.
4. For operationally relevant changes, update `memory/progress.md` with the current outcome and the checks that passed. Keep no more than five recently completed outcomes.
5. If no checks exist, say the work is unverified and add a follow-up item to define checks.
6. Do not describe code as correct based only on inspection. Provide command output, artifact paths, or reviewer evidence.
7. Keep historical detail out of `memory/`. Git is factual code history; when `[integrations.icm] enabled = true`, ICM is the optional semantic/historical store.

Useful helper:

```bash
./.agent-md/bin/discover_helpers.sh
```
