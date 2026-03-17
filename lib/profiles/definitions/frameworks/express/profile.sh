#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep routing, middleware, validation, and service logic separate.\n- Avoid an unstructured pile of request handlers and implicit middleware coupling.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "\"express\"" "package.json" && return 0
    evop_profile_match_prompt 40 "$prompt" "express" && return 0
    return 1
}
