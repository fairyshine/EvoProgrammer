#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep Terraform modules, environments, and provider configuration explicit and reviewable.\n- Favor reusable modules, predictable variable contracts, and validation-friendly changes over one-off inline duplication.\n- Treat state boundaries, secret flow, and rollout blast radius as first-class constraints during edits.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect root modules, shared modules, provider setup, variables, and environment overlays before editing Terraform code."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve module contracts, state layout, and plan readability while changing Terraform definitions."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer formatting, validation, targeted terraform tests, and plan-like checks before any apply-oriented workflow."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "State drift, secret exposure, destructive resource replacement, and environment skew are the main Terraform risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "main.tf" "terraform.tfvars" "terragrunt.hcl" && return 0
    evop_profile_match_file_pattern 95 "$target_dir" "*.tf" "*.tfvars" "*.tftest.hcl" && return 0
    evop_profile_match_prompt 40 "$prompt" "terraform" "terragrunt" "hcl" "infrastructure as code" && return 0
    return 1
}
