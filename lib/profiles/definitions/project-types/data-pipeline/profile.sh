#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for reproducibility, scheduling clarity, data lineage, and recoverable failure handling.\n- Keep ingestion, transformation, validation, and output stages easy to inspect.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 41 "$prompt" "data pipeline" "etl" "ingestion pipeline" "batch job" && return 0
    return 1
}
