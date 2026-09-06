#!/bin/bash
# state-enforcement.sh
# Stop hook: validates operational state, blocks Integrity failures, and
# reports out-of-scope Quality warnings without blocking.
#
# Skipped if memory/progress.md doesn't exist (memory system not
# installed) or if we're not in a git repo.
#
# No stop_hook_active bypass. A retry does not make a missing progress
# update disappear. The only way out is to update progress.md, correct
# an invalid [state] configuration, or remove progress.md to opt out.
#
# Hook output contract: exit 0 + JSON block decision on stdout. Earlier
# versions mixed JSON with exit 2, which Claude silently discarded.
#
# The state contract and classifier live in _lib.sh and are shared with
# pre-commit and Codex's stop wrapper.

# Read and discard stdin.
cat > /dev/null

# shellcheck source=.claude/hooks/_lib.sh
. "$(dirname "$0")/_lib.sh"

RESULT=$(state_enforcement_result worktree)
[ -n "$RESULT" ] || exit 0

RESULT_STATUS=$(printf '%s' "$RESULT" | jq -r '.status')
MESSAGE=$(policy_human_message "$RESULT")
if [ "$RESULT_STATUS" = "fail" ]; then
  jq -n --arg r "$MESSAGE" '{decision: "block", reason: $r}'
else
  jq -n --arg m "$MESSAGE" '{hookSpecificOutput: {hookEventName: "Stop", additionalContext: $m}}'
fi
exit 0
