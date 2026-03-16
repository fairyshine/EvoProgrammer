#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for API clarity, operational safety, observability, and maintainable service boundaries.\n- Be explicit about configuration, storage, and deployment assumptions.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 50 "$prompt" "backend service" "api service" "microservice" "rest api" "backend" && return 0
    return 1
}
