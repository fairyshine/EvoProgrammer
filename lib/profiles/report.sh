#!/usr/bin/env zsh

evop_profiles_validate_category() {
    case "$1" in
        all|languages|frameworks|project-types)
            return 0
            ;;
        *)
            evop_fail "Unsupported profiles category: $1"
            ;;
    esac
}

evop_profiles_validate_format() {
    case "$1" in
        summary|json|env)
            return 0
            ;;
        *)
            evop_fail "Unsupported profiles format: $1"
            ;;
    esac
}

evop_profiles_category_label() {
    case "$1" in
        languages)
            printf 'Languages'
            ;;
        frameworks)
            printf 'Frameworks'
            ;;
        project-types)
            printf 'Project types'
            ;;
        *)
            return 1
            ;;
    esac
}

evop_profiles_category_env_prefix() {
    case "$1" in
        languages)
            printf 'LANGUAGE'
            ;;
        frameworks)
            printf 'FRAMEWORK'
            ;;
        project-types)
            printf 'PROJECT_TYPE'
            ;;
        *)
            return 1
            ;;
    esac
}

evop_profiles_selected_categories() {
    local selected_category="${1:-all}"

    if [[ "$selected_category" == "all" ]]; then
        printf '%s\n' languages frameworks project-types
        return 0
    fi

    printf '%s\n' "$selected_category"
}

evop_profiles_category_count() {
    local category_dir="$1"
    local count=0
    local profile_name=""

    while IFS= read -r profile_name; do
        [[ -n "$profile_name" ]] || continue
        count=$((count + 1))
    done < <(evop_supported_profiles_for_category "$category_dir")

    printf '%s' "$count"
}

evop_profiles_json_escape() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"

    printf '%s' "$value"
}

evop_profiles_render_json_string() {
    printf '"%s"' "$(evop_profiles_json_escape "$1")"
}

evop_profiles_summary_line() {
    local category_dir="$1"
    local profile_name="$2"
    local line=""

    evop_load_profile_definition "$category_dir" "$profile_name"

    while IFS= read -r line; do
        line="${line#- }"
        [[ -n "$line" ]] || continue
        printf '%s' "$line"
        evop_reset_profile_definition
        return 0
    done <<<"$EVOP_PROFILE_PROMPT"

    evop_reset_profile_definition
    printf 'No summary available.'
}

evop_profiles_print_env_assignment() {
    printf '%s=%q\n' "$1" "$2"
}

evop_print_profiles_summary() {
    local selected_category="$1"
    local category_dir=""
    local category_label=""
    local profile_name=""
    local summary=""
    local path=""
    local count=0

    if [[ "$selected_category" == "all" ]]; then
        evop_print_section "Supported profiles:"
    else
        evop_print_section "Supported profiles ($(evop_profiles_category_label "$selected_category")):"
    fi

    while IFS= read -r category_dir; do
        [[ -n "$category_dir" ]] || continue
        category_label="$(evop_profiles_category_label "$category_dir")"
        count="$(evop_profiles_category_count "$category_dir")"
        evop_print_section "$category_label ($count):"

        while IFS= read -r profile_name; do
            [[ -n "$profile_name" ]] || continue
            summary="$(evop_profiles_summary_line "$category_dir" "$profile_name")"
            path="$(evop_profile_definition_path "$category_dir" "$profile_name")"
            evop_print_list_item "$profile_name: $summary [$path]"
        done < <(evop_supported_profiles_for_category "$category_dir")
    done < <(evop_profiles_selected_categories "$selected_category")
}

evop_render_profiles_json() {
    local selected_category="$1"
    local category_dir=""
    local category_key=""
    local profile_name=""
    local summary=""
    local path=""
    local category_needs_comma=0
    local item_needs_comma=0

    printf '{\n'
    printf '  "category": %s,\n' "$(evop_profiles_render_json_string "$selected_category")"
    printf '  "categories": {'

    while IFS= read -r category_dir; do
        [[ -n "$category_dir" ]] || continue
        if (( category_needs_comma == 1 )); then
            printf ','
        fi
        printf '\n    %s: [' "$(evop_profiles_render_json_string "$category_dir")"
        category_key="$category_dir"
        item_needs_comma=0

        while IFS= read -r profile_name; do
            [[ -n "$profile_name" ]] || continue
            summary="$(evop_profiles_summary_line "$category_key" "$profile_name")"
            path="$(evop_profile_definition_path "$category_key" "$profile_name")"
            if (( item_needs_comma == 1 )); then
                printf ','
            fi
            printf '\n      {"name": %s, "summary": %s, "path": %s}' \
                "$(evop_profiles_render_json_string "$profile_name")" \
                "$(evop_profiles_render_json_string "$summary")" \
                "$(evop_profiles_render_json_string "$path")"
            item_needs_comma=1
        done < <(evop_supported_profiles_for_category "$category_key")

        printf '\n    ]'
        category_needs_comma=1
    done < <(evop_profiles_selected_categories "$selected_category")

    printf '\n  }\n'
    printf '}\n'
}

evop_print_profiles_env() {
    local selected_category="$1"
    local category_dir=""
    local env_prefix=""
    local profile_name=""
    local summary=""
    local path=""
    local index=0

    evop_profiles_print_env_assignment "EVOP_PROFILES_CATEGORY" "$selected_category"

    while IFS= read -r category_dir; do
        [[ -n "$category_dir" ]] || continue
        env_prefix="$(evop_profiles_category_env_prefix "$category_dir")"
        evop_profiles_print_env_assignment "EVOP_PROFILES_${env_prefix}_COUNT" "$(evop_profiles_category_count "$category_dir")"

        index=0
        while IFS= read -r profile_name; do
            [[ -n "$profile_name" ]] || continue
            index=$((index + 1))
            summary="$(evop_profiles_summary_line "$category_dir" "$profile_name")"
            path="$(evop_profile_definition_path "$category_dir" "$profile_name")"
            evop_profiles_print_env_assignment "EVOP_PROFILES_${env_prefix}_${index}_NAME" "$profile_name"
            evop_profiles_print_env_assignment "EVOP_PROFILES_${env_prefix}_${index}_SUMMARY" "$summary"
            evop_profiles_print_env_assignment "EVOP_PROFILES_${env_prefix}_${index}_PATH" "$path"
        done < <(evop_supported_profiles_for_category "$category_dir")
    done < <(evop_profiles_selected_categories "$selected_category")
}

evop_print_profiles_output() {
    local output_format="$1"
    local selected_category="$2"

    case "$output_format" in
        summary)
            evop_print_profiles_summary "$selected_category"
            ;;
        json)
            evop_render_profiles_json "$selected_category"
            ;;
        env)
            evop_print_profiles_env "$selected_category"
            ;;
    esac
}

evop_write_profiles_report() {
    local file_path="$1"
    local output_format="$2"
    local selected_category="$3"

    [[ -n "$file_path" ]] || return 0

    mkdir -p "$(dirname "$file_path")"
    evop_print_profiles_output "$output_format" "$selected_category" >"$file_path"
}
