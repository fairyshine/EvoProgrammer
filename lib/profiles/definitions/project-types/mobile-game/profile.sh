#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for touch-first interaction, low-friction onboarding, and mobile performance constraints.\n- Account for battery, memory, varying screen sizes, and mobile asset handling.\n- Prefer iteration speed, simple packaging, and testable gameplay slices.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect the gameplay loop, state transitions, scene or system wiring, and input handling first."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Change one gameplay boundary at a time and keep assets, state, and player feedback in sync."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer play-loop validation, state transition checks, and performance-sensitive smoke tests."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "State desync, input regressions, save data, and resource loading are the primary risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 97 "$target_dir" "AndroidManifest.xml" "Info.plist" && return 0
    evop_profile_match_prompt 97 "$prompt" "mobile game" "ios game" "android game" "手机游戏" && return 0
    return 1
}
