#!/usr/bin/env bats

load helpers

setup()    { setup_repo; }
teardown() { teardown_repo; }

@test "new export without a matching test is a quality warning" {
  mkdir -p src
  echo 'export function answer() { return 42 }' > src/answer.ts
  out=$(run_hook tdd-check.sh '{"tool_input":{"file_path":"src/answer.ts"}}')
  echo "$out" | jq -e '
    .hookSpecificOutput.additionalContext |
    test("WARNING QUALITY_TDD_COVERAGE_RECOMMENDED")
  ' >/dev/null
}

@test "matching test keeps the TDD nudge silent" {
  mkdir -p src
  echo 'export function answer() { return 42 }' > src/answer.ts
  echo 'test("answer", () => {})' > src/answer.test.ts
  out=$(run_hook tdd-check.sh '{"tool_input":{"file_path":"src/answer.ts"}}')
  [ -z "$out" ]
}
