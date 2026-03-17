#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for responsive rendering, asset loading, input handling, and browser deployment constraints.\n- Prefer quick playtesting and maintainable gameplay slices.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect the gameplay loop, state transitions, scene or system wiring, and input handling first."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Change one gameplay boundary at a time and keep assets, state, and player feedback in sync."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer play-loop validation, state transition checks, and performance-sensitive smoke tests."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "State desync, input regressions, save data, and resource loading are the primary risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 94 "$prompt" "browser game" "html5 game" "web game" && return 0
    return 1
}
