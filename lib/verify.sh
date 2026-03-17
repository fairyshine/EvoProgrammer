#!/usr/bin/env bash

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

evop_verify_report_var_name() {
    local slot="$1"
    local field="$2"

    case "$slot:$field" in
        lint:status) printf 'EVOP_VERIFY_REPORT_LINT_STATUS' ;;
        lint:command) printf 'EVOP_VERIFY_REPORT_LINT_COMMAND' ;;
        lint:log_file) printf 'EVOP_VERIFY_REPORT_LINT_LOG_FILE' ;;
        lint:exit_code) printf 'EVOP_VERIFY_REPORT_LINT_EXIT_CODE' ;;
        lint:duration_ms) printf 'EVOP_VERIFY_REPORT_LINT_DURATION_MS' ;;
        typecheck:status) printf 'EVOP_VERIFY_REPORT_TYPECHECK_STATUS' ;;
        typecheck:command) printf 'EVOP_VERIFY_REPORT_TYPECHECK_COMMAND' ;;
        typecheck:log_file) printf 'EVOP_VERIFY_REPORT_TYPECHECK_LOG_FILE' ;;
        typecheck:exit_code) printf 'EVOP_VERIFY_REPORT_TYPECHECK_EXIT_CODE' ;;
        typecheck:duration_ms) printf 'EVOP_VERIFY_REPORT_TYPECHECK_DURATION_MS' ;;
        test:status) printf 'EVOP_VERIFY_REPORT_TEST_STATUS' ;;
        test:command) printf 'EVOP_VERIFY_REPORT_TEST_COMMAND' ;;
        test:log_file) printf 'EVOP_VERIFY_REPORT_TEST_LOG_FILE' ;;
        test:exit_code) printf 'EVOP_VERIFY_REPORT_TEST_EXIT_CODE' ;;
        test:duration_ms) printf 'EVOP_VERIFY_REPORT_TEST_DURATION_MS' ;;
        build:status) printf 'EVOP_VERIFY_REPORT_BUILD_STATUS' ;;
        build:command) printf 'EVOP_VERIFY_REPORT_BUILD_COMMAND' ;;
        build:log_file) printf 'EVOP_VERIFY_REPORT_BUILD_LOG_FILE' ;;
        build:exit_code) printf 'EVOP_VERIFY_REPORT_BUILD_EXIT_CODE' ;;
        build:duration_ms) printf 'EVOP_VERIFY_REPORT_BUILD_DURATION_MS' ;;
        *) return 1 ;;
    esac
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
    eval "printf '%s' \"\${$var_name}\""
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

evop_render_verify_steps_json() {
    local output="{"
    local slot=""
    local needs_comma=0
    local step_status=""
    local command=""
    local log_file=""
    local exit_code=""
    local duration_ms=""

    while IFS= read -r slot; do
        [[ -n "$slot" ]] || continue
        step_status="$(evop_get_verify_report_step "$slot" "status")"
        command="$(evop_get_verify_report_step "$slot" "command")"
        log_file="$(evop_get_verify_report_step "$slot" "log_file")"
        exit_code="$(evop_get_verify_report_step "$slot" "exit_code")"
        duration_ms="$(evop_get_verify_report_step "$slot" "duration_ms")"

        if (( needs_comma == 1 )); then
            output+=", "
        fi

        output+="$(evop_render_json_string "$slot"): {"
        output+="\"status\": $(evop_render_json_string "$step_status"), "
        output+="\"command\": $(evop_render_json_string_or_null "$command"), "
        output+="\"log_file\": $(evop_render_json_string_or_null "$log_file"), "
        output+="\"exit_code\": ${exit_code:-0}, "
        output+="\"duration_ms\": ${duration_ms:-0}"
        output+="}"
        needs_comma=1
    done < <(evop_project_verification_slots)

    output+="}"
    printf '%s' "$output"
}

evop_render_verify_report_json() {
    printf '{\n'
    printf '  "target_dir": %s,\n' "$(evop_render_json_string_or_null "$EVOP_VERIFY_REPORT_TARGET_DIR")"
    printf '  "verify_dir": %s,\n' "$(evop_render_json_string_or_null "$EVOP_VERIFY_REPORT_VERIFY_DIR")"
    printf '  "selected_steps": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_VERIFY_REPORT_SELECTED_STEPS")"
    printf '  "continue_on_error": %s,\n' "$([[ "$EVOP_VERIFY_REPORT_CONTINUE_ON_ERROR" == "1" ]] && printf true || printf false)"
    printf '  "dry_run": %s,\n' "$([[ "$EVOP_VERIFY_REPORT_DRY_RUN" == "1" ]] && printf true || printf false)"
    printf '  "final_status": %s,\n' "${EVOP_VERIFY_REPORT_FINAL_STATUS:-0}"
    printf '  "steps": %s\n' "$(evop_render_verify_steps_json)"
    printf '}\n'
}

evop_render_verify_report_env() {
    local slot=""
    local slot_key=""

    evop_print_env_assignment "EVOP_VERIFY_TARGET_DIR" "$EVOP_VERIFY_REPORT_TARGET_DIR"
    evop_print_env_assignment "EVOP_VERIFY_VERIFY_DIR" "$EVOP_VERIFY_REPORT_VERIFY_DIR"
    evop_print_env_assignment "EVOP_VERIFY_SELECTED_STEPS" "$EVOP_VERIFY_REPORT_SELECTED_STEPS"
    evop_print_env_assignment "EVOP_VERIFY_CONTINUE_ON_ERROR" "$EVOP_VERIFY_REPORT_CONTINUE_ON_ERROR"
    evop_print_env_assignment "EVOP_VERIFY_DRY_RUN" "$EVOP_VERIFY_REPORT_DRY_RUN"
    evop_print_env_assignment "EVOP_VERIFY_FINAL_STATUS" "$EVOP_VERIFY_REPORT_FINAL_STATUS"

    while IFS= read -r slot; do
        [[ -n "$slot" ]] || continue
        slot_key="$(printf '%s' "$slot" | tr '[:lower:]-' '[:upper:]_')"
        evop_print_env_assignment "EVOP_VERIFY_${slot_key}_STATUS" "$(evop_get_verify_report_step "$slot" "status")"
        evop_print_env_assignment "EVOP_VERIFY_${slot_key}_COMMAND" "$(evop_get_verify_report_step "$slot" "command")"
        evop_print_env_assignment "EVOP_VERIFY_${slot_key}_LOG_FILE" "$(evop_get_verify_report_step "$slot" "log_file")"
        evop_print_env_assignment "EVOP_VERIFY_${slot_key}_EXIT_CODE" "$(evop_get_verify_report_step "$slot" "exit_code")"
        evop_print_env_assignment "EVOP_VERIFY_${slot_key}_DURATION_MS" "$(evop_get_verify_report_step "$slot" "duration_ms")"
    done < <(evop_project_verification_slots)
}

evop_write_verify_report() {
    local file_path="$1"
    local format="$2"

    [[ -n "$file_path" ]] || return 0

    mkdir -p "$(dirname "$file_path")"

    case "$format" in
        json)
            evop_render_verify_report_json >"$file_path"
            ;;
        env)
            evop_render_verify_report_env >"$file_path"
            ;;
        *)
            evop_fail "Unsupported verify report format: $format"
            ;;
    esac
}
