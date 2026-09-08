#!/bin/bash
# Reference independent-attestation verifier backed by GitHub Actions.
# It performs read-only `gh api` queries and emits one attestation JSON on pass.

set -u

fail() {
  printf 'GitHub Actions attestation unavailable: %s\n' "$1" >&2
  exit 1
}

read_setting() {
  local file="$1" key="$2"
  awk -F= -v key="$key" '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    $1 == key {
      count++
      value = substr($0, index($0, "=") + 1)
    }
    END {
      if (count != 1 || value == "") exit 1
      print value
    }
  ' "$file"
}

command -v git >/dev/null 2>&1 || fail "git is required."
command -v jq >/dev/null 2>&1 || fail "jq is required."
command -v gh >/dev/null 2>&1 || fail "the gh CLI is required; install and authenticate it, then retry."

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) \
  || fail "run the verifier inside the target Git worktree."
HEAD_SHA=$(git rev-parse --verify 'HEAD^{commit}' 2>/dev/null) \
  || fail "the current HEAD commit is unavailable."
printf '%s\n' "$HEAD_SHA" | grep -Eq '^[0-9a-fA-F]{40}$' \
  || fail "HEAD must resolve to one full 40-character SHA."
HEAD_SHA=$(printf '%s' "$HEAD_SHA" | tr '[:upper:]' '[:lower:]')

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd -P) \
  || fail "the verifier directory cannot be resolved."
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"
CONFIG_PATH="$SCRIPT_DIR/github-actions-independent.conf"
[ -f "$CONFIG_PATH" ] || fail "provider configuration is missing: $CONFIG_PATH."
case "$SCRIPT_PATH" in "$ROOT"/*) SCRIPT_REL=${SCRIPT_PATH#"$ROOT"/} ;; *) fail "the reference verifier must be repo-local." ;; esac
case "$CONFIG_PATH" in "$ROOT"/*) CONFIG_REL=${CONFIG_PATH#"$ROOT"/} ;; *) fail "the provider configuration must be repo-local." ;; esac

REPOSITORY=$(read_setting "$CONFIG_PATH" repository) \
  || fail "provider configuration must declare repository=OWNER/REPO exactly once."
WORKFLOW=$(read_setting "$CONFIG_PATH" workflow) \
  || fail "provider configuration must declare workflow=FILE exactly once."
WORKFLOW_PATH=$(read_setting "$CONFIG_PATH" workflow_path) \
  || fail "provider configuration must declare workflow_path=PATH exactly once."
printf '%s\n' "$REPOSITORY" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*/[A-Za-z0-9][A-Za-z0-9._-]*$' \
  || fail "repository must be a literal OWNER/REPO value."
printf '%s\n' "$WORKFLOW" | grep -Eq '^[A-Za-z0-9._-]+\.ya?ml$' \
  || fail "workflow must be a literal .yml or .yaml filename."
[ "$WORKFLOW_PATH" = ".github/workflows/$WORKFLOW" ] \
  || fail "workflow_path must identify the configured workflow under .github/workflows/."

for TRUSTED_PATH in "$SCRIPT_REL" "$CONFIG_REL" "$WORKFLOW_PATH"; do
  [ ! -L "$ROOT/$TRUSTED_PATH" ] \
    || fail "trust path is a symlink: $TRUSTED_PATH."
  git -C "$ROOT" cat-file -e "HEAD:$TRUSTED_PATH" 2>/dev/null \
    || fail "trust path is not present in HEAD: $TRUSTED_PATH."
  git -C "$ROOT" diff --quiet HEAD -- "$TRUSTED_PATH" \
    || fail "trust path differs from HEAD: $TRUSTED_PATH."
done

PARENT_SHA=$(git -C "$ROOT" rev-parse --verify 'HEAD^' 2>/dev/null) \
  || fail "a verifier cannot bootstrap trust in its introducing root commit."
if ! git -C "$ROOT" diff-tree --quiet --no-commit-id -r \
  "$PARENT_SHA" "$HEAD_SHA" -- "$SCRIPT_REL" "$CONFIG_REL" "$WORKFLOW_PATH"; then
  fail "a verifier cannot bootstrap trust in the same commit that introduces or modifies it or its workflow."
fi

gh auth status --hostname github.com >/dev/null 2>&1 \
  || fail "gh authentication for github.com is unavailable; run 'gh auth status' and repair credentials."

RESPONSE_FILE=$(mktemp "${TMPDIR:-/tmp}/agent-md-gh-runs.XXXXXX") \
  || fail "temporary response storage is unavailable."
cleanup() { rm -f "$RESPONSE_FILE"; }
trap cleanup EXIT

ENDPOINT="repos/$REPOSITORY/actions/workflows/$WORKFLOW/runs"
if ! gh api --method GET "$ENDPOINT" \
  --raw-field "head_sha=$HEAD_SHA" --raw-field 'per_page=100' > "$RESPONSE_FILE" 2>/dev/null; then
  fail "the GitHub Actions API query failed; verify gh authentication and Actions read access."
fi

jq -e '
  type == "object" and
  (.workflow_runs | type == "array") and
  all(.workflow_runs[];
    type == "object" and
    (.id | type == "number") and
    (.created_at | type == "string") and
    (.run_attempt | type == "number") and
    (.head_sha | type == "string") and
    (.status | type == "string") and
    ((.conclusion | type == "string") or .conclusion == null) and
    (.path | type == "string") and
    (.html_url | type == "string"))
' "$RESPONSE_FILE" >/dev/null 2>&1 \
  || fail "GitHub returned an invalid workflow-runs JSON response."

RUN=$(jq -c --arg sha "$HEAD_SHA" --arg workflow_path "$WORKFLOW_PATH" '
  [.workflow_runs[] |
    select(.head_sha == $sha and (((.path | split("@"))[0]) == $workflow_path))] |
  sort_by([.created_at, .run_attempt, .id]) |
  if length == 0 then empty else .[-1] end
' "$RESPONSE_FILE")
[ -n "$RUN" ] \
  || fail "no run of $WORKFLOW was found for exact commit $HEAD_SHA."

RUN_ID=$(printf '%s' "$RUN" | jq -r '.id')
RUN_STATUS=$(printf '%s' "$RUN" | jq -r '.status')
RUN_CONCLUSION=$(printf '%s' "$RUN" | jq -r '.conclusion // "absent"')
if [ "$RUN_STATUS" != completed ] || [ "$RUN_CONCLUSION" != success ]; then
  fail "latest matching run $RUN_ID is status=$RUN_STATUS conclusion=$RUN_CONCLUSION; completed success is required."
fi

REFERENCE=$(printf '%s' "$RUN" | jq -r '.html_url')
if [ -z "$REFERENCE" ] || [ "$REFERENCE" = null ]; then
  fail "the successful workflow run has no stable reference."
fi

jq -cn --arg commit "$HEAD_SHA" --arg reference "$REFERENCE" '{
  status:"pass",
  kind:"independent",
  origin:"ci",
  target:{commit:$commit},
  reference:$reference
}'
