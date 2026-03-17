#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for ergonomic command structure, discoverable help output, and reproducible local execution.\n- Keep startup, configuration, and error messages straightforward.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect command parsing, config loading, and command-specific tests before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep stdout, stderr, exit codes, and help text behavior consistent with existing commands."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer command-level regression tests plus manual checks for representative invocations."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Flag parsing changes, shell-facing output, and backward compatibility are the main risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 49 "$prompt" "cli tool" "command line" "terminal tool" "命令行" && return 0
    return 1
}
