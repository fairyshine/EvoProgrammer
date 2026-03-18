#!/usr/bin/env zsh

evop_validate_inspect_format() {
    case "$1" in
        summary|commands|diagnostics|profiles|doctor|prompt|timings|json|env|agent|agent-json|agent-env)
            return 0
            ;;
        *)
            evop_fail "Unsupported inspect format: $1"
            ;;
    esac
}

evop_print_project_inspection_output() {
    local output_format="$1"
    local recommend_for="${2:-none}"

    case "$output_format" in
        summary)
            evop_print_project_inspection_report
            ;;
        commands)
            evop_print_project_command_report
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
        agent)
            evop_print_project_agent_catalog_report "all" "all" "$recommend_for"
            ;;
        agent-json)
            evop_render_agent_catalog_bundle_json "all" "all" "$recommend_for"
            ;;
        agent-env)
            evop_print_project_agent_catalog_env "all" "all" "$recommend_for"
            ;;
    esac
}

evop_write_project_inspection_report() {
    local file_path="$1"
    local output_format="$2"
    local recommend_for="${3:-none}"

    [[ -n "$file_path" ]] || return 0

    mkdir -p "$(dirname "$file_path")"
    evop_print_project_inspection_output "$output_format" "$recommend_for" >"$file_path"
}
