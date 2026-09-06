#!/bin/bash
# _lib.sh — shared helpers for agent-md hooks.
# Source this from other hooks:  . "$(dirname "$0")/_lib.sh"
#
# Kept minimal on purpose — shell, not Python, so hooks stay dependency-free.
# All functions are safe to call with `set -u` enabled.

# read_toml <file> <section> <key>
# Prints the value or nothing. Handles `key = "value"` or `key = value`.
# Skips lines after `#`. Not a full TOML parser — just enough for our use.
read_toml() {
  local file="$1" section="$2" key="$3"
  [ -f "$file" ] || return 0
  awk -v section="$section" -v key="$key" '
    BEGIN { in_sec = 0 }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*\[/ {
      sec = $0
      sub(/^[[:space:]]*\[/, "", sec); sub(/\][[:space:]]*$/, "", sec)
      gsub(/[[:space:]]/, "", sec)
      in_sec = (sec == section) ? 1 : 0
      next
    }
    in_sec && index($0, "=") > 0 {
      k = substr($0, 1, index($0, "=") - 1)
      v = substr($0, index($0, "=") + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
      sub(/[[:space:]]*#.*$/, "", v)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      if (k == key) {
        if (v ~ /^".*"$/)      { gsub(/^"|"$/, "", v) }
        else if (v ~ /^'\''.*'\''$/) { gsub(/^'\''|'\''$/, "", v) }
        print v
        exit
      }
    }
  ' "$file"
}

# read_toml_array <file> <section> <key>
# Prints one quoted string per line. Return codes distinguish a valid key
# (0, including an empty array), a missing key/file (1), and malformed
# input (2). This intentionally implements only the string-array subset
# agent-md exposes; it is not a general TOML parser.
read_toml_array() {
  local file="$1" section="$2" key="$3"
  [ -f "$file" ] || return 1
  awk -v wanted_section="$section" -v wanted_key="$key" '
    function invalid() { bad = 1 }

    function parse_value(text,    i, c) {
      for (i = 1; i <= length(text); i++) {
        c = substr(text, i, 1)

        if (done) {
          if (c == "#") return
          if (c !~ /[[:space:]]/) invalid()
          continue
        }

        if (quoted) {
          if (escaped) {
            value = value c
            escaped = 0
          } else if (quote == "\"" && c == "\\") {
            escaped = 1
          } else if (c == quote) {
            print value
            value = ""
            quoted = 0
            need_separator = 1
          } else {
            value = value c
          }
          continue
        }

        if (c == "#") return
        if (c ~ /[[:space:]]/) continue

        if (!opened) {
          if (c == "[") opened = 1
          else invalid()
          continue
        }

        if (need_separator) {
          if (c == ",") need_separator = 0
          else if (c == "]") done = 1
          else invalid()
          continue
        }

        if (c == "\"" || c == "\047") {
          quoted = 1
          quote = c
        } else if (c == "]") {
          done = 1
        } else {
          invalid()
        }
      }
    }

    BEGIN { in_section = 0 }

    found && !done {
      parse_value($0)
      next
    }

    /^[[:space:]]*#/ { next }

    /^[[:space:]]*\[/ {
      current = $0
      sub(/^[[:space:]]*\[/, "", current)
      sub(/\][[:space:]]*(#.*)?$/, "", current)
      gsub(/[[:space:]]/, "", current)
      in_section = (current == wanted_section)
      next
    }

    in_section && index($0, "=") > 0 {
      candidate = substr($0, 1, index($0, "=") - 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", candidate)
      if (candidate == wanted_key) {
        found = 1
        parse_value(substr($0, index($0, "=") + 1))
      }
    }

    END {
      if (bad || (found && (!opened || !done || quoted))) exit 2
      if (!found) exit 1
    }
  ' "$file"
}

# toml_path — location of the config file (override with AGENT_MD_TOML env)
toml_path() {
  echo "${AGENT_MD_TOML:-agent-md.toml}"
}

# stat_mtime <path> — portable mtime in epoch seconds (Linux + macOS).
stat_mtime() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null
}

# file_size <path> — portable byte size (Linux + macOS).
file_size() {
  stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null
}

# policy_result_json <status> <severity> <code> <message> <suggestion> [paths]
# Builds the small internal result contract shared by agent-md controls.
# Paths are newline-delimited so filenames containing spaces remain intact.
# Hook wrappers translate this result to each host's existing JSON shape.
policy_result_json() {
  local result_status="$1" severity="$2" code="$3" message="$4"
  local suggestion="$5" paths="${6:-}" paths_json
  paths_json=$(printf '%s' "$paths" | jq -Rsc 'split("\n") | map(select(length > 0))')
  jq -cn \
    --arg status "$result_status" \
    --arg severity "$severity" \
    --arg code "$code" \
    --arg message "$message" \
    --arg suggestion "$suggestion" \
    --argjson paths "$paths_json" '
      {
        status: $status,
        severity: $severity,
        code: $code,
        message: $message,
        suggestion: $suggestion
      } + if ($paths | length) > 0 then {paths: $paths} else {} end
    '
}

# policy_human_message <policy-result-json>
# Keeps hook output readable while exposing stable severity/code tokens.
policy_human_message() {
  local result="$1" severity code message suggestion paths rendered
  severity=$(printf '%s' "$result" | jq -r '.severity | ascii_upcase')
  code=$(printf '%s' "$result" | jq -r '.code')
  message=$(printf '%s' "$result" | jq -r '.message')
  suggestion=$(printf '%s' "$result" | jq -r '.suggestion // empty')
  paths=$(printf '%s' "$result" | jq -r '(.paths // []) | join(", ")')

  rendered="[${severity} ${code}] ${message}"
  [ -z "$paths" ] || rendered="${rendered} Paths: ${paths}."
  [ -z "$suggestion" ] || rendered="${rendered} Recovery: ${suggestion}"
  printf '%s\n' "$rendered"
}

# detect_pm — prints the detected Node package manager based on lockfile,
# or nothing. Order: pnpm > yarn > bun > npm > (nothing).
detect_pm() {
  if   [ -f "pnpm-lock.yaml" ];                       then echo pnpm
  elif [ -f "yarn.lock" ];                            then echo yarn
  elif [ -f "bun.lockb" ] || [ -f "bun.lock" ];       then echo bun
  elif [ -f "package-lock.json" ] || [ -f "package.json" ]; then echo npm
  fi
}

# npm_test_cmd — prints the test-runner invocation for the detected PM,
# or nothing if no JS project was detected.
npm_test_cmd() {
  case "$(detect_pm)" in
    pnpm) echo "pnpm test --silent" ;;
    yarn) echo "yarn test --silent" ;;
    bun)  echo "bun test" ;;
    npm)  echo "npm test --silent" ;;
    *)    echo "" ;;
  esac
}

