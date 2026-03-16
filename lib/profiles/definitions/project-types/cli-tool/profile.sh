#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for ergonomic command structure, discoverable help output, and reproducible local execution.\n- Keep startup, configuration, and error messages straightforward.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 49 "$prompt" "cli tool" "command line" "terminal tool" "命令行" && return 0
    return 1
}
