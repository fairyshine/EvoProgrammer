#!/usr/bin/env zsh

EVOP_PROFILE_DIAGNOSTICS_LANGUAGES=""
EVOP_PROFILE_DIAGNOSTICS_FRAMEWORKS=""
EVOP_PROFILE_DIAGNOSTICS_PROJECT_TYPES=""

evop_reset_profile_diagnostics() {
    EVOP_PROFILE_DIAGNOSTICS_LANGUAGES=""
    EVOP_PROFILE_DIAGNOSTICS_FRAMEWORKS=""
    EVOP_PROFILE_DIAGNOSTICS_PROJECT_TYPES=""
}

evop_profile_diagnostics_var_name() {
    case "$1" in
        languages)
            printf 'EVOP_PROFILE_DIAGNOSTICS_LANGUAGES'
            ;;
        frameworks)
            printf 'EVOP_PROFILE_DIAGNOSTICS_FRAMEWORKS'
            ;;
        project-types)
            printf 'EVOP_PROFILE_DIAGNOSTICS_PROJECT_TYPES'
            ;;
        *)
            return 1
            ;;
    esac
}

evop_profile_diagnostics_json_key() {
    case "$1" in
        languages)
            printf 'languages'
            ;;
        frameworks)
            printf 'frameworks'
            ;;
        project-types)
            printf 'project_types'
            ;;
        *)
            return 1
            ;;
    esac
}

evop_profile_diagnostics_label() {
    case "$1" in
        languages)
            printf 'Language candidates'
            ;;
        frameworks)
            printf 'Framework candidates'
            ;;
        project-types)
            printf 'Project-type candidates'
            ;;
        *)
            return 1
            ;;
    esac
}

evop_record_profile_detection_candidate() {
    local category_dir="$1"
    local profile_name="$2"
    local score="$3"
    local var_name=""
    local current=""

    var_name="$(evop_profile_diagnostics_var_name "$category_dir")" || return 1
    current="${(P)var_name}"

    if [[ -n "$current" ]]; then
        printf -v "$var_name" '%s\n%s\t%s' "$current" "$profile_name" "$score"
    else
        printf -v "$var_name" '%s\t%s' "$profile_name" "$score"
    fi
}

evop_profile_detection_candidates() {
    local category_dir="$1"
    local var_name=""

    var_name="$(evop_profile_diagnostics_var_name "$category_dir")" || return 1
    printf '%s' "${(P)var_name}"
}

evop_profile_detection_candidates_sorted() {
    local category_dir="$1"
    local candidates=""

    candidates="$(evop_profile_detection_candidates "$category_dir")" || return 1
    [[ -n "$candidates" ]] || return 0

    printf '%s\n' "$candidates" | LC_ALL=C sort -t $'\t' -k2,2nr -k1,1
}

evop_profile_detection_has_candidates() {
    local category_dir="$1"
    [[ -n "$(evop_profile_detection_candidates "$category_dir")" ]]
}
