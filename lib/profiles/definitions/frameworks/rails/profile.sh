#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Follow Rails conventions for app structure, migrations, jobs, and environment config.\n- Keep domain logic from leaking entirely into controllers and views.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "rails" "Gemfile" && return 0
    evop_profile_match_prompt 40 "$prompt" "rails" && return 0
    return 1
}
