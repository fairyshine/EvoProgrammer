#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer Bundler-managed dependencies and standard Ruby project conventions.\n- Keep business logic, app wiring, and background jobs or scripts clearly separated.\n- Make the local development and test workflow straightforward.\n- Favor readable, idiomatic Ruby over clever abstractions.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "Gemfile" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.rb" && return 0
    evop_profile_match_prompt 40 "$prompt" "ruby" && return 0
    return 1
}
