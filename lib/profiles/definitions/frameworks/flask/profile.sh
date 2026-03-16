#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Keep the Flask app modular with explicit app factory or blueprint structure where appropriate.\n- Avoid turning a small service into a monolith of globals and implicit side effects.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "flask" "pyproject.toml" "requirements.txt" "requirements-dev.txt" && return 0
    evop_profile_match_prompt 40 "$prompt" "flask" && return 0
    return 1
}
