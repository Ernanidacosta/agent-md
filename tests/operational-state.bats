#!/usr/bin/env bats

load helpers

setup() {
  setup_repo
  write_progress active "Implement operational state"
}

teardown() { teardown_repo; }

commit_progress() {
  git add memory/progress.md
  git commit -q -m "baseline progress"
}

@test "valid progress status passes validation" {
  . .claude/hooks/_lib.sh
  run validate_progress_content "$(cat memory/progress.md)"
  [ "$status" -eq 0 ]
}

@test "missing progress status fails validation" {
  sed -i '/^Status:/d' memory/progress.md
  . .claude/hooks/_lib.sh
  run validate_progress_content "$(cat memory/progress.md)"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Status"* ]]
}

@test "invalid progress status fails validation" {
  sed -i 's/^Status:.*/Status: paused/' memory/progress.md
  . .claude/hooks/_lib.sh
  run validate_progress_content "$(cat memory/progress.md)"
  [ "$status" -ne 0 ]
  [[ "$output" == *"planned, active, blocked, verifying, or done"* ]]
}

@test "multiple progress statuses fail validation" {
  sed -i '/^Status:/a Status: verifying' memory/progress.md
  . .claude/hooks/_lib.sh
  run validate_progress_content "$(cat memory/progress.md)"
  [ "$status" -ne 0 ]
  [[ "$output" == *"exactly one Status"* ]]
}

@test "active progress requires a task" {
  sed -i '/^Task:/d' memory/progress.md
  . .claude/hooks/_lib.sh
  run validate_progress_content "$(cat memory/progress.md)"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Task"* ]]
}

@test "malformed progress plus source change blocks" {
  commit_progress
  sed -i '/^## Blockers$/d' memory/progress.md
  mkdir -p src
  echo 'x = 1' > src/example.py
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  echo "$out" | jq -e '.decision == "block"' >/dev/null
  echo "$out" | jq -e '.reason | test("ERROR STATE_PROGRESS_INVALID")' >/dev/null
}

@test "source changed inside Scope does not warn" {
  write_progress active "Implement auth" 'src/auth/**'
  commit_progress
  mkdir -p src/auth
  echo 'x = 1' > src/auth/user.py
  write_progress active "Implement auth behavior" 'src/auth/**'
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  [ -z "$out" ]
}

@test "source changed outside Scope emits a warning with paths" {
  write_progress active "Implement auth" 'src/auth/**'
  commit_progress
  mkdir -p src/payments
  echo 'x = 1' > src/payments/charge.py
  write_progress active "Implement auth behavior" 'src/auth/**'
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  echo "$out" | jq -e 'has("decision") | not' >/dev/null
  echo "$out" | jq -e '
    .hookSpecificOutput.additionalContext |
    test("WARNING QUALITY_OUT_OF_SCOPE_CHANGE") and
    test("src/payments/charge.py")
  ' >/dev/null
}

@test "absence of Scope does not emit a warning" {
  commit_progress
  mkdir -p src
  echo 'x = 1' > src/example.py
  write_progress active "Implement updated behavior"
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  [ -z "$out" ]
}

@test "ignored metadata does not enter Scope analysis" {
  write_progress active "Implement auth" 'src/auth/**'
  commit_progress
  echo 'enabled = true' > .ai-memory.toml
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  [ -z "$out" ]
}

@test "more than five recently completed items is invalid" {
  commit_progress
  sed -i '/^None$/{$d;}' memory/progress.md
  cat >> memory/progress.md <<'EOF'
- one
- two
- three
- four
- five
- six
EOF
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  echo "$out" | jq -e '.decision == "block"' >/dev/null
  echo "$out" | jq -e '.reason | test("ERROR STATE_PROGRESS_INVALID")' >/dev/null
}

@test "gotcha without Rule continues to fail" {
  commit_progress
  cat > memory/gotchas.md <<'EOF'
# Active Gotchas
EOF
  git add memory/gotchas.md
  git commit -q -m "baseline gotchas"
  cat >> memory/gotchas.md <<'EOF'

## Retry ownership

**Why:** HTTP retries duplicated jobs.
EOF
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  echo "$out" | jq -e '.decision == "block"' >/dev/null
  echo "$out" | jq -e '.reason | test("ERROR STATE_GOTCHA_RULE_MISSING")' >/dev/null
}

@test "gotcha without Why fails structured validation" {
  commit_progress
  cat > memory/gotchas.md <<'EOF'
# Active Gotchas
EOF
  git add memory/gotchas.md
  git commit -q -m "baseline gotchas"
  cat >> memory/gotchas.md <<'EOF'

## Retry ownership

**Rule:** Only queue consumers schedule retries.
EOF
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  echo "$out" | jq -e '.decision == "block"' >/dev/null
  echo "$out" | jq -e '.reason | test("ERROR STATE_GOTCHA_INVALID")' >/dev/null
}

@test "complete structured gotcha passes" {
  commit_progress
  cat > memory/gotchas.md <<'EOF'
# Active Gotchas
EOF
  git add memory/gotchas.md
  git commit -q -m "baseline gotchas"
  cat >> memory/gotchas.md <<'EOF'

## Retry ownership

**Rule:** Only queue consumers schedule retries.
**Why:** HTTP-layer retries caused duplicate jobs.
**Scope:** src/workers/**
**Evidence:** retry_deduplication test
**Added:** 2026-09
EOF
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  [ -z "$out" ]
}

@test "all declared transitions pass" {
  . .claude/hooks/_lib.sh
  for transition in \
    planned:active active:blocked active:verifying blocked:active \
    verifying:active verifying:done done:planned done:active active:active; do
    run progress_transition_allowed "${transition%%:*}" "${transition#*:}"
    [ "$status" -eq 0 ]
  done
}

@test "invalid observed transition is detected as a warning" {
  write_progress planned "Plan next slice"
  commit_progress
  write_progress done "Skip implementation"
  out=$(run_hook state-enforcement.sh '{"stop_hook_active":false}')
  echo "$out" | jq -e 'has("decision") | not' >/dev/null
  echo "$out" | jq -e '
    .hookSpecificOutput.additionalContext |
    test("WARNING STATE_TRANSITION_INVALID")
  ' >/dev/null
}

@test "pre-commit reports Scope warnings without blocking" {
  write_progress active "Implement auth" 'src/auth/**'
  commit_progress
  mkdir -p src/payments
  echo 'x = 1' > src/payments/charge.py
  write_progress active "Implement auth behavior" 'src/auth/**'
  git add memory/progress.md src/payments/charge.py
  run bash .githooks/pre-commit
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'WARNING QUALITY_OUT_OF_SCOPE_CHANGE'
}
