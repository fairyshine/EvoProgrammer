#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for API clarity, versionability, documentation, and test coverage.\n- Keep public interfaces intentional and avoid leaking internal assumptions.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect exported interfaces, examples, and compatibility-sensitive tests first."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Minimize churn in public APIs and update docs or examples alongside behavior changes."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prioritize API-level tests, examples, and compatibility checks before release-oriented builds."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Public interfaces, semantic versioning expectations, and cross-package consumers deserve extra care."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_repo_looks_like_library "$target_dir"; then
        EVOP_PROFILE_DETECT_SCORE=87
        return 0
    fi

    evop_profile_match_prompt 48 "$prompt" "sdk" "library" "package" "crate" "module" && return 0
    return 1
}
