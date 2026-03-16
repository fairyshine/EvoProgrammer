#!/usr/bin/env bash

EVOPROGRAMMER_DEFAULT_AGENT="codex"
EVOP_PARSED_LIST=()

evop_validate_agent() {
    local agent="$1"

    case "$agent" in
        codex|claude)
            ;;
        *)
            evop_fail "Unsupported agent: $agent"
            ;;
    esac
}

evop_agent_command_name() {
    local agent="$1"

    case "$agent" in
        codex)
            printf 'codex'
            ;;
        claude)
            printf 'claude'
            ;;
    esac
}

evop_agent_display_name() {
    local agent="$1"

    case "$agent" in
        codex)
            printf 'Codex'
            ;;
        claude)
            printf 'Claude Code'
            ;;
    esac
}

evop_build_agent_command() {
    local agent="$1"
    local target_dir="$2"
    local prompt="$3"
    shift 3

    EVOP_AGENT_COMMAND=()

    case "$agent" in
        codex)
            EVOP_AGENT_COMMAND=(codex exec --dangerously-bypass-approvals-and-sandbox --cd "$target_dir" --add-dir "$target_dir")
            ;;
        claude)
            EVOP_AGENT_COMMAND=(claude --print --dangerously-skip-permissions)
            ;;
    esac

    if (($# > 0)); then
        EVOP_AGENT_COMMAND+=("$@")
    fi

    EVOP_AGENT_COMMAND+=("$prompt")
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
