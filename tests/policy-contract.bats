#!/usr/bin/env bats

load helpers

setup()    { setup_repo; }
teardown() { teardown_repo; }

@test "policy result contract has stable required fields and contextual paths" {
  . .claude/hooks/_lib.sh
  result=$(policy_result_json \
    "fail" "error" "STATE_PROGRESS_STALE" \
    "Progress is stale." "Update memory/progress.md." \
    $'src/foo bar.py\npackages/a/src/x.ts')

  echo "$result" | jq -e '
    .status == "fail" and
    .severity == "error" and
    .code == "STATE_PROGRESS_STALE" and
    .message == "Progress is stale." and
    .suggestion == "Update memory/progress.md." and
    .paths == ["src/foo bar.py", "packages/a/src/x.ts"]
  ' >/dev/null
}

@test "destructive command violation is fatal and keeps PreToolUse protocol" {
  out=$(run_hook block-destructive.sh '{"tool_input":{"command":"git reset --hard"}}')
  echo "$out" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
  echo "$out" | jq -e '
    .hookSpecificOutput.permissionDecisionReason |
    test("FATAL SAFETY_DESTRUCTIVE_COMMAND")
  ' >/dev/null
}

@test "dangerous path violation has its own stable fatal code" {
  out=$(run_hook block-destructive.sh '{"tool_input":{"command":"rm -rf /"}}')
  echo "$out" | jq -e '
    .hookSpecificOutput.permissionDecisionReason |
    test("FATAL SAFETY_PATH_VIOLATION")
  ' >/dev/null
}

@test "required verification failure is an error and remains blocking" {
  cat > agent-md.toml <<'EOF'
[verify]
test = "false"
EOF
  out=$(run_hook stop-verify.sh '{"stop_hook_active":true}')
  echo "$out" | jq -e '.decision == "block"' >/dev/null
  echo "$out" | jq -e '.reason | test("ERROR VERIFY_REQUIRED_FAILED")' >/dev/null
}

@test "missing optional verification is a non-blocking warning" {
  out=$(run_hook stop-verify.sh '{"stop_hook_active":false}')
  echo "$out" | jq -e 'has("decision") | not' >/dev/null
  echo "$out" | jq -e '
    .hookSpecificOutput.additionalContext |
    test("WARNING VERIFY_NOT_CONFIGURED")
  ' >/dev/null
}

@test "invalid enforcement configuration is an error and blocks" {
  mkdir -p memory
  echo '# progress' > memory/progress.md
  git add memory/progress.md
  git commit -q -m "init progress"
  cat > agent-md.toml <<'EOF'
[state]
source_globs = [src/**]
EOF
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  echo "$out" | jq -e '.decision == "block"' >/dev/null
  echo "$out" | jq -e '.reason | test("ERROR CONFIG_INVALID")' >/dev/null
}

@test "human policy output states severity code message and recovery" {
  . .claude/hooks/_lib.sh
  result=$(policy_result_json \
    "fail" "error" "CONFIG_INVALID" \
    "State configuration is invalid." "Fix state.source_globs." "")
  message=$(policy_human_message "$result")
  [[ "$message" == *"[ERROR CONFIG_INVALID]"* ]]
  [[ "$message" == *"State configuration is invalid."* ]]
  [[ "$message" == *"Recovery: Fix state.source_globs."* ]]
}
