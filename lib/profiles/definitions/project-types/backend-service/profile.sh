#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for API clarity, operational safety, observability, and maintainable service boundaries.\n- Be explicit about configuration, storage, and deployment assumptions.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect request handlers, schemas, service logic, persistence, and contract tests first."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve API contracts, validation behavior, and error semantics while changing internals."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prioritize contract tests, integration tests, and schema or migration safety checks."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "API compatibility, idempotency, persistence changes, and background jobs are high-risk."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 50 "$prompt" "backend service" "api service" "microservice" "rest api" "backend" && return 0
    return 1
}
