#!/usr/bin/env zsh

# shellcheck disable=SC2034

PROFILE_DEFINITIONS_DIR="$PROFILE_CATALOG_DIR/definitions"
EVOP_PROFILE_CATEGORIES="languages frameworks project-types"
EVOP_SUPPORTED_PROFILES_CACHE_LANGUAGES=""
EVOP_SUPPORTED_PROFILES_CACHE_FRAMEWORKS=""
EVOP_SUPPORTED_PROFILES_CACHE_PROJECT_TYPES=""
EVOP_PROFILE_LOADED_KEY=""

typeset -A EVOP_PROFILE_PROMPT_CACHE=()
typeset -A EVOP_PROFILE_DETECT_FUNCTION_CACHE=()
typeset -A EVOP_PROFILE_APPLY_FUNCTION_CACHE=()

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
    local cache_var_name=""
    local cached_profiles=""
    local discovered_profiles=""
    local profile_dir=""

    evop_validate_profile_category "$category_dir"
    category_path="$PROFILE_DEFINITIONS_DIR/$category_dir"

    case "$category_dir" in
        languages)
            cache_var_name="EVOP_SUPPORTED_PROFILES_CACHE_LANGUAGES"
            ;;
        frameworks)
            cache_var_name="EVOP_SUPPORTED_PROFILES_CACHE_FRAMEWORKS"
            ;;
        project-types)
            cache_var_name="EVOP_SUPPORTED_PROFILES_CACHE_PROJECT_TYPES"
            ;;
    esac

    cached_profiles="${(P)cache_var_name}"
    if [[ -n "$cached_profiles" ]]; then
        printf '%s\n' "$cached_profiles"
        return 0
    fi

    if [[ ! -d "$category_path" ]]; then
        return 0
    fi

    for profile_dir in "$category_path"/*; do
        [[ -d "$profile_dir" && -f "$profile_dir/profile.sh" ]] || continue
        [[ -n "$discovered_profiles" ]] && discovered_profiles+=$'\n'
        discovered_profiles+="${profile_dir##*/}"
    done

    printf -v "$cache_var_name" '%s' "$discovered_profiles"

    if [[ -n "$discovered_profiles" ]]; then
        printf '%s\n' "$discovered_profiles"
    fi
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

    if evop_prompt_contains_any "$prompt" "$@"; then
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
    EVOP_PROFILE_LOADED_KEY=""
    EVOP_PROFILE_DIR=""
    EVOP_PROFILE_SCRIPTS_DIR=""
    EVOP_PROFILE_PROMPT=""
    EVOP_PROFILE_DETECT_SCORE=""
    unset -f evop_profile_detect 2>/dev/null || true
    unset -f evop_profile_apply_project_context 2>/dev/null || true
}

evop_profile_cache_key() {
    local category_dir="$1"
    local profile_name="$2"

    printf '%s:%s' "$category_dir" "$profile_name"
}

evop_cache_loaded_profile_definition() {
    local cache_key="$1"
    local cached_function=""

    EVOP_PROFILE_PROMPT_CACHE[$cache_key]="$EVOP_PROFILE_PROMPT"

    if evop_function_exists evop_profile_detect; then
        cached_function="$(evop_profile_cached_function_name "detect" "$cache_key")"
        unset -f "$cached_function" 2>/dev/null || true
        functions -c evop_profile_detect "$cached_function"
        EVOP_PROFILE_DETECT_FUNCTION_CACHE[$cache_key]="$cached_function"
    else
        EVOP_PROFILE_DETECT_FUNCTION_CACHE[$cache_key]=""
    fi

    if evop_function_exists evop_profile_apply_project_context; then
        cached_function="$(evop_profile_cached_function_name "apply_project_context" "$cache_key")"
        unset -f "$cached_function" 2>/dev/null || true
        functions -c evop_profile_apply_project_context "$cached_function"
        EVOP_PROFILE_APPLY_FUNCTION_CACHE[$cache_key]="$cached_function"
    else
        EVOP_PROFILE_APPLY_FUNCTION_CACHE[$cache_key]=""
    fi
}

