#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for host integration boundaries, version compatibility, and packaging clarity.\n- Keep plugin code isolated from host-specific glue as much as possible.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect host registration points, capability hooks, packaging metadata, and compatibility tests first."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep host-specific adapters thin and avoid spreading plugin assumptions across unrelated modules."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer host-facing smoke checks, packaging validation, and backward-compatibility checks."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Host API drift, plugin lifecycle hooks, packaging metadata, and version compatibility are the main risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_repo_looks_like_plugin "$target_dir"; then
        EVOP_PROFILE_DETECT_SCORE=89
        return 0
    fi

    evop_profile_match_prompt 40 "$prompt" "plugin" "extension" "addon" "add-on" && return 0
    return 1
}
