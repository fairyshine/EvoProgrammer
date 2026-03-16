#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Prefer `pyproject.toml`-based project structure.\n- Use virtual-environment-friendly commands and document setup clearly.\n- Favor typed Python, modular packages, and `pytest`-style tests when tests are appropriate.\n- Keep scripts and entrypoints simple to run from a clean machine.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "pyproject.toml" "requirements.txt" "setup.py" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.py" && return 0
    evop_profile_match_prompt 40 "$prompt" "python" && return 0
    return 1
}