evop_restore_cached_profile_definition() {
    local cache_key="$1"
    local profile_dir="$2"
    local cached_function=""

    EVOP_PROFILE_DIR="$profile_dir"
    EVOP_PROFILE_SCRIPTS_DIR="$profile_dir/scripts"
    EVOP_PROFILE_PROMPT="${EVOP_PROFILE_PROMPT_CACHE[$cache_key]}"

    unset -f evop_profile_detect 2>/dev/null || true
    unset -f evop_profile_apply_project_context 2>/dev/null || true

    cached_function="${EVOP_PROFILE_DETECT_FUNCTION_CACHE[$cache_key]}"
    if [[ -n "$cached_function" ]]; then
        functions -c "$cached_function" evop_profile_detect
    fi

    cached_function="${EVOP_PROFILE_APPLY_FUNCTION_CACHE[$cache_key]}"
    if [[ -n "$cached_function" ]]; then
        functions -c "$cached_function" evop_profile_apply_project_context
    fi
}

evop_profile_cached_function_name() {
    local kind="$1"
    local cache_key="$2"
    local sanitized_key="$cache_key"

    sanitized_key="${sanitized_key//[^[:alnum:]_]/_}"
    printf 'evop_cached_profile_%s_%s' "$kind" "$sanitized_key"
}

evop_load_profile_definition() {
    local category_dir="$1"
    local profile_name="$2"
    local definition_path
    local profile_dir
    local cache_key=""

    evop_validate_profile_category "$category_dir"
    cache_key="$(evop_profile_cache_key "$category_dir" "$profile_name")"
    if [[ "$EVOP_PROFILE_LOADED_KEY" == "$cache_key" ]]; then
        return 0
    fi

    evop_reset_profile_definition
    definition_path="$(evop_profile_definition_path "$category_dir" "$profile_name")"
    if [[ ! -f "$definition_path" ]]; then
        evop_fail "Profile definition is missing: $definition_path"
    fi

    profile_dir="${definition_path%/profile.sh}"
    EVOP_PROFILE_DIR="$profile_dir"
    EVOP_PROFILE_SCRIPTS_DIR="$profile_dir/scripts"
    EVOP_PROFILE_PROMPT=""

    if [[ -n ${EVOP_PROFILE_PROMPT_CACHE[$cache_key]+set} ]]; then
        evop_restore_cached_profile_definition "$cache_key" "$profile_dir"
        EVOP_PROFILE_LOADED_KEY="$cache_key"
        return 0
    fi

    # shellcheck source=/dev/null
    source "$definition_path"
    evop_cache_loaded_profile_definition "$cache_key"
    EVOP_PROFILE_LOADED_KEY="$cache_key"
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

    if evop_function_exists evop_profile_apply_project_context; then
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
    local candidate_mode="all"
    local candidate_profiles=""

    EVOP_DETECTED_PROFILE=""
    evop_prepare_text_match_context "$prompt"
    evop_prepare_profile_detection_candidates "$category_dir" "$target_dir" "$prompt"
    candidate_mode="$EVOP_PROFILE_CANDIDATE_MODE"
    candidate_profiles="$EVOP_PROFILE_CANDIDATE_LIST"

    if [[ "$candidate_mode" == "none" ]]; then
        evop_reset_profile_definition
        return 1
    fi

    while IFS= read -r profile_name; do
        [[ -n "$profile_name" ]] || continue
        evop_load_profile_definition "$category_dir" "$profile_name"

        if ! evop_function_exists evop_profile_detect; then
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

        evop_record_profile_detection_candidate "$category_dir" "$profile_name" "$score"

        if (( score > best_score )); then
            best_profile="$profile_name"
            best_score="$score"
        fi
    done < <(
        if [[ "$candidate_mode" == "filtered" ]]; then
            printf '%s\n' "$candidate_profiles"
        else
            evop_supported_profiles_for_category "$category_dir"
        fi
    )

    evop_reset_profile_definition

    if [[ -n "$best_profile" ]]; then
        EVOP_DETECTED_PROFILE="$best_profile"
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
