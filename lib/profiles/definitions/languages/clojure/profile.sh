#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer data-oriented, REPL-friendly workflows with clear namespaces and small pure functions.\n- Keep dependency aliases, tooling entrypoints, and test commands explicit so local execution stays reproducible.\n- Separate runtime wiring from transformation logic, and be deliberate about immutable data boundaries.'

evop_profile_apply_project_context() {
    local target_dir="$1"

    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect namespace boundaries, deps aliases, runtime entrypoints, and focused tests before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve data flow clarity and keep side effects localized at the edges."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer REPL-friendly targeted checks and the narrowest project test command that covers the change."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Namespace wiring, dynamic configuration, and lazy data boundaries are the main Clojure risks."

    if [[ -d "$target_dir/test" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Existing Clojure tests are present; extend the nearest namespace coverage before broader runs."
    fi
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "deps.edn" "project.clj" "build.boot" && return 0
    evop_profile_match_file_pattern 85 "$target_dir" "*.clj" "*.cljs" "*.cljc" && return 0
    evop_profile_match_prompt 40 "$prompt" "clojure" "clojurescript" "leiningen" && return 0
    return 1
}
