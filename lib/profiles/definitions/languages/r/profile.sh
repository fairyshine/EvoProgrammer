#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer reproducible project-local environments such as `renv`, explicit package dependencies, and scriptable data workflows.\n- Keep analysis, modeling, and app-facing code separated so experiments and productionized reports do not drift together.\n- Favor deterministic scripts, checked inputs, and testthat-backed coverage around changed behavior when the repo already uses it.'

evop_profile_apply_project_context() {
    local target_dir="$1"

    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect entry scripts, reusable analysis helpers, package metadata, and testthat coverage before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep data-loading, transformation, visualization, and app glue separated so workflows stay reproducible."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer targeted testthat coverage, reproducible script runs, and linter checks before broader report or app validation."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Hidden global state, environment-specific package resolution, and unchecked data-shape assumptions are the main R risks."

    if [[ -d "$target_dir/tests" || -d "$target_dir/testthat" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Existing R test coverage is present; extend the nearest testthat checks before broader end-to-end validation."
    fi
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "DESCRIPTION" "renv.lock" "NAMESPACE" && return 0
    evop_profile_match_file_pattern 95 "$target_dir" "*.Rproj" "*.R" "*.Rmd" && return 0
    evop_profile_match_prompt 40 "$prompt" "r language" "rscript" "tidyverse" "ggplot2" "shiny" "rstats" && return 0
    return 1
}
