#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for offline play, clear progression, save/load behavior, and moment-to-moment responsiveness.\n- Keep game loops, assets, controls, and content pipelines understandable for a solo codebase.\n- Prefer simple deployment and playtesting workflows over backend complexity.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect the gameplay loop, state transitions, scene or system wiring, and input handling first."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Change one gameplay boundary at a time and keep assets, state, and player feedback in sync."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer play-loop validation, state transition checks, and performance-sensitive smoke tests."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "State desync, input regressions, save data, and resource loading are the primary risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 95 "$prompt" "single-player game" "offline game" "solo game" "单机游戏" && return 0
    evop_profile_match_prompt 70 "$prompt" "game" "玩法" "关卡" "combat loop" "boss fight" && return 0
    return 1
}
