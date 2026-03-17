#!/usr/bin/env zsh

evop_format_prefixed_lines() {
    local prefix="$1"
    local text="$2"
    local output=""
    local line=""

    [[ -n "$text" ]] || return 0

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        output+="$prefix$line"$'\n'
    done <<<"$text"

    printf '%s' "$output"
}

evop_format_inline_lines() {
    local text="$1"
    local output=""
    local line=""

    [[ -n "$text" ]] || return 0

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if [[ -n "$output" ]]; then
            output+=" | "
        fi
        output+="$line"
    done <<<"$text"

    printf '%s' "$output"
}

evop_json_escape() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"

    printf '%s' "$value"
}

evop_render_json_string() {
    printf '"%s"' "$(evop_json_escape "$1")"
}

evop_render_json_string_or_null() {
    if [[ -n "$1" ]]; then
        evop_render_json_string "$1"
    else
        printf 'null'
    fi
}

evop_render_json_array_from_lines() {
    local text="$1"
    local output="["
    local line=""
    local needs_comma=0

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if (( needs_comma == 1 )); then
            output+=", "
        fi
        output+="$(evop_render_json_string "$line")"
        needs_comma=1
    done <<<"$text"

    output+="]"
    printf '%s' "$output"
}

evop_append_project_command_lines() {
    local prefix="$1"
    local include_sources="${2:-0}"
    local output=""
    local slot=""
    local label=""
    local command=""
    local source=""

    while IFS= read -r slot; do
        command="$(evop_get_project_command "$slot")"
        [[ -n "$command" ]] || continue

        label="$(evop_project_command_label "$slot")"
        output+="$prefix$label: $command"

        if [[ "$include_sources" == "1" ]]; then
            source="$(evop_get_project_command_source "$slot")"
            [[ -n "$source" && "$source" != "none" ]] && output+=" [$source]"
        fi

        output+=$'\n'
    done < <(evop_project_command_slots)

    printf '%s' "$output"
}

evop_print_env_assignment() {
    printf '%s=%q\n' "$1" "$2"
}
