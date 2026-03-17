#!/usr/bin/env zsh

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
    evop_decode_env_value "$1"
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
    local metadata_path="$1"
    local dir_path=""
    local line=""
    local key=""
    local encoded_value=""
    local decoded_value=""

    evop_reset_status_entry
    dir_path="${metadata_path%/*}"
    EVOP_STATUS_ENTRY_NAME="${dir_path##*/}"
    EVOP_STATUS_ENTRY_PATH="$dir_path"

    case "${metadata_path##*/}" in
        session.env)
            EVOP_STATUS_ENTRY_KIND="session"
            ;;
        metadata.env)
            EVOP_STATUS_ENTRY_KIND="run"
            ;;
        *)
            return 1
            ;;
    esac

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
    local metadata_path=""

    evop_reset_status_entries

    while IFS= read -r metadata_path; do
        [[ -n "$metadata_path" ]] || continue
        EVOP_STATUS_TOTAL_DISCOVERED=$((EVOP_STATUS_TOTAL_DISCOVERED + 1))

        evop_status_collect_entry "$metadata_path" || continue
        if ! evop_status_entry_matches_filters "$kind_filter" "$status_filter" "$agent_filter"; then
            continue
        fi

        EVOP_STATUS_MATCHED_COUNT=$((EVOP_STATUS_MATCHED_COUNT + 1))
        if [[ "$show_all" != "1" && "$EVOP_STATUS_SHOWN_COUNT" -ge "$limit" ]]; then
            continue
        fi

        evop_status_append_entry "$(evop_status_serialize_current_entry)"
    done < <(
        find "$artifacts_root" -type f \( -name 'session.env' -o -name 'metadata.env' \) 2>/dev/null \
            | LC_ALL=C sort -r
    )
}
