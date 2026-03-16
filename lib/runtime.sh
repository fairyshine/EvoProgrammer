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

evop_resolve_physical_dir() {
    local path="$1"
    (
        cd "$path" && pwd -P
    )
}

evop_path_is_within() {
    local path="$1"
    local parent_dir="$2"

    [[ "$path" == "$parent_dir" || "$path" == "$parent_dir/"* ]]
}

evop_relative_path_within() {
    local path="$1"
    local parent_dir="$2"

    if [[ "$path" == "$parent_dir" ]]; then
        printf '.'
        return 0
    fi

    if [[ "$path" == "$parent_dir/"* ]]; then
        printf '%s' "${path#"$parent_dir"/}"
        return 0
    fi

    return 1
}

evop_append_unique_line() {
    local path="$1"
    local line="$2"

    mkdir -p "$(dirname "$path")"
    touch "$path"

    if ! grep -Fqx -- "$line" "$path"; then
        printf '%s\n' "$line" >>"$path"
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
    local path="$1"
    shift
    local first=1

    mkdir -p "$(dirname "$path")"
    : >"$path"

    for arg in "$@"; do
        if (( first == 1 )); then
            printf '%q' "$arg" >>"$path"
            first=0
        else
            printf ' %q' "$arg" >>"$path"
        fi
    done

    printf '\n' >>"$path"
}

evop_run_and_capture() {
    local target_dir="$1"
    local output_file="$2"
    shift 2
    local status

    mkdir -p "$(dirname "$output_file")"

    set +e
    (
        cd "$target_dir"
        "$@"
    ) 2>&1 | tee "$output_file"
    status="${PIPESTATUS[0]}"
    set -e

    return "$status"
}
