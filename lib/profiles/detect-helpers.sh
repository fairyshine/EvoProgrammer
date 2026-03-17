#!/usr/bin/env bash

# shellcheck disable=SC2178,SC2296

EVOP_DETECT_FACTS_DIR=""
EVOP_DETECT_MAX_DEPTH="${EVOP_DETECT_MAX_DEPTH:-4}"
declare -a EVOP_DETECT_FILES_REL=()
declare -a EVOP_DETECT_FILE_BASENAMES=()
declare -a EVOP_DETECT_PATH_BASENAMES=()
EVOP_DETECT_CACHE_RESULT=""
EVOP_DETECT_BASENAME_SET_ENABLED=0
EVOP_DETECT_MATCHING_FILES_RESULT=""
EVOP_DETECT_FILE_TEXT_RESULT=""

if [[ -n "${ZSH_VERSION:-}" ]]; then
    EVOP_DETECT_CACHE_BACKEND="associative-array"
    EVOP_DETECT_BASENAME_SET_ENABLED=1
    typeset -A EVOP_DETECT_MATCHING_FILES_CACHE
    typeset -A EVOP_DETECT_DIRECTORY_TEXT_CACHE
    typeset -A EVOP_DETECT_FILE_TEXT_CACHE
    typeset -A EVOP_DETECT_FILE_BASENAME_SET
    typeset -A EVOP_DETECT_PATH_BASENAME_SET
elif [[ -n "${BASH_VERSION:-}" && ${BASH_VERSINFO[0]:-0} -ge 4 ]]; then
    EVOP_DETECT_CACHE_BACKEND="associative-array"
    EVOP_DETECT_BASENAME_SET_ENABLED=1
    declare -A EVOP_DETECT_MATCHING_FILES_CACHE=()
    declare -A EVOP_DETECT_DIRECTORY_TEXT_CACHE=()
    declare -A EVOP_DETECT_FILE_TEXT_CACHE=()
    declare -A EVOP_DETECT_FILE_BASENAME_SET=()
    declare -A EVOP_DETECT_PATH_BASENAME_SET=()
else
    EVOP_DETECT_CACHE_BACKEND="line-table"
    EVOP_DETECT_MATCHING_FILES_CACHE=""
    EVOP_DETECT_DIRECTORY_TEXT_CACHE=""
    EVOP_DETECT_FILE_TEXT_CACHE=""
    EVOP_DETECT_FILE_BASENAME_SET=""
    EVOP_DETECT_PATH_BASENAME_SET=""
fi

EVOP_DETECT_PRUNE_DIRS=(.git node_modules vendor target build dist __pycache__ .venv .next .tox .mypy_cache .pytest_cache .cargo .gradle .bundle)

evop_detection_record_file_basename() {
    local basename="$1"

    if (( EVOP_DETECT_BASENAME_SET_ENABLED != 1 )); then
        return 0
    fi

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        EVOP_DETECT_FILE_BASENAME_SET[$basename]=1
    else
        EVOP_DETECT_FILE_BASENAME_SET["$basename"]=1
    fi
}

evop_detection_record_path_basename() {
    local basename="$1"

    if (( EVOP_DETECT_BASENAME_SET_ENABLED != 1 )); then
        return 0
    fi

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        EVOP_DETECT_PATH_BASENAME_SET[$basename]=1
    else
        EVOP_DETECT_PATH_BASENAME_SET["$basename"]=1
    fi
}

evop_detection_file_basename_exists() {
    local basename="$1"

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        [[ -n ${EVOP_DETECT_FILE_BASENAME_SET[$basename]+set} ]]
        return $?
    fi

    [[ -n "${EVOP_DETECT_FILE_BASENAME_SET[$basename]+set}" ]]
}

evop_detection_path_basename_exists() {
    local basename="$1"

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        [[ -n ${EVOP_DETECT_PATH_BASENAME_SET[$basename]+set} ]]
        return $?
    fi

    [[ -n "${EVOP_DETECT_PATH_BASENAME_SET[$basename]+set}" ]]
}

evop_reset_detection_facts() {
    EVOP_DETECT_FACTS_DIR=""
    EVOP_DETECT_FILES_REL=()
    EVOP_DETECT_FILE_BASENAMES=()
    EVOP_DETECT_PATH_BASENAMES=()
    EVOP_DETECT_CACHE_RESULT=""
    EVOP_DETECT_MATCHING_FILES_RESULT=""
    EVOP_DETECT_FILE_TEXT_RESULT=""

    if [[ "$EVOP_DETECT_CACHE_BACKEND" == "associative-array" ]]; then
        EVOP_DETECT_MATCHING_FILES_CACHE=()
        EVOP_DETECT_DIRECTORY_TEXT_CACHE=()
        EVOP_DETECT_FILE_TEXT_CACHE=()
        EVOP_DETECT_FILE_BASENAME_SET=()
        EVOP_DETECT_PATH_BASENAME_SET=()
    else
        EVOP_DETECT_MATCHING_FILES_CACHE=""
        EVOP_DETECT_DIRECTORY_TEXT_CACHE=""
        EVOP_DETECT_FILE_TEXT_CACHE=""
        EVOP_DETECT_FILE_BASENAME_SET=""
        EVOP_DETECT_PATH_BASENAME_SET=""
    fi
}

