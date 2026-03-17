#!/usr/bin/env bash

EVOP_STATUS_ENTRY_SEPARATOR=$'\034'
EVOP_STATUS_ENTRIES=""
EVOP_STATUS_TOTAL_DISCOVERED=0
EVOP_STATUS_MATCHED_COUNT=0
EVOP_STATUS_SHOWN_COUNT=0

EVOP_STATUS_ENTRY_NAME=""
EVOP_STATUS_ENTRY_KIND=""
EVOP_STATUS_ENTRY_PATH=""
EVOP_STATUS_ENTRY_AGENT=""
EVOP_STATUS_ENTRY_STARTED_AT=""
EVOP_STATUS_ENTRY_DISPLAY_STATUS=""
EVOP_STATUS_ENTRY_LAST_ITERATION=""
EVOP_STATUS_ENTRY_FINAL_STATUS=""

evop_reset_status_entries() {
    EVOP_STATUS_ENTRIES=""
    EVOP_STATUS_TOTAL_DISCOVERED=0
    EVOP_STATUS_MATCHED_COUNT=0
    EVOP_STATUS_SHOWN_COUNT=0
}

evop_reset_status_entry() {
    EVOP_STATUS_ENTRY_NAME=""
    EVOP_STATUS_ENTRY_KIND=""
    EVOP_STATUS_ENTRY_PATH=""
    EVOP_STATUS_ENTRY_AGENT=""
    EVOP_STATUS_ENTRY_STARTED_AT=""
    EVOP_STATUS_ENTRY_DISPLAY_STATUS=""
    EVOP_STATUS_ENTRY_LAST_ITERATION=""
    EVOP_STATUS_ENTRY_FINAL_STATUS=""
}

evop_status_validate_format() {
    case "$1" in
        summary|json|env)
            return 0
            ;;
        *)
            evop_fail "Unsupported status format: $1"
            ;;
    esac
}

evop_status_validate_kind() {
    case "$1" in
        all|run|session)
            return 0
            ;;
        *)
            evop_fail "Unsupported status kind: $1"
            ;;
    esac
}

evop_status_decode_env_value() {
    local encoded_value="$1"
    local decoded_value=""

    eval "decoded_value=$encoded_value"
    printf '%s' "$decoded_value"
}

evop_status_entry_kind_matches() {
    local kind_filter="$1"
    local entry_kind="$2"

    [[ "$kind_filter" == "all" || "$kind_filter" == "$entry_kind" ]]
}

evop_status_entry_matches_filters() {
    local kind_filter="$1"
    local status_filter="$2"
    local agent_filter="$3"

    evop_status_entry_kind_matches "$kind_filter" "$EVOP_STATUS_ENTRY_KIND" || return 1

    if [[ -n "$status_filter" && "$EVOP_STATUS_ENTRY_DISPLAY_STATUS" != "$status_filter" ]]; then
        return 1
    fi

    if [[ -n "$agent_filter" && "$EVOP_STATUS_ENTRY_AGENT" != "$agent_filter" ]]; then
        return 1
    fi

    return 0
}

evop_status_collect_entry() {
    local dir_path="$1"
    local metadata_path=""
    local line=""
    local key=""
    local encoded_value=""
    local decoded_value=""

    evop_reset_status_entry
    EVOP_STATUS_ENTRY_NAME="${dir_path##*/}"
    EVOP_STATUS_ENTRY_PATH="$dir_path"

    if [[ -f "$dir_path/session.env" ]]; then
        metadata_path="$dir_path/session.env"
        EVOP_STATUS_ENTRY_KIND="session"
    elif [[ -f "$dir_path/metadata.env" ]]; then
        metadata_path="$dir_path/metadata.env"
        EVOP_STATUS_ENTRY_KIND="run"
    else
        return 1
    fi

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        key="${line%%=*}"
        encoded_value="${line#*=}"
        decoded_value="$(evop_status_decode_env_value "$encoded_value")"

        case "$key" in
            AGENT)
                EVOP_STATUS_ENTRY_AGENT="$decoded_value"
                ;;
            STARTED_AT)
                EVOP_STATUS_ENTRY_STARTED_AT="$decoded_value"
                ;;
            STATE)
                EVOP_STATUS_ENTRY_DISPLAY_STATUS="$decoded_value"
                ;;
            STATUS)
                if [[ "$EVOP_STATUS_ENTRY_KIND" == "run" ]]; then
                    EVOP_STATUS_ENTRY_DISPLAY_STATUS="$decoded_value"
                fi
                ;;
            LAST_ITERATION)
                EVOP_STATUS_ENTRY_LAST_ITERATION="$decoded_value"
                ;;
            FINAL_STATUS)
                EVOP_STATUS_ENTRY_FINAL_STATUS="$decoded_value"
                ;;
        esac
    done <"$metadata_path"

    return 0
}

