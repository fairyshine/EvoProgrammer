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

evop_filter_agent_command_catalog_lines() {
    local text="$1"
    local capability_filter="${2:-all}"
    local output=""
    local kind=""
    local command=""
    local source=""
    local capability=""

    while IFS=$'\t' read -r kind command source; do
        [[ -n "$kind" && -n "$command" && -n "$source" ]] || continue
        if ! evop_agent_command_catalog_matches_capability "$kind" "$command" "$source" "$capability_filter"; then
            continue
        fi
        capability="$(evop_agent_command_capability "$kind" "$command" "$source")"
        output+="$kind"$'\t'"$capability"$'\t'"$command"$'\t'"$source"$'\n'
    done <<<"$text"

    printf '%s' "$output"
}

evop_render_agent_command_catalog_json() {
    local text="$1"
    local capability_filter="${2:-all}"
    local filtered_text=""

    filtered_text="$(evop_filter_agent_command_catalog_lines "$text" "$capability_filter")"
    evop_render_agent_command_catalog_json_from_filtered "$filtered_text"
}

evop_render_agent_command_catalog_json_from_filtered() {
    local filtered_text="$1"
    local output="["
    local kind=""
    local capability=""
    local command=""
    local source=""
    local needs_comma=0

    while IFS=$'\t' read -r kind capability command source; do
        [[ -n "$kind" && -n "$capability" && -n "$command" && -n "$source" ]] || continue
        if (( needs_comma == 1 )); then
            output+=", "
        fi
        output+="{\"kind\": $(evop_render_json_string "$kind"), \"capability\": "
        output+="$(evop_render_json_string "$capability")"
        output+=", \"command\": $(evop_render_json_string "$command")"
        output+=", \"source\": $(evop_render_json_string "$source")}"
        needs_comma=1
    done <<<"$filtered_text"

    output+="]"
    printf '%s' "$output"
}

evop_render_agent_tool_lines_from_catalog() {
    local text="$1"
    local capability_filter="${2:-all}"
    local filtered_text=""

    filtered_text="$(evop_filter_agent_command_catalog_lines "$text" "$capability_filter")"
    evop_render_agent_tool_lines_from_filtered_catalog "$filtered_text"
}

evop_render_agent_tool_lines_from_filtered_catalog() {
    local filtered_text="$1"
    local kind=""
    local capability=""
    local command=""
    local source=""
    local output=""

    while IFS=$'\t' read -r kind capability command source; do
        [[ -n "$command" && -n "$source" ]] || continue
        output+="$command [$source]"$'\n'
    done <<<"$filtered_text"

    printf '%s' "$output"
}

evop_render_agent_support_tool_catalog_json() {
    local text="$1"
    local output="["
    local name=""
    local path=""
    local source=""
    local capability=""
    local usage=""
    local needs_comma=0

    while IFS=$'\t' read -r name path source capability usage; do
        [[ -n "$name" && -n "$path" && -n "$source" && -n "$capability" && -n "$usage" ]] || continue
        if (( needs_comma == 1 )); then
            output+=", "
        fi
        output+="{\"name\": $(evop_render_json_string "$name"), \"path\": "
        output+="$(evop_render_json_string "$path")"
        output+=", \"source\": $(evop_render_json_string "$source")"
        output+=", \"capability\": $(evop_render_json_string "$capability")"
        output+=", \"usage\": $(evop_render_json_string "$usage")}"
        needs_comma=1
    done <<<"$text"

    output+="]"
    printf '%s' "$output"
}

evop_render_agent_catalog_bundle_json() {
    local output_kind="${1:-all}"
    local capability_filter="${2:-all}"
    local filtered_command_catalog=""

    printf '{\n'
    printf '  "target_dir": %s,\n' "$(evop_render_json_string_or_null "${TARGET_DIR:-}")"
    printf '  "agent": %s,\n' "$(evop_render_json_string_or_null "${AGENT:-}")"
    printf '  "language_profile": {"name": %s, "source": %s},\n' \
        "$(evop_render_json_string_or_null "${LANGUAGE_PROFILE:-}")" \
        "$(evop_render_json_string_or_null "${LANGUAGE_PROFILE_SOURCE:-}")"
    printf '  "package_manager": %s,\n' "$(evop_render_json_string_or_null "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER")"
    printf '  "workspace_mode": %s,\n' "$(evop_render_json_string_or_null "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE")"
    printf '  "workspace_packages": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES")"
    printf '  "kind": %s,\n' "$(evop_render_json_string "$output_kind")"
    printf '  "capability_filter": %s,\n' "$(evop_render_json_string "$capability_filter")"
    if [[ "$output_kind" == "support" ]]; then
        printf '  "agent_command_catalog": [],\n'
        printf '  "agent_tools": [],\n'
    else
        filtered_command_catalog="$(evop_filter_agent_command_catalog_lines "$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG" "$capability_filter")"
        printf '  "agent_command_catalog": %s,\n' "$(evop_render_agent_command_catalog_json_from_filtered "$filtered_command_catalog")"
        printf '  "agent_tools": %s,\n' "$(evop_render_json_array_from_lines "$(evop_render_agent_tool_lines_from_filtered_catalog "$filtered_command_catalog")")"
    fi
    if [[ "$output_kind" == "commands" ]]; then
        printf '  "agent_support_tool_catalog": [],\n'
        printf '  "agent_support_tools": [],\n'
    else
        printf '  "agent_support_tool_catalog": %s,\n' "$(evop_render_agent_support_tool_catalog_json "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG")"
        printf '  "agent_support_tools": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS")"
    fi
    printf '  "timings": %s\n' "$(evop_render_project_context_timings_json)"
    printf '}\n'
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
