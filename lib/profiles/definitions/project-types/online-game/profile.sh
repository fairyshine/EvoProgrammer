#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for client/server boundaries, latency tolerance, synchronization, and operational safety.\n- Be explicit about networking assumptions, state authority, and failure handling.\n- Prefer observability, testability, and incremental rollout of multiplayer features.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect the gameplay loop, state transitions, scene or system wiring, and input handling first."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Change one gameplay boundary at a time and keep assets, state, and player feedback in sync."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer play-loop validation, state transition checks, and performance-sensitive smoke tests."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "State desync, input regressions, save data, and resource loading are the primary risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 96 "$prompt" "online game" "multiplayer" "networked game" "dedicated server" "client sync" "server authoritative" "联网游戏" && return 0
    return 1
}