# has_npm_test_script — returns 0 if package.json declares a real test script.
has_npm_test_script() {
  [ -f "package.json" ] || return 1
  local t
  t=$(jq -r '.scripts.test // empty' package.json 2>/dev/null)
  [ -n "$t" ] && [ "$t" != 'echo "Error: no test specified" && exit 1' ]
}

# Defaults intentionally favor executable product/test code. Metadata and
# agent infrastructure are excluded separately. scripts/** and tools/**
# are not ignored: executable files there match the extension globs below.
default_source_globs() {
  printf '%s\n' \
    'src/**' 'app/**' 'apps/**' 'lib/**' 'packages/**' \
    'test/**' 'tests/**' 'spec/**' \
    '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hpp' '*.cs' \
    '*.go' '*.java' '*.kt' '*.kts' '*.php' '*.py' '*.pyi' \
    '*.rb' '*.rs' '*.scala' '*.swift' \
    '*.sh' '*.bash' '*.zsh' '*.bats' \
    '*.js' '*.jsx' '*.mjs' '*.cjs' '*.ts' '*.tsx' \
    '*.vue' '*.svelte' '*.astro' '*.html' \
    '*.css' '*.scss' '*.sass' '*.less' \
    '*.sql' '*.graphql' '*.gql' '*.proto' '*.tf'
}

