#!/usr/bin/env zsh

EVOP_HOOKS_DIR=".evoprogrammer/hooks"

evop_run_hook() {
    local target_dir="$1"
    local hook_name="$2"
    local hook_path="$target_dir/$EVOP_HOOKS_DIR/$hook_name"

    if [[ ! -x "$hook_path" ]]; then
        return 0
    fi

    evop_log_verbose "Running hook: $hook_name"

    if ! (cd "$target_dir" && "$hook_path"); then
        evop_print_stderr "Warning: hook '$hook_name' failed (exit $?). Continuing."
    fi
}
