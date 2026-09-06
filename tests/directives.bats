#!/usr/bin/env bats

@test "directives define the evidence-first workflow" {
  run grep -q 'Establish reproducible evidence' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
  run grep -q 'Repeat the same evidence' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
}

@test "directives use behavioral objectives instead of a five-file limit" {
  run grep -q 'One behavioral objective per implementation slice' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
  run grep -q 'roughly five touched files' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -ne 0 ]
}

@test "directives require diff inspection and behavioral verification after edits" {
  run grep -q 'Inspect the resulting diff or affected region' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
  run grep -q 'Verify the affected behavior' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
}

@test "directives distinguish verification evidence classes without substitution" {
  for evidence_class in Static Automated Runtime Smoke Visual Independent; do
    run grep -q "\*\*${evidence_class}\*\*" "$BATS_TEST_DIRNAME/../AGENT.md"
    [ "$status" -eq 0 ]
  done
  run grep -q 'one does not automatically replace another' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
}

@test "directives make done evidence-backed and keep independent execution advisory" {
  run grep -q 'Status: done.*not proof by itself' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
  run grep -q 'never invokes another model automatically' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
}
