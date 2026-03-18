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

evop_project_package_json_scripts_cached() {
    local file_path="$1"
    local script_names=""

    EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT=""

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_CACHE "$file_path"; then
        EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT"
        return 0
    fi

    if [[ -f "$file_path" ]]; then
        script_names="$(
            awk '
                BEGIN {
                    RS = "\0"
                    ORS = ""
                    depth = 0
                    in_string = 0
                    escape = 0
                    pending_key = 0
                    want_scripts = 0
                    in_scripts = 0
                    scripts_depth = 0
                    token = ""
                    output = ""
                }
                {
                    text = $0
                    for (i = 1; i <= length(text); i++) {
                        ch = substr(text, i, 1)

                        if (in_string) {
                            if (escape) {
                                token = token ch
                                escape = 0
                                continue
                            }

                            if (ch == "\\") {
                                escape = 1
                                continue
                            }

                            if (ch == "\"") {
                                in_string = 0
                                pending_key = 1
                                continue
                            }

                            token = token ch
                            continue
                        }

                        if (pending_key) {
                            if (ch ~ /[[:space:]]/) {
                                continue
                            }

                            if (ch == ":") {
                                if (in_scripts && depth == scripts_depth) {
                                    add_key(token)
                                } else if (!in_scripts && depth == 1 && token == "scripts") {
                                    want_scripts = 1
                                }
                            }

                            pending_key = 0
                            token = ""
                        }

                        if (ch == "\"") {
                            in_string = 1
                            token = ""
                            continue
                        }

                        if (ch == "{") {
                            depth++
                            if (want_scripts && !in_scripts) {
                                in_scripts = 1
                                scripts_depth = depth
                                want_scripts = 0
                            }
                            continue
                        }

                        if (ch == "}") {
                            if (in_scripts && depth == scripts_depth) {
                                in_scripts = 0
                                scripts_depth = 0
                            }
                            if (depth > 0) {
                                depth--
                            }
                            continue
                        }
                    }
                }
                END {
                    print output
                }
                function add_key(key, needle) {
                    if (key == "") {
                        return
                    }

                    needle = "\n" key "\n"
                    if (index("\n" output "\n", needle) != 0) {
                        return
                    }

                    if (output != "") {
                        output = output "\n"
                    }

                    output = output key
                }
            ' "$file_path"
        )"
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_CACHE "$file_path" "$script_names"
    EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT="$script_names"
    printf '%s' "$EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT"
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
        evop_project_package_json_scripts_cached "$target_dir/$rel_manifest_path" >/dev/null
        case $'\n'"$EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT"$'\n' in
            *$'\n'"$script_name"$'\n'*)
                evop_project_context_cache_store EVOP_PROJECT_CONTEXT_WORKSPACE_SCRIPT_CACHE "$cache_key" "1"
                return 0
                ;;
        esac
    done <<<"$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_RESULT"

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_WORKSPACE_SCRIPT_CACHE "$cache_key" "0"
    return 1
}

evop_append_unique_multiline_value() {
    local var_name="$1"
    local line="$2"
    local current="${(P)var_name:-}"

    [[ -n "$line" ]] || return 0

    case $'\n'"$current"$'\n' in
        *$'\n'"$line"$'\n'*)
            return 0
            ;;
    esac

    if [[ -n "$current" ]]; then
        printf -v "$var_name" '%s\n%s' "$current" "$line"
    else
        printf -v "$var_name" '%s' "$line"
    fi
}

evop_agent_tool_surface_script_command() {
    local package_manager="$1"
    local script_name="$2"

    case "$package_manager" in
        pnpm)
            printf 'pnpm %s' "$script_name"
            ;;
        yarn)
            printf 'yarn %s' "$script_name"
            ;;
        bun)
            printf 'bun run %s' "$script_name"
            ;;
        npm|*)
            printf 'npm run %s' "$script_name"
            ;;
    esac
}

evop_command_available_cached() {
    local command_name="$1"

    [[ -n "$command_name" ]] || return 1

    if evop_resolve_command_path_cached "$command_name"; then
        return 0
    fi

    return 1
}

