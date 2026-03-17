#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Separate UI widgets from core logic and keep signal-slot wiring understandable.\n- Make cross-platform build and packaging steps explicit.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 100 "$target_dir" "*.ui" && return 0
    evop_profile_match_directory_text 95 "$target_dir" "qt" "CMakeLists.txt" "*.pro" "pyproject.toml" && return 0
    evop_profile_match_prompt 40 "$prompt" "qt" && return 0
    return 1
}
