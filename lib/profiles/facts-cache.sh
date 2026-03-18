#!/usr/bin/env zsh

# shellcheck disable=SC2034

EVOP_DETECT_FACTS_DIR=""
EVOP_DETECT_MAX_DEPTH="${EVOP_DETECT_MAX_DEPTH:-4}"
declare -a EVOP_DETECT_FILES_REL=()
declare -a EVOP_DETECT_FILE_BASENAMES=()
declare -a EVOP_DETECT_FILE_EXTENSIONS=()
declare -a EVOP_DETECT_PATH_BASENAMES=()
EVOP_DETECT_CACHE_RESULT=""
EVOP_DETECT_MATCHING_FILES_RESULT=""
EVOP_DETECT_FILE_TEXT_RESULT=""

typeset -A EVOP_DETECT_MATCHING_FILES_CACHE=()
typeset -A EVOP_DETECT_FILE_PATTERN_CACHE=()
typeset -A EVOP_DETECT_DIRECTORY_TEXT_CACHE=()
typeset -A EVOP_DETECT_FILE_TEXT_CACHE=()
typeset -A EVOP_DETECT_FILE_BASENAME_SET=()
typeset -A EVOP_DETECT_FILE_EXTENSION_SET=()
typeset -A EVOP_DETECT_PATH_BASENAME_SET=()

EVOP_DETECT_PRUNE_DIRS=(.git node_modules vendor target build dist __pycache__ .venv .next .tox .mypy_cache .pytest_cache .cargo .gradle .bundle)

evop_reset_detection_facts() {
    EVOP_DETECT_FACTS_DIR=""
    EVOP_DETECT_FILES_REL=()
    EVOP_DETECT_FILE_BASENAMES=()
    EVOP_DETECT_FILE_EXTENSIONS=()
    EVOP_DETECT_PATH_BASENAMES=()
    EVOP_DETECT_CACHE_RESULT=""
    EVOP_DETECT_MATCHING_FILES_RESULT=""
    EVOP_DETECT_FILE_TEXT_RESULT=""
    EVOP_DETECT_MATCHING_FILES_CACHE=()
    EVOP_DETECT_FILE_PATTERN_CACHE=()
    EVOP_DETECT_DIRECTORY_TEXT_CACHE=()
    EVOP_DETECT_FILE_TEXT_CACHE=()
    EVOP_DETECT_FILE_BASENAME_SET=()
    EVOP_DETECT_FILE_EXTENSION_SET=()
    EVOP_DETECT_PATH_BASENAME_SET=()
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

    case "$cache_name" in
        EVOP_DETECT_MATCHING_FILES_CACHE)
            [[ -n ${EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]+set} ]] || return 1
            EVOP_DETECT_CACHE_RESULT="${EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]}"
            ;;
        EVOP_DETECT_FILE_PATTERN_CACHE)
            [[ -n ${EVOP_DETECT_FILE_PATTERN_CACHE[$cache_key]+set} ]] || return 1
            EVOP_DETECT_CACHE_RESULT="${EVOP_DETECT_FILE_PATTERN_CACHE[$cache_key]}"
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

    return 0
}

evop_detection_cache_store() {
    local cache_name="$1"
    local cache_key="$2"
    local cache_value="$3"

    case "$cache_name" in
        EVOP_DETECT_MATCHING_FILES_CACHE)
            EVOP_DETECT_MATCHING_FILES_CACHE[$cache_key]="$cache_value"
            ;;
        EVOP_DETECT_FILE_PATTERN_CACHE)
            EVOP_DETECT_FILE_PATTERN_CACHE[$cache_key]="$cache_value"
            ;;
        EVOP_DETECT_DIRECTORY_TEXT_CACHE)
            EVOP_DETECT_DIRECTORY_TEXT_CACHE[$cache_key]="$cache_value"
            ;;
        EVOP_DETECT_FILE_TEXT_CACHE)
            EVOP_DETECT_FILE_TEXT_CACHE[$cache_key]="$cache_value"
            ;;
    esac
}
