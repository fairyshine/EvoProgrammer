#!/usr/bin/env bash

# shellcheck disable=SC2178

EVOP_DETECT_FACTS_DIR=""
EVOP_DETECT_MAX_DEPTH="${EVOP_DETECT_MAX_DEPTH:-4}"
declare -a EVOP_DETECT_FILES_REL=()
declare -a EVOP_DETECT_FILE_BASENAMES=()
declare -a EVOP_DETECT_PATH_BASENAMES=()
EVOP_DETECT_CACHE_RESULT=""

if [[ -n "${ZSH_VERSION:-}" ]]; then
    typeset -A EVOP_DETECT_MATCHING_FILES_CACHE
    typeset -A EVOP_DETECT_DIRECTORY_TEXT_CACHE
else
    EVOP_DETECT_MATCHING_FILES_CACHE=""
    EVOP_DETECT_DIRECTORY_TEXT_CACHE=""
fi

EVOP_DETECT_PRUNE_DIRS=(.git node_modules vendor target build dist __pycache__ .venv .next .tox .mypy_cache .pytest_cache .cargo .gradle .bundle)

evop_reset_detection_facts() {
    EVOP_DETECT_FACTS_DIR=""
    EVOP_DETECT_FILES_REL=()
    EVOP_DETECT_FILE_BASENAMES=()
    EVOP_DETECT_PATH_BASENAMES=()
    EVOP_DETECT_CACHE_RESULT=""

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        EVOP_DETECT_MATCHING_FILES_CACHE=()
        EVOP_DETECT_DIRECTORY_TEXT_CACHE=()
    else
        EVOP_DETECT_MATCHING_FILES_CACHE=""
        EVOP_DETECT_DIRECTORY_TEXT_CACHE=""
    fi
}

evop_collect_detection_facts() {
    local directory="$1"
    local entry_path
    local rel
    local prune_args=()
    local dir_name

    evop_reset_detection_facts
    EVOP_DETECT_FACTS_DIR="$directory"

    for dir_name in "${EVOP_DETECT_PRUNE_DIRS[@]}"; do
        if (( ${#prune_args[@]} > 0 )); then
            prune_args+=(-o)
        fi
        prune_args+=(-name "$dir_name")
    done

    while IFS= read -r -d '' entry_path; do
        rel="${entry_path#"$directory"/}"
        EVOP_DETECT_FILES_REL+=("$rel")
        EVOP_DETECT_FILE_BASENAMES+=("$(basename "$entry_path")")
    done < <(find "$directory" -maxdepth "$EVOP_DETECT_MAX_DEPTH" \( -type d \( "${prune_args[@]}" \) -prune \) -o -type f -print0 2>/dev/null)

    while IFS= read -r -d '' entry_path; do
        if [[ "$entry_path" == "$directory" ]]; then
            continue
        fi
        EVOP_DETECT_PATH_BASENAMES+=("$(basename "$entry_path")")
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

    EVOP_DETECT_CACHE_RESULT=""

    if [[ -z "${ZSH_VERSION:-}" ]]; then
        return 1
    fi

    case "$cache_name" in
        EVOP_DETECT_MATCHING_FILES_CACHE)
            [[ -n ${EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]+set} ]] || return 1
            EVOP_DETECT_CACHE_RESULT="${EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]}"
            ;;
        EVOP_DETECT_DIRECTORY_TEXT_CACHE)
            [[ -n ${EVOP_DETECT_DIRECTORY_TEXT_CACHE[$cache_key]+set} ]] || return 1
            EVOP_DETECT_CACHE_RESULT="${EVOP_DETECT_DIRECTORY_TEXT_CACHE[$cache_key]}"
            ;;
        *)
            return 1
            ;;
    esac
}

evop_detection_cache_store() {
    local cache_name="$1"
    local cache_key="$2"
    local cache_value="$3"

    if [[ -z "${ZSH_VERSION:-}" ]]; then
        return 0
    fi

    case "$cache_name" in
        EVOP_DETECT_MATCHING_FILES_CACHE)
            EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]="$cache_value"
            ;;
        EVOP_DETECT_DIRECTORY_TEXT_CACHE)
            EVOP_DETECT_DIRECTORY_TEXT_CACHE[$cache_key]="$cache_value"
            ;;
    esac
}

evop_filename_matches_any_pattern() {
    local filename="$1"
    shift
    local pattern

    # shellcheck disable=SC2254
    for pattern in "$@"; do
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
    local filename="$2"

    evop_ensure_detection_facts "$directory"

    if (( ${#EVOP_DETECT_FILE_BASENAMES[@]} == 0 )); then
        return 1
    fi

    local basename
    for basename in "${EVOP_DETECT_FILE_BASENAMES[@]}"; do
        if [[ "$basename" == "$filename" ]]; then
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
    local name="$2"

    evop_ensure_detection_facts "$directory"

    if (( ${#EVOP_DETECT_PATH_BASENAMES[@]} == 0 )); then
        return 1
    fi

    local basename
    for basename in "${EVOP_DETECT_PATH_BASENAMES[@]}"; do
        if [[ "$basename" == "$name" ]]; then
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

    cache_key="$(evop_detection_cache_key "$directory" "$@")"
    if evop_detection_cache_lookup EVOP_DETECT_MATCHING_FILES_CACHE "$cache_key"; then
        printf '%s' "$EVOP_DETECT_CACHE_RESULT"
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
    printf '%s' "$matches"
}

evop_lowercase() {
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

evop_directory_contains_text() {
    local directory="$1"
    local text="$2"
    shift 2
    local cache_key=""
    local matching_files=""
    local rel_path=""

    cache_key="$(evop_detection_cache_key "$directory" "$text" "$@")"
    if evop_detection_cache_lookup EVOP_DETECT_DIRECTORY_TEXT_CACHE "$cache_key"; then
        [[ "$EVOP_DETECT_CACHE_RESULT" == "1" ]]
        return $?
    fi

    matching_files="$(evop_directory_matching_files "$directory" "$@")"
    if [[ -z "$matching_files" ]]; then
        evop_detection_cache_store EVOP_DETECT_DIRECTORY_TEXT_CACHE "$cache_key" "0"
        return 1
    fi

    while IFS= read -r rel_path; do
        [[ -n "$rel_path" ]] || continue
        if grep -Fqi -- "$text" "$directory/$rel_path"; then
            evop_detection_cache_store EVOP_DETECT_DIRECTORY_TEXT_CACHE "$cache_key" "1"
            return 0
        fi
    done <<<"$matching_files"

    evop_detection_cache_store EVOP_DETECT_DIRECTORY_TEXT_CACHE "$cache_key" "0"
    return 1
}
