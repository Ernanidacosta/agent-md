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

# ICM is an optional semantic/historical memory provider. Detection is
# deliberately read-only: doctor never starts it or calls its daemon/API.
ICM_ENABLED=""
if [ -f .claude/hooks/_lib.sh ]; then
  # shellcheck source=.claude/hooks/_lib.sh
  . .claude/hooks/_lib.sh
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
