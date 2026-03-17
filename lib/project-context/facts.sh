#!/usr/bin/env bash

# shellcheck disable=SC2178

EVOP_PROJECT_CONTEXT_FACTS_DIR=""
EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND="line-table"
EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS=0
EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS=0
EVOP_PROJECT_CONTEXT_FACTS_CACHE_MISSES=0
EVOP_PROJECT_CONTEXT_FACTS_CACHE_RELATIVE_EXISTS_ENTRIES=0
EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_LITERAL_ENTRIES=0
EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_REGEX_ENTRIES=0
EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_TEXT_ENTRIES=0
EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT=""
EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE_ENABLED=0
EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT=""

if [[ -n "${ZSH_VERSION:-}" ]]; then
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND="associative-array"
    EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE_ENABLED=1
    typeset -A EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE
    typeset -A EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE
    typeset -A EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE
    typeset -A EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE
elif [[ -n "${BASH_VERSION:-}" && ${BASH_VERSINFO[0]:-0} -ge 4 ]]; then
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND="associative-array"
    EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE_ENABLED=1
    declare -A EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE=()
    declare -A EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE=()
    declare -A EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE=()
    declare -A EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE=()
else
    EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE=""
    EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE=""
    EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE=""
    EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE=""
fi

evop_reset_project_context_facts() {
    EVOP_PROJECT_CONTEXT_FACTS_DIR=""
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS=0
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS=0
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_MISSES=0
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_RELATIVE_EXISTS_ENTRIES=0
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_LITERAL_ENTRIES=0
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_REGEX_ENTRIES=0
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_TEXT_ENTRIES=0
    EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT=""
    EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT=""

    if [[ "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND" == "associative-array" ]]; then
        EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE=()
        EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE=()
        EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE=()
        EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE=()
    else
        EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE=""
        EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE=""
        EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE=""
        EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE=""
    fi
}

evop_use_project_context_facts_dir() {
    local target_dir="$1"

    if [[ "$EVOP_PROJECT_CONTEXT_FACTS_DIR" != "$target_dir" ]]; then
        evop_reset_project_context_facts
        EVOP_PROJECT_CONTEXT_FACTS_DIR="$target_dir"
    fi
}

evop_project_context_cache_lookup_line_table() {
    local cache_name="$1"
    local cache_key="$2"
    local cache_contents=""
    local current_key=""
    local cached_value=""

    eval "cache_contents=\${$cache_name-}"
    while IFS=$'\t' read -r current_key cached_value; do
        [[ -n "$current_key" ]] || continue
        if [[ "$current_key" == "$cache_key" ]]; then
            EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT="$cached_value"
            return 0
        fi
    done <<<"$cache_contents"

    return 1
}

evop_project_context_cache_store_line_table() {
    local cache_name="$1"
    local cache_key="$2"
    local cached_value="$3"
    local cache_contents=""

    eval "cache_contents=\${$cache_name-}"
    if [[ -n "$cache_contents" ]]; then
        printf -v "$cache_name" '%s\n%s\t%s' "$cache_contents" "$cache_key" "$cached_value"
    else
        printf -v "$cache_name" '%s\t%s' "$cache_key" "$cached_value"
    fi
}

if [[ "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND" == "associative-array" ]]; then
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        evop_project_context_cache_lookup_assoc() {
            local cache_name="$1"
            local cache_key="$2"

            case "$cache_name" in
                EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE)
                    [[ -n ${EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE[$cache_key]+set} ]] || return 1
                    EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT="${EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE[$cache_key]}"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE)
                    [[ -n ${EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE[$cache_key]+set} ]] || return 1
                    EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT="${EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE[$cache_key]}"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE)
                    [[ -n ${EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE[$cache_key]+set} ]] || return 1
                    EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT="${EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE[$cache_key]}"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE)
                    [[ -n ${EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE[$cache_key]+set} ]] || return 1
                    EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT="${EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE[$cache_key]}"
                    ;;
                *)
                    return 1
                    ;;
            esac
        }

        evop_project_context_cache_store_assoc() {
            local cache_name="$1"
            local cache_key="$2"
            local cached_value="$3"

            case "$cache_name" in
                EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE)
                    EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE[$cache_key]="$cached_value"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE)
                    EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE[$cache_key]="$cached_value"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE)
                    EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE[$cache_key]="$cached_value"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE)
                    EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE[$cache_key]="$cached_value"
                    ;;
            esac
        }
    else
        evop_project_context_cache_lookup_assoc() {
            local cache_name="$1"
            local cache_key="$2"

            case "$cache_name" in
                EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE)
                    [[ -n "${EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE[$cache_key]+set}" ]] || return 1
                    EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT="${EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE[$cache_key]}"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE)
                    [[ -n "${EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE[$cache_key]+set}" ]] || return 1
                    EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT="${EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE[$cache_key]}"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE)
                    [[ -n "${EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE[$cache_key]+set}" ]] || return 1
                    EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT="${EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE[$cache_key]}"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE)
                    [[ -n "${EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE[$cache_key]+set}" ]] || return 1
                    EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT="${EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE[$cache_key]}"
                    ;;
                *)
                    return 1
                    ;;
            esac
        }

        evop_project_context_cache_store_assoc() {
            local cache_name="$1"
            local cache_key="$2"
            local cached_value="$3"

            case "$cache_name" in
                EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE)
                    EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE["$cache_key"]="$cached_value"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE)
                    EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE["$cache_key"]="$cached_value"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE)
                    EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE["$cache_key"]="$cached_value"
                    ;;
                EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE)
                    EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE["$cache_key"]="$cached_value"
                    ;;
            esac
        }
    fi
