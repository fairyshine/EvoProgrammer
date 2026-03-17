#!/usr/bin/env bash

EVOP_PROJECT_CONTEXT_FACTS_DIR=""
EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE=""
EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE=""
EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE=""

evop_reset_project_context_facts() {
    EVOP_PROJECT_CONTEXT_FACTS_DIR=""
    EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE=""
    EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE=""
    EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE=""
}

evop_use_project_context_facts_dir() {
    local target_dir="$1"

    if [[ "$EVOP_PROJECT_CONTEXT_FACTS_DIR" != "$target_dir" ]]; then
        EVOP_PROJECT_CONTEXT_FACTS_DIR="$target_dir"
        EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE=""
        EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE=""
        EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE=""
    fi
}

evop_project_context_cache_lookup() {
    local cache_name="$1"
    local cache_key="$2"
    local cache_contents=""
    local current_key=""
    local cached_value=""

    eval "cache_contents=\${$cache_name-}"
    while IFS=$'\t' read -r current_key cached_value; do
        [[ -n "$current_key" ]] || continue
        if [[ "$current_key" == "$cache_key" ]]; then
            printf '%s' "$cached_value"
            return 0
        fi
    done <<<"$cache_contents"

    return 1
}

evop_project_context_cache_store() {
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

evop_project_relative_exists() {
    local target_dir="$1"
    local rel_path="$2"
    local cached_value=""

    evop_use_project_context_facts_dir "$target_dir"

    cached_value="$(evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE "$rel_path" || true)"
    if [[ -n "$cached_value" ]]; then
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

evop_project_file_contains_literal_cached() {
    local file_path="$1"
    local needle="$2"
    local cache_key="$file_path|$needle"
    local cached_value=""

    cached_value="$(evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE "$cache_key" || true)"
    if [[ -n "$cached_value" ]]; then
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    if [[ -f "$file_path" ]] && grep -Fq -- "$needle" "$file_path"; then
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

    cached_value="$(evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key" || true)"
    if [[ -n "$cached_value" ]]; then
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
