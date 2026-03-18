#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer project-scoped Julia environments, explicit package dependencies, and code organized into importable modules.\n- Keep numerical or data-heavy logic reproducible, with benchmark or test coverage near changed behavior when practical.'

evop_profile_apply_project_context() {
    local target_dir="$1"

    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect Project.toml, module entrypoints, numerical kernels, and test fixtures before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve project environment assumptions and keep performance-sensitive code paths easy to measure."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer project-scoped Julia test runs and the narrowest reproducible benchmark or fixture coverage."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Global state, environment drift, and performance-sensitive allocations are the main Julia risks."

    if [[ -d "$target_dir/test" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Existing Julia tests are present; extend the nearest test file before broader runs."
    fi
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "Project.toml" "Manifest.toml" && return 0
    evop_profile_match_file_pattern 85 "$target_dir" "*.jl" && return 0
    evop_profile_match_prompt 40 "$prompt" "julia" && return 0
    return 1
}
