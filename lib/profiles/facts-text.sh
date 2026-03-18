#!/usr/bin/env zsh

EVOP_TEXT_MATCH_CONTEXT=""
EVOP_TEXT_MATCH_CONTEXT_LOWERED=""
typeset -A EVOP_TEXT_MATCH_NEEDLE_CACHE=()

evop_lowercase() {
    local lowered_text="${(L)1}"
    printf '%s' "$lowered_text"
}

evop_prepare_text_match_context() {
    local text="${1:-}"

    if [[ "$EVOP_TEXT_MATCH_CONTEXT" == "$text" ]]; then
        return 0
    fi

    EVOP_TEXT_MATCH_CONTEXT="$text"
    EVOP_TEXT_MATCH_CONTEXT_LOWERED="$(evop_lowercase "$text")"
}

evop_lowercase_match_needle() {
    local text="${1:-}"
    local lowered_text=""

    if [[ -n ${EVOP_TEXT_MATCH_NEEDLE_CACHE[$text]+set} ]]; then
        printf '%s' "${EVOP_TEXT_MATCH_NEEDLE_CACHE[$text]}"
        return 0
    fi

    lowered_text="$(evop_lowercase "$text")"
    EVOP_TEXT_MATCH_NEEDLE_CACHE[$text]="$lowered_text"
    printf '%s' "$lowered_text"
}

evop_lowered_text_contains_any() {
    local lowered_text="${1:-}"
    shift
    local needle=""
    local lowered_needle=""

    for needle in "$@"; do
        lowered_needle="$(evop_lowercase_match_needle "$needle")"
        if [[ "$lowered_text" == *"$lowered_needle"* ]]; then
            return 0
        fi
    done

    return 1
}

evop_text_contains_any() {
    local text
    text="$(evop_lowercase "$1")"
    shift

    evop_lowered_text_contains_any "$text" "$@"
}

evop_prompt_contains_any() {
    local prompt="${1:-}"
    shift
    local lowered_prompt=""

    [[ -n "$prompt" ]] || return 1

    if [[ "$prompt" == "$EVOP_TEXT_MATCH_CONTEXT" ]]; then
        lowered_prompt="$EVOP_TEXT_MATCH_CONTEXT_LOWERED"
    else
        lowered_prompt="$(evop_lowercase "$prompt")"
    fi

    evop_lowered_text_contains_any "$lowered_prompt" "$@"
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
