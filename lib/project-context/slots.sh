#!/usr/bin/env zsh

typeset -a EVOP_PROJECT_COMMAND_SLOT_ORDER=(
    dev
    build
    test
    lint
    typecheck
)

typeset -a EVOP_PROJECT_VERIFICATION_SLOT_ORDER=(
    lint
    typecheck
    test
    build
)

typeset -A EVOP_PROJECT_COMMAND_LABELS=(
    [dev]="Dev"
    [build]="Build"
    [test]="Test"
    [lint]="Lint"
    [typecheck]="Typecheck"
)

typeset -A EVOP_PROJECT_COMMAND_VALUE_VARS=(
    [dev]="EVOP_PROJECT_CONTEXT_DEV_COMMAND"
    [build]="EVOP_PROJECT_CONTEXT_BUILD_COMMAND"
    [test]="EVOP_PROJECT_CONTEXT_TEST_COMMAND"
    [lint]="EVOP_PROJECT_CONTEXT_LINT_COMMAND"
    [typecheck]="EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND"
)

typeset -A EVOP_PROJECT_COMMAND_SOURCE_VARS=(
    [dev]="EVOP_PROJECT_CONTEXT_DEV_COMMAND_SOURCE"
    [build]="EVOP_PROJECT_CONTEXT_BUILD_COMMAND_SOURCE"
    [test]="EVOP_PROJECT_CONTEXT_TEST_COMMAND_SOURCE"
    [lint]="EVOP_PROJECT_CONTEXT_LINT_COMMAND_SOURCE"
    [typecheck]="EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND_SOURCE"
)

typeset -A EVOP_PROJECT_COMMAND_ENV_KEYS=(
    [dev]="DEV"
    [build]="BUILD"
    [test]="TEST"
    [lint]="LINT"
    [typecheck]="TYPECHECK"
)

evop_project_command_slots() {
    printf '%s\n' "${EVOP_PROJECT_COMMAND_SLOT_ORDER[@]}"
}

evop_project_verification_slots() {
    printf '%s\n' "${EVOP_PROJECT_VERIFICATION_SLOT_ORDER[@]}"
}

evop_project_command_value_var() {
    [[ -n "${EVOP_PROJECT_COMMAND_VALUE_VARS[$1]:-}" ]] || return 1
    printf '%s' "${EVOP_PROJECT_COMMAND_VALUE_VARS[$1]}"
}

evop_project_command_source_var() {
    [[ -n "${EVOP_PROJECT_COMMAND_SOURCE_VARS[$1]:-}" ]] || return 1
    printf '%s' "${EVOP_PROJECT_COMMAND_SOURCE_VARS[$1]}"
}

evop_project_command_label() {
    [[ -n "${EVOP_PROJECT_COMMAND_LABELS[$1]:-}" ]] || return 1
    printf '%s' "${EVOP_PROJECT_COMMAND_LABELS[$1]}"
}

evop_project_command_env_key() {
    [[ -n "${EVOP_PROJECT_COMMAND_ENV_KEYS[$1]:-}" ]] || return 1
    printf '%s' "${EVOP_PROJECT_COMMAND_ENV_KEYS[$1]}"
}
