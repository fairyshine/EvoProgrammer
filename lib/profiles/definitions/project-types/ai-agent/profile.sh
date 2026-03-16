#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for tool boundaries, prompt/system behavior clarity, observability, and reproducible workflows.\n- Be explicit about model assumptions, safety constraints, and execution traces.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 42 "$prompt" "ai agent" "assistant" "tool-using agent" "workflow agent" && return 0
    return 1
}
