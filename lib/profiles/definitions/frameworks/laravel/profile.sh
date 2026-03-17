#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Follow Laravel conventions for routing, services, migrations, queues, and config.\n- Keep application logic structured beyond controllers and facades.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "artisan" && return 0
    evop_profile_match_directory_text 95 "$target_dir" "laravel/framework" "composer.json" && return 0
    evop_profile_match_prompt 40 "$prompt" "laravel" && return 0
    return 1
}
