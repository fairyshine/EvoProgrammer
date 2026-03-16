#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Keep Actix handlers, extractors, state, and service logic clearly separated.\n- Be explicit about async boundaries and operational behavior.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "actix-web" "Cargo.toml" && return 0
    evop_profile_match_prompt 40 "$prompt" "actix" && return 0
    return 1
}
