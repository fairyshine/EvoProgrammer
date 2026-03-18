#!/usr/bin/env zsh

evop_validate_catalog_format() {
    case "$1" in
        summary|json|env)
            return 0
            ;;
        *)
            evop_fail "Unsupported catalog format: $1"
            ;;
    esac
}

evop_validate_catalog_kind() {
    case "$1" in
        all|commands|support)
            return 0
            ;;
        *)
            evop_fail "Unsupported catalog kind: $1"
            ;;
    esac
}

evop_print_agent_catalog_output() {
    local output_format="$1"
    local output_kind="${2:-all}"

    case "$output_format" in
        summary)
            evop_print_project_agent_catalog_report "$output_kind"
            ;;
        json)
            evop_render_agent_catalog_bundle_json "$output_kind"
            ;;
        env)
            evop_print_project_agent_catalog_env "$output_kind"
            ;;
    esac
}

evop_write_agent_catalog_report() {
    local file_path="$1"
    local output_format="$2"
    local output_kind="${3:-all}"

    [[ -n "$file_path" ]] || return 0

    mkdir -p "$(dirname "$file_path")"
    evop_print_agent_catalog_output "$output_format" "$output_kind" >"$file_path"
}
