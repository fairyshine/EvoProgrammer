#!/usr/bin/env zsh

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
        slot_key="$(evop_project_command_env_key "$slot")"
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