default_ignore_globs() {
  printf '%s\n' \
    'memory/**' 'docs/**' '.agent/**' '.agent-md/**' '.agents/**' \
    '.claude/**' '.codex/**' '.cursor/**' '.githooks/**' \
    '.github/**' '.windsurf/**' \
    '*.md' 'LICENSE' 'LICENSE.*' \
    '.gitignore' '.gitattributes' '.editorconfig' '.ai-memory.toml' \
    'agent-md.toml' 'agent-md.toml.example'
}

# load_state_globs — populates the two newline-delimited globals below.
# A configured key replaces its default independently. Empty arrays are
# therefore meaningful and must not be confused with absent keys.
load_state_globs() {
  local config parsed status
  config=$(toml_path)
  AGENT_MD_STATE_ERROR=""

  parsed=$(read_toml_array "$config" state source_globs)
  status=$?
  case "$status" in
    0) AGENT_MD_SOURCE_GLOBS="$parsed" ;;
    1) AGENT_MD_SOURCE_GLOBS=$(default_source_globs) ;;
    *)
      AGENT_MD_STATE_ERROR="Invalid ${config}: state.source_globs must be an array of quoted strings."
      return 2
      ;;
  esac

  parsed=$(read_toml_array "$config" state ignore_globs)
  status=$?
  case "$status" in
    0) AGENT_MD_IGNORE_GLOBS="$parsed" ;;
    1) AGENT_MD_IGNORE_GLOBS=$(default_ignore_globs) ;;
    *)
      AGENT_MD_STATE_ERROR="Invalid ${config}: state.ignore_globs must be an array of quoted strings."
      return 2
      ;;
  esac
}

path_matches_globs() {
  local path="$1" patterns="$2" pattern
  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    # shellcheck disable=SC2254
    case "$path" in
      $pattern) return 0 ;;
    esac
  done <<EOF
$patterns
EOF
  return 1
}

path_is_operationally_relevant() {
  local path="$1"
  path_matches_globs "$path" "$AGENT_MD_IGNORE_GLOBS" && return 1
  path_matches_globs "$path" "$AGENT_MD_SOURCE_GLOBS"
}

