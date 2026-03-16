#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Use Django conventions for apps, settings, models, migrations, and admin integration.\n- Keep business logic out of views where practical and structure reusable apps cleanly.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "manage.py" && return 0
    evop_profile_match_directory_text 95 "$target_dir" "django" "pyproject.toml" "requirements.txt" "requirements-dev.txt" && return 0
    evop_profile_match_prompt 40 "$prompt" "django" && return 0
    return 1
}
