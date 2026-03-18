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
            case "$entry_basename" in
                *.*)
                    entry_extension="${entry_basename##*.}"
                    if [[ "$entry_extension" != "$entry_basename" ]]; then
                        EVOP_DETECT_FILE_EXTENSIONS+=("$entry_extension")
                        evop_detection_record_file_extension "$entry_extension"
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
    local basename

    evop_ensure_detection_facts "$directory"

    if (( ${#EVOP_DETECT_FILE_BASENAMES[@]} == 0 )); then
        return 1
    fi

    for basename in "${EVOP_DETECT_FILE_BASENAMES[@]}"; do
        if evop_filename_matches_any_pattern "$basename" "$@"; then
            return 0
        fi
    done

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
