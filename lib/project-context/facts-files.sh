#!/usr/bin/env zsh

evop_project_relative_exists() {
    local target_dir="$1"
    local rel_path="$2"
    local cached_value=""

    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE "$rel_path"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    if [[ -e "$target_dir/$rel_path" ]]; then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE "$rel_path" "1"
        return 0
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE "$rel_path" "0"
    return 1
}

evop_project_file_text_cached() {
    local file_path="$1"
    local file_text=""

    EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT=""

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE "$file_path"; then
        EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
        return 0
    fi

    if [[ -f "$file_path" ]]; then
        file_text="$(<"$file_path")"
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE "$file_path" "$file_text"
    EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT="$file_text"
    printf '%s' "$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
}

evop_project_file_contains_literal_cached() {
    local file_path="$1"
    local needle="$2"
    local cache_key="$file_path|$needle"
    local cached_value=""
    local file_text=""

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE "$cache_key"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    evop_project_file_text_cached "$file_path" >/dev/null
    file_text="$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
    if [[ "$file_text" == *"$needle"* ]]; then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE "$cache_key" "1"
        return 0
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE "$cache_key" "0"
    return 1
}

evop_project_file_contains_regex_cached() {
    local file_path="$1"
    local regex="$2"
    local cache_key="$file_path|$regex"
    local cached_value=""

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    if [[ -f "$file_path" ]] && grep -Eq "$regex" "$file_path"; then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key" "1"
        return 0
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key" "0"
    return 1
}

evop_project_file_text_contains_regex_cached() {
    local file_path="$1"
    local regex="$2"
    local cache_key="$file_path|text:$regex"
    local cached_value=""
    local file_text=""

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    evop_project_file_text_cached "$file_path" >/dev/null
    file_text="$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
    if [[ -n "$file_text" && "$file_text" =~ $regex ]]; then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key" "1"
        return 0
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE "$cache_key" "0"
    return 1
}

evop_project_makefile_targets_cached() {
    local file_path="$1"
    local file_text=""
    local line=""
    local targets=""
    local target_name=""

    EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT=""

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_CACHE "$file_path"; then
        EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT"
        return 0
    fi

    if [[ -f "$file_path" ]]; then
        evop_project_file_text_cached "$file_path" >/dev/null
        file_text="$EVOP_PROJECT_CONTEXT_FILE_TEXT_RESULT"
        while IFS= read -r line; do
            case "$line" in
                [![:space:]#]*:*)
                    target_name="${line%%:*}"
                    ;;
                *)
                    continue
                    ;;
            esac
            [[ "$target_name" =~ ^[[:alnum:]_.-]+$ ]] || continue
            case $'\n'"$targets"$'\n' in
                *$'\n'"$target_name"$'\n'*)
                    ;;
                *)
                    [[ -n "$targets" ]] && targets+=$'\n'
                    targets+="$target_name"
                    ;;
            esac
        done <<<"$file_text"
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_CACHE "$file_path" "$targets"
    EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT="$targets"
    printf '%s' "$EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT"
}

evop_project_workspace_manifest_search_dirs() {
    local target_dir="$1"
    local rel_dir=""

    for rel_dir in apps packages services libs crates modules cmd tools plugins extensions examples projects; do
        if [[ -d "$target_dir/$rel_dir" ]]; then
            printf '%s\n' "$target_dir/$rel_dir"
        fi
    done
}