changed_files() {
  local scope="${1:-worktree}"
  if [ "$scope" = "staged" ]; then
    git diff --cached --name-only -- 2>/dev/null
    return
  fi
  {
    git diff --name-only -- 2>/dev/null
    git diff --cached --name-only -- 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | sort -u
}

filter_operationally_relevant_files() {
  local file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if path_is_operationally_relevant "$file"; then
      printf '%s\n' "$file"
    fi
  done
}

# validate_progress_content <markdown>
# Validates the deliberately small operational-state format. This is a
# line-oriented contract checker, not a general Markdown parser.
validate_progress_content() {
  local content="$1"
  printf '%s\n' "$content" | awk '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    function fail(message) {
      if (!bad) print message
      bad = 1
    }
    function body_item(line, section_name) {
      if (line == "None") return 1
      if (line ~ /^- [^[:space:]]/) return 1
      fail(section_name " must contain list items or the literal None.")
      return 0
    }

    BEGIN { stage = 0; section = "preamble" }

    /^<!--/ { if ($0 !~ /-->/) in_comment = 1; next }
    in_comment { if ($0 ~ /-->/) in_comment = 0; next }

    /^# / {
      h1_count++
      if ($0 != "# Progress") fail("The document must start with exactly # Progress.")
      next
    }

    /^## / {
      heading = substr($0, 4)
      if (heading == "Current") {
        current_count++
        if (stage != 0) fail("## Current must be the first section.")
        stage = 1; section = "current"
      } else if (heading == "Scope") {
        scope_count++
        if (stage != 1) fail("Optional ## Scope must follow ## Current.")
        stage = 2; section = "scope"
      } else if (heading == "Next") {
        next_count++
        if (stage != 1 && stage != 2) fail("## Next must follow ## Current or ## Scope.")
        stage = 3; section = "next"
      } else if (heading == "Blockers") {
        blockers_count++
        if (stage != 3) fail("## Blockers must follow ## Next.")
        stage = 4; section = "blockers"
      } else if (heading == "Recently Completed") {
        recent_section_count++
        if (stage != 4) fail("## Recently Completed must follow ## Blockers.")
        stage = 5; section = "recent"
      } else {
        fail("Unknown progress section: ## " heading ".")
        section = "unknown"
      }
      next
    }

    /^[[:space:]]*$/ { next }

    {
      if (section == "current") {
        if ($0 ~ /^Status:/) {
          status_count++
          status_value = trim(substr($0, 8))
        } else if ($0 ~ /^Task:/) {
          task_count++
          task_value = trim(substr($0, 6))
        } else {
          fail("## Current accepts only Status and Task fields.")
        }
      } else if (section == "scope") {
        if ($0 ~ /^- [^[:space:]]/) scope_item_count++
        else fail("## Scope must contain non-empty list items.")
      } else if (section == "next") {
        if (body_item($0, "## Next")) next_item_count++
      } else if (section == "blockers") {
        if (body_item($0, "## Blockers")) blocker_item_count++
      } else if (section == "recent") {
        if (body_item($0, "## Recently Completed")) {
          recent_body_count++
          if ($0 ~ /^- /) recent_item_count++
        }
      } else if (section == "preamble") {
        fail("Only blank lines are allowed before ## Current.")
      } else {
        fail("Content appears under an invalid progress section.")
      }
    }

    END {
      if (h1_count != 1) fail("The document must contain exactly one # Progress heading.")
      if (current_count != 1 || next_count != 1 || blockers_count != 1 || recent_section_count != 1 || stage != 5)
        fail("Required sections are ## Current, optional ## Scope, ## Next, ## Blockers, and ## Recently Completed in that order.")
      if (scope_count > 1) fail("The document may contain at most one ## Scope section.")
      if (status_count != 1) fail("## Current must contain exactly one Status field.")
      if (status_value !~ /^(planned|active|blocked|verifying|done)$/)
        fail("Status must be planned, active, blocked, verifying, or done.")
      if (task_count > 1) fail("## Current may contain at most one Task field.")
      if (status_value ~ /^(active|blocked|verifying)$/ && (task_count != 1 || task_value == ""))
        fail("Task is required when Status is active, blocked, or verifying.")
      if (scope_count == 1 && scope_item_count == 0) fail("Remove an empty ## Scope section or add at least one path glob.")
      if (next_item_count == 0) fail("## Next must explicitly contain list items or None.")
      if (blocker_item_count == 0) fail("## Blockers must explicitly contain list items or None.")
      if (recent_body_count == 0) fail("## Recently Completed must explicitly contain list items or None.")
      if (recent_item_count > 5) fail("## Recently Completed may contain at most five items.")
      exit (bad ? 1 : 0)
    }
  '
}

progress_status_from_content() {
  local content="$1"
  printf '%s\n' "$content" | awk '
    /^## Current$/ { current = 1; next }
    /^## / { current = 0 }
    current && /^Status:/ {
      value = substr($0, 8)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      print value
      exit
    }
  '
}

progress_scope_from_content() {
  local content="$1"
  printf '%s\n' "$content" | awk '
    /^## Scope$/ { scope = 1; next }
    /^## / { scope = 0 }
    scope && /^- [^[:space:]]/ { print substr($0, 3) }
  '
}