evop_resolve_command_path_cached() {
    local command_name="$1"
    local cached_value=""
    local resolved_path=""

    EVOP_PROJECT_CONTEXT_COMMAND_PATH_RESULT=""
    [[ -n "$command_name" ]] || return 1

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_COMMAND_PATH_CACHE "$command_name"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        if [[ "$cached_value" == "__missing__" ]]; then
            return 1
        fi
        EVOP_PROJECT_CONTEXT_COMMAND_PATH_RESULT="$cached_value"
        return 0
    fi

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_COMMAND_AVAILABILITY_CACHE "$command_name"; then
        cached_value="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        if [[ "$cached_value" == "1" ]] && evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_COMMAND_PATH_CACHE "$command_name"; then
            EVOP_PROJECT_CONTEXT_COMMAND_PATH_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
            [[ -n "$EVOP_PROJECT_CONTEXT_COMMAND_PATH_RESULT" && "$EVOP_PROJECT_CONTEXT_COMMAND_PATH_RESULT" != "__missing__" ]]
            return $?
        fi
        [[ "$cached_value" == "1" ]]
        return $?
    fi

    resolved_path="$(command -v "$command_name" 2>/dev/null || true)"
    if [[ -n "$resolved_path" ]]; then
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_COMMAND_AVAILABILITY_CACHE "$command_name" "1"
        evop_project_context_cache_store EVOP_PROJECT_CONTEXT_COMMAND_PATH_CACHE "$command_name" "$resolved_path"
        EVOP_PROJECT_CONTEXT_COMMAND_PATH_RESULT="$resolved_path"
        return 0
    fi

    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_COMMAND_AVAILABILITY_CACHE "$command_name" "0"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_COMMAND_PATH_CACHE "$command_name" "__missing__"
    return 1
}

evop_append_agent_support_tool_if_available() {
    local var_name="$1"
    local command_name="$2"
    local source_label="$3"

    if evop_command_available_cached "$command_name"; then
        evop_append_unique_multiline_value "$var_name" "$command_name [$source_label]"
    fi
}

evop_append_agent_support_tool_catalog_entry() {
    local var_name="$1"
    local command_name="$2"
    local source_label="$3"
    local capability="$4"
    local usage_hint="$5"
    local current="${(P)var_name:-}"
    local entry=""

    if ! evop_resolve_command_path_cached "$command_name"; then
        return 0
    fi

    entry="$command_name"$'\t'"$EVOP_PROJECT_CONTEXT_COMMAND_PATH_RESULT"$'\t'"$source_label"$'\t'"$capability"$'\t'"$usage_hint"
    case $'\n'"$current"$'\n' in
        *$'\n'"$entry"$'\n'*)
            return 0
            ;;
    esac

    if [[ -n "$current" ]]; then
        printf -v "$var_name" '%s\n%s' "$current" "$entry"
    else
        printf -v "$var_name" '%s' "$entry"
    fi
}

evop_append_agent_support_tool_candidate() {
    local var_name="$1"
    local command_name="$2"
    local source_label="$3"
    local capability="$4"
    local usage_hint="$5"
    local current="${(P)var_name:-}"
    local entry=""

    [[ -n "$command_name" && -n "$source_label" && -n "$capability" && -n "$usage_hint" ]] || return 0

    entry="$command_name"$'\t'"$source_label"$'\t'"$capability"$'\t'"$usage_hint"
    case $'\n'"$current"$'\n' in
        *$'\n'"$entry"$'\n'*)
            return 0
            ;;
    esac

    if [[ -n "$current" ]]; then
        printf -v "$var_name" '%s\n%s' "$current" "$entry"
    else
        printf -v "$var_name" '%s' "$entry"
    fi
}

