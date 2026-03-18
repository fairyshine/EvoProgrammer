#!/usr/bin/env zsh

evop_detection_record_file_basename() {
    local basename="$1"

    EVOP_DETECT_FILE_BASENAME_SET[$basename]=1
}

evop_detection_record_file_extension() {
    local extension="$1"

    [[ -n "$extension" ]] || return 0
    EVOP_DETECT_FILE_EXTENSION_SET[$extension]=1
}

evop_detection_record_path_basename() {
    local basename="$1"

    EVOP_DETECT_PATH_BASENAME_SET[$basename]=1
}

evop_detection_index_rel_path() {
    local index_name="$1"
    local key="$2"
    local rel_path="$3"
    local current=""

    [[ -n "$key" ]] || return 0

    case "$index_name" in
        EVOP_DETECT_FILE_PATHS_BY_BASENAME)
            current="${EVOP_DETECT_FILE_PATHS_BY_BASENAME[$key]-}"
            if [[ -n "$current" ]]; then
                EVOP_DETECT_FILE_PATHS_BY_BASENAME[$key]+=$'\n'"$rel_path"
            else
                EVOP_DETECT_FILE_PATHS_BY_BASENAME[$key]="$rel_path"
            fi
            ;;
        EVOP_DETECT_FILE_PATHS_BY_EXTENSION)
            current="${EVOP_DETECT_FILE_PATHS_BY_EXTENSION[$key]-}"
            if [[ -n "$current" ]]; then
                EVOP_DETECT_FILE_PATHS_BY_EXTENSION[$key]+=$'\n'"$rel_path"
            else
                EVOP_DETECT_FILE_PATHS_BY_EXTENSION[$key]="$rel_path"
            fi
            ;;
    esac
}

evop_detection_file_basename_exists() {
    local basename="$1"
    [[ -n ${EVOP_DETECT_FILE_BASENAME_SET[$basename]+set} ]]
}

evop_detection_file_extension_exists() {
    local extension="$1"
    [[ -n ${EVOP_DETECT_FILE_EXTENSION_SET[$extension]+set} ]]
}

evop_detection_path_basename_exists() {
    local basename="$1"
    [[ -n ${EVOP_DETECT_PATH_BASENAME_SET[$basename]+set} ]]
}

evop_detection_rel_paths_for_basename() {
    local basename="$1"

    printf '%s' "${EVOP_DETECT_FILE_PATHS_BY_BASENAME[$basename]-}"
}

evop_detection_rel_paths_for_extension() {
    local extension="$1"

    printf '%s' "${EVOP_DETECT_FILE_PATHS_BY_EXTENSION[$extension]-}"
}

