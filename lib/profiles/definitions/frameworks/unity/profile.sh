#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep gameplay scripts, prefabs, scenes, and data assets organized for team iteration.\n- Separate engine glue from reusable gameplay logic where possible.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_directory_has_path_named "$target_dir" "Assets" && evop_directory_has_path_named "$target_dir" "ProjectSettings"; then
        EVOP_PROFILE_DETECT_SCORE=100
        return 0
    fi

    evop_profile_match_prompt 40 "$prompt" "unity" && return 0
    return 1
}
