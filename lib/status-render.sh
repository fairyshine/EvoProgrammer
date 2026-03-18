#!/usr/bin/env zsh

evop_status_json_escape() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"

    printf '%s' "$value"
}

evop_status_render_json_string() {
    printf '"%s"' "$(evop_status_json_escape "$1")"
}

evop_status_render_json_entries() {
    local output="["
    local needs_comma=0
    local name=""
    local kind=""
    local started_at=""
    local agent=""
    local display_status=""
    local last_iteration=""
    local final_status=""
    local path=""

    while IFS="$EVOP_STATUS_ENTRY_SEPARATOR" read -r name kind started_at agent display_status last_iteration final_status path; do
        [[ -n "$name" ]] || continue

        if (( needs_comma == 1 )); then
            output+=", "
        fi

        output+="{\"name\": $(evop_status_render_json_string "$name"), "
        output+="\"kind\": $(evop_status_render_json_string "$kind"), "
        output+="\"started_at\": $(evop_status_render_json_string "$started_at"), "
        output+="\"agent\": $(evop_status_render_json_string "$agent"), "
        output+="\"status\": $(evop_status_render_json_string "$display_status"), "
        output+="\"last_iteration\": $(evop_status_render_json_string "$last_iteration"), "
        output+="\"final_status\": $(evop_status_render_json_string "$final_status"), "
        output+="\"path\": $(evop_status_render_json_string "$path")}"
        needs_comma=1
    done <<<"$EVOP_STATUS_ENTRIES"

    output+="]"
    printf '%s' "$output"
}

evop_print_status_env_assignment() {
    printf '%s=%q\n' "$1" "$2"
}

evop_print_status_summary() {
    local name=""
    local kind=""
    local started_at=""
    local agent=""
    local display_status=""
    local last_iteration=""
    local final_status=""
    local path=""

    if (( EVOP_STATUS_MATCHED_COUNT == 0 )); then
        echo "No runs found."
        return 0
    fi

    evop_print_key_value "Target directory:" "${TARGET_DIR:-}"
    evop_print_key_value "Artifacts root:" "${artifacts_root:-}"
    evop_print_section "Recent entries:"

    while IFS="$EVOP_STATUS_ENTRY_SEPARATOR" read -r name kind started_at agent display_status last_iteration final_status path; do
        [[ -n "$name" ]] || continue

        if [[ "$kind" == "session" ]]; then
            evop_print_list_item "$name  $started_at  agent=$agent  state=$display_status  iterations=$last_iteration  final_status=$final_status"
        else
            evop_print_list_item "$name  $started_at  agent=$agent  status=$display_status"
        fi
    done <<<"$EVOP_STATUS_ENTRIES"

    printf '\n%s %d of %d matching entries shown.\n' "$(evop_print_status_badge "shown")" "$EVOP_STATUS_SHOWN_COUNT" "$EVOP_STATUS_MATCHED_COUNT"
}

evop_print_status_json() {
    printf '{\n'
    printf '  "target_dir": %s,\n' "$(evop_status_render_json_string "${TARGET_DIR:-}")"
    printf '  "artifacts_root": %s,\n' "$(evop_status_render_json_string "${artifacts_root:-}")"
    printf '  "filters": {"kind": %s, "status": %s, "agent": %s},\n' \
        "$(evop_status_render_json_string "${STATUS_KIND:-all}")" \
        "$(evop_status_render_json_string "${STATUS_FILTER:-}")" \
        "$(evop_status_render_json_string "${STATUS_AGENT_FILTER:-}")"
    printf '  "matched_count": %s,\n' "$EVOP_STATUS_MATCHED_COUNT"
    printf '  "shown_count": %s,\n' "$EVOP_STATUS_SHOWN_COUNT"
    printf '  "total_discovered": %s,\n' "$EVOP_STATUS_TOTAL_DISCOVERED"
    printf '  "entries": %s\n' "$(evop_status_render_json_entries)"
    printf '}\n'
}

evop_print_status_env() {
    local index=0
    local name=""
    local kind=""
    local started_at=""
    local agent=""
    local display_status=""
    local last_iteration=""
    local final_status=""
    local path=""

    evop_print_status_env_assignment "EVOP_STATUS_TARGET_DIR" "${TARGET_DIR:-}"
    evop_print_status_env_assignment "EVOP_STATUS_ARTIFACTS_ROOT" "${artifacts_root:-}"
    evop_print_status_env_assignment "EVOP_STATUS_FILTER_KIND" "${STATUS_KIND:-all}"
    evop_print_status_env_assignment "EVOP_STATUS_FILTER_STATUS" "${STATUS_FILTER:-}"
    evop_print_status_env_assignment "EVOP_STATUS_FILTER_AGENT" "${STATUS_AGENT_FILTER:-}"
    evop_print_status_env_assignment "EVOP_STATUS_MATCHED_COUNT" "$EVOP_STATUS_MATCHED_COUNT"
    evop_print_status_env_assignment "EVOP_STATUS_SHOWN_COUNT" "$EVOP_STATUS_SHOWN_COUNT"
    evop_print_status_env_assignment "EVOP_STATUS_TOTAL_DISCOVERED" "$EVOP_STATUS_TOTAL_DISCOVERED"

    while IFS="$EVOP_STATUS_ENTRY_SEPARATOR" read -r name kind started_at agent display_status last_iteration final_status path; do
        [[ -n "$name" ]] || continue
        index=$((index + 1))
        evop_print_status_env_assignment "EVOP_STATUS_ENTRY_${index}_NAME" "$name"
        evop_print_status_env_assignment "EVOP_STATUS_ENTRY_${index}_KIND" "$kind"
        evop_print_status_env_assignment "EVOP_STATUS_ENTRY_${index}_STARTED_AT" "$started_at"
        evop_print_status_env_assignment "EVOP_STATUS_ENTRY_${index}_AGENT" "$agent"
        evop_print_status_env_assignment "EVOP_STATUS_ENTRY_${index}_STATUS" "$display_status"
        evop_print_status_env_assignment "EVOP_STATUS_ENTRY_${index}_LAST_ITERATION" "$last_iteration"
        evop_print_status_env_assignment "EVOP_STATUS_ENTRY_${index}_FINAL_STATUS" "$final_status"
        evop_print_status_env_assignment "EVOP_STATUS_ENTRY_${index}_PATH" "$path"
    done <<<"$EVOP_STATUS_ENTRIES"
}

evop_print_status_output() {
    local output_format="$1"

    case "$output_format" in
        summary)
            evop_print_status_summary
            ;;
        json)
            evop_print_status_json
            ;;
        env)
            evop_print_status_env
            ;;
    esac
}

evop_write_status_report() {
    local file_path="$1"
    local output_format="$2"

    [[ -n "$file_path" ]] || return 0

    mkdir -p "$(dirname "$file_path")"
    evop_print_status_output "$output_format" >"$file_path"
}
