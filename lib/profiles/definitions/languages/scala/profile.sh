#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer reproducible sbt-driven workflows, explicit module boundaries, and maintainable package structure.\n- Keep functional and object-oriented patterns intentional rather than mixing styles without a clear reason.\n- Make effect boundaries, async behavior, and JVM assumptions explicit when changing production code.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect build.sbt, module boundaries, effect or service layers, and the nearest Scala test coverage before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve type contracts, constructor wiring, and effect boundaries while refactoring Scala code."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer sbt compile, targeted unit tests, and formatting or lint checks before broader integration runs."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Implicit resolution, effect semantics, and cross-module API churn are the main Scala risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "build.sbt" && return 0
    evop_profile_match_file_pattern 95 "$target_dir" "*.scala" "*.sc" && return 0
    evop_profile_match_prompt 40 "$prompt" "scala" "sbt" && return 0
    return 1
}