progress_transition_allowed() {
  local previous="$1" current="$2"
  [ "$previous" = "$current" ] && return 0
  case "${previous}:${current}" in
    planned:active|active:blocked|active:verifying|blocked:active|\
    verifying:active|verifying:done|done:planned|done:active) return 0 ;;
    *) return 1 ;;
  esac
}

state_file_snapshot() {
  local path="$1" scope="${2:-worktree}"
  if [ "$scope" = "staged" ] \
     && git ls-files --cached --error-unmatch "$path" &>/dev/null; then
    git show ":${path}" 2>/dev/null
  elif [ -f "$path" ]; then
    cat "$path"
  fi
}

validate_gotchas_content() {
  local content="$1"
  printf '%s\n' "$content" | awk '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    function fail(code, message) {
      if (!bad) print code "|" message
      bad = 1
    }
    function finish_item() {
      if (!in_item) return
      if (rule_count == 0) fail("STATE_GOTCHA_RULE_MISSING", "Gotcha " title " is missing a required Rule field.")
      else if (rule_count > 1) fail("STATE_GOTCHA_INVALID", "Gotcha " title " has multiple Rule fields.")
      else if (why_count != 1) fail("STATE_GOTCHA_INVALID", "Gotcha " title " must contain exactly one non-empty Why field.")
    }

    /^<!--/ { if ($0 !~ /-->/) in_comment = 1; next }
    in_comment { if ($0 ~ /-->/) in_comment = 0; next }

    /^# / {
      h1_count++
      if ($0 != "# Active Gotchas") fail("STATE_GOTCHA_INVALID", "The document must start with # Active Gotchas.")
      next
    }

    /^## / {
      finish_item()
      title = substr($0, 4)
      if (trim(title) == "") fail("STATE_GOTCHA_INVALID", "Gotcha headings must be non-empty.")
      in_item = 1
      item_count++
      rule_count = 0
      why_count = 0
      next
    }

    in_item && /^\*\*Rule(:\*\*|\*\*:)/ {
      value = $0
      sub(/^\*\*Rule:\*\*[[:space:]]*/, "", value)
      sub(/^\*\*Rule\*\*:[[:space:]]*/, "", value)
      rule_count++
      if (trim(value) == "") fail("STATE_GOTCHA_RULE_MISSING", "Gotcha " title " has an empty Rule field.")
      next
    }

    in_item && /^\*\*Why(:\*\*|\*\*:)/ {
      value = $0
      sub(/^\*\*Why:\*\*[[:space:]]*/, "", value)
      sub(/^\*\*Why\*\*:[[:space:]]*/, "", value)
      why_count++
      if (trim(value) == "") fail("STATE_GOTCHA_INVALID", "Gotcha " title " has an empty Why field.")
      next
    }

    !in_item && /^- / {
      fail("STATE_GOTCHA_RULE_MISSING", "Gotcha entries must use ## headings and include Rule and Why fields.")
    }

    END {
      finish_item()
      if (h1_count != 1) fail("STATE_GOTCHA_INVALID", "The document must contain exactly one # Active Gotchas heading.")
      exit (bad ? 1 : 0)
    }
  '
}

