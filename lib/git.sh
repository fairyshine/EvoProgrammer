#!/usr/bin/env zsh

# shellcheck disable=SC2034

EVOP_GIT_BASELINE_READY=0
EVOP_GIT_BASELINE_CHANGED_PATHS=()
typeset -A EVOP_GIT_BASELINE_FINGERPRINTS=()
EVOP_GIT_CHANGED_PATHS_RESULT=()

evop_git_reset_iteration_baseline() {
    EVOP_GIT_BASELINE_READY=0
    EVOP_GIT_BASELINE_CHANGED_PATHS=()
    EVOP_GIT_CHANGED_PATHS_RESULT=()
    EVOP_GIT_BASELINE_FINGERPRINTS=()
}

evop_git_is_repo() {
    local target_dir="$1"

    command -v git >/dev/null 2>&1 || return 1
    (cd "$target_dir" && git rev-parse --show-toplevel >/dev/null 2>&1)
}

evop_git_has_head() {
    local target_dir="$1"

    (cd "$target_dir" && git rev-parse --verify HEAD >/dev/null 2>&1)
}

evop_git_append_unique_path() {
    local rel_path="$1"
    local existing=""

    [[ -n "$rel_path" ]] || return 0

    for existing in "${EVOP_GIT_CHANGED_PATHS_RESULT[@]}"; do
        if [[ "$existing" == "$rel_path" ]]; then
            return 0
        fi
    done

    EVOP_GIT_CHANGED_PATHS_RESULT+=("$rel_path")
}

evop_git_collect_changed_paths() {
    local target_dir="$1"
    local rel_path=""

    EVOP_GIT_CHANGED_PATHS_RESULT=()

    while IFS= read -r -d '' rel_path; do
        evop_git_append_unique_path "$rel_path"
    done < <(
        cd "$target_dir" &&
            {
                git diff --name-only --relative -z
                git diff --cached --name-only --relative -z
                git ls-files --others --exclude-standard -z
            } 2>/dev/null
    )
}

evop_git_path_fingerprint() {
    local target_dir="$1"
    local rel_path="$2"
    local abs_path="$target_dir/$rel_path"

    if [[ -L "$abs_path" ]]; then
        printf 'symlink:%s' "$(readlink "$abs_path")"
        return 0
    fi

    if [[ -f "$abs_path" ]]; then
        printf 'file:%s' "$(cd "$target_dir" && git hash-object -- "$rel_path" 2>/dev/null)"
        return 0
    fi

    if [[ -e "$abs_path" ]]; then
        printf 'path:present'
        return 0
    fi

    printf 'missing'
}

evop_git_snapshot_iteration_baseline() {
    local target_dir="$1"
    local rel_path=""

    evop_git_reset_iteration_baseline

    if ! evop_git_is_repo "$target_dir"; then
        return 1
    fi

    evop_git_collect_changed_paths "$target_dir"
    EVOP_GIT_BASELINE_CHANGED_PATHS=("${EVOP_GIT_CHANGED_PATHS_RESULT[@]}")

    for rel_path in "${EVOP_GIT_BASELINE_CHANGED_PATHS[@]}"; do
        EVOP_GIT_BASELINE_FINGERPRINTS[$rel_path]="$(evop_git_path_fingerprint "$target_dir" "$rel_path")"
    done

    EVOP_GIT_BASELINE_READY=1
    return 0
}

evop_git_default_commit_message() {
    local prompt="${1:-}"
    local summary="$prompt"

    summary="${summary//$'\r'/ }"
    summary="${summary//$'\n'/ }"
    while [[ "$summary" == *"  "* ]]; do
        summary="${summary//  / }"
    done
    summary="${summary#"${summary%%[![:space:]]*}"}"
    summary="${summary%"${summary##*[![:space:]]}"}"

    if [[ -z "$summary" ]]; then
        printf 'feat: apply EvoProgrammer update'
        return 0
    fi

    if (( ${#summary} > 60 )); then
        summary="${summary[1,57]}..."
    fi

    printf 'feat: %s' "$summary"
}

evop_git_collect_iteration_paths() {
    local target_dir="$1"
    local current_paths=()
    local rel_path=""
    local baseline_fingerprint=""
    local current_fingerprint=""

    EVOP_GIT_CHANGED_PATHS_RESULT=()

    if ! evop_git_is_repo "$target_dir"; then
        return 1
    fi

    evop_git_collect_changed_paths "$target_dir"
    current_paths=("${EVOP_GIT_CHANGED_PATHS_RESULT[@]}")
    EVOP_GIT_CHANGED_PATHS_RESULT=()

    for rel_path in "${current_paths[@]}"; do
        if [[ -z ${EVOP_GIT_BASELINE_FINGERPRINTS[$rel_path]+set} ]]; then
            EVOP_GIT_CHANGED_PATHS_RESULT+=("$rel_path")
            continue
        fi

        baseline_fingerprint="${EVOP_GIT_BASELINE_FINGERPRINTS[$rel_path]}"
        current_fingerprint="$(evop_git_path_fingerprint "$target_dir" "$rel_path")"
        if [[ "$baseline_fingerprint" != "$current_fingerprint" ]]; then
            EVOP_GIT_CHANGED_PATHS_RESULT+=("$rel_path")
        fi
    done
}

evop_git_auto_commit_iteration() {
    local target_dir="$1"
    local commit_message="${2:-}"
    shift 2

    if ! evop_git_is_repo "$target_dir"; then
        evop_print_stderr "Warning: auto-commit skipped because the target directory is not inside a git repository."
        return 0
    fi

    if (( EVOP_GIT_BASELINE_READY != 1 )); then
        evop_git_snapshot_iteration_baseline "$target_dir" || return 0
    fi

    evop_git_collect_iteration_paths "$target_dir"
    if (( ${#EVOP_GIT_CHANGED_PATHS_RESULT[@]} == 0 )); then
        evop_log_verbose "Auto-commit skipped: no new iteration changes were detected."
        return 0
    fi

    if [[ -z "$commit_message" ]]; then
        commit_message="$(evop_git_default_commit_message "${1:-}")"
    fi

    evop_log_event "info" "Auto-committing iteration changes."

    (
        cd "$target_dir"
        git add -A -- "${EVOP_GIT_CHANGED_PATHS_RESULT[@]}"
        if evop_git_has_head "$target_dir"; then
            git commit -m "$commit_message" -- "${EVOP_GIT_CHANGED_PATHS_RESULT[@]}"
        else
            git commit -m "$commit_message"
        fi
    )
}
