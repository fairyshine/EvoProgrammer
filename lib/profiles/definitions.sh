#!/usr/bin/env bash

PROFILE_DEFINITIONS_DIR="$PROFILE_CATALOG_DIR/definitions"
EVOP_PROFILE_CATEGORIES="languages frameworks project-types"

evop_validate_profile_category() {
    local category_dir="$1"

    case "$category_dir" in
        languages|frameworks|project-types)
            ;;
        *)
            evop_fail "Unsupported profile category: $category_dir"
            ;;
    esac
}

evop_supported_profiles_for_category() {
    local category_dir="$1"
    local category_path

    evop_validate_profile_category "$category_dir"
    category_path="$PROFILE_DEFINITIONS_DIR/$category_dir"

    if [[ ! -d "$category_path" ]]; then
        return 0
    fi

    while IFS= read -r profile_dir; do
        basename "$profile_dir"
    done < <(
        find "$category_path" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/profile.sh' ';' -print 2>/dev/null \
            | LC_ALL=C sort
    )
}

evop_profile_match_file_named() {
    local score="$1"
    local target_dir="$2"
    shift 2

    while (($# > 0)); do
        if evop_directory_has_file_named "$target_dir" "$1"; then
            EVOP_PROFILE_DETECT_SCORE="$score"
            return 0
        fi
        shift
    done

    return 1
}

evop_profile_match_file_pattern() {
    local score="$1"
    local target_dir="$2"
    shift 2

    if evop_directory_has_file_pattern "$target_dir" "$@"; then
        EVOP_PROFILE_DETECT_SCORE="$score"
        return 0
    fi

    return 1
}

evop_profile_match_path_named() {
    local score="$1"
    local target_dir="$2"
    shift 2

    while (($# > 0)); do
        if evop_directory_has_path_named "$target_dir" "$1"; then
            EVOP_PROFILE_DETECT_SCORE="$score"
            return 0
        fi
        shift
    done

    return 1
}

evop_profile_match_directory_text() {
    local score="$1"
    local target_dir="$2"
    local needle="$3"
    shift 3

    if evop_directory_contains_text "$target_dir" "$needle" "$@"; then
        EVOP_PROFILE_DETECT_SCORE="$score"
        return 0
    fi

    return 1
}

evop_profile_match_prompt() {
    local score="$1"
    local prompt="${2:-}"
    shift 2

    if evop_text_contains_any "$prompt" "$@"; then
        EVOP_PROFILE_DETECT_SCORE="$score"
        return 0
    fi

    return 1
}

evop_profile_definition_path() {
    local category_dir="$1"
    local profile_name="$2"

    evop_validate_profile_category "$category_dir"
    printf '%s/%s/%s/profile.sh' "$PROFILE_DEFINITIONS_DIR" "$category_dir" "$profile_name"
}

evop_reset_profile_definition() {
    EVOP_PROFILE_DIR=""
    EVOP_PROFILE_SCRIPTS_DIR=""
    EVOP_PROFILE_PROMPT=""
    EVOP_PROFILE_DETECT_SCORE=""
    unset -f evop_profile_detect 2>/dev/null || true
    unset -f evop_profile_apply_project_context 2>/dev/null || true
}

evop_load_profile_definition() {
    local category_dir="$1"
    local profile_name="$2"
    local path
    local profile_dir

    evop_reset_profile_definition
    path="$(evop_profile_definition_path "$category_dir" "$profile_name")"
    if [[ ! -f "$path" ]]; then
        evop_fail "Profile definition is missing: $path"
    fi

    profile_dir="$(cd "$(dirname "$path")" && pwd)"
    EVOP_PROFILE_DIR="$profile_dir"
    EVOP_PROFILE_SCRIPTS_DIR="$profile_dir/scripts"
    EVOP_PROFILE_PROMPT=""

    # shellcheck source=/dev/null
    source "$path"
}

evop_print_profile_prompt() {
    local category_dir="$1"
    local profile_name="$2"

    evop_load_profile_definition "$category_dir" "$profile_name"

    if [[ -z "$EVOP_PROFILE_PROMPT" ]]; then
        evop_fail "Profile prompt is empty: $(evop_profile_definition_path "$category_dir" "$profile_name")"
    fi

    printf '%s' "$EVOP_PROFILE_PROMPT"
}

evop_apply_profile_project_context_hooks() {
    local category_dir="$1"
    local profile_name="${2:-}"
    local target_dir="$3"
    local prompt="${4:-}"

    [[ -n "$profile_name" ]] || return 0

    evop_load_profile_definition "$category_dir" "$profile_name"

    if declare -F evop_profile_apply_project_context >/dev/null 2>&1; then
        evop_profile_apply_project_context "$target_dir" "$prompt"
    fi

    evop_reset_profile_definition
}

evop_detect_profile_via_hooks() {
    local category_dir="$1"
    local target_dir="$2"
    local prompt="${3:-}"
    local profile_name
    local score
    local best_profile=""
    local best_score=-1

    while IFS= read -r profile_name; do
        [[ -n "$profile_name" ]] || continue
        evop_load_profile_definition "$category_dir" "$profile_name"

        if ! declare -F evop_profile_detect >/dev/null 2>&1; then
            continue
        fi

        EVOP_PROFILE_DETECT_SCORE=""
        if ! evop_profile_detect "$target_dir" "$prompt"; then
            continue
        fi

        score="${EVOP_PROFILE_DETECT_SCORE:-100}"
        if [[ ! "$score" =~ ^[0-9]+$ ]]; then
            evop_fail "Profile detect score must be a non-negative integer: $(evop_profile_definition_path "$category_dir" "$profile_name")"
        fi

        if (( score > best_score )); then
            best_profile="$profile_name"
            best_score="$score"
        fi
    done < <(evop_supported_profiles_for_category "$category_dir")

    evop_reset_profile_definition

    if [[ -n "$best_profile" ]]; then
        printf '%s' "$best_profile"
        return 0
    fi

    return 1
}

evop_language_guidance() {
    local language_profile="$1"
    evop_print_profile_prompt "languages" "$language_profile"
}

evop_framework_guidance() {
    local framework_profile="$1"
    evop_print_profile_prompt "frameworks" "$framework_profile"
}

evop_project_type_guidance() {
    local project_type="$1"
    evop_print_profile_prompt "project-types" "$project_type"
}
