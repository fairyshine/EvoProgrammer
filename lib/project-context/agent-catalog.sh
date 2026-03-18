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

evop_validate_agent_recommend_task_kind() {
    case "${1:-none}" in
        none|auto|review|bugfix|refactor|performance|feature)
            return 0
            ;;
        *)
            evop_fail "Unsupported recommended task kind: $1"
            ;;
    esac
}

evop_resolve_agent_recommend_task_kind() {
    local requested_kind="${1:-none}"

    if [[ "$requested_kind" == "auto" ]]; then
        printf '%s' "${EVOP_PROJECT_CONTEXT_TASK_KIND:-feature}"
        return 0
    fi

    printf '%s' "$requested_kind"
}

evop_agent_command_runner() {
    local kind="$1"
    local command="$2"

    case "$kind" in
        repo_executable|repo_helper_executable)
            printf 'direct'
            ;;
        top_level_script|test_harness_script)
            printf 'shell-runtime'
            ;;
        repo_helper_program)
            case "${command%% *}" in
                sh|zsh)
                    printf 'shell-runtime'
                    ;;
                *)
                    printf 'language-runtime'
                    ;;
            esac
            ;;
        package_script)
            printf 'package-manager'
            ;;
        make_target)
            printf 'make'
            ;;
        just_target|taskfile_target)
            printf 'task-runner'
            ;;
        *)
            printf 'runtime'
            ;;
    esac
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
            make_target|just_target|taskfile_target|package_script)
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

evop_agent_command_workdir() {
    local kind="$1"
    local command="$2"
    local source="$3"

    : "${kind:?}" "${command:?}" "${source:?}"
    printf 'repo-root'
}

evop_agent_command_priority() {
    local kind="$1"
    local command="$2"
    local source="$3"
    local capability=""

    capability="$(evop_agent_command_capability "$kind" "$command" "$source")"
    case "$capability" in
        inspect|verify|lint|clean|status|profiles|catalog|bootstrap|doctor|context)
            printf 'high'
            ;;
        generate|format|task)
            printf 'normal'
            ;;
        *)
            printf 'low'
            ;;
    esac
}

evop_agent_command_usage() {
    local kind="$1"
    local command="$2"
    local source="$3"
    local capability=""

    capability="$(evop_agent_command_capability "$kind" "$command" "$source")"
    case "$capability" in
        inspect)
            printf 'inspect repository state or generate repo context'
            ;;
        verify|lint)
            printf 'run verification or quality gates through the repo workflow'
            ;;
        bootstrap)
            printf 'prepare the repository environment or setup workflow'
            ;;
        doctor)
            printf 'check local prerequisites and environment wiring'
            ;;
        context)
            printf 'refresh or export repository context for downstream tools'
            ;;
        clean)
            printf 'remove generated artifacts or stale run state'
            ;;
        status)
            printf 'report repository or automation status'
            ;;
        profiles|catalog)
            printf 'list structured repo metadata for wrappers or agents'
            ;;
        generate)
            printf 'run repo generation or codegen workflows'
            ;;
        format)
            printf 'apply repository formatting workflows'
            ;;
        release)
            printf 'invoke release or packaging automation'
            ;;
        task)
            printf 'run a repo-local executable task entrypoint directly'
            ;;
        *)
            case "$kind" in
                package_script)
                    printf 'run a repository-managed package script'
                    ;;
                make_target)
                    printf 'invoke a declared Makefile target'
                    ;;
                just_target)
                    printf 'invoke a declared Justfile recipe'
                    ;;
                taskfile_target)
                    printf 'invoke a declared Taskfile task'
                    ;;
                repo_helper_program|repo_helper_executable)
                    printf 'invoke a repo-local helper program'
                    ;;
                test_harness_script)
                    printf 'run a focused repository test harness'
                    ;;
                *)
                    printf 'invoke a discovered repository command surface'
                    ;;
            esac
            ;;
    esac
}

evop_agent_command_priority_rank() {
    case "$1" in
        high)
            printf '1'
            ;;
        normal)
            printf '2'
            ;;
        *)
            printf '3'
            ;;
    esac
}

evop_agent_command_kind_rank() {
    case "$1" in
        repo_executable)
            printf '10'
            ;;
        top_level_script)
            printf '20'
            ;;
        test_harness_script)
            printf '25'
            ;;
        repo_helper_executable)
            printf '30'
            ;;
        repo_helper_program)
            printf '40'
            ;;
        package_script)
            printf '50'
            ;;
        just_target)
            printf '55'
            ;;
        taskfile_target)
            printf '57'
            ;;
        make_target)
            printf '60'
            ;;
        *)
            printf '90'
            ;;
    esac
}

