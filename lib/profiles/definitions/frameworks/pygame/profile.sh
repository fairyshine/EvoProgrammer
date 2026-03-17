#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep the game loop, input handling, rendering, and asset loading separated and easy to extend.\n- Prefer practical performance and quick playtesting over heavyweight abstraction.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "pygame" "pyproject.toml" "requirements.txt" && return 0
    evop_profile_match_prompt 40 "$prompt" "pygame" && return 0
    return 1
}
