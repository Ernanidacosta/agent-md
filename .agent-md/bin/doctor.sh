#!/bin/bash
# doctor.sh — check an agent-md installation for common wiring problems
# Usage: ./.agent-md/bin/doctor.sh

set -u

FAIL=0

ok() { printf 'ok  %s\n' "$*"; }
warn() { printf 'warn %s\n' "$*"; }
bad() { printf 'bad %s\n' "$*"; FAIL=1; }

have() {
  command -v "$1" >/dev/null 2>&1
}

have git || bad "git is not installed"
have jq || bad "jq is not installed; hooks need it for JSON parsing"
have bash || bad "bash is not installed"

SHARED_LIB=.claude/hooks/_lib.sh
if [ -f "$SHARED_LIB" ]; then
  # shellcheck source=.claude/hooks/_lib.sh
  . "$SHARED_LIB"
else
  bad "shared policy library missing: $SHARED_LIB"
fi

if [ -f AGENT.md ]; then
  ok "AGENT.md exists"
else
  bad "AGENT.md missing"
fi

if [ -f AGENT.md ] && [ -f CLAUDE.md ]; then
  if cmp -s AGENT.md CLAUDE.md; then
    ok "CLAUDE.md matches AGENT.md"
  else
    bad "CLAUDE.md drifted from AGENT.md"
  fi
fi

if [ -f AGENTS.md ]; then ok "AGENTS.md exists"; else warn "AGENTS.md missing"; fi
if [ -f .claude/settings.json ]; then ok "Claude settings present"; else warn "Claude settings missing"; fi
if [ -f .codex/hooks.json ]; then ok "Codex hooks present"; else warn "Codex hooks missing"; fi
if [ -f .codex/hooks.json ]; then
  for SHARED_HOOK in _lib.sh block-destructive.sh truncation-check.sh \
    stop-verify.sh state-enforcement.sh sensory-reminder.sh; do
    if [ ! -f ".claude/hooks/$SHARED_HOOK" ]; then
      bad "Codex shared hook dependency missing: .claude/hooks/$SHARED_HOOK"
    fi
  done
fi
if [ -d .agent-md/bin ]; then ok "agent-md helpers present"; else warn ".agent-md/bin missing"; fi
if [ -d memory ]; then ok "memory directory present"; else warn "memory directory missing"; fi

if [ -f "$SHARED_LIB" ]; then
  CONTRACT=$(verification_contract_json "$(toml_path)")
  printf 'Verification:\n'
  if [ "$(printf '%s' "$CONTRACT" | jq -r '.valid')" != true ]; then
    bad "$(policy_human_message "$(printf '%s' "$CONTRACT" | jq -c '.error')")"
  else
    printf '  %-12s %-10s %-15s %s\n' check policy origin availability
    while IFS= read -r SPEC; do
      [ -n "$SPEC" ] || continue
      CHECK_NAME=$(printf '%s' "$SPEC" | jq -r '.name')
      REQUIREMENT=$(printf '%s' "$SPEC" | jq -r '.requirement')
      ORIGIN=$(printf '%s' "$SPEC" | jq -r '.origin')
      COMMAND=$(printf '%s' "$SPEC" | jq -r '.command')
      AVAILABILITY="not configured"
      if [ "$ORIGIN" != "not configured" ]; then
        if verification_command_preflight "$COMMAND"; then
          AVAILABILITY="available"
        else
          PREFLIGHT_STATUS=$?
          case "$PREFLIGHT_STATUS" in
            1) AVAILABILITY="unavailable" ;;
            2) AVAILABILITY="not preflighted" ;;
            *) AVAILABILITY="invalid" ;;
          esac
        fi
      fi
      printf '  %-12s %-10s %-15s %s\n' \
        "$CHECK_NAME" "$REQUIREMENT" "$ORIGIN" "$AVAILABILITY"
      if [ "$REQUIREMENT" = required ] && [ "$ORIGIN" = "not configured" ]; then
        bad "[ERROR VERIFY_UNAVAILABLE] Required check '$CHECK_NAME' has no command. Recovery: configure verify.$CHECK_NAME."
      elif [ "$AVAILABILITY" = unavailable ] || [ "$AVAILABILITY" = invalid ]; then
        if [ "$REQUIREMENT" = required ]; then
          bad "[ERROR VERIFY_UNAVAILABLE] Required check '$CHECK_NAME' is $AVAILABILITY. Recovery: fix or install its command."
        else
          warn "[WARNING VERIFY_UNAVAILABLE] Optional check '$CHECK_NAME' is $AVAILABILITY."
        fi
      fi
    done < <(printf '%s' "$CONTRACT" | jq -c '.checks[]')
    TIMEOUT=$(printf '%s' "$CONTRACT" | jq -r '.timeout_seconds // empty')
    if [ -n "$TIMEOUT" ]; then
      if have timeout || have gtimeout; then
        ok "verification timeout is ${TIMEOUT}s"
      else
        bad "[ERROR VERIFY_UNAVAILABLE] timeout is configured but timeout/gtimeout is unavailable"
      fi
    else
      warn "verification timeout is not configured; host limits remain the only bound"
    fi
  fi
