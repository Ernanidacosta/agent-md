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

@test "directives define non-numeric Risk as evidence policy, not safety judgment" {
  run grep -q 'Risk answers.*how much evidence' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
  run grep -q 'There is no numeric score' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
  for risk_level in low medium high critical; do
    run grep -q "\`$risk_level\`" "$BATS_TEST_DIRNAME/../AGENT.md"
    [ "$status" -eq 0 ]
  done
}

@test "directives forbid self-approval and Safety bypass through Risk" {
  run grep -q 'agent-authored.*is not evidence' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
  run grep -q 'bypass a fatal destructive-command' "$BATS_TEST_DIRNAME/../AGENT.md"
  [ "$status" -eq 0 ]
}
