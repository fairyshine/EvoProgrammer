#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Prefer `pyproject.toml`-based project structure and explicit dependency management.\n- Use virtual-environment-friendly commands and keep setup reproducible on a clean machine.\n- Favor typed Python, small modules, and testable packages over logic hidden in scripts.\n- Keep framework or CLI entrypoints thin, and add `pytest`-style tests around changed behavior when relevant.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "pyproject.toml" "requirements.txt" "setup.py" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.py" && return 0
    evop_profile_match_prompt 40 "$prompt" "python" && return 0
    return 1
}
