#!/bin/bash
# truncation-check.sh
# Runs after Grep and Bash tool calls.
# Detects when tool output was truncated (>50K chars -> 2KB preview).
# Injects a warning so the agent knows to read the full file or narrow scope.

# shellcheck source=.claude/hooks/_lib.sh
. "$(dirname "$0")/_lib.sh"

INPUT=$(cat)

# Extract tool_response as string - handles both string and object responses
TOOL_RESPONSE=$(echo "$INPUT" | jq -r '
  if (.tool_response | type) == "string" then .tool_response
  elif (.tool_response | type) == "object" then (.tool_response | tostring)
  else empty
  end
')

# Check for the persisted-output truncation marker
if echo "$TOOL_RESPONSE" | grep -q "Output too large"; then
  # Warn but don't block - the tool already ran, blocking won't undo it
  RESULT=$(policy_result_json \
    "warn" "warning" "DIAGNOSTIC_OUTPUT_TRUNCATED" \
    "Tool output was truncated to a preview; incomplete output must not be treated as complete evidence." \
    "Read the persisted full output before acting, or rerun with a narrower scope.")
  MSG=$(policy_human_message "$RESULT")
  jq -n --arg m "$MSG" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $m}}'
  exit 0
fi

# Note: previous versions warned on low Grep result counts as "possibly
# truncated". That was backwards — truncation happens from TOO MUCH output.
# Precise searches returning 0–4 hits are legitimate and common. Removed.

exit 0
