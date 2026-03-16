#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for responsive rendering, asset loading, input handling, and browser deployment constraints.\n- Prefer quick playtesting and maintainable gameplay slices.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 94 "$prompt" "browser game" "html5 game" "web game" && return 0
    return 1
}
