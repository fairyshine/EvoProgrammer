#!/usr/bin/env zsh

evop_supported_profiles_as_string() {
    local category_dir="$1"
    local output=""
    local profile_name

    while IFS= read -r profile_name; do
        [[ -n "$profile_name" ]] || continue
        if [[ -n "$output" ]]; then
            output+=" "
        fi
        output+="$profile_name"
    done < <(evop_supported_profiles_for_category "$category_dir")

    printf '%s' "$output"
}

evop_profile_is_supported() {
    local category_dir="$1"
    local requested_profile="$2"
    local profile_name

    while IFS= read -r profile_name; do
        [[ -n "$profile_name" ]] || continue
        if [[ "$profile_name" == "$requested_profile" ]]; then
            return 0
        fi
    done < <(evop_supported_profiles_for_category "$category_dir")

    return 1
}

evop_validate_profile_name() {
    local category_dir="$1"
    local profile_name="${2:-}"
    local label="$3"
    local supported_values

    if [[ -z "$profile_name" ]]; then
        return 0
    fi

    if evop_profile_is_supported "$category_dir" "$profile_name"; then
        return 0
    fi

    supported_values="$(evop_supported_profiles_as_string "$category_dir")"
    evop_fail "Unsupported $label: $profile_name. Supported values: $supported_values"
}

evop_validate_language_profile() {
    local language_profile="${1:-}"
    evop_validate_profile_name "languages" "$language_profile" "language profile"
}

evop_validate_framework_profile() {
    local framework_profile="${1:-}"
    evop_validate_profile_name "frameworks" "$framework_profile" "framework profile"
}

evop_validate_project_type() {
    local project_type="${1:-}"
    evop_validate_profile_name "project-types" "$project_type" "project type"
}
