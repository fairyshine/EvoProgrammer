#!/usr/bin/env bash

EVOP_DETECT_FACTS_DIR=""
EVOP_DETECT_MAX_DEPTH="${EVOP_DETECT_MAX_DEPTH:-4}"
declare -a EVOP_DETECT_FILES_REL=()
declare -a EVOP_DETECT_FILE_BASENAMES=()
declare -a EVOP_DETECT_PATH_BASENAMES=()

EVOP_DETECT_PRUNE_DIRS=(.git node_modules vendor target build dist __pycache__ .venv .next .tox .mypy_cache .pytest_cache .cargo .gradle .bundle)

evop_reset_detection_facts() {
    EVOP_DETECT_FACTS_DIR=""
    EVOP_DETECT_FILES_REL=()
    EVOP_DETECT_FILE_BASENAMES=()
    EVOP_DETECT_PATH_BASENAMES=()
}

evop_collect_detection_facts() {
    local directory="$1"
    local path
    local rel
    local prune_args=()
    local dir_name

    evop_reset_detection_facts
    EVOP_DETECT_FACTS_DIR="$directory"

    for dir_name in "${EVOP_DETECT_PRUNE_DIRS[@]}"; do
        prune_args+=(-name "$dir_name" -o)
    done
    # remove trailing -o
    unset 'prune_args[${#prune_args[@]}-1]'

    while IFS= read -r -d '' path; do
        rel="${path#"$directory"/}"
        EVOP_DETECT_FILES_REL+=("$rel")
        EVOP_DETECT_FILE_BASENAMES+=("$(basename "$path")")
    done < <(find "$directory" -maxdepth "$EVOP_DETECT_MAX_DEPTH" \( -type d \( "${prune_args[@]}" \) -prune \) -o -type f -print0 2>/dev/null)

    while IFS= read -r -d '' path; do
        if [[ "$path" == "$directory" ]]; then
            continue
        fi
        EVOP_DETECT_PATH_BASENAMES+=("$(basename "$path")")
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
    local rel_path
    local filename

    evop_ensure_detection_facts "$directory"

    if (( ${#EVOP_DETECT_FILES_REL[@]} == 0 )); then
        return 1
    fi

    for rel_path in "${EVOP_DETECT_FILES_REL[@]}"; do
        filename="$(basename "$rel_path")"
        if ! evop_filename_matches_any_pattern "$filename" "$@"; then
            continue
        fi

        if grep -Fqi -- "$text" "$directory/$rel_path"; then
            return 0
        fi
    done

    return 1
}
