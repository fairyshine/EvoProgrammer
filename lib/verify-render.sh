#!/usr/bin/env zsh

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
        slot_key="$(evop_project_command_env_key "$slot")"
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
