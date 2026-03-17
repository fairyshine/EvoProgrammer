#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep Gin routing, middleware, request validation, and domain logic cleanly separated.\n- Favor simple service boundaries and testable handlers.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "gin-gonic/gin" "go.mod" "*.go" && return 0
    evop_profile_match_prompt 40 "$prompt" "gin" && return 0
    return 1
}
