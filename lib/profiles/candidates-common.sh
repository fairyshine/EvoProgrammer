#!/usr/bin/env zsh

# shellcheck disable=SC2034

EVOP_PROFILE_CANDIDATE_MODE="all"
EVOP_PROFILE_CANDIDATE_LIST=""
EVOP_REPO_HAS_NON_SHELL_RUNTIME_MARKERS_CACHE_DIR=""
EVOP_REPO_HAS_NON_SHELL_RUNTIME_MARKERS_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_VALUE=""

evop_reset_profile_candidates() {
    EVOP_PROFILE_CANDIDATE_MODE="all"
    EVOP_PROFILE_CANDIDATE_LIST=""
}

evop_profile_candidates_cache_result_matches() {
    local cached_value="$1"
    [[ "$cached_value" == "1" ]]
}

evop_profile_candidate_append_unique() {
    local var_name="$1"
    local value="$2"
    local current="${(P)var_name}"

    [[ -n "$value" ]] || return 0

    case $'\n'"$current"$'\n' in
        *$'\n'"$value"$'\n'*)
            return 0
            ;;
    esac

    if [[ -n "$current" ]]; then
        printf -v "$var_name" '%s\n%s' "$current" "$value"
    else
        printf -v "$var_name" '%s' "$value"
    fi
}

evop_profile_candidate_add_if_prompt_matches() {
    local var_name="$1"
    local candidate="$2"
    local prompt="${3:-}"
    shift 3

    [[ -n "$prompt" ]] || return 0
    if evop_prompt_contains_any "$prompt" "$@"; then
        evop_profile_candidate_append_unique "$var_name" "$candidate"
    fi
}

evop_repo_has_non_shell_runtime_markers() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_HAS_NON_SHELL_RUNTIME_MARKERS_CACHE_DIR" == "$target_dir" ]]; then
        evop_profile_candidates_cache_result_matches "$EVOP_REPO_HAS_NON_SHELL_RUNTIME_MARKERS_CACHE_VALUE"
        return $?
    fi

    if evop_directory_has_file_named "$target_dir" \
        "package.json" \
        "pyproject.toml" \
        "requirements.txt" \
        "setup.py" \
        "DESCRIPTION" \
        "renv.lock" \
        "NAMESPACE" \
        "Cargo.toml" \
        "go.mod" \
        "Gemfile" \
        "composer.json" \
        "pom.xml" \
        "build.gradle" \
        "build.gradle.kts" \
        "Package.swift" \
        "project.godot" \
        "pubspec.yaml" \
        "AndroidManifest.xml" \
        "Info.plist" \
        "CMakeLists.txt" \
        "main.tf" \
        "terraform.tfvars" \
        "terragrunt.hcl"; then
        EVOP_REPO_HAS_NON_SHELL_RUNTIME_MARKERS_CACHE_DIR="$target_dir"
        EVOP_REPO_HAS_NON_SHELL_RUNTIME_MARKERS_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.sln" "*.csproj" "*.uproject" "*.Rproj" "*.tf" "*.tfvars"; then
        EVOP_REPO_HAS_NON_SHELL_RUNTIME_MARKERS_CACHE_DIR="$target_dir"
        EVOP_REPO_HAS_NON_SHELL_RUNTIME_MARKERS_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_HAS_NON_SHELL_RUNTIME_MARKERS_CACHE_DIR="$target_dir"
    EVOP_REPO_HAS_NON_SHELL_RUNTIME_MARKERS_CACHE_VALUE="0"
    return 1
}

evop_repo_looks_like_shell_cli() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_DIR" == "$target_dir" ]]; then
        evop_profile_candidates_cache_result_matches "$EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_VALUE"
        return $?
    fi

    if evop_repo_has_non_shell_runtime_markers "$target_dir"; then
        EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_VALUE="0"
        return 1
    fi

    if evop_directory_has_path_named "$target_dir" "bin"; then
        EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.sh" \
        && evop_directory_has_path_named "$target_dir" "lib" "tests"; then
        EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_SHELL_CLI_CACHE_VALUE="0"
    return 1
}

evop_prepare_profile_detection_candidates() {
    local category_dir="$1"
    local target_dir="$2"
    local prompt="${3:-}"

    evop_reset_profile_candidates

    case "$category_dir" in
        languages)
            evop_prepare_language_profile_candidates "$target_dir" "$prompt"
            ;;
        frameworks)
            evop_prepare_framework_profile_candidates "$target_dir" "$prompt"
            ;;
        project-types)
            evop_prepare_project_type_candidates "$target_dir" "$prompt"
            ;;
        *)
            EVOP_PROFILE_CANDIDATE_MODE="all"
            ;;
    esac
}