fi

evop_project_context_cache_entry_count_var_name() {
    case "$1" in
        EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE)
            printf 'EVOP_PROJECT_CONTEXT_FACTS_CACHE_RELATIVE_EXISTS_ENTRIES'
            ;;
        EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE)
            printf 'EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_LITERAL_ENTRIES'
            ;;
        EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE)
            printf 'EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_REGEX_ENTRIES'
            ;;
        EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE)
            printf 'EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_TEXT_ENTRIES'
            ;;
        *)
            return 1
            ;;
    esac
}

evop_project_context_cache_increment_entry_count() {
    local cache_name="$1"
    local count_var_name=""
    local current_count=0

    count_var_name="$(evop_project_context_cache_entry_count_var_name "$cache_name")" || return 1
    eval "current_count=\${$count_var_name:-0}"
    printf -v "$count_var_name" '%s' "$((current_count + 1))"
}

evop_project_context_cache_lookup() {
    local cache_name="$1"
    local cache_key="$2"

    EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT=""
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS=$((EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS + 1))

    if [[ "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND" == "associative-array" ]]; then
        if evop_project_context_cache_lookup_assoc "$cache_name" "$cache_key"; then
            EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS=$((EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS + 1))
            return 0
        fi
    elif evop_project_context_cache_lookup_line_table "$cache_name" "$cache_key"; then
        EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS=$((EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS + 1))
        return 0
    fi

    EVOP_PROJECT_CONTEXT_FACTS_CACHE_MISSES=$((EVOP_PROJECT_CONTEXT_FACTS_CACHE_MISSES + 1))
    return 1
}

evop_project_context_cache_store() {
    local cache_name="$1"
    local cache_key="$2"
    local cached_value="$3"

    if [[ "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND" == "associative-array" ]]; then
        evop_project_context_cache_store_assoc "$cache_name" "$cache_key" "$cached_value"
    else
        evop_project_context_cache_store_line_table "$cache_name" "$cache_key" "$cached_value"
    fi

    evop_project_context_cache_increment_entry_count "$cache_name" || true
}

evop_project_context_cache_entry_count() {
    local cache_name="$1"
    local count_var_name=""

    count_var_name="$(evop_project_context_cache_entry_count_var_name "$cache_name")" || {
        printf '0'
        return 0
    }
    eval "printf '%s' \"\${$count_var_name:-0}\""
}

evop_project_context_cache_hit_rate_percent() {
    if (( EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS == 0 )); then
        printf '0'
        return 0
    fi

    printf '%s' $((EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS * 100 / EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS))
}

evop_print_project_context_facts_diagnostics() {
    printf 'Facts cache backend: %s\n' "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND"
    printf 'Facts cache lookups: %s\n' "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS"
    printf 'Facts cache hits: %s\n' "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS"
    printf 'Facts cache misses: %s\n' "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_MISSES"
    printf 'Facts cache hit rate: %s%%\n' "$(evop_project_context_cache_hit_rate_percent)"
    printf 'Relative-exists cache entries: %s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE)"
    printf 'File-literal cache entries: %s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE)"
    printf 'File-regex cache entries: %s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE)"
    printf 'File-text cache entries: %s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE)"
}

evop_render_project_context_facts_diagnostics_json() {
    printf '{"backend": %s, "lookups": %s, "hits": %s, "misses": %s, "hit_rate_percent": %s, "relative_exists_entries": %s, "file_literal_entries": %s, "file_regex_entries": %s, "file_text_entries": %s}' \
        "\"$EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND\"" \
        "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS" \
        "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS" \
        "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_MISSES" \
        "$(evop_project_context_cache_hit_rate_percent)" \
        "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE)" \
        "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE)" \
        "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE)" \
        "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE)"
}

evop_project_relative_exists() {
    local target_dir="$1"
    local rel_path="$2"
    local cached_value=""

    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE "$rel_path"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    if [[ -e "$target_dir/$rel_path" ]]; then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE "$rel_path" "1"
        return 0
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE "$rel_path" "0"
    return 1
}

evop_project_file_text_cached() {
    local file_path="$1"
    local file_text=""

    EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT=""

    if (( EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE_ENABLED != 1 )); then
        if [[ -f "$file_path" ]]; then
            EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT="$(cat -- "$file_path")"
            printf '%s' "$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
        fi
        return 0
    fi

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE "$file_path"; then
        EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
        return 0
    fi

    if [[ -f "$file_path" ]]; then
        file_text="$(cat -- "$file_path")"
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE "$file_path" "$file_text"
    EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT="$file_text"
    printf '%s' "$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
}

evop_project_file_contains_literal_cached() {
    local file_path="$1"
    local needle="$2"
    local cache_key="$file_path|$needle"
    local cached_value=""
    local file_text=""

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE "$cache_key"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    if (( EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE_ENABLED == 1 )); then
        evop_project_file_text_cached "$file_path" >/dev/null
        file_text="$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
        if [[ "$file_text" == *"$needle"* ]]; then
            evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE "$cache_key" "1"
            return 0
        fi
    elif [[ -f "$file_path" ]] && grep -Fq -- "$needle" "$file_path"; then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE "$cache_key" "1"
        return 0
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE "$cache_key" "0"
    return 1
}

evop_project_file_contains_regex_cached() {
    local file_path="$1"
    local regex="$2"
    local cache_key="$file_path|$regex"
    local cached_value=""

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    if [[ -f "$file_path" ]] && grep -Eq "$regex" "$file_path"; then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key" "1"
        return 0
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key" "0"
    return 1
}
