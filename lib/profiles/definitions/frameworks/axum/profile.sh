#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Keep routers, extractors, shared state, and application services modular and typed clearly.\n- Favor composable middleware and maintainable request handling.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "axum" "Cargo.toml" && return 0
    evop_profile_match_prompt 40 "$prompt" "axum" && return 0
    return 1
}
