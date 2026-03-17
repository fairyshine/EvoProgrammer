#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Follow POSIX-compatible patterns where practical and prefer portable shell idioms.\n- Use `set -euo pipefail` and explicit error handling to keep scripts robust.\n- Keep functions small, source-able, and testable in isolation.\n- Quote variables consistently and avoid unnecessary subshells or external processes.'

evop_profile_apply_project_context() {
    local target_dir="$1"

    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect sourced libraries, function definitions, and shell test harnesses before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep functions small and source-able; update callers and tests together to avoid broken pipelines."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Run shellcheck, targeted test cases, and a dry-run of affected entry scripts before broader checks."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Quoting errors, word splitting, unset variables, and changed exit codes can silently break callers."

    if [[ -d "$target_dir/tests" || -d "$target_dir/test" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Existing shell tests are present; extend the nearest coverage before broadening integration checks."
    fi
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 100 "$target_dir" "*.sh" && return 0
    evop_profile_match_file_named 90 "$target_dir" ".zshrc" ".zprofile" ".bashrc" ".bash_profile" && return 0
    evop_profile_match_prompt 40 "$prompt" "bash" "shell" "shell script" "脚本" && return 0
    return 1
}
