#!/usr/bin/env zsh

evop_agent_is_supported() {
    local requested_agent="$1"
    local agent_name

    while IFS= read -r agent_name; do
        [[ -n "$agent_name" ]] || continue
        if [[ "$agent_name" == "$requested_agent" ]]; then
            return 0
        fi
    done < <(evop_supported_agents)

    return 1
}

evop_validate_agent() {
    local agent="$1"
    local supported_values

    if evop_agent_is_supported "$agent"; then
        return 0
    fi

    supported_values="$(evop_supported_agents_as_string)"
    evop_fail "Unsupported agent: $agent. Supported values: $supported_values"
}