evop_collect_detection_facts() {
    local directory="$1"
    local entry_path
    local rel
    local prune_args=()
    local dir_name
    local entry_basename=""

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
        fi
    done < <(find "$directory" -maxdepth "$EVOP_DETECT_MAX_DEPTH" \( -type d \( "${prune_args[@]}" \) -prune \) -o \( -type f -o -type d \) -print0 2>/dev/null)
}

evop_ensure_detection_facts() {
    local directory="$1"

    if [[ "$EVOP_DETECT_FACTS_DIR" != "$directory" ]]; then
        evop_collect_detection_facts "$directory"
    fi
}

evop_detection_cache_key() {
    local output=""
    local part=""

    for part in "$@"; do
        [[ -n "$output" ]] && output+=$'\034'
        output+="$part"
    done

    printf '%s' "$output"
}

evop_detection_cache_lookup() {
    local cache_name="$1"
    local cache_key="$2"
    local cache_contents=""
    local current_key=""
    local cached_value=""

    EVOP_DETECT_CACHE_RESULT=""

    if [[ "$EVOP_DETECT_CACHE_BACKEND" == "associative-array" ]]; then
        if [[ -n "${ZSH_VERSION:-}" ]]; then
            case "$cache_name" in
                EVOP_DETECT_MATCHING_FILES_CACHE)
                    [[ -n ${EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]+set} ]] || return 1
                    EVOP_DETECT_CACHE_RESULT="${EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]}"
                    ;;
                EVOP_DETECT_DIRECTORY_TEXT_CACHE)
                    [[ -n ${EVOP_DETECT_DIRECTORY_TEXT_CACHE[$cache_key]+set} ]] || return 1
                    EVOP_DETECT_CACHE_RESULT="${EVOP_DETECT_DIRECTORY_TEXT_CACHE[$cache_key]}"
                    ;;
                EVOP_DETECT_FILE_TEXT_CACHE)
                    [[ -n ${EVOP_DETECT_FILE_TEXT_CACHE[$cache_key]+set} ]] || return 1
                    EVOP_DETECT_CACHE_RESULT="${EVOP_DETECT_FILE_TEXT_CACHE[$cache_key]}"
                    ;;
                *)
                    return 1
                    ;;
            esac
        else
            case "$cache_name" in
                EVOP_DETECT_MATCHING_FILES_CACHE)
                    [[ -n "${EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]+set}" ]] || return 1
                    EVOP_DETECT_CACHE_RESULT="${EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]}"
                    ;;
                EVOP_DETECT_DIRECTORY_TEXT_CACHE)
                    [[ -n "${EVOP_DETECT_DIRECTORY_TEXT_CACHE[$cache_key]+set}" ]] || return 1
                    EVOP_DETECT_CACHE_RESULT="${EVOP_DETECT_DIRECTORY_TEXT_CACHE[$cache_key]}"
                    ;;
                EVOP_DETECT_FILE_TEXT_CACHE)
                    [[ -n "${EVOP_DETECT_FILE_TEXT_CACHE[$cache_key]+set}" ]] || return 1
                    EVOP_DETECT_CACHE_RESULT="${EVOP_DETECT_FILE_TEXT_CACHE[$cache_key]}"
                    ;;
                *)
                    return 1
                    ;;
            esac
        fi

        return 0
    fi

    eval "cache_contents=\${$cache_name-}"
    while IFS=$'\t' read -r current_key cached_value; do
        [[ -n "$current_key" ]] || continue
        if [[ "$current_key" == "$cache_key" ]]; then
            EVOP_DETECT_CACHE_RESULT="$cached_value"
            return 0
        fi
    done <<<"$cache_contents"

    return 1
}

evop_detection_cache_store() {
    local cache_name="$1"
    local cache_key="$2"
    local cache_value="$3"
    local cache_contents=""

    if [[ "$EVOP_DETECT_CACHE_BACKEND" == "associative-array" ]]; then
        if [[ -n "${ZSH_VERSION:-}" ]]; then
            case "$cache_name" in
                EVOP_DETECT_MATCHING_FILES_CACHE)
                    EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]="$cache_value"
                    ;;
                EVOP_DETECT_DIRECTORY_TEXT_CACHE)
                    EVOP_DETECT_DIRECTORY_TEXT_CACHE[$cache_key]="$cache_value"
                    ;;
                EVOP_DETECT_FILE_TEXT_CACHE)
                    EVOP_DETECT_FILE_TEXT_CACHE[$cache_key]="$cache_value"
                    ;;
            esac
        else
            case "$cache_name" in
                EVOP_DETECT_MATCHING_FILES_CACHE)
                    EVOP_DETECT_MATCHING_FILES_CACHE["$cache_key"]="$cache_value"
                    ;;
                EVOP_DETECT_DIRECTORY_TEXT_CACHE)
                    EVOP_DETECT_DIRECTORY_TEXT_CACHE["$cache_key"]="$cache_value"
                    ;;
                EVOP_DETECT_FILE_TEXT_CACHE)
                    EVOP_DETECT_FILE_TEXT_CACHE["$cache_key"]="$cache_value"
                    ;;
            esac
        fi
        return 0
    fi

    eval "cache_contents=\${$cache_name-}"
    if [[ -n "$cache_contents" ]]; then
        printf -v "$cache_name" '%s\n%s\t%s' "$cache_contents" "$cache_key" "$cache_value"
    else
        printf -v "$cache_name" '%s\t%s' "$cache_key" "$cache_value"
    fi
}

