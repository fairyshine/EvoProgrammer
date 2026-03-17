#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for reproducibility, scheduling clarity, data lineage, and recoverable failure handling.\n- Keep ingestion, transformation, validation, and output stages easy to inspect.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect input parsing, transforms, output sinks, and retry or scheduling paths first."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve data contracts, checkpoint semantics, and rerun safety while changing logic."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer fixture-based data regression tests and rerun or idempotency validation."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Schema drift, partial writes, duplicate processing, and observability gaps are high-risk."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 41 "$prompt" "data pipeline" "etl" "ingestion pipeline" "batch job" && return 0
    return 1
}
