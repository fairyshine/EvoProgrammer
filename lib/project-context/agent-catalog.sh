#!/usr/bin/env zsh

evop_append_agent_command_catalog_entry() {
    local var_name="$1"
    local kind="$2"
    local command="$3"
    local source="$4"
    local current="${(P)var_name:-}"
    local entry=""

    [[ -n "$kind" && -n "$command" && -n "$source" ]] || return 0

    entry="$kind"$'\t'"$command"$'\t'"$source"
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

evop_append_agent_command_surface_line() {
    local var_name="$1"
    local command="$2"
    local source="$3"

    evop_append_unique_multiline_value "$var_name" "$command [$source]"
}

evop_agent_command_capability() {
    local kind="$1"
    local command="$2"
    local source="$3"
    local capability=""
    local token=""

    if [[ "$command" == ./* ]]; then
        token="${command##*/}"
    else
        token="${command##* }"
    fi
    token="${token##*/}"
    token="${token%.sh}"
    token="${token%.py}"
    token="${token%.js}"
    token="${token%.cjs}"
    token="${token%.mjs}"
    token="${token:l}"

    case "$token" in
        inspect)
            capability="inspect"
            ;;
        verify|run_tests|run_extended_tests)
            capability="verify"
            ;;
        run_lint)
            capability="lint"
            ;;
        clean)
            capability="clean"
            ;;
        status)
            capability="status"
            ;;
        profiles)
            capability="profiles"
            ;;
        catalog)
            capability="catalog"
            ;;
        install|bootstrap)
            capability="bootstrap"
            ;;
        release)
            capability="release"
            ;;
        generate|codegen)
            capability="generate"
            ;;
        format|fmt)
            capability="format"
            ;;
        doctor)
            capability="doctor"
            ;;
        sync-context|context-tool)
            capability="context"
            ;;
    esac

    if [[ -z "$capability" ]]; then
        case "$kind" in
            test_harness_script)
                capability="verify"
                ;;
            repo_helper_program|repo_helper_executable)
                case "$command" in
                    *bootstrap*|*setup*)
                        capability="bootstrap"
                        ;;
                    *generate*|*codegen*)
                        capability="generate"
                        ;;
                    *release*)
                        capability="release"
                        ;;
                    *inspect*|*context*)
                        capability="context"
                        ;;
                    *verify*|*test*)
                        capability="verify"
                        ;;
                    *lint*)
                        capability="lint"
                        ;;
                    *clean*)
                        capability="clean"
                        ;;
                    *)
                        capability="automation"
                        ;;
                esac
                ;;
            repo_executable)
                capability="task"
                ;;
            make_target|package_script)
                case "$command" in
                    *inspect*)
                        capability="inspect"
                        ;;
                    *verify*|*test*|*run_tests*)
                        capability="verify"
                        ;;
                    *lint*)
                        capability="lint"
                        ;;
                    *clean*)
                        capability="clean"
                        ;;
                    *status*)
                        capability="status"
                        ;;
                    *profile*)
                        capability="profiles"
                        ;;
                    *catalog*)
                        capability="catalog"
                        ;;
                    *generate*|*codegen*)
                        capability="generate"
                        ;;
                    *format*|*fmt*)
                        capability="format"
                        ;;
                    *doctor*)
                        capability="doctor"
                        ;;
                    *)
                        capability="automation"
                        ;;
                esac
                ;;
            *)
                capability="automation"
                ;;
        esac
    fi

    if [[ -z "$capability" && "$source" == "repo executable" ]]; then
        capability="task"
    fi

    printf '%s' "$capability"
}

evop_agent_command_catalog_matches_capability() {
    local kind="$1"
    local command="$2"
    local source="$3"
    local capability_filter="${4:-all}"
    local capability=""

    [[ -z "$capability_filter" || "$capability_filter" == "all" ]] && return 0

    capability="$(evop_agent_command_capability "$kind" "$command" "$source")"
    [[ "$capability" == "$capability_filter" ]]
}

evop_agent_helper_shell_command() {
    local file_path="$1"
    local rel_path="$2"
    local first_line=""

    if [[ -f "$file_path" ]]; then
        IFS= read -r first_line <"$file_path" || true
    fi

    case "$first_line" in
        '#!/bin/sh'*|'#!/usr/bin/env sh'*)
            printf 'sh ./%s' "$rel_path"
            ;;
        *)
            printf 'zsh ./%s' "$rel_path"
            ;;
    esac
}

evop_agent_invocable_helper_command() {
    local file_path="$1"
    local rel_path="$2"

    case "$rel_path" in
        *.sh)
            evop_agent_helper_shell_command "$file_path" "$rel_path"
            return 0
            ;;
        *.py)
            if evop_command_available_cached python3; then
                printf 'python3 ./%s' "$rel_path"
                return 0
            fi
            ;;
        *.js|*.cjs|*.mjs)
            if evop_command_available_cached node; then
                printf 'node ./%s' "$rel_path"
                return 0
            fi
            ;;
    esac

    return 1
}