evop_filename_matches_any_pattern() {
    local filename="$1"
    shift
    local pattern

    for pattern in "$@"; do
        if [[ -n "${ZSH_VERSION:-}" ]]; then
            # shellcheck disable=SC2053,SC2296
            if [[ "$filename" == ${~pattern} ]]; then
                return 0
            fi
            continue
        fi

        # shellcheck disable=SC2254
        case "$filename" in
            $pattern)
                return 0
                ;;
        esac
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

    if (( EVOP_DETECT_BASENAME_SET_ENABLED == 1 )); then
        for filename in "$@"; do
            if evop_detection_file_basename_exists "$filename"; then
                return 0
            fi
        done
        return 1
    fi

    local basename=""
    for basename in "${EVOP_DETECT_FILE_BASENAMES[@]}"; do
        for filename in "$@"; do
            if [[ "$basename" == "$filename" ]]; then
                return 0
            fi
        done
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

    if (( EVOP_DETECT_BASENAME_SET_ENABLED == 1 )); then
        for name in "$@"; do
            if evop_detection_path_basename_exists "$name"; then
                return 0
            fi
        done
        return 1
    fi

    local basename=""
    for basename in "${EVOP_DETECT_PATH_BASENAMES[@]}"; do
        for name in "$@"; do
            if [[ "$basename" == "$name" ]]; then
                return 0
            fi
        done
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

evop_lowercase() {
    if [[ -n "${BASH_VERSION:-}" ]]; then
        printf '%s' "${1,,}"
        return 0
    fi

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        local lowered_text="${(L)1}"
        printf '%s' "$lowered_text"
        return 0
    fi

    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

evop_text_contains_any() {
    local text
    text="$(evop_lowercase "$1")"
    shift
    local needle

    for needle in "$@"; do
        if [[ "$text" == *"$(evop_lowercase "$needle")"* ]]; then
            return 0
        fi
    done

    return 1
}

evop_detection_file_text() {
    local file_path="$1"
    local file_text=""

    EVOP_DETECT_FILE_TEXT_RESULT=""
    if evop_detection_cache_lookup EVOP_DETECT_FILE_TEXT_CACHE "$file_path"; then
        EVOP_DETECT_FILE_TEXT_RESULT="$EVOP_DETECT_CACHE_RESULT"
        printf '%s' "$EVOP_DETECT_FILE_TEXT_RESULT"
        return 0
    fi

    if [[ -f "$file_path" ]]; then
        file_text="$(<"$file_path")"
        file_text="$(evop_lowercase "$file_text")"
    fi

    evop_detection_cache_store EVOP_DETECT_FILE_TEXT_CACHE "$file_path" "$file_text"
    EVOP_DETECT_FILE_TEXT_RESULT="$file_text"
    printf '%s' "$EVOP_DETECT_FILE_TEXT_RESULT"
}

evop_directory_contains_text() {
    local directory="$1"
    local text="$2"
    shift 2
    local cache_key=""
    local matching_files=""
    local rel_path=""
    local lowered_text=""
    local file_text=""

    cache_key="$(evop_detection_cache_key "$directory" "$text" "$@")"
    if evop_detection_cache_lookup EVOP_DETECT_DIRECTORY_TEXT_CACHE "$cache_key"; then
        [[ "$EVOP_DETECT_CACHE_RESULT" == "1" ]]
        return $?
    fi

    evop_directory_matching_files "$directory" "$@" >/dev/null
    matching_files="$EVOP_DETECT_MATCHING_FILES_RESULT"
    if [[ -z "$matching_files" ]]; then
        evop_detection_cache_store EVOP_DETECT_DIRECTORY_TEXT_CACHE "$cache_key" "0"
        return 1
    fi

    lowered_text="$(evop_lowercase "$text")"
    while IFS= read -r rel_path; do
        [[ -n "$rel_path" ]] || continue
        evop_detection_file_text "$directory/$rel_path" >/dev/null
        file_text="$EVOP_DETECT_FILE_TEXT_RESULT"
        if [[ "$file_text" == *"$lowered_text"* ]]; then
            evop_detection_cache_store EVOP_DETECT_DIRECTORY_TEXT_CACHE "$cache_key" "1"
            return 0
        fi
    done <<<"$matching_files"

    evop_detection_cache_store EVOP_DETECT_DIRECTORY_TEXT_CACHE "$cache_key" "0"
    return 1
}
