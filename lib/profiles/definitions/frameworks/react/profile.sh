#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Keep component boundaries intentional, state flow clear, and rendering paths easy to reason about.\n- Avoid over-centralizing all behavior into one component tree.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "\"react\"" "package.json" && return 0
    evop_profile_match_prompt 40 "$prompt" "react" && return 0
    return 1
}
