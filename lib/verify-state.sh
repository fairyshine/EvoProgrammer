#!/usr/bin/env zsh

# shellcheck disable=SC2034

EVOP_VERIFY_REPORT_TARGET_DIR=""
EVOP_VERIFY_REPORT_VERIFY_DIR=""
EVOP_VERIFY_REPORT_SELECTED_STEPS=""
EVOP_VERIFY_REPORT_CONTINUE_ON_ERROR=0
EVOP_VERIFY_REPORT_DRY_RUN=0
EVOP_VERIFY_REPORT_FINAL_STATUS=0

EVOP_VERIFY_REPORT_LINT_STATUS="not_selected"
EVOP_VERIFY_REPORT_LINT_COMMAND=""
EVOP_VERIFY_REPORT_LINT_LOG_FILE=""
EVOP_VERIFY_REPORT_LINT_EXIT_CODE=0
EVOP_VERIFY_REPORT_LINT_DURATION_MS=0

EVOP_VERIFY_REPORT_TYPECHECK_STATUS="not_selected"
EVOP_VERIFY_REPORT_TYPECHECK_COMMAND=""
EVOP_VERIFY_REPORT_TYPECHECK_LOG_FILE=""
EVOP_VERIFY_REPORT_TYPECHECK_EXIT_CODE=0
EVOP_VERIFY_REPORT_TYPECHECK_DURATION_MS=0

EVOP_VERIFY_REPORT_TEST_STATUS="not_selected"
EVOP_VERIFY_REPORT_TEST_COMMAND=""
EVOP_VERIFY_REPORT_TEST_LOG_FILE=""
EVOP_VERIFY_REPORT_TEST_EXIT_CODE=0
EVOP_VERIFY_REPORT_TEST_DURATION_MS=0

EVOP_VERIFY_REPORT_BUILD_STATUS="not_selected"
EVOP_VERIFY_REPORT_BUILD_COMMAND=""
EVOP_VERIFY_REPORT_BUILD_LOG_FILE=""
EVOP_VERIFY_REPORT_BUILD_EXIT_CODE=0
EVOP_VERIFY_REPORT_BUILD_DURATION_MS=0

typeset -A EVOP_VERIFY_REPORT_FIELD_VARS=(
    [lint:status]="EVOP_VERIFY_REPORT_LINT_STATUS"
    [lint:command]="EVOP_VERIFY_REPORT_LINT_COMMAND"
    [lint:log_file]="EVOP_VERIFY_REPORT_LINT_LOG_FILE"
    [lint:exit_code]="EVOP_VERIFY_REPORT_LINT_EXIT_CODE"
    [lint:duration_ms]="EVOP_VERIFY_REPORT_LINT_DURATION_MS"
    [typecheck:status]="EVOP_VERIFY_REPORT_TYPECHECK_STATUS"
    [typecheck:command]="EVOP_VERIFY_REPORT_TYPECHECK_COMMAND"
    [typecheck:log_file]="EVOP_VERIFY_REPORT_TYPECHECK_LOG_FILE"
    [typecheck:exit_code]="EVOP_VERIFY_REPORT_TYPECHECK_EXIT_CODE"
    [typecheck:duration_ms]="EVOP_VERIFY_REPORT_TYPECHECK_DURATION_MS"
    [test:status]="EVOP_VERIFY_REPORT_TEST_STATUS"
    [test:command]="EVOP_VERIFY_REPORT_TEST_COMMAND"
    [test:log_file]="EVOP_VERIFY_REPORT_TEST_LOG_FILE"
    [test:exit_code]="EVOP_VERIFY_REPORT_TEST_EXIT_CODE"
    [test:duration_ms]="EVOP_VERIFY_REPORT_TEST_DURATION_MS"
    [build:status]="EVOP_VERIFY_REPORT_BUILD_STATUS"
    [build:command]="EVOP_VERIFY_REPORT_BUILD_COMMAND"
    [build:log_file]="EVOP_VERIFY_REPORT_BUILD_LOG_FILE"
    [build:exit_code]="EVOP_VERIFY_REPORT_BUILD_EXIT_CODE"
    [build:duration_ms]="EVOP_VERIFY_REPORT_BUILD_DURATION_MS"
)

evop_verify_report_var_name() {
    local field_key="$1:$2"

    [[ -n "${EVOP_VERIFY_REPORT_FIELD_VARS[$field_key]:-}" ]] || return 1
    printf '%s' "${EVOP_VERIFY_REPORT_FIELD_VARS[$field_key]}"
}

evop_reset_verify_report() {
    local slot=""

    EVOP_VERIFY_REPORT_TARGET_DIR=""
    EVOP_VERIFY_REPORT_VERIFY_DIR=""
    EVOP_VERIFY_REPORT_SELECTED_STEPS=""
    EVOP_VERIFY_REPORT_CONTINUE_ON_ERROR=0
    EVOP_VERIFY_REPORT_DRY_RUN=0
    EVOP_VERIFY_REPORT_FINAL_STATUS=0

    while IFS= read -r slot; do
        evop_set_verify_report_step "$slot" "status" "not_selected"
        evop_set_verify_report_step "$slot" "command" ""
        evop_set_verify_report_step "$slot" "log_file" ""
        evop_set_verify_report_step "$slot" "exit_code" 0
        evop_set_verify_report_step "$slot" "duration_ms" 0
    done < <(evop_project_verification_slots)
}

evop_set_verify_report_step() {
    local slot="$1"
    local field="$2"
    local value="${3-}"
    local var_name=""

    var_name="$(evop_verify_report_var_name "$slot" "$field")" || return 1
    printf -v "$var_name" '%s' "$value"
}

evop_get_verify_report_step() {
    local slot="$1"
    local field="$2"
    local var_name=""

    var_name="$(evop_verify_report_var_name "$slot" "$field")" || return 1
    printf '%s' "${(P)var_name}"
}

evop_begin_verify_report() {
    local target_dir="$1"
    local verify_dir="$2"
    local selected_steps="$3"
    local continue_on_error="$4"
    local dry_run="$5"
    local slot=""

    evop_reset_verify_report
    EVOP_VERIFY_REPORT_TARGET_DIR="$target_dir"
    EVOP_VERIFY_REPORT_VERIFY_DIR="$verify_dir"
    EVOP_VERIFY_REPORT_SELECTED_STEPS="$selected_steps"
    EVOP_VERIFY_REPORT_CONTINUE_ON_ERROR="$continue_on_error"
    EVOP_VERIFY_REPORT_DRY_RUN="$dry_run"

    while IFS= read -r slot; do
        [[ -n "$slot" ]] || continue
        evop_set_verify_report_step "$slot" "status" "pending"
    done <<<"$selected_steps"
}

evop_record_verify_step() {
    local slot="$1"
    local command="$2"
    local log_file="$3"
    local step_status="$4"
    local exit_code="$5"
    local duration_ms="$6"

    evop_set_verify_report_step "$slot" "command" "$command"
    evop_set_verify_report_step "$slot" "log_file" "$log_file"
    evop_set_verify_report_step "$slot" "status" "$step_status"
    evop_set_verify_report_step "$slot" "exit_code" "$exit_code"
    evop_set_verify_report_step "$slot" "duration_ms" "$duration_ms"
}
