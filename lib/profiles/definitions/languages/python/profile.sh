#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer `pyproject.toml`-based project structure and explicit dependency management.\n- Use virtual-environment-friendly commands and keep setup reproducible on a clean machine.\n- Favor typed Python, small modules, and testable packages over logic hidden in scripts.\n- Keep framework or CLI entrypoints thin, and add `pytest`-style tests around changed behavior when relevant.'

evop_profile_apply_project_context() {
    local target_dir="$1"

    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect package entrypoints, service modules, schemas, and tests before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep framework glue thin and move changed behavior into importable, testable modules."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer static checks and targeted pytest coverage before broader integration validation."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Watch import-time side effects, environment-dependent behavior, and untyped data crossing module boundaries."

    if [[ -d "$target_dir/tests" || -d "$target_dir/test" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Existing pytest-style tests are present; extend the nearest coverage before broadening integration checks."
    fi
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "pyproject.toml" "requirements.txt" "setup.py" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.py" && return 0
    evop_profile_match_prompt 40 "$prompt" "python" && return 0
    return 1
}
