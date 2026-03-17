#!/usr/bin/env bash

EVOPROGRAMMER_ARTIFACTS_SUBDIR=".evoprogrammer/runs"

evop_require_option_value() {
    local option="$1"
    local argument_count="$2"
    if (( argument_count < 2 )); then
        evop_fail "Missing value for $option."
    fi
}

evop_resolve_artifacts_root() {
    local target_dir="$1"
    local artifacts_dir="${2:-}"

    if [[ -n "$artifacts_dir" ]]; then
        printf '%s' "$artifacts_dir"
        return 0
    fi

    printf '%s/%s' "$target_dir" "$EVOPROGRAMMER_ARTIFACTS_SUBDIR"
}

evop_prompt_source_label() {
    local prompt_file="${1:-}"

    if [[ -n "$prompt_file" ]]; then
        printf 'file:%s' "$prompt_file"
        return 0
    fi

    printf 'inline'
}

evop_resolve_physical_dir() {
    local target_path="$1"
    (
        cd "$target_path" && pwd -P
    )
}

evop_path_is_within() {
    local target_path="$1"
    local parent_dir="$2"

    [[ "$target_path" == "$parent_dir" || "$target_path" == "$parent_dir/"* ]]
}

evop_relative_path_within() {
    local target_path="$1"
    local parent_dir="$2"

    if [[ "$target_path" == "$parent_dir" ]]; then
        printf '.'
        return 0
    fi

    if [[ "$target_path" == "$parent_dir/"* ]]; then
        printf '%s' "${target_path#"$parent_dir"/}"
        return 0
    fi

    return 1
}

evop_append_unique_line() {
    local file_path="$1"
    local line="$2"

    mkdir -p "$(dirname "$file_path")"
    touch "$file_path"

    if ! grep -Fqx -- "$line" "$file_path"; then
        printf '%s\n' "$line" >>"$file_path"
    fi
}

evop_maybe_exclude_artifacts_dir() {
    local target_dir="$1"
    local artifacts_root="$2"
    local target_dir_abs
    local artifacts_root_abs
    local repo_root
    local git_common_dir
    local exclude_root
    local exclude_pattern
    local exclude_file

    mkdir -p "$artifacts_root"
    target_dir_abs="$(evop_resolve_physical_dir "$target_dir")" || return 0
    artifacts_root_abs="$(evop_resolve_physical_dir "$artifacts_root")" || return 0

    if ! evop_path_is_within "$artifacts_root_abs" "$target_dir_abs"; then
        return 0
    fi

    if ! command -v git >/dev/null 2>&1; then
        return 0
    fi

    if ! repo_root="$(cd "$target_dir_abs" && git rev-parse --show-toplevel 2>/dev/null)"; then
        return 0
    fi

    if ! git_common_dir="$(cd "$target_dir_abs" && git rev-parse --git-common-dir 2>/dev/null)"; then
        return 0
    fi

    if [[ "$git_common_dir" != /* ]]; then
        git_common_dir="$(cd "$target_dir_abs" && cd "$git_common_dir" && pwd -P)"
    fi

    exclude_root="$artifacts_root_abs"
    if evop_path_is_within "$artifacts_root_abs" "$target_dir_abs/.evoprogrammer"; then
        exclude_root="$target_dir_abs/.evoprogrammer"
    fi

    if ! evop_path_is_within "$exclude_root" "$repo_root"; then
        return 0
    fi

    exclude_pattern="$(evop_relative_path_within "$exclude_root" "$repo_root")" || return 0
    if [[ "$exclude_pattern" == "." ]]; then
        return 0
    fi

    exclude_file="$git_common_dir/info/exclude"
    evop_append_unique_line "$exclude_file" "${exclude_pattern%/}/"
}

evop_timestamp_utc() {
    date -u +"%Y%m%dT%H%M%SZ"
}

evop_prepare_unique_dir() {
    local base_dir="$1"
    local prefix="$2"
    local timestamp
    local candidate
    local suffix=0

    timestamp="$(evop_timestamp_utc)"
    mkdir -p "$base_dir"
    candidate="$base_dir/$prefix-$timestamp-$$"

    while [[ -e "$candidate" ]]; do
        suffix=$((suffix + 1))
        candidate="$base_dir/$prefix-$timestamp-$$-$suffix"
    done

    mkdir -p "$candidate"
    printf '%s' "$candidate"
}

evop_write_command_file() {
    local file_path="$1"
    shift
    local first=1

    mkdir -p "$(dirname "$file_path")"
    : >"$file_path"

    for arg in "$@"; do
        if (( first == 1 )); then
            printf '%q' "$arg" >>"$file_path"
            first=0
        else
            printf ' %q' "$arg" >>"$file_path"
        fi
    done

    printf '\n' >>"$file_path"
}

evop_write_env_file() {
    local file_path="$1"
    shift
    local key
    local value

    if (( $# % 2 != 0 )); then
        evop_fail "Metadata entries must be key/value pairs."
    fi

    mkdir -p "$(dirname "$file_path")"
    : >"$file_path"

    while (($# > 0)); do
        key="$1"
        value="$2"
        shift 2
        printf '%s=%q\n' "$key" "$value" >>"$file_path"
    done
}

evop_build_loop_command() {
    local loop_script="$1"
    local agent="$2"
    local prompt="$3"
    local prompt_file="$4"
    local language_profile="$5"
    local framework_profile="$6"
    local project_type="$7"
    local artifacts_dir="$8"
    local context_file="$9"
    local agent_args_list="${10}"
    shift 10

    EVOP_LOOP_COMMAND=("$loop_script" --agent "$agent")

    if [[ -n "$language_profile" ]]; then
        EVOP_LOOP_COMMAND+=(--language "$language_profile")
    fi

    if [[ -n "$framework_profile" ]]; then
        EVOP_LOOP_COMMAND+=(--framework "$framework_profile")
    fi

    if [[ -n "$project_type" ]]; then
        EVOP_LOOP_COMMAND+=(--project-type "$project_type")
    fi

    if [[ -n "$prompt_file" ]]; then
        EVOP_LOOP_COMMAND+=(--prompt-file "$prompt_file")
    else
        EVOP_LOOP_COMMAND+=(--prompt "$prompt")
    fi

    EVOP_LOOP_COMMAND+=(--artifacts-dir "$artifacts_dir")

    if [[ -n "$context_file" ]]; then
        EVOP_LOOP_COMMAND+=(--context-file "$context_file")
    fi

    if [[ -n "$agent_args_list" ]]; then
        EVOP_LOOP_COMMAND+=(--agent-args "$agent_args_list")
    fi

    if (($# > 0)); then
        EVOP_LOOP_COMMAND+=("$@")
    fi
}

evop_run_and_capture() {
    local target_dir="$1"
    local output_file="$2"
    shift 2
    local exit_code

    mkdir -p "$(dirname "$output_file")"

    set +e
    (
        cd "$target_dir"
        "$@"
    ) 2>&1 | tee "$output_file"
    evop_capture_pipeline_status0
    exit_code="$EVOP_PIPELINE_STATUS0"
    set -e

    return "$exit_code"
}
