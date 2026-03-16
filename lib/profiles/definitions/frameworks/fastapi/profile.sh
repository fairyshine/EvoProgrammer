#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Use clear request and response schemas, dependency injection, and async boundaries only where they actually help.\n- Keep routers thin and separate domain logic, persistence, and background work for maintainability.\n- Preserve predictable validation, error handling, and test coverage around API contracts.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "fastapi" "pyproject.toml" "requirements.txt" "requirements-dev.txt" && return 0
    evop_profile_match_prompt 40 "$prompt" "fastapi" && return 0
    return 1
}