# state_enforcement_result [worktree|staged] — emits one structured result:
# the highest-priority Integrity failure, otherwise a Quality scope warning.
# Prints nothing when no action is needed.
state_enforcement_result() {
  local scope="${1:-worktree}"
  git rev-parse --is-inside-work-tree &>/dev/null || return 0

  local modified_files relevant_files relevant_count progress_changed gotchas_changed
  local progress_content progress_error previous_content previous_status current_status
  local gotchas_content gotchas_error gotchas_code gotchas_message

  if [ -f "memory/progress.md" ]; then
    if ! load_state_globs; then
      policy_result_json \
        "fail" "error" "CONFIG_INVALID" \
        "$AGENT_MD_STATE_ERROR" \
        "Fix the enforcement configuration before finishing."
      return 0
    fi
  fi

  modified_files=$(changed_files "$scope")

  gotchas_changed=$(printf '%s\n' "$modified_files" | grep -c '^memory/gotchas\.md$' || true)
  gotchas_changed=${gotchas_changed:-0}
  if [ "$gotchas_changed" -gt 0 ]; then
    gotchas_content=$(state_file_snapshot memory/gotchas.md "$scope")
    if [ -n "$gotchas_content" ] && ! gotchas_error=$(validate_gotchas_content "$gotchas_content"); then
      gotchas_code=${gotchas_error%%|*}
      gotchas_message=${gotchas_error#*|}
      policy_result_json \
        "fail" "error" "$gotchas_code" \
        "$gotchas_message" \
        "Keep only reusable gotchas and add non-empty Rule and Why fields." \
        "memory/gotchas.md"
      return 0
    fi
  fi

  [ -f "memory/progress.md" ] || return 0

  relevant_files=$(printf '%s\n' "$modified_files" | filter_operationally_relevant_files)
  relevant_count=$(printf '%s\n' "$relevant_files" | grep -c . || true)
  relevant_count=${relevant_count:-0}
  progress_changed=$(printf '%s\n' "$modified_files" | grep -c '^memory/progress\.md$' || true)
  progress_changed=${progress_changed:-0}

  if [ "$relevant_count" -gt 0 ] || [ "$progress_changed" -gt 0 ]; then
    progress_content=$(state_file_snapshot memory/progress.md "$scope")
    if ! progress_error=$(validate_progress_content "$progress_content"); then
      policy_result_json \
        "fail" "error" "STATE_PROGRESS_INVALID" \
        "$progress_error" \
        "Restore the documented progress.md structure before continuing." \
        "memory/progress.md"
      return 0
    fi

    if [ "$progress_changed" -gt 0 ]; then
      previous_content=$(git show HEAD:memory/progress.md 2>/dev/null || true)
      if [ -n "$previous_content" ] \
         && validate_progress_content "$previous_content" >/dev/null 2>&1; then
        previous_status=$(progress_status_from_content "$previous_content")
        current_status=$(progress_status_from_content "$progress_content")
        if ! progress_transition_allowed "$previous_status" "$current_status"; then
          policy_result_json \
            "warn" "warning" "STATE_TRANSITION_INVALID" \
            "The observed progress status change from ${previous_status} to ${current_status} is not a declared direct transition." \
            "Review the transition or capture the required intermediate operational state." \
            "memory/progress.md"
          return 0
        fi
      fi
    fi
  fi

  [ "$relevant_count" -eq 0 ] && return 0

  # Repos may gitignore memory/ (e.g. a global ~/.gitignore excluding it).
  # git diff/ls-files never sees those edits, so progress_changed would be
  # stuck at 0 forever once any relevant file changes. Fall back to mtime:
  # progress.md newer than every modified relevant file counts as updated.
  if [ "$progress_changed" -eq 0 ] && git check-ignore -q memory/progress.md 2>/dev/null; then
    local progress_mtime newest_source_mtime file file_mtime all_sources_exist
    progress_mtime=$(stat_mtime memory/progress.md)
    progress_mtime=${progress_mtime:-0}
    newest_source_mtime=0
    all_sources_exist=1
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      if [ ! -e "$file" ]; then
        all_sources_exist=0
        continue
      fi
      file_mtime=$(stat_mtime "$file")
      file_mtime=${file_mtime:-0}
      if [ "$file_mtime" -gt "$newest_source_mtime" ]; then
        newest_source_mtime=$file_mtime
      fi
    done <<EOF
$relevant_files
EOF
    if [ "$all_sources_exist" -eq 1 ] \
       && [ "$progress_mtime" -ge "$newest_source_mtime" ]; then
      progress_changed=1
    fi
  fi

  if [ "$progress_changed" -eq 0 ]; then
    local paths
    paths=$(printf '%s\n' "$relevant_files" | awk 'NR <= 10')
    policy_result_json \
      "fail" "error" "STATE_PROGRESS_STALE" \
      "${relevant_count} operationally relevant file(s) changed but memory/progress.md was not updated." \
      "Update memory/progress.md to reflect the current task state before finishing." \
      "$paths"
    return 0
  fi

  local task_scope_globs out_of_scope_files out_of_scope_count file
  task_scope_globs=$(progress_scope_from_content "$progress_content")
  [ -n "$task_scope_globs" ] || return 0

  out_of_scope_files=""
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if ! path_matches_globs "$file" "$task_scope_globs"; then
      if [ -n "$out_of_scope_files" ]; then
        out_of_scope_files="${out_of_scope_files}
${file}"
      else
        out_of_scope_files="$file"
      fi
    fi
  done <<EOF
$relevant_files
EOF

  out_of_scope_count=$(printf '%s\n' "$out_of_scope_files" | grep -c . || true)
  out_of_scope_count=${out_of_scope_count:-0}
  if [ "$out_of_scope_count" -gt 0 ]; then
    policy_result_json \
      "warn" "warning" "QUALITY_OUT_OF_SCOPE_CHANGE" \
      "${out_of_scope_count} operationally relevant file(s) changed outside the declared task Scope." \
      "Review whether Scope or the implementation plan should be adjusted; Scope is not a safety boundary." \
      "$out_of_scope_files"
  fi
}

# state_enforcement_reason [worktree|staged] — backward-compatible human
# adapter used by Claude/Codex Stop hooks and the pre-commit fallback.
state_enforcement_reason() {
  local result result_status
  result=$(state_enforcement_result "${1:-worktree}")
  [ -n "$result" ] || return 0
  result_status=$(printf '%s' "$result" | jq -r '.status')
  [ "$result_status" = "fail" ] && policy_human_message "$result"
}

# Backward-compatible name used by existing Stop wrappers and downstream
# integrations copied from earlier agent-md releases.
progress_stale_reason() {
  state_enforcement_reason worktree
}

# visual_evidence_ok <artifacts_dir> <freshness_seconds>
# Returns 0 when there's at least one fresh, non-empty markdown evidence
# file in <artifacts_dir> that mentions the filename of at least one
# fresh, non-empty image in the same directory. The markdown must also
# include the minimum verification fields agent-md asks for.
#
# This is deliberately opinionated — the agent must write prose about
# what it verified, not just drop a screenshot. A screenshot alone is
# a photo of something, not a verification claim.
visual_evidence_ok() {
  local dir="$1" fresh="$2"
  [ -d "$dir" ] || return 1
  local now
  now=$(date +%s)

  local md img img_name md_mtime img_mtime md_size img_size
  while IFS= read -r md; do
    [ -z "$md" ] && continue
    md_size=$(file_size "$md")
    [ "${md_size:-0}" -gt 0 ] || continue
    md_mtime=$(stat_mtime "$md")
    [ -z "$md_mtime" ] && continue
    [ $((now - md_mtime)) -le "$fresh" ] || continue
    grep -Eiq 'changed files?:' "$md" || continue
    grep -Eiq '(route|url):' "$md" || continue
    grep -Eiq 'viewport:' "$md" || continue
    grep -Eiq '(observed|result):' "$md" || continue

    while IFS= read -r img; do
      [ -z "$img" ] && continue
      img_size=$(file_size "$img")
      [ "${img_size:-0}" -gt 0 ] || continue
      img_mtime=$(stat_mtime "$img")
      [ -z "$img_mtime" ] && continue
      [ $((now - img_mtime)) -le "$fresh" ] || continue
      img_name=$(basename "$img")
      if grep -qF "$img_name" "$md" 2>/dev/null; then
        return 0
      fi
    done < <(find "$dir" -type f \( -name '*.png' -o -name '*.jpg' \
      -o -name '*.jpeg' -o -name '*.webp' -o -name '*.gif' \) 2>/dev/null)
  done < <(find "$dir" -type f -name '*.md' 2>/dev/null)

  return 1
}
