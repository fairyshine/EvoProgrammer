#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer Composer-based dependency management and clear application structure.\n- Keep framework glue, domain logic, and templates or views clearly separated.\n- Make runtime assumptions explicit and document setup for a clean machine.\n- Favor maintainable conventions over one-off scripts.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "composer.json" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.php" && return 0
    evop_profile_match_prompt 40 "$prompt" "php" && return 0
    return 1
}
