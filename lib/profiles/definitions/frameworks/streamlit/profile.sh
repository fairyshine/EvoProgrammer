#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for interactive iteration speed, clear controls, and readable experiment or dashboard flows.\n- Keep data loading, app state, and presentation logic separated where possible.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "streamlit" "pyproject.toml" "requirements.txt" && return 0
    evop_profile_match_prompt 40 "$prompt" "streamlit" && return 0
    return 1
}
