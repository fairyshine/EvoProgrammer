#!/usr/bin/env bash

evop_validate_inspect_format() {
    case "$1" in
        summary|diagnostics|profiles|doctor|prompt|timings|json|env)
            return 0
            ;;
        *)
            evop_fail "Unsupported inspect format: $1"
            ;;
    esac
}

evop_print_project_inspection_output() {
    local output_format="$1"

    case "$output_format" in
        summary)
            evop_print_project_inspection_report
            ;;
        diagnostics)
            evop_print_project_inspection_diagnostics
            ;;
        profiles)
            evop_print_profile_detection_report
            ;;
        timings)
            evop_print_project_inspection_timings
            ;;
        doctor)
            printf 'OK agent %s\n' "$AGENT"
            evop_print_current_profiles "doctor"
            printf 'OK target-dir %s\n' "$TARGET_DIR"
            ;;
        prompt)
            printf '%s' "$(evop_render_project_context_prompt)"
            ;;
        json)
            evop_render_project_context_json
            ;;
        env)
            evop_print_project_inspection_env
            ;;
    esac
}

evop_write_project_inspection_report() {
    local file_path="$1"
    local output_format="$2"

    [[ -n "$file_path" ]] || return 0

    mkdir -p "$(dirname "$file_path")"
    evop_print_project_inspection_output "$output_format" >"$file_path"
}
