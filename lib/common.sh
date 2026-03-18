#!/usr/bin/env zsh

# shellcheck disable=SC2034

EVOPROGRAMMER_DEFAULT_PROMPT="improve this repo"
EVOP_VERBOSITY="${EVOP_VERBOSITY:-1}"
EVOP_TTY_COLORS_ENABLED=""

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
    local exit_code="${2:-1}"
    evop_print_stderr "$message"
    exit "$exit_code"
}

evop_function_exists() {
    typeset -f "$1" >/dev/null 2>&1
}

evop_callsite_file_path() {
    if [[ -n "${BASH_SOURCE[1]:-}" ]]; then
        printf '%s' "${BASH_SOURCE[1]}"
        return 0
    fi

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        if [[ -n "${funcfiletrace[1]:-}" ]]; then
            printf '%s' "${funcfiletrace[1]%:*}"
            return 0
        fi

        if [[ -n "${funcsourcetrace[1]:-}" ]]; then
            printf '%s' "${funcsourcetrace[1]%:*}"
            return 0
        fi
    fi

    return 1
}

evop_callsite_dir() {
    local file_path=""

    file_path="$(evop_callsite_file_path)" || return 1
    (cd "$(dirname -- "$file_path")" && pwd)
}

evop_require_executable_file() {
    local file_path="$1"
    local label="$2"
    if [[ ! -x "$file_path" ]]; then
        evop_fail "$label is missing or not executable: $file_path"
    fi
}

evop_require_directory() {
    local dir_path="$1"
    if [[ ! -d "$dir_path" ]]; then
        evop_fail "Target directory does not exist: $dir_path"
    fi
}

evop_require_regular_file() {
    local file_path="$1"
    local label="$2"
    if [[ ! -f "$file_path" ]]; then
        evop_fail "$label does not exist: $file_path"
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

evop_trim_whitespace() {
    local value="${1:-}"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

evop_decode_env_value() {
    local encoded_value="$1"
    local decoded_value=""

    eval "decoded_value=$encoded_value"
    printf '%s' "$decoded_value"
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

evop_resolve_optional_prompt() {
    local prompt="$1"
    local prompt_file="$2"

    if [[ -n "$prompt_file" ]]; then
        evop_require_regular_file "$prompt_file" "Prompt file"
        prompt="$(<"$prompt_file")"
    fi

    printf '%s' "$prompt"
}

evop_print_command_preview() {
    local target_dir="$1"
    shift
    local rendered_command=""
    local arg=""

    for arg in "$@"; do
        if [[ -n "$rendered_command" ]]; then
            rendered_command+=" "
        fi
        rendered_command+="$(printf '%q' "$arg")"
    done

    evop_print_key_value "Target directory:" "$target_dir"
    evop_print_section "Command preview:"
    evop_print_list_item "$rendered_command"
}

evop_enable_tty_colors() {
    if [[ -n "$EVOP_TTY_COLORS_ENABLED" ]]; then
        [[ "$EVOP_TTY_COLORS_ENABLED" == "1" ]]
        return $?
    fi

    if [[ -n "${NO_COLOR:-}" ]]; then
        EVOP_TTY_COLORS_ENABLED="0"
    elif [[ -n "${CLICOLOR_FORCE:-}" && "${CLICOLOR_FORCE:-0}" != "0" ]]; then
        EVOP_TTY_COLORS_ENABLED="1"
    elif [[ -t 1 ]]; then
        EVOP_TTY_COLORS_ENABLED="1"
    else
        EVOP_TTY_COLORS_ENABLED="0"
    fi

    [[ "$EVOP_TTY_COLORS_ENABLED" == "1" ]]
}

evop_color_code() {
    case "$1" in
        reset) printf '\033[0m' ;;
        bold) printf '\033[1m' ;;
        dim) printf '\033[2m' ;;
        cyan) printf '\033[36m' ;;
        blue) printf '\033[34m' ;;
        green) printf '\033[32m' ;;
        yellow) printf '\033[33m' ;;
        red) printf '\033[31m' ;;
        magenta) printf '\033[35m' ;;
        gray) printf '\033[90m' ;;
        *) return 1 ;;
    esac
}

evop_style_text() {
    local style="$1"
    local text="$2"

    if ! evop_enable_tty_colors; then
        printf '%s' "$text"
        return 0
    fi

    printf '%b%s%b' "$(evop_color_code "$style")" "$text" "$(evop_color_code reset)"
}

evop_print_section() {
    local title="$1"

    if evop_enable_tty_colors; then
        printf '\n%b %s %b\n' "$(evop_color_code blue)$(evop_color_code bold)" "$title" "$(evop_color_code reset)"
    else
        printf '\n%s\n' "$title"
    fi
}

evop_print_key_value() {
    local key="$1"
    local value="$2"
    local key_text=""

    [[ -n "$value" ]] || return 0

    key_text="$(evop_style_text cyan "$key")"
    printf '%s %s\n' "$key_text" "$value"
}

evop_print_list_item() {
    local value="$1"
    local bullet=""

    [[ -n "$value" ]] || return 0

    bullet="$(evop_style_text magenta "•")"
    printf '  %s %s\n' "$bullet" "$value"
}

evop_print_status_badge() {
    local badge_text="$1"
    local normalized="${1:l}"
    local style="gray"

    case "$normalized" in
        passed|success|completed|done)
            style="green"
            ;;
        failed|error)
            style="red"
            ;;
        running|active|in_progress|in-progress)
            style="yellow"
            ;;
        skipped|missing|dry_run|dry-run)
            style="gray"
            ;;
    esac

    if evop_enable_tty_colors; then
        printf '%b[%s]%b' "$(evop_color_code "$style")$(evop_color_code bold)" "$badge_text" "$(evop_color_code reset)"
    else
        printf '[%s]' "$badge_text"
    fi
}

evop_print_event_line() {
    local level="$1"
    local message="$2"
    local badge=""

    case "$level" in
        info) badge="$(evop_print_status_badge "info")" ;;
        run) badge="$(evop_print_status_badge "run")" ;;
        ready) badge="$(evop_print_status_badge "ready")" ;;
        skip) badge="$(evop_print_status_badge "skip")" ;;
        pass) badge="$(evop_print_status_badge "passed")" ;;
        fail) badge="$(evop_print_status_badge "failed")" ;;
        warn) badge="$(evop_print_status_badge "warn")" ;;
        *) badge="$(evop_print_status_badge "$level")" ;;
    esac

    printf '%s %s\n' "$badge" "$message"
}

evop_log_event() {
    local level="$1"
    shift

    if (( EVOP_VERBOSITY >= 1 )); then
        evop_print_event_line "$level" "$*"
    fi
}

evop_log_event_stderr() {
    local level="$1"
    shift
    evop_print_event_line "$level" "$*" >&2
}
