#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep engine module boundaries, gameplay classes, and assets organized for scale.\n- Make build assumptions and editor/runtime dependencies explicit.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 100 "$target_dir" "*.uproject" && return 0
    evop_profile_match_prompt 40 "$prompt" "unreal" && return 0
    return 1
}
