#!/usr/bin/env zsh

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

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE "$file_path"; then
        EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
        return 0
    fi

    if [[ -f "$file_path" ]]; then
        file_text="$(<"$file_path")"
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

    evop_project_file_text_cached "$file_path" >/dev/null
    file_text="$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
    if [[ "$file_text" == *"$needle"* ]]; then
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

evop_project_file_text_contains_regex_cached() {
    local file_path="$1"
    local regex="$2"
    local cache_key="$file_path|text:$regex"
    local cached_value=""
    local file_text=""

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    evop_project_file_text_cached "$file_path" >/dev/null
    file_text="$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
    if [[ -n "$file_text" && "$file_text" =~ $regex ]]; then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key" "1"
        return 0
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key" "0"
    return 1
}

evop_project_makefile_targets_cached() {
    local file_path="$1"
    local file_text=""
    local line=""
    local targets=""
    local target_name=""

    EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT=""

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_CACHE "$file_path"; then
        EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT"
        return 0
    fi

    if [[ -f "$file_path" ]]; then
        evop_project_file_text_cached "$file_path" >/dev/null
        file_text="$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
        while IFS= read -r line; do
            case "$line" in
                [![:space:]#]*:*)
                    target_name="${line%%:*}"
                    ;;
                *)
                    continue
                    ;;
            esac
            [[ "$target_name" =~ ^[[:alnum:]_.-]+$ ]] || continue
            case $'\n'"$targets"$'\n' in
                *$'\n'"$target_name"$'\n'*)
                    ;;
                *)
                    [[ -n "$targets" ]] && targets+=$'\n'
                    targets+="$target_name"
                    ;;
            esac
        done <<<"$file_text"
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_CACHE "$file_path" "$targets"
    EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT="$targets"
    printf '%s' "$EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT"
}
