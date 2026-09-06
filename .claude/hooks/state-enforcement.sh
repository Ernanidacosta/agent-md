#!/bin/bash
# state-enforcement.sh
# Stop hook: blocks task completion if operationally relevant files
# changed but memory/progress.md was NOT updated.
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
# The actual staleness check lives in _lib.sh's progress_stale_reason —
# shared with precompact-state-check.sh (same question, different
# trigger and JSON shape) and with Codex's stop.sh, which invokes this
# script directly (see .codex/hooks/stop.sh).

# Read and discard stdin.
cat > /dev/null

# shellcheck source=.claude/hooks/_lib.sh
. "$(dirname "$0")/_lib.sh"

REASON=$(state_enforcement_reason worktree)
if [ -n "$REASON" ]; then
  jq -n --arg r "$REASON" '{decision: "block", reason: $r}'
fi
exit 0
