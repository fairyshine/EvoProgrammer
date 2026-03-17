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

evop_validate_verify_list_format() {
    case "$1" in
        summary|json|env)
            return 0
            ;;
        *)
            evop_fail "Unsupported verify list format: $1"
            ;;
    esac
}

evop_collect_verify_missing_steps() {
    local selected_steps="$1"
    local slot=""
    local command=""
    local missing=""

    while IFS= read -r slot; do
        [[ -n "$slot" ]] || continue
        command="$(evop_get_project_command "$slot")"
        [[ -n "$command" ]] && continue
        [[ -n "$missing" ]] && missing+=$'\n'
        missing+="$slot"
    done <<<"$selected_steps"

    printf '%s' "$missing"
}

evop_require_verify_commands() {
    local selected_steps="$1"
    local missing=""
    local inline_missing=""

    missing="$(evop_collect_verify_missing_steps "$selected_steps")"
    [[ -n "$missing" ]] || return 0

    inline_missing="${missing//$'\n'/, }"
    evop_fail "Missing verification commands for selected steps: $inline_missing"
}

evop_print_verify_plan_summary() {
    local target_dir="$1"
    local selected_steps="$2"
    local slot=""
    local command=""
    local source=""

    printf 'Target directory: %s\n' "$target_dir"
    printf 'Selected verification steps:\n'
    while IFS= read -r slot; do
        [[ -n "$slot" ]] || continue
        command="$(evop_get_project_command "$slot")"
        source="$(evop_get_project_command_source "$slot")"
        if [[ -n "$command" ]]; then
            printf -- '- %s: %s' "$slot" "$command"
            [[ -n "$source" && "$source" != "none" ]] && printf ' [%s]' "$source"
            printf '\n'
        else
            printf -- '- %s: missing\n' "$slot"
        fi
    done <<<"$selected_steps"
}

evop_render_verify_plan_steps_json() {
    local selected_steps="$1"
    local output="{"
    local slot=""
    local command=""
    local source=""
    local runnable=0
    local needs_comma=0

    while IFS= read -r slot; do
        [[ -n "$slot" ]] || continue
        command="$(evop_get_project_command "$slot")"
        source="$(evop_get_project_command_source "$slot")"
        runnable=0
        [[ -n "$command" ]] && runnable=1
        if (( needs_comma == 1 )); then
            output+=", "
        fi
        output+="$(evop_render_json_string "$slot"): {"
        output+="\"command\": $(evop_render_json_string_or_null "$command"), "
        output+="\"source\": $(evop_render_json_string_or_null "$source"), "
        output+="\"runnable\": $([[ "$runnable" == "1" ]] && printf true || printf false)"
        output+="}"
        needs_comma=1
    done <<<"$selected_steps"

    output+="}"
    printf '%s' "$output"
}

evop_render_verify_plan_json() {
    local target_dir="$1"
    local selected_steps="$2"

    printf '{\n'
    printf '  "target_dir": %s,\n' "$(evop_render_json_string_or_null "$target_dir")"
    printf '  "selected_steps": %s,\n' "$(evop_render_json_array_from_lines "$selected_steps")"
    printf '  "steps": %s\n' "$(evop_render_verify_plan_steps_json "$selected_steps")"
    printf '}\n'
}

evop_render_verify_plan_env() {
    local target_dir="$1"
    local selected_steps="$2"
    local slot=""
    local slot_key=""
    local command=""
    local source=""

    evop_print_env_assignment "EVOP_VERIFY_PLAN_TARGET_DIR" "$target_dir"
    evop_print_env_assignment "EVOP_VERIFY_PLAN_SELECTED_STEPS" "$selected_steps"

    while IFS= read -r slot; do
        [[ -n "$slot" ]] || continue
        slot_key="$(printf '%s' "$slot" | tr '[:lower:]-' '[:upper:]_')"
        command="$(evop_get_project_command "$slot")"
        source="$(evop_get_project_command_source "$slot")"
        evop_print_env_assignment "EVOP_VERIFY_PLAN_${slot_key}_COMMAND" "$command"
        evop_print_env_assignment "EVOP_VERIFY_PLAN_${slot_key}_SOURCE" "$source"
        evop_print_env_assignment "EVOP_VERIFY_PLAN_${slot_key}_RUNNABLE" "$([[ -n "$command" ]] && printf 1 || printf 0)"
    done <<<"$selected_steps"
}

evop_print_verify_plan() {
    local target_dir="$1"
    local selected_steps="$2"
    local format="$3"

    case "$format" in
        summary)
            evop_print_verify_plan_summary "$target_dir" "$selected_steps"
            ;;
        json)
            evop_render_verify_plan_json "$target_dir" "$selected_steps"
            ;;
        env)
            evop_render_verify_plan_env "$target_dir" "$selected_steps"
            ;;
    esac
}
