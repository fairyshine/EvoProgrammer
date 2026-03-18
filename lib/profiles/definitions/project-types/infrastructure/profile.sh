#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for reproducible environments, explicit rollout safety, and clear separation between modules, environments, and generated state.\n- Keep infrastructure definitions reviewable, idempotent, and easy to validate locally or in CI.\n- Treat secrets, drift, and deployment blast radius as first-class constraints when changing automation.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect environment overlays, shared modules, provider configuration, and deploy entrypoints before editing infrastructure code."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve state boundaries, module contracts, and rollout sequencing while changing infrastructure definitions."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer formatting, validation, dry-run or plan output, and environment-specific smoke checks before apply-like steps."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "State drift, secret handling, destructive changes, and environment skew are the main infrastructure risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_repo_looks_like_infrastructure "$target_dir"; then
        EVOP_PROFILE_DETECT_SCORE=93
        return 0
    fi

    evop_profile_match_prompt 48 "$prompt" "terraform" "infra" "infrastructure" "helm" "kubernetes" "k8s" "ansible" "iac" && return 0
    return 1
}
