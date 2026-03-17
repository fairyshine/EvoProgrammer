#!/usr/bin/env zsh

# shellcheck disable=SC1003,SC1091,SC2034

EVOPROGRAMMER_DEFAULT_AGENT="codex"
EVOP_PARSED_LIST=()
EVOP_AGENT_COMMAND=()

if [[ -z "${EVOP_AGENT_LIB_DIR:-}" ]]; then
    if [[ -n "${EVOP_LIB_DIR:-}" ]]; then
        EVOP_AGENT_LIB_DIR="$EVOP_LIB_DIR/agents"
    else
        EVOP_AGENT_LIB_DIR="$(evop_callsite_dir)/agents"
    fi
fi

source "$EVOP_AGENT_LIB_DIR/catalog.sh"
source "$EVOP_AGENT_LIB_DIR/validate.sh"

evop_agent_command_name() {
    local agent="$1"

    evop_load_agent_definition "$agent"
    printf '%s' "$EVOP_AGENT_COMMAND_NAME"
}

evop_agent_display_name() {
    local agent="$1"

    evop_load_agent_definition "$agent"
    printf '%s' "$EVOP_AGENT_DISPLAY_NAME"
}

evop_build_agent_command() {
    local agent="$1"
    local target_dir="$2"
    local prompt="$3"
    shift 3

    evop_load_agent_definition "$agent"

    if ! evop_function_exists evop_agent_build_command; then
        evop_fail "Agent definition for '$agent' does not define evop_agent_build_command."
    fi

    if (($# > 0)); then
        evop_agent_build_command "$target_dir" "$prompt" "$@"
    else
        evop_agent_build_command "$target_dir" "$prompt"
    fi
}

evop_trim_whitespace() {
    local value="$1"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

evop_parse_string_list() {
    local raw="$1"
    local rest
    local item
    local char
    local closed
    local escaped

    EVOP_PARSED_LIST=()
    raw="$(evop_trim_whitespace "$raw")"

    if [[ "${raw:0:1}" != "[" || "${raw: -1}" != "]" ]]; then
        evop_fail "Agent args must be a JSON-like string list such as [\"--model\",\"sonnet\"]."
    fi

    rest="${raw:1:${#raw}-2}"
    rest="$(evop_trim_whitespace "$rest")"

    if [[ -z "$rest" ]]; then
        return 0
    fi

    while true; do
        rest="$(evop_trim_whitespace "$rest")"
        if [[ "${rest:0:1}" != '"' ]]; then
            evop_fail "Agent args must be a JSON-like string list such as [\"--model\",\"sonnet\"]."
        fi

        rest="${rest:1}"
        item=""
        closed=0
        escaped=0

        while ((${#rest} > 0)); do
            char="${rest:0:1}"
            rest="${rest:1}"

            if (( escaped == 1 )); then
                case "$char" in
                    '"'|'\'|/)
                        item+="$char"
                        ;;
                    b)
                        item+=$'\b'
                        ;;
                    f)
                        item+=$'\f'
                        ;;
                    n)
                        item+=$'\n'
                        ;;
                    r)
                        item+=$'\r'
                        ;;
                    t)
                        item+=$'\t'
                        ;;
                    *)
                        evop_fail "Unsupported escape sequence in agent args list: \\$char"
                        ;;
                esac
                escaped=0
                continue
            fi

            case "$char" in
                '\\')
                    escaped=1
                    ;;
                '"')
                    closed=1
                    break
                    ;;
                *)
                    item+="$char"
                    ;;
            esac
        done

        if (( closed == 0 || escaped == 1 )); then
            evop_fail "Agent args list contains an unterminated string."
        fi

        EVOP_PARSED_LIST+=("$item")
        rest="$(evop_trim_whitespace "$rest")"

        if [[ -z "$rest" ]]; then
            break
        fi

        if [[ "${rest:0:1}" != "," ]]; then
            evop_fail "Agent args must be a comma-separated string list."
        fi

        rest="${rest:1}"
    done
}