evop_collect_agent_support_tool_candidates() {
    local target_dir="$1"
    local package_manager="${2:-}"
    local language_profile="${3:-}"
    local output=""

    evop_append_agent_support_tool_candidate output git "host cli" "vcs" "inspect repository state and record commits"
    evop_append_agent_support_tool_candidate output zsh "shell runtime" "shell" "run repo shell entrypoints and zsh automation"
    evop_append_agent_support_tool_candidate output sh "shell runtime" "shell" "run POSIX shell scripts and portable snippets"
    evop_append_agent_support_tool_candidate output find "filesystem cli" "filesystem" "walk the repository tree by path or type"
    evop_append_agent_support_tool_candidate output xargs "pipeline cli" "pipeline" "fan commands out across piped file lists"
    evop_append_agent_support_tool_candidate output sed "text cli" "text" "apply focused line-oriented text transforms"
    evop_append_agent_support_tool_candidate output awk "text cli" "text" "extract or reshape structured text output"

    if evop_command_available_cached rg; then
        evop_append_agent_support_tool_candidate output rg "search cli" "search" "prefer for fast text and file discovery"
    else
        evop_append_agent_support_tool_candidate output grep "search cli" "search" "fallback text search when rg is unavailable"
    fi

    if [[ -f "$target_dir/package.json" ]]; then
        evop_append_agent_support_tool_candidate output jq "json cli" "json" "inspect or rewrite JSON command output"
        evop_append_agent_support_tool_candidate output node "language runtime" "runtime" "run JavaScript helpers and repo-local Node programs"
    fi

    if [[ -f "$target_dir/Makefile" || -f "$target_dir/makefile" ]]; then
        evop_append_agent_support_tool_candidate output make "build tool" "automation" "invoke declared Makefile targets directly"
    fi

    if [[ -f "$target_dir/Dockerfile" || -f "$target_dir/docker-compose.yml" || -f "$target_dir/docker-compose.yaml" || -f "$target_dir/compose.yml" || -f "$target_dir/compose.yaml" ]]; then
        evop_append_agent_support_tool_candidate output docker "container cli" "container" "build images or run declared container workflows"
    fi

    case "$package_manager" in
        pnpm|yarn|npm|bun|poetry|uv|cargo|go|composer|gradle|maven|dotnet|flutter|dart|mix|clojure|leiningen|stack|cabal|julia|luarocks|lua|zig|terraform|swift|bundler|cmake|r|python)
            evop_append_agent_support_tool_candidate output "$package_manager" "package manager" "package-manager" "install dependencies and run repository-managed tasks"
            ;;
    esac

    case "$language_profile" in
        javascript|typescript)
            evop_append_agent_support_tool_candidate output node "language runtime" "runtime" "run JavaScript helpers and repo-local Node programs"
            ;;
        python)
            evop_append_agent_support_tool_candidate output python3 "language runtime" "runtime" "run Python helpers and one-off diagnostics"
            ;;
        ruby)
            evop_append_agent_support_tool_candidate output ruby "language runtime" "runtime" "run Ruby helpers and task scripts"
            ;;
        php)
            evop_append_agent_support_tool_candidate output php "language runtime" "runtime" "run PHP entrypoints and utilities"
            ;;
        go)
            evop_append_agent_support_tool_candidate output go "language runtime" "runtime" "run Go tools or module-aware commands"
            ;;
        rust)
            evop_append_agent_support_tool_candidate output cargo "language runtime" "runtime" "run Cargo-managed tools and Rust automation"
            ;;
        java|kotlin)
            evop_append_agent_support_tool_candidate output java "language runtime" "runtime" "run JVM utilities and generated tooling"
            ;;
        csharp|fsharp|visual-basic)
            evop_append_agent_support_tool_candidate output dotnet "language runtime" "runtime" "run dotnet tools and project entrypoints"
            ;;
        dart)
            evop_append_agent_support_tool_candidate output dart "language runtime" "runtime" "run Dart tooling and scripts"
            ;;
        elixir)
            evop_append_agent_support_tool_candidate output elixir "language runtime" "runtime" "run Elixir scripts and Mix-backed helpers"
            ;;
        swift)
            evop_append_agent_support_tool_candidate output swift "language runtime" "runtime" "run Swift package tools and scripts"
            ;;
        lua)
            evop_append_agent_support_tool_candidate output lua "language runtime" "runtime" "run Lua scripts and helper programs"
            ;;
        terraform)
            evop_append_agent_support_tool_candidate output terraform "language runtime" "runtime" "run Terraform planning and validation commands"
            ;;
    esac

    printf '%s' "$output"
}

evop_project_agent_support_tools_cached() {
    local target_dir="$1"
    local package_manager="${2:-}"
    local language_profile="${3:-}"
    local cache_key="agent-support-tools|$package_manager|$language_profile"
    local output=""
    local tool_name=""
    local source_label=""

    EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_RESULT"
        return 0
    fi

    evop_project_agent_support_tool_catalog_cached "$target_dir" "$package_manager" "$language_profile" >/dev/null
    while IFS=$'\t' read -r tool_name resolved_path source_label capability usage_hint; do
        [[ -n "$tool_name" && -n "$source_label" ]] || continue
        evop_append_unique_multiline_value output "$tool_name [$source_label]"
    done <<<"$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_RESULT"

    EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_RESULT="$output"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_CACHE "$cache_key" "$output"
    printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_RESULT"
}

evop_project_agent_support_tool_catalog_cached() {
    local target_dir="$1"
    local package_manager="${2:-}"
    local language_profile="${3:-}"
    local cache_key="agent-support-tool-catalog|$package_manager|$language_profile"
    local output=""

    EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_RESULT"
        return 0
    fi

    while IFS=$'\t' read -r tool_name source_label capability usage_hint; do
        [[ -n "$tool_name" && -n "$source_label" && -n "$capability" && -n "$usage_hint" ]] || continue
        evop_append_agent_support_tool_catalog_entry output "$tool_name" "$source_label" "$capability" "$usage_hint"
    done <<<"$(evop_collect_agent_support_tool_candidates "$target_dir" "$package_manager" "$language_profile")"

    EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_RESULT="$output"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_CACHE "$cache_key" "$output"
    printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_RESULT"
}