evop_project_workspace_manifests_cached() {
    local target_dir="$1"
    local cache_key="workspace-manifests"
    local search_dirs=()
    local search_dir=""
    local abs_manifest_path=""
    local rel_manifest_path=""
    local manifest_paths=()
    local sorted_manifests=""

    EVOP_PROJECT_CONTEXT_WORKSPACE_MANIFESTS_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_WORKSPACE_MANIFESTS_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_WORKSPACE_MANIFESTS_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_WORKSPACE_MANIFESTS_RESULT"
        return 0
    fi

    while IFS= read -r search_dir; do
        [[ -n "$search_dir" ]] || continue
        search_dirs+=("$search_dir")
    done < <(evop_project_workspace_manifest_search_dirs "$target_dir")

    if (( ${#search_dirs[@]} == 0 )); then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_WORKSPACE_MANIFESTS_CACHE "$cache_key" ""
        return 0
    fi

    while IFS= read -r abs_manifest_path; do
        [[ -n "$abs_manifest_path" ]] || continue
        rel_manifest_path="${abs_manifest_path#"$target_dir"/}"
        manifest_paths+=("$rel_manifest_path")
    done < <(
        find "${search_dirs[@]}" -maxdepth 3 -type f \
            \( \
                -name 'package.json' -o \
                -name 'pyproject.toml' -o \
                -name 'Cargo.toml' -o \
                -name 'go.mod' -o \
                -name 'pom.xml' -o \
                -name 'build.gradle' -o \
                -name 'build.gradle.kts' -o \
                -name 'mix.exs' -o \
                -name 'project.clj' -o \
                -name 'deps.edn' -o \
                -name 'pubspec.yaml' -o \
                -name 'Package.swift' -o \
                -name '*.csproj' -o \
                -name '*.fsproj' -o \
                -name '*.vbproj' \
            \) -print 2>/dev/null
    )

    if (( ${#manifest_paths[@]} > 0 )); then
        sorted_manifests="$(printf '%s\n' "${manifest_paths[@]}" | LC_ALL=C sort -u)"
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_WORKSPACE_MANIFESTS_CACHE "$cache_key" "$sorted_manifests"
    EVOP_PROJECT_CONTEXT_WORKSPACE_MANIFESTS_RESULT="$sorted_manifests"
    printf '%s' "$EVOP_PROJECT_CONTEXT_WORKSPACE_MANIFESTS_RESULT"
}

evop_project_workspace_package_json_manifests_cached() {
    local target_dir="$1"
    local cache_key="workspace-package-json-manifests"
    local rel_manifest_path=""
    local package_json_manifests=""

    EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_RESULT"
        return 0
    fi

    evop_project_workspace_manifests_cached "$target_dir" >/dev/null
    while IFS= read -r rel_manifest_path; do
        [[ "${rel_manifest_path##*/}" == "package.json" ]] || continue
        [[ -n "$package_json_manifests" ]] && package_json_manifests+=$'\n'
        package_json_manifests+="$rel_manifest_path"
    done <<<"$EVOP_PROJECT_CONTEXT_WORKSPACE_MANIFESTS_RESULT"

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_CACHE "$cache_key" "$package_json_manifests"
    EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_RESULT="$package_json_manifests"
    printf '%s' "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_RESULT"
}

evop_project_workspace_has_package_json_script_cached() {
    local target_dir="$1"
    local script_name="$2"
    local cache_key="workspace-script|$script_name"
    local cached_value=""
    local rel_manifest_path=""

    [[ -n "$script_name" ]] || return 1
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_WORKSPACE_SCRIPT_CACHE "$cache_key"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    evop_project_workspace_package_json_manifests_cached "$target_dir" >/dev/null
    if [[ -z "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_RESULT" ]]; then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_WORKSPACE_SCRIPT_CACHE "$cache_key" "0"
        return 1
    fi

    while IFS= read -r rel_manifest_path; do
        [[ -n "$rel_manifest_path" ]] || continue
        if evop_project_file_text_contains_regex_cached "$target_dir/$rel_manifest_path" "\"$script_name\"[[:space:]]*:"; then
            evop_project_context_cache_store EVOP_PROJECT_CONTEXT_WORKSPACE_SCRIPT_CACHE "$cache_key" "1"
            return 0
        fi
    done <<<"$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_RESULT"

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_WORKSPACE_SCRIPT_CACHE "$cache_key" "0"
    return 1
}
