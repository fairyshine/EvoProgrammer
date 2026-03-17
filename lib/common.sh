#!/usr/bin/env bash

EVOPROGRAMMER_DEFAULT_PROMPT="improve this repo"
EVOP_VERBOSITY="${EVOP_VERBOSITY:-1}"

evop_print_stderr() {
    printf '%s\n' "$*" >&2
}

evop_log_info() {
    if (( EVOP_VERBOSITY >= 1 )); then
        printf '%s\n' "$*"
    fi
}

evop_log_verbose() {
    if (( EVOP_VERBOSITY >= 2 )); then
        printf '%s\n' "$*"
    fi
}

evop_fail() {
    local message="$1"
    local status="${2:-1}"
    evop_print_stderr "$message"
    exit "$status"
}

evop_require_executable_file() {
    local path="$1"
    local label="$2"
    if [[ ! -x "$path" ]]; then
        evop_fail "$label is missing or not executable: $path"
    fi
}

evop_require_directory() {
    local path="$1"
    if [[ ! -d "$path" ]]; then
        evop_fail "Target directory does not exist: $path"
    fi
}

evop_require_regular_file() {
    local path="$1"
    local label="$2"
    if [[ ! -f "$path" ]]; then
        evop_fail "$label does not exist: $path"
    fi
}

evop_require_command() {
    local command_name="$1"
    if ! command -v "$command_name" >/dev/null 2>&1; then
        evop_fail "The '$command_name' CLI is required but was not found in PATH." 127
    fi
}

evop_validate_non_negative_integer() {
    local label="$1"
    local value="$2"
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        evop_fail "$label must be a non-negative integer."
    fi
}

evop_validate_zero_or_one() {
    local label="$1"
    local value="$2"
    if [[ "$value" != "0" && "$value" != "1" ]]; then
        evop_fail "$label must be 0 or 1."
    fi
}

evop_is_blank() {
    local value="$1"
    [[ "$value" =~ ^[[:space:]]*$ ]]
}

evop_resolve_prompt() {
    local prompt="$1"
    local prompt_file="$2"

    if [[ -n "$prompt_file" ]]; then
        evop_require_regular_file "$prompt_file" "Prompt file"
        prompt="$(<"$prompt_file")"
    fi

    if evop_is_blank "$prompt"; then
        evop_fail "Prompt must not be empty."
    fi

    printf '%s' "$prompt"
}

evop_print_command_preview() {
    local target_dir="$1"
    shift

    printf 'Target directory: %s\n' "$target_dir"
    printf 'Command:'
    printf ' %q' "$@"
    printf '\n'
}