evop_agent_command_capability_preference_list() {
    case "${1:-feature}" in
        review)
            printf '%s\n' inspect verify lint status context profiles catalog
            ;;
        bugfix)
            printf '%s\n' inspect verify lint context status doctor automation
            ;;
        refactor)
            printf '%s\n' inspect context verify lint format status automation
            ;;
        performance)
            printf '%s\n' inspect context verify lint status doctor automation
            ;;
        feature|*)
            printf '%s\n' generate task inspect verify lint bootstrap context automation
            ;;
    esac
}

evop_project_agent_command_metadata_cached() {
    local target_dir="$1"
    local package_manager="${2:-}"
    local cache_key="agent-command-metadata|$package_manager"
    local output=""
    local kind=""
    local command=""
    local source=""
    local capability=""
    local runner=""
    local workdir=""
    local priority=""
    local usage=""

    EVOP_PROJECT_CONTEXT_AGENT_COMMAND_METADATA_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_AGENT_COMMAND_METADATA_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_AGENT_COMMAND_METADATA_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_METADATA_RESULT"
        return 0
    fi

    evop_project_agent_command_catalog_cached "$target_dir" "$package_manager" >/dev/null
    while IFS=$'\t' read -r kind command source; do
        [[ -n "$kind" && -n "$command" && -n "$source" ]] || continue
        capability="$(evop_agent_command_capability "$kind" "$command" "$source")"
        runner="$(evop_agent_command_runner "$kind" "$command")"
        workdir="$(evop_agent_command_workdir "$kind" "$command" "$source")"
        priority="$(evop_agent_command_priority "$kind" "$command" "$source")"
        usage="$(evop_agent_command_usage "$kind" "$command" "$source")"
        output+="$kind"$'\t'"$capability"$'\t'"$command"$'\t'"$source"$'\t'"$runner"$'\t'"$workdir"$'\t'"$priority"$'\t'"$usage"$'\n'
    done <<<"$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_RESULT"

    EVOP_PROJECT_CONTEXT_AGENT_COMMAND_METADATA_RESULT="$output"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_AGENT_COMMAND_METADATA_CACHE "$cache_key" "$output"
    printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_METADATA_RESULT"
}

evop_filter_agent_command_metadata_lines() {
    local metadata_text="$1"
    local capability_filter="${2:-all}"
    local output=""
    local kind=""
    local capability=""
    local command=""
    local source=""
    local runner=""
    local workdir=""
    local priority=""
    local usage=""

    while IFS=$'\t' read -r kind capability command source runner workdir priority usage; do
        [[ -n "$kind" && -n "$capability" && -n "$command" && -n "$source" ]] || continue
        if [[ -n "$capability_filter" && "$capability_filter" != "all" && "$capability" != "$capability_filter" ]]; then
            continue
        fi
        output+="$kind"$'\t'"$capability"$'\t'"$command"$'\t'"$source"$'\t'"$runner"$'\t'"$workdir"$'\t'"$priority"$'\t'"$usage"$'\n'
    done <<<"$metadata_text"

    printf '%s' "$output"
}

evop_recommend_agent_command_metadata_lines() {
    local metadata_text="$1"
    local task_kind="${2:-none}"
    local output=""
    local used_commands=""
    local capability=""
    local best_line=""
    local best_score=0
    local kind=""
    local current_capability=""
    local command=""
    local best_command=""
    local source=""
    local runner=""
    local workdir=""
    local priority=""
    local usage=""
    local score=0

    task_kind="$(evop_resolve_agent_recommend_task_kind "$task_kind")"
    [[ -n "$task_kind" && "$task_kind" != "none" ]] || return 0

    while IFS= read -r capability; do
        [[ -n "$capability" ]] || continue
        best_line=""
        best_command=""
        best_score=0
        while IFS=$'\t' read -r kind current_capability command source runner workdir priority usage; do
            [[ -n "$kind" && -n "$current_capability" && -n "$command" && -n "$source" ]] || continue
            [[ "$current_capability" == "$capability" ]] || continue
            case $'\n'"$used_commands"$'\n' in
                *$'\n'"$command"$'\n'*)
                    continue
                    ;;
            esac
            score=$(( $(evop_agent_command_priority_rank "$priority") * 100 + $(evop_agent_command_kind_rank "$kind") ))
            if [[ -z "$best_line" || "$score" -lt "$best_score" ]]; then
                best_line="$kind"$'\t'"$current_capability"$'\t'"$command"$'\t'"$source"$'\t'"$runner"$'\t'"$workdir"$'\t'"$priority"$'\t'"$usage"
                best_command="$command"
                best_score="$score"
            fi
        done <<<"$metadata_text"

        if [[ -n "$best_line" ]]; then
            output+="$best_line"$'\n'
            if [[ -n "$used_commands" ]]; then
                used_commands+=$'\n'
            fi
            used_commands+="$best_command"
        fi
    done < <(evop_agent_command_capability_preference_list "$task_kind")

    printf '%s' "$output"
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

