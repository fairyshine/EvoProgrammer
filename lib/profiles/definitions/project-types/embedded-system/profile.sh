#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for hardware constraints, deterministic behavior, build reproducibility, and testability.\n- Be explicit about platform assumptions, memory limits, and deployment steps.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 39 "$prompt" "embedded" "firmware" "mcu" "microcontroller" && return 0
    return 1
}
