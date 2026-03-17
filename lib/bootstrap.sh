#!/bin/sh

# shellcheck disable=SC2034,SC3028

evop_exec_with_preferred_shell() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        return 0
    fi

    if command -v zsh >/dev/null 2>&1; then
        exec zsh "$@"
    fi

    printf '%s\n' "This script requires zsh, but it was not found in PATH." >&2
    exit 127
}

evop_exec_with_bash() {
    evop_exec_with_preferred_shell "$@"
}

evop_run_with_preferred_shell() {
    if ! command -v zsh >/dev/null 2>&1; then
        printf '%s\n' "This command requires zsh, but it was not found in PATH." >&2
        return 127
    fi

    EVOP_PREFERRED_SHELL=zsh zsh -c "$1"
}

EVOP_PIPELINE_STATUS0=0

if [ -n "${ZSH_VERSION:-}" ]; then
    evop_capture_pipeline_status0() {
        EVOP_PIPELINE_STATUS0="${pipestatus[1]:-0}"
    }
else
    evop_capture_pipeline_status0() {
        EVOP_PIPELINE_STATUS0="${PIPESTATUS[0]:-0}"
    }
fi