evop_project_bin_executables_cached() {
    local target_dir="$1"
    local cache_key="bin-executables"
    local output=""
    local candidate=""

    EVOP_PROJECT_CONTEXT_BIN_EXECUTABLES_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_BIN_EXECUTABLES_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_BIN_EXECUTABLES_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_BIN_EXECUTABLES_RESULT"
        return 0
    fi

    for candidate in "$target_dir"/bin/*(N-.x:t); do
        if [[ -n "$output" ]]; then
            output+=$'\n'
        fi
        output+="$candidate"
    done

    EVOP_PROJECT_CONTEXT_BIN_EXECUTABLES_RESULT="$output"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_BIN_EXECUTABLES_CACHE "$cache_key" "$output"
    printf '%s' "$EVOP_PROJECT_CONTEXT_BIN_EXECUTABLES_RESULT"
}

evop_project_top_level_shell_scripts_cached() {
    local target_dir="$1"
    local cache_key="top-level-shell-scripts"
    local output=""
    local candidate=""

    EVOP_PROJECT_CONTEXT_TOP_LEVEL_SHELL_SCRIPTS_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_TOP_LEVEL_SHELL_SCRIPTS_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_TOP_LEVEL_SHELL_SCRIPTS_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_TOP_LEVEL_SHELL_SCRIPTS_RESULT"
        return 0
    fi

    for candidate in "$target_dir"/*.sh(N-.:t); do
        if [[ -n "$output" ]]; then
            output+=$'\n'
        fi
        output+="$candidate"
    done

    EVOP_PROJECT_CONTEXT_TOP_LEVEL_SHELL_SCRIPTS_RESULT="$output"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_TOP_LEVEL_SHELL_SCRIPTS_CACHE "$cache_key" "$output"
    printf '%s' "$EVOP_PROJECT_CONTEXT_TOP_LEVEL_SHELL_SCRIPTS_RESULT"
}

evop_project_helper_surface_paths_cached() {
    local target_dir="$1"
    local helper_dir="$2"
    local cache_key="helper-surface-paths|$helper_dir"
    local output=""
    local helper_paths=()
    local helper_path=""

    EVOP_PROJECT_CONTEXT_HELPER_SURFACE_PATHS_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_HELPER_SURFACE_PATHS_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_HELPER_SURFACE_PATHS_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_HELPER_SURFACE_PATHS_RESULT"
        return 0
    fi

    if [[ -d "$target_dir/$helper_dir" ]]; then
        helper_paths=(
            "$target_dir/$helper_dir"/*(N-.)
            "$target_dir/$helper_dir"/*/*(N-.)
        )
        helper_paths=("${(@on)helper_paths}")
        for helper_path in "${helper_paths[@]}"; do
            if [[ -n "$output" ]]; then
                output+=$'\n'
            fi
            output+="$helper_path"
        done
    fi

    EVOP_PROJECT_CONTEXT_HELPER_SURFACE_PATHS_RESULT="$output"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_HELPER_SURFACE_PATHS_CACHE "$cache_key" "$output"
    printf '%s' "$EVOP_PROJECT_CONTEXT_HELPER_SURFACE_PATHS_RESULT"
}

