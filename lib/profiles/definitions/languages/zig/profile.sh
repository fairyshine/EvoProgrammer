#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer explicit `zig build` workflows, small composable modules, and predictable cross-compilation settings.\n- Keep allocation, error handling, and target assumptions visible in the code and build definitions.'

evop_profile_apply_project_context() {
    local target_dir="$1"

    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect build.zig, entrypoints, allocator boundaries, and focused tests before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve target configuration, error unions, and allocator ownership while changing behavior."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer `zig build` and `zig build test` over ad hoc compile commands when the repo ships a build graph."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Cross-target assumptions, manual memory management, and build graph changes are the main Zig risks."

    if [[ -d "$target_dir/test" || -d "$target_dir/tests" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Existing Zig tests are present; extend the nearest test target before broader runs."
    fi
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "build.zig" && return 0
    evop_profile_match_file_pattern 85 "$target_dir" "*.zig" && return 0
    evop_profile_match_prompt 40 "$prompt" "zig" && return 0
    return 1
}
