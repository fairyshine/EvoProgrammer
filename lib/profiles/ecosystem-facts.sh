#!/usr/bin/env zsh

# shellcheck disable=SC2034

EVOP_ECOSYSTEM_MANIFEST_TEXT_RESULT=""
typeset -A EVOP_ECOSYSTEM_MANIFEST_TEXT_CACHE=()

evop_ecosystem_manifest_patterns() {
    local ecosystem="$1"

    case "$ecosystem" in
        node)
            printf '%s\n' "package.json"
            ;;
        python)
            printf '%s\n' "pyproject.toml" "requirements.txt" "requirements-dev.txt" "setup.py"
            ;;
        cargo)
            printf '%s\n' "Cargo.toml"
            ;;
        go)
            printf '%s\n' "go.mod"
            ;;
        composer)
            printf '%s\n' "composer.json"
            ;;
        ruby)
            printf '%s\n' "Gemfile"
            ;;
        elixir)
            printf '%s\n' "mix.exs"
            ;;
        java)
            printf '%s\n' "pom.xml" "build.gradle" "build.gradle.kts"
            ;;
        dart)
            printf '%s\n' "pubspec.yaml"
            ;;
        *)
            return 1
            ;;
    esac
}

evop_ecosystem_manifest_text() {
    local target_dir="$1"
    local ecosystem="$2"
    local cache_key=""
    local patterns=()
    local matching_files=""
    local rel_path=""
    local combined_text=""

    EVOP_ECOSYSTEM_MANIFEST_TEXT_RESULT=""
    cache_key="$(evop_detection_cache_key "$target_dir" "$ecosystem" "manifest-text")"
    if [[ -n ${EVOP_ECOSYSTEM_MANIFEST_TEXT_CACHE[$cache_key]+set} ]]; then
        EVOP_ECOSYSTEM_MANIFEST_TEXT_RESULT="${EVOP_ECOSYSTEM_MANIFEST_TEXT_CACHE[$cache_key]}"
        printf '%s' "$EVOP_ECOSYSTEM_MANIFEST_TEXT_RESULT"
        return 0
    fi

    patterns=("${(@f)$(evop_ecosystem_manifest_patterns "$ecosystem" 2>/dev/null)}")
    if (( ${#patterns[@]} == 0 )); then
        return 1
    fi

    evop_directory_matching_files "$target_dir" "${patterns[@]}" >/dev/null
    matching_files="$EVOP_DETECT_MATCHING_FILES_RESULT"
    if [[ -z "$matching_files" ]]; then
        EVOP_ECOSYSTEM_MANIFEST_TEXT_CACHE[$cache_key]=""
        return 0
    fi

    while IFS= read -r rel_path; do
        [[ -n "$rel_path" ]] || continue
        evop_detection_file_text "$target_dir/$rel_path" >/dev/null
        [[ -n "$combined_text" ]] && combined_text+=$'\n'
        combined_text+="$EVOP_DETECT_FILE_TEXT_RESULT"
    done <<<"$matching_files"

    EVOP_ECOSYSTEM_MANIFEST_TEXT_CACHE[$cache_key]="$combined_text"
    EVOP_ECOSYSTEM_MANIFEST_TEXT_RESULT="$combined_text"
    printf '%s' "$EVOP_ECOSYSTEM_MANIFEST_TEXT_RESULT"
}

evop_ecosystem_manifest_contains_any() {
    local target_dir="$1"
    local ecosystem="$2"
    shift 2
    local manifest_text=""
    local needle=""

    evop_ecosystem_manifest_text "$target_dir" "$ecosystem" >/dev/null
    manifest_text="$EVOP_ECOSYSTEM_MANIFEST_TEXT_RESULT"
    [[ -n "$manifest_text" ]] || return 1

    for needle in "$@"; do
        if [[ "$manifest_text" == *"$(evop_lowercase "$needle")"* ]]; then
            return 0
        fi
    done

    return 1
}

evop_repo_has_node_package() {
    local target_dir="$1"
    shift
    local package_name=""

    for package_name in "$@"; do
        if evop_ecosystem_manifest_contains_any "$target_dir" "node" "\"$package_name\"" "'$package_name'"; then
            return 0
        fi
    done

    return 1
}

evop_repo_has_python_package() {
    local target_dir="$1"
    shift

    evop_ecosystem_manifest_contains_any "$target_dir" "python" "$@"
}

evop_repo_has_cargo_crate() {
    local target_dir="$1"
    shift

    evop_ecosystem_manifest_contains_any "$target_dir" "cargo" "$@"
}

evop_repo_has_go_module() {
    local target_dir="$1"
    shift

    evop_ecosystem_manifest_contains_any "$target_dir" "go" "$@"
}

evop_repo_has_composer_package() {
    local target_dir="$1"
    shift
    local package_name=""

    for package_name in "$@"; do
        if evop_ecosystem_manifest_contains_any "$target_dir" "composer" "\"$package_name\"" "'$package_name'"; then
            return 0
        fi
    done

    return 1
}

evop_repo_has_gem() {
    local target_dir="$1"
    shift

    evop_ecosystem_manifest_contains_any "$target_dir" "ruby" "$@"
}

evop_repo_has_mix_package() {
    local target_dir="$1"
    shift

    evop_ecosystem_manifest_contains_any "$target_dir" "elixir" "$@"
}

evop_repo_has_java_dependency() {
    local target_dir="$1"
    shift

    evop_ecosystem_manifest_contains_any "$target_dir" "java" "$@"
}

evop_repo_has_pubspec_dependency() {
    local target_dir="$1"
    shift

    evop_ecosystem_manifest_contains_any "$target_dir" "dart" "$@"
}