evop_detection_pattern_is_exact_filename() {
    local pattern="$1"

    [[ "$pattern" != *[\*\?\[]* ]]
}

evop_detection_pattern_simple_extension() {
    local pattern="$1"
    local extension=""

    [[ "$pattern" == \*.* ]] || return 1
    extension="${pattern#*.}"
    [[ -n "$extension" ]] || return 1
    [[ "$extension" != *.* ]] || return 1
    [[ "$extension" != *[\*\?\[]* ]]
}

evop_detection_append_unique_match_lines() {
    local matches_var_name="$1"
    local rel_paths="$2"
    local rel_path=""
    local current_matches=""

    [[ -n "$rel_paths" ]] || return 0

    while IFS= read -r rel_path; do
        [[ -n "$rel_path" ]] || continue
        current_matches="${(P)matches_var_name}"
        case $'\n'"$current_matches"$'\n' in
            *$'\n'"$rel_path"$'\n'*)
                continue
                ;;
        esac
        if [[ -n "$current_matches" ]]; then
            printf -v "$matches_var_name" '%s\n%s' "$current_matches" "$rel_path"
        else
            printf -v "$matches_var_name" '%s' "$rel_path"
        fi
    done <<<"$rel_paths"
}

evop_collect_detection_facts() {
    local directory="$1"
    local entry_path
    local rel
    local prune_args=()
    local dir_name
    local entry_basename=""
    local entry_extension=""

    evop_reset_detection_facts
    EVOP_DETECT_FACTS_DIR="$directory"

    for dir_name in "${EVOP_DETECT_PRUNE_DIRS[@]}"; do
        if (( ${#prune_args[@]} > 0 )); then
            prune_args+=(-o)
        fi
        prune_args+=(-name "$dir_name")
    done

    while IFS= read -r -d '' entry_path; do
        if [[ "$entry_path" == "$directory" ]]; then
            continue
        fi
        rel="${entry_path#"$directory"/}"
        entry_basename="${entry_path##*/}"
        EVOP_DETECT_PATH_BASENAMES+=("$entry_basename")
        evop_detection_record_path_basename "$entry_basename"
        if [[ -f "$entry_path" ]]; then
            EVOP_DETECT_FILES_REL+=("$rel")
            EVOP_DETECT_FILE_BASENAMES+=("$entry_basename")
            evop_detection_record_file_basename "$entry_basename"
            evop_detection_index_rel_path EVOP_DETECT_FILE_PATHS_BY_BASENAME "$entry_basename" "$rel"
            case "$entry_basename" in
                *.*)
                    entry_extension="${entry_basename##*.}"
                    if [[ "$entry_extension" != "$entry_basename" ]]; then
                        EVOP_DETECT_FILE_EXTENSIONS+=("$entry_extension")
                        evop_detection_record_file_extension "$entry_extension"
                        evop_detection_index_rel_path EVOP_DETECT_FILE_PATHS_BY_EXTENSION "$entry_extension" "$rel"
                    fi
                    ;;
            esac
        fi
    done < <(find "$directory" -maxdepth "$EVOP_DETECT_MAX_DEPTH" \( -type d \( "${prune_args[@]}" \) -prune \) -o \( -type f -o -type d \) -print0 2>/dev/null)
}

evop_ensure_detection_facts() {
    local directory="$1"

    if [[ "$EVOP_DETECT_FACTS_DIR" != "$directory" ]]; then
        evop_collect_detection_facts "$directory"
    fi
}

evop_filename_matches_any_pattern() {
    local filename="$1"
    shift
    local pattern

    for pattern in "$@"; do
        if [[ "$filename" == ${~pattern} ]]; then
            return 0
        fi
    done

    return 1
}

evop_directory_has_file_named() {
    local directory="$1"
    shift
    local filename=""

    evop_ensure_detection_facts "$directory"

    if (( ${#EVOP_DETECT_FILE_BASENAMES[@]} == 0 )); then
        return 1
    fi

    for filename in "$@"; do
        if evop_detection_file_basename_exists "$filename"; then
            return 0
        fi
    done

    return 1
}

evop_directory_has_file_pattern() {
    local directory="$1"
    shift
    local cache_key=""
    local cached_value=""
    local basename
    local pattern=""
    local saw_complex_pattern=0
    local extension=""

    evop_ensure_detection_facts "$directory"
    cache_key="$(evop_detection_cache_key "$directory" "$@")"

    if evop_detection_cache_lookup EVOP_DETECT_FILE_PATTERN_CACHE "$cache_key"; then
        cached_value="$EVOP_DETECT_CACHE_RESULT"
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    if (( ${#EVOP_DETECT_FILE_BASENAMES[@]} == 0 )); then
        evop_detection_cache_store EVOP_DETECT_FILE_PATTERN_CACHE "$cache_key" "0"
        return 1
    fi

    for pattern in "$@"; do
        if evop_detection_pattern_is_exact_filename "$pattern"; then
            if evop_detection_file_basename_exists "$pattern"; then
                evop_detection_cache_store EVOP_DETECT_FILE_PATTERN_CACHE "$cache_key" "1"
                return 0
            fi
            continue
        fi

        if evop_detection_pattern_simple_extension "$pattern"; then
            extension="${pattern#*.}"
            if evop_detection_file_extension_exists "$extension"; then
                evop_detection_cache_store EVOP_DETECT_FILE_PATTERN_CACHE "$cache_key" "1"
                return 0
            fi
            continue
        fi

        saw_complex_pattern=1
    done

    if (( saw_complex_pattern == 0 )); then
        evop_detection_cache_store EVOP_DETECT_FILE_PATTERN_CACHE "$cache_key" "0"
        return 1
    fi

    for basename in "${EVOP_DETECT_FILE_BASENAMES[@]}"; do
        if evop_filename_matches_any_pattern "$basename" "$@"; then
            evop_detection_cache_store EVOP_DETECT_FILE_PATTERN_CACHE "$cache_key" "1"
            return 0
        fi
    done

    evop_detection_cache_store EVOP_DETECT_FILE_PATTERN_CACHE "$cache_key" "0"
    return 1
}

evop_directory_has_path_named() {
    local directory="$1"
    shift
    local name=""

    evop_ensure_detection_facts "$directory"

    if (( ${#EVOP_DETECT_PATH_BASENAMES[@]} == 0 )); then
        return 1
    fi

    for name in "$@"; do
        if evop_detection_path_basename_exists "$name"; then
            return 0
        fi
    done

    return 1
}

evop_directory_has_file_extension() {
    local directory="$1"
    shift
    local extension=""

    evop_ensure_detection_facts "$directory"

    if (( ${#EVOP_DETECT_FILE_EXTENSIONS[@]} == 0 )); then
        return 1
    fi

    for extension in "$@"; do
        if evop_detection_file_extension_exists "$extension"; then
            return 0
        fi
    done

    return 1
}

evop_directory_matching_files() {
    local directory="$1"
    shift
    local cache_key=""
    local rel_path=""
    local filename=""
    local matches=""
    local pattern=""
    local extension=""
    local indexed_matches=""
    local saw_complex_pattern=0

    EVOP_DETECT_MATCHING_FILES_RESULT=""
    cache_key="$(evop_detection_cache_key "$directory" "$@")"
    if evop_detection_cache_lookup EVOP_DETECT_MATCHING_FILES_CACHE "$cache_key"; then
        EVOP_DETECT_MATCHING_FILES_RESULT="$EVOP_DETECT_CACHE_RESULT"
        printf '%s' "$EVOP_DETECT_MATCHING_FILES_RESULT"
        return 0
    fi

    evop_ensure_detection_facts "$directory"

    if (( ${#EVOP_DETECT_FILES_REL[@]} == 0 )); then
        evop_detection_cache_store EVOP_DETECT_MATCHING_FILES_CACHE "$cache_key" ""
        return 0
    fi

    for pattern in "$@"; do
        if evop_detection_pattern_is_exact_filename "$pattern"; then
            indexed_matches="$(evop_detection_rel_paths_for_basename "$pattern")"
            evop_detection_append_unique_match_lines matches "$indexed_matches"
            continue
        fi

        if evop_detection_pattern_simple_extension "$pattern"; then
            extension="${pattern#*.}"
            indexed_matches="$(evop_detection_rel_paths_for_extension "$extension")"
            evop_detection_append_unique_match_lines matches "$indexed_matches"
            continue
        fi

        saw_complex_pattern=1
        break
    done

    if (( saw_complex_pattern == 0 )); then
        evop_detection_cache_store EVOP_DETECT_MATCHING_FILES_CACHE "$cache_key" "$matches"
        EVOP_DETECT_MATCHING_FILES_RESULT="$matches"
        printf '%s' "$EVOP_DETECT_MATCHING_FILES_RESULT"
        return 0
    fi

    for rel_path in "${EVOP_DETECT_FILES_REL[@]}"; do
        filename="${rel_path##*/}"
        if evop_filename_matches_any_pattern "$filename" "$@"; then
            [[ -n "$matches" ]] && matches+=$'\n'
            matches+="$rel_path"
        fi
    done

    evop_detection_cache_store EVOP_DETECT_MATCHING_FILES_CACHE "$cache_key" "$matches"
    EVOP_DETECT_MATCHING_FILES_RESULT="$matches"
    printf '%s' "$EVOP_DETECT_MATCHING_FILES_RESULT"
}