evop_collect_helper_surface_paths() {
    local target_dir="$1"
    local helper_dir="$2"
    local helper_paths=()
    local helper_path=""

    [[ -d "$target_dir/$helper_dir" ]] || return 0

    helper_paths=(
        "$target_dir/$helper_dir"/*(N-.)
        "$target_dir/$helper_dir"/*/*(N-.)
    )
    helper_paths=("${(@on)helper_paths}")

    for helper_path in "${helper_paths[@]}"; do
        printf '%s\n' "$helper_path"
    done
}

evop_append_helper_dir_agent_commands() {
    local output_name="$1"
    local target_dir="$2"
    local helper_dir="$3"
    local helper_path=""
    local rel_helper_path=""
    local command=""

    while IFS= read -r helper_path; do
        [[ -n "$helper_path" ]] || continue
        rel_helper_path="${helper_path#"$target_dir"/}"
        if [[ -x "$helper_path" ]]; then
            evop_append_agent_command_catalog_entry "$output_name" "repo_helper_executable" "./$rel_helper_path" "repo helper executable"
            continue
        fi

        if command="$(evop_agent_invocable_helper_command "$helper_path" "$rel_helper_path" 2>/dev/null)"; then
            evop_append_agent_command_catalog_entry "$output_name" "repo_helper_program" "$command" "repo helper program"
        fi
    done < <(evop_collect_helper_surface_paths "$target_dir" "$helper_dir")
}

evop_append_test_harness_agent_commands() {
    local output_name="$1"
    local target_dir="$2"
    local harness_paths=()
    local harness_path=""
    local rel_harness_path=""
    local command=""

    harness_paths=(
        "$target_dir/tests"/run*.sh(N-.)
        "$target_dir/tests"/*/run*.sh(N-.)
    )
    harness_paths=("${(@on)harness_paths}")

    for harness_path in "${harness_paths[@]}"; do
        rel_harness_path="${harness_path#"$target_dir"/}"
        command="$(evop_agent_helper_shell_command "$harness_path" "$rel_harness_path")"
        evop_append_agent_command_catalog_entry "$output_name" "test_harness_script" "$command" "test harness script"
    done
}

evop_project_agent_local_command_catalog_cached() {
    local target_dir="$1"
    local cache_key="agent-local-command-catalog"
    local output=""
    local candidate=""
    local top_level_script=""
    local makefile=""
    local target=""

    EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_RESULT"
        return 0
    fi

    for candidate in "$target_dir"/bin/*(N-.x:t); do
        evop_append_agent_command_catalog_entry output "repo_executable" "./bin/$candidate" "repo executable"
    done

    for candidate in "$target_dir"/*.sh(N-.); do
        top_level_script="${candidate:t}"
        evop_append_agent_command_catalog_entry output "top_level_script" "zsh ./$top_level_script" "top-level script"
    done

    for candidate in scripts tools hack dev; do
        evop_append_helper_dir_agent_commands output "$target_dir" "$candidate"
    done

    evop_append_test_harness_agent_commands output "$target_dir"

    if [[ -f "$target_dir/Makefile" ]]; then
        makefile="$target_dir/Makefile"
    elif [[ -f "$target_dir/makefile" ]]; then
        makefile="$target_dir/makefile"
    fi

    if [[ -n "$makefile" ]]; then
        for target in inspect verify doctor clean status profiles catalog install bootstrap ci release format fmt; do
            if evop_makefile_has_target "$makefile" "$target"; then
                evop_append_agent_command_catalog_entry output "make_target" "make $target" "make target"
            fi
        done
    fi

    EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_RESULT="$output"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_CACHE "$cache_key" "$output"
    printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_RESULT"
}

evop_project_agent_command_catalog_cached() {
    local target_dir="$1"
    local package_manager="${2:-}"
    local cache_key="agent-command-catalog|$package_manager"
    local output=""
    local target=""
    local command=""
    local package_json="$target_dir/package.json"

    EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_RESULT"
        return 0
    fi

    evop_project_agent_local_command_catalog_cached "$target_dir" >/dev/null
    output="$EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_RESULT"

    if [[ -n "$package_manager" && -f "$package_json" ]]; then
        evop_project_package_json_scripts_cached "$package_json" >/dev/null
        for target in inspect verify doctor clean status profiles catalog install bootstrap setup ci release generate codegen format fmt; do
            case $'\n'"$EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT"$'\n' in
                *$'\n'"$target"$'\n'*)
                    command="$(evop_agent_tool_surface_script_command "$package_manager" "$target")"
                    evop_append_agent_command_catalog_entry output "package_script" "$command" "package.json script"
                    ;;
            esac
        done
    fi

    EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_RESULT="$output"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_CACHE "$cache_key" "$output"
    printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_RESULT"
}

evop_project_agent_tool_surfaces_cached() {
    local target_dir="$1"
    local package_manager="${2:-}"
    local cache_key="agent-tool-surfaces|$package_manager"
    local output=""
    local kind=""
    local command=""
    local source=""

    EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_RESULT"
        return 0
    fi

    evop_project_agent_command_catalog_cached "$target_dir" "$package_manager" >/dev/null
    while IFS=$'\t' read -r kind command source; do
        [[ -n "$kind" && -n "$command" && -n "$source" ]] || continue
        evop_append_agent_command_surface_line output "$command" "$source"
    done <<<"$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_RESULT"

    EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_RESULT="$output"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_CACHE "$cache_key" "$output"
    printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_RESULT"
}
