#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep contexts, routers, channels, LiveView boundaries, and supervision wiring aligned with Phoenix conventions.\n- Be explicit about request flow, socket state, and background work so web and real-time behavior stay predictable.\n- Prefer narrow controller or LiveView changes that preserve context boundaries and testability.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_repo_has_mix_package "$target_dir" "phoenix"; then
        EVOP_PROFILE_DETECT_SCORE=100
        return 0
    fi

    evop_profile_match_directory_text 95 "$target_dir" "phoenix" "mix.exs" "*.exs" && return 0
    evop_profile_match_prompt 40 "$prompt" "phoenix" && return 0
    return 1
}
