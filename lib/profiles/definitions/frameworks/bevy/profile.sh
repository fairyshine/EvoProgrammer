#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Keep ECS systems, resources, and plugins modular and easy to reason about.\n- Prefer explicit scheduling and data flow over hidden coupling.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "bevy" "Cargo.toml" && return 0
    evop_profile_match_prompt 40 "$prompt" "bevy" && return 0
    return 1
}
