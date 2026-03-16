#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for API clarity, versionability, documentation, and test coverage.\n- Keep public interfaces intentional and avoid leaking internal assumptions.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 48 "$prompt" "sdk" "library" "package" "crate" "module" && return 0
    return 1
}
