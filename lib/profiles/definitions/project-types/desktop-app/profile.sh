#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for local installation, usability, state persistence, and platform-specific packaging.\n- Keep app shell concerns separate from domain logic.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 47 "$prompt" "desktop app" "desktop application" "桌面应用" && return 0
    return 1
}
