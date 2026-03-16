#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Be explicit about main/renderer boundaries, IPC contracts, and packaging assumptions.\n- Keep desktop integration isolated from app business logic.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "\"electron\"" "package.json" && return 0
    evop_profile_match_prompt 40 "$prompt" "electron" && return 0
    return 1
}
