#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer explicit module boundaries, reproducible Stack or Cabal workflows, and small pure units that are easy to test.\n- Keep effectful code narrow, surface type signatures when they improve readability, and document build assumptions clearly.'

evop_profile_apply_project_context() {
    local target_dir="$1"

    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect exposed modules, package manifests, executables, and nearby tests before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep pure logic isolated from IO edges and preserve module or package boundaries while changing behavior."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer Cabal or Stack build and test commands plus the nearest regression coverage."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Public module exports, package wiring, and type-level refactors can ripple through multiple call sites."

    if [[ -d "$target_dir/test" || -d "$target_dir/tests" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Existing Haskell tests are present; extend the closest suite before broader validation."
    fi
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "stack.yaml" "cabal.project" && return 0
    evop_profile_match_file_pattern 95 "$target_dir" "*.cabal" && return 0
    evop_profile_match_file_pattern 85 "$target_dir" "*.hs" "*.lhs" && return 0
    evop_profile_match_prompt 40 "$prompt" "haskell" "cabal" "stack" && return 0
    return 1
}
