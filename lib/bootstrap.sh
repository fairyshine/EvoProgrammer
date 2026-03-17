#!/bin/sh

evop_exec_with_preferred_shell() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        return 0
    fi

    if [ -n "${BASH_VERSION:-}" ]; then
        if command -v shopt >/dev/null 2>&1 && shopt -oq posix; then
            :
        elif [ -z "${POSIXLY_CORRECT:-}" ]; then
            return 0
        fi
    fi

    if command -v zsh >/dev/null 2>&1; then
        exec zsh "$@"
    fi

    if command -v bash >/dev/null 2>&1; then
        exec bash "$@"
    fi

    printf '%s\n' "This script requires zsh or bash, but neither was found in PATH." >&2
    exit 127
}

evop_exec_with_bash() {
    evop_exec_with_preferred_shell "$@"
}

evop_run_with_preferred_shell() {
    if command -v zsh >/dev/null 2>&1; then
        EVOP_PREFERRED_SHELL=zsh zsh -c "$1"
        return $?
    fi

    if command -v bash >/dev/null 2>&1; then
        EVOP_PREFERRED_SHELL=bash bash -c "$1"
        return $?
    fi

    EVOP_PREFERRED_SHELL=sh sh -c "$1"
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