fi

if [ -f "$SHARED_LIB" ] && [ -f memory/progress.md ]; then
  PROGRESS_CONTENT=$(cat memory/progress.md)
  printf 'Risk:\n'
  if ! PROGRESS_ERROR=$(validate_progress_content "$PROGRESS_CONTENT"); then
    bad "[ERROR STATE_PROGRESS_INVALID] $PROGRESS_ERROR"
  else
    PROGRESS_STATUS=$(progress_status_from_content "$PROGRESS_CONTENT")
    RISK_COUNT=$(progress_risk_count_from_content "$PROGRESS_CONTENT")
    RISK_VALUE=$(progress_risk_from_content "$PROGRESS_CONTENT")
    RISK_FILES=$(risk_changed_files worktree || true)
    RISK_SIGNALS=$(risk_signals_for_files "$RISK_FILES" worktree)
    printf '  declared: %s\n' "${RISK_VALUE:-not declared}"
    printf '  status: %s\n' "$PROGRESS_STATUS"
    printf '  signals: %s\n' "$(if [ -n "$RISK_SIGNALS" ]; then printf '%s\n' "$RISK_SIGNALS" | awk 'BEGIN { first=1 } { if (!first) printf ", "; printf "%s", $0; first=0 } END { print "" }'; else printf none; fi)"
    if [ "$RISK_COUNT" -eq 0 ]; then
      if [ -n "$RISK_FILES" ]; then
        warn "[WARNING RISK_NOT_DECLARED] Relevant work has no declared Risk; no low default was inferred."
      fi
      printf '  consistency: not declared\n'
    elif [ "$RISK_COUNT" -ne 1 ] || ! printf '%s\n' "$RISK_VALUE" | grep -Eq '^(low|medium|high|critical)$'; then
      bad "[ERROR RISK_INVALID] Risk must occur once and be low, medium, high, or critical."
      printf '  consistency: invalid\n'
    elif [ -n "$(risk_underrating_signals "$RISK_VALUE" "$RISK_SIGNALS")" ]; then
      warn "[WARNING RISK_POSSIBLY_UNDERRATED] Declared Risk may be inconsistent with observed signals."
      printf '  consistency: review suggested\n'
    else
      printf '  consistency: ok\n'
    fi

    if [ "$(printf '%s' "$CONTRACT" | jq -r '.valid')" = true ]; then
      printf 'Requirements:\n'
      REQUIRED_MISSING=$(printf '%s' "$CONTRACT" | jq '[.checks[] | select(.requirement == "required" and .origin == "not configured")] | length')
      if [ "$REQUIRED_MISSING" -eq 0 ]; then
        printf '  required checks: configured\n'
      else
        printf '  required checks: missing\n'
      fi
      RUNTIME_COUNT=$(printf '%s' "$CONTRACT" | jq '[.checks[] | select((.name == "runtime" or .name == "smoke") and .origin != "not configured")] | length')
      if [ "$RUNTIME_COUNT" -gt 0 ]; then
        printf '  runtime/smoke: configured\n'
      else
        printf '  runtime/smoke: not configured (applicability advisory)\n'
      fi

      for EVIDENCE_CHECK in independent approval; do
        EVIDENCE_ORIGIN=$(printf '%s' "$CONTRACT" | jq -r --arg check "$EVIDENCE_CHECK" '.checks[] | select(.name == $check) | .origin')
        EVIDENCE_CAPABILITIES=$(printf '%s' "$CONTRACT" | jq -r --arg check "$EVIDENCE_CHECK" \
          '.checks[] | select(.name == $check) | .capabilities | if length == 0 then "not declared" else join(", ") end')
        if [ "$EVIDENCE_CHECK" = independent ]; then
          EVIDENCE_LABEL=Independent
          case "$RISK_VALUE" in high|critical) EVIDENCE_REQUIRED=yes ;; *) EVIDENCE_REQUIRED=no ;; esac
        else
          EVIDENCE_LABEL=Approval
          if [ "$RISK_VALUE" = critical ]; then EVIDENCE_REQUIRED=yes; else EVIDENCE_REQUIRED=no; fi
        fi
        printf '%s verifier:\n' "$EVIDENCE_LABEL"
        printf '  required by current risk: %s\n' "$EVIDENCE_REQUIRED"
        printf '  configured: %s\n' "$(if [ "$EVIDENCE_ORIGIN" = configured ]; then printf yes; else printf no; fi)"
        if [ "$EVIDENCE_ORIGIN" != configured ]; then
          printf '  path: not configured\n'
          printf '  origin: not configured\n'
          printf '  integrity: not applicable\n'
          printf '  executable: no\n'
          printf '  trust: not configured\n'
          printf '  capabilities: %s\n' "$EVIDENCE_CAPABILITIES"
          printf '  capability status: not applicable\n'
          continue
        fi
        EVIDENCE_ANCHOR=$(attestation_trust_anchor_json "$(toml_path)" "$EVIDENCE_CHECK")
        printf '  path: %s\n' "$(printf '%s' "$EVIDENCE_ANCHOR" | jq -r '.path')"
        printf '  origin: %s\n' "$(printf '%s' "$EVIDENCE_ANCHOR" | jq -r '.location')"
        printf '  integrity: %s\n' "$(printf '%s' "$EVIDENCE_ANCHOR" | jq -r '.integrity')"
        printf '  executable: %s\n' "$(printf '%s' "$EVIDENCE_ANCHOR" | jq -r 'if .executable then "yes" else "no" end')"
        printf '  trust: %s\n' "$(printf '%s' "$EVIDENCE_ANCHOR" | jq -r '.trust')"
        printf '  capabilities: %s\n' "$EVIDENCE_CAPABILITIES"
        EVIDENCE_MISSING_CAPABILITIES=$(attestation_missing_capabilities "$CONTRACT" "$EVIDENCE_CHECK")
        if [ "$EVIDENCE_CAPABILITIES" = "not declared" ]; then
          printf '  capability status: not declared\n'
        elif [ -n "$EVIDENCE_MISSING_CAPABILITIES" ]; then
          printf '  capability status: unavailable\n'
          while IFS= read -r EVIDENCE_CAPABILITY; do
            [ -n "$EVIDENCE_CAPABILITY" ] || continue
            printf '  dependency %s: unavailable\n' "$EVIDENCE_CAPABILITY"
          done <<EOF