evop_status_append_entry() {
    local serialized_entry="$1"

    if [[ -n "$EVOP_STATUS_ENTRIES" ]]; then
        EVOP_STATUS_ENTRIES+=$'\n'
    fi
    EVOP_STATUS_ENTRIES+="$serialized_entry"
    EVOP_STATUS_SHOWN_COUNT=$((EVOP_STATUS_SHOWN_COUNT + 1))
}

evop_status_serialize_current_entry() {
    printf '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s' \
        "$EVOP_STATUS_ENTRY_NAME" \
        "$EVOP_STATUS_ENTRY_SEPARATOR" \
        "$EVOP_STATUS_ENTRY_KIND" \
        "$EVOP_STATUS_ENTRY_SEPARATOR" \
        "$EVOP_STATUS_ENTRY_STARTED_AT" \
        "$EVOP_STATUS_ENTRY_SEPARATOR" \
        "$EVOP_STATUS_ENTRY_AGENT" \
        "$EVOP_STATUS_ENTRY_SEPARATOR" \
        "$EVOP_STATUS_ENTRY_DISPLAY_STATUS" \
        "$EVOP_STATUS_ENTRY_SEPARATOR" \
        "$EVOP_STATUS_ENTRY_LAST_ITERATION" \
        "$EVOP_STATUS_ENTRY_SEPARATOR" \
        "$EVOP_STATUS_ENTRY_FINAL_STATUS" \
        "$EVOP_STATUS_ENTRY_SEPARATOR" \
        "$EVOP_STATUS_ENTRY_PATH"
}

evop_collect_status_entries() {
    local artifacts_root="$1"
    local kind_filter="$2"
    local status_filter="$3"
    local agent_filter="$4"
    local show_all="$5"
    local limit="$6"
    local dir_path=""

    evop_reset_status_entries

    while IFS= read -r dir_path; do
        [[ -n "$dir_path" ]] || continue
        EVOP_STATUS_TOTAL_DISCOVERED=$((EVOP_STATUS_TOTAL_DISCOVERED + 1))

        evop_status_collect_entry "$dir_path" || continue
        if ! evop_status_entry_matches_filters "$kind_filter" "$status_filter" "$agent_filter"; then
            continue
        fi

        EVOP_STATUS_MATCHED_COUNT=$((EVOP_STATUS_MATCHED_COUNT + 1))
        if [[ "$show_all" != "1" && "$EVOP_STATUS_SHOWN_COUNT" -ge "$limit" ]]; then
            continue
        fi

        evop_status_append_entry "$(evop_status_serialize_current_entry)"
    done < <(find "$artifacts_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | LC_ALL=C sort -r)
}

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

    while IFS="$EVOP_STATUS_ENTRY_SEPARATOR" read -r name kind started_at agent display_status last_iteration final_status path; do
        [[ -n "$name" ]] || continue

        if [[ "$kind" == "session" ]]; then
            printf '%s  %s  agent=%s  state=%s  iterations=%s  final_status=%s\n' \
                "$name" "$started_at" "$agent" "$display_status" "$last_iteration" "$final_status"
        else
            printf '%s  %s  agent=%s  status=%s\n' \
                "$name" "$started_at" "$agent" "$display_status"
        fi
    done <<<"$EVOP_STATUS_ENTRIES"

    printf '\n%d of %d matching entries shown.\n' "$EVOP_STATUS_SHOWN_COUNT" "$EVOP_STATUS_MATCHED_COUNT"
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
