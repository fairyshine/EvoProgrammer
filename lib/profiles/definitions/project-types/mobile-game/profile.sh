#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for touch-first interaction, low-friction onboarding, and mobile performance constraints.\n- Account for battery, memory, varying screen sizes, and mobile asset handling.\n- Prefer iteration speed, simple packaging, and testable gameplay slices.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 97 "$target_dir" "AndroidManifest.xml" "Info.plist" && return 0
    evop_profile_match_prompt 97 "$prompt" "mobile game" "ios game" "android game" "手机游戏" && return 0
    return 1
}