$EVIDENCE_MISSING_CAPABILITIES
EOF
          warn "[WARNING VERIFY_UNAVAILABLE] $EVIDENCE_LABEL verifier dependencies are unavailable; final evidence cannot be produced."
        else
          printf '  capability status: available\n'
        fi
        if [ "$(printf '%s' "$EVIDENCE_ANCHOR" | jq -r '.eligible')" != true ]; then
          if [ "$PROGRESS_STATUS" = "done" ] && [ "$EVIDENCE_REQUIRED" = yes ]; then
            bad "[ERROR RISK_ATTESTATION_UNTRUSTED] $EVIDENCE_LABEL verifier is not eligible: $(printf '%s' "$EVIDENCE_ANCHOR" | jq -r '.reason')."
          else
            warn "[WARNING RISK_ATTESTATION_UNTRUSTED] $EVIDENCE_LABEL verifier is not yet eligible: $(printf '%s' "$EVIDENCE_ANCHOR" | jq -r '.reason')."
          fi
        elif [ "$(printf '%s' "$EVIDENCE_ANCHOR" | jq -r '.location')" = external ]; then
          warn "$EVIDENCE_LABEL verifier trust is environment-managed; agent-md does not audit host ownership or parent directories."
        fi
      done
    fi
  fi
fi

# ICM is an optional semantic/historical memory provider. Detection is
# deliberately read-only: doctor never starts it or calls its daemon/API.
ICM_ENABLED=""
if [ -f "$SHARED_LIB" ]; then
  ICM_ENABLED=$(read_toml "$(toml_path)" integrations.icm enabled)
fi

if [ "$ICM_ENABLED" = "true" ]; then
  if have icm; then
    ok "ICM is enabled and the icm command is available"
  else
    ICM_RESULT=$(policy_result_json \
      "warn" "warning" "INTEGRATION_ICM_UNAVAILABLE" \
      "ICM is enabled but the icm command is unavailable; agent-md remains fully operational." \
      "Install ICM for semantic recall, or disable the optional declaration.")
    warn "$(policy_human_message "$ICM_RESULT")"
  fi
elif have icm; then
  warn "ICM is available but not declared in agent-md.toml"
else
  ok "ICM is optional and not enabled"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  HOOKS_PATH=$(git config --get core.hooksPath || true)
  if [ "$HOOKS_PATH" = ".githooks" ]; then
    ok "git hook fallback is active"
  elif [ -f .githooks/pre-commit ]; then
    warn "git hook fallback installed but not active"
  fi
else
  warn "not inside a git worktree"
fi

if [ "$FAIL" -eq 0 ]; then
  ok "agent-md doctor finished"
else
  bad "agent-md doctor found problems"
fi

exit "$FAIL"