evop_project_test_harness_paths_cached() {
    local target_dir="$1"
    local cache_key="test-harness-paths"
    local output=""
    local harness_paths=()
    local harness_path=""

    EVOP_PROJECT_CONTEXT_TEST_HARNESS_PATHS_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_TEST_HARNESS_PATHS_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_TEST_HARNESS_PATHS_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_TEST_HARNESS_PATHS_RESULT"
        return 0
    fi

    harness_paths=(
        "$target_dir/tests"/run*.sh(N-.)
        "$target_dir/tests"/*/run*.sh(N-.)
    )
    harness_paths=("${(@on)harness_paths}")

    for harness_path in "${harness_paths[@]}"; do
        if [[ -n "$output" ]]; then
            output+=$'\n'
        fi
        output+="$harness_path"
    done

    EVOP_PROJECT_CONTEXT_TEST_HARNESS_PATHS_RESULT="$output"
    evop_project_context_cache_store EVOP_PROJECT_CONTEXT_TEST_HARNESS_PATHS_CACHE "$cache_key" "$output"
    printf '%s' "$EVOP_PROJECT_CONTEXT_TEST_HARNESS_PATHS_RESULT"
}

evop_append_helper_dir_agent_commands() {
    local output_name="$1"
    local target_dir="$2"
    local helper_dir="$3"
    local helper_path=""
    local rel_helper_path=""
    local command=""

    evop_project_helper_surface_paths_cached "$target_dir" "$helper_dir" >/dev/null
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
    done <<<"$EVOP_PROJECT_CONTEXT_HELPER_SURFACE_PATHS_RESULT"
}

evop_append_test_harness_agent_commands() {
    local output_name="$1"
    local target_dir="$2"
    local harness_path=""
    local rel_harness_path=""
    local command=""

    evop_project_test_harness_paths_cached "$target_dir" >/dev/null
    while IFS= read -r harness_path; do
        [[ -n "$harness_path" ]] || continue
        rel_harness_path="${harness_path#"$target_dir"/}"
        command="$(evop_agent_helper_shell_command "$harness_path" "$rel_harness_path")"
        evop_append_agent_command_catalog_entry "$output_name" "test_harness_script" "$command" "test harness script"
    done <<<"$EVOP_PROJECT_CONTEXT_TEST_HARNESS_PATHS_RESULT"
}

evop_project_agent_local_command_catalog_cached() {
    local target_dir="$1"
    local cache_key="agent-local-command-catalog"
    local output=""
    local top_level_script=""
    local makefile=""
    local justfile=""
    local taskfile=""
    local target=""

    EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_RESULT=""
    evop_use_project_context_facts_dir "$target_dir"

    if evop_project_context_cache_lookup EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_CACHE "$cache_key"; then
        EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_RESULT="$EVOP_PROJECT_CONTEXT_CACHE_LOOKUP_RESULT"
        printf '%s' "$EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_RESULT"
        return 0
    fi

    evop_project_bin_executables_cached "$target_dir" >/dev/null
    while IFS= read -r candidate; do
        [[ -n "$candidate" ]] || continue
        evop_append_agent_command_catalog_entry output "repo_executable" "./bin/$candidate" "repo executable"
    done <<<"$EVOP_PROJECT_CONTEXT_BIN_EXECUTABLES_RESULT"

    evop_project_top_level_shell_scripts_cached "$target_dir" >/dev/null
    while IFS= read -r top_level_script; do
        [[ -n "$top_level_script" ]] || continue
        evop_append_agent_command_catalog_entry output "top_level_script" "zsh ./$top_level_script" "top-level script"
    done <<<"$EVOP_PROJECT_CONTEXT_TOP_LEVEL_SHELL_SCRIPTS_RESULT"

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

    if [[ -f "$target_dir/Justfile" ]]; then
        justfile="$target_dir/Justfile"
    elif [[ -f "$target_dir/justfile" ]]; then
        justfile="$target_dir/justfile"
    elif [[ -f "$target_dir/.justfile" ]]; then
        justfile="$target_dir/.justfile"
    fi

    if [[ -n "$justfile" ]]; then
        for target in inspect verify doctor clean status profiles catalog install bootstrap setup ci release generate codegen format fmt dev start build test lint typecheck; do
            if evop_justfile_has_target "$justfile" "$target"; then
                evop_append_agent_command_catalog_entry output "just_target" "$(evop_just_recipe_command "$justfile" "$target")" "Justfile recipe"
            fi
        done
    fi

    if [[ -f "$target_dir/Taskfile.yml" ]]; then
        taskfile="$target_dir/Taskfile.yml"
    elif [[ -f "$target_dir/Taskfile.yaml" ]]; then
        taskfile="$target_dir/Taskfile.yaml"
    elif [[ -f "$target_dir/taskfile.yml" ]]; then
        taskfile="$target_dir/taskfile.yml"
    elif [[ -f "$target_dir/taskfile.yaml" ]]; then
        taskfile="$target_dir/taskfile.yaml"
    fi

    if [[ -n "$taskfile" ]]; then
        for target in inspect verify doctor clean status profiles catalog install bootstrap setup ci release generate codegen format fmt dev start build test lint typecheck; do
            if evop_taskfile_has_target "$taskfile" "$target"; then
                evop_append_agent_command_catalog_entry output "taskfile_target" "$(evop_taskfile_task_command "$taskfile" "$target")" "Taskfile task"
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
