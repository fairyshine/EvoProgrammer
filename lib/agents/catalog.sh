#!/usr/bin/env bash

if [[ -z "${EVOP_AGENT_DEFINITIONS_DIR:-}" ]]; then
    if [[ -n "${EVOP_AGENT_LIB_DIR:-}" ]]; then
        EVOP_AGENT_DEFINITIONS_DIR="$EVOP_AGENT_LIB_DIR/definitions"
    else
        EVOP_AGENT_DEFINITIONS_DIR="$(evop_callsite_dir)/definitions"
    fi
fi

evop_supported_agents() {
    local agent_dir

    if [[ ! -d "$EVOP_AGENT_DEFINITIONS_DIR" ]]; then
        return 0
    fi

    while IFS= read -r agent_dir; do
        basename "$agent_dir"
    done < <(
        find "$EVOP_AGENT_DEFINITIONS_DIR" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/agent.sh' ';' -print 2>/dev/null \
            | LC_ALL=C sort
    )
}

evop_supported_agents_as_string() {
    local output=""
    local agent_name

    while IFS= read -r agent_name; do
        [[ -n "$agent_name" ]] || continue
        if [[ -n "$output" ]]; then
            output+=" "
        fi
        output+="$agent_name"
    done < <(evop_supported_agents)

    printf '%s' "$output"
}

evop_reset_agent_definition() {
    EVOP_AGENT_COMMAND_NAME=""
    EVOP_AGENT_DISPLAY_NAME=""
    unset -f evop_agent_build_command 2>/dev/null || true
}

evop_load_agent_definition() {
    local agent_name="$1"
    local definition_path="$EVOP_AGENT_DEFINITIONS_DIR/$agent_name/agent.sh"

    evop_reset_agent_definition

    if [[ ! -f "$definition_path" ]]; then
        evop_fail "Agent definition is missing: $definition_path"
    fi

    EVOP_AGENT_COMMAND=()

    # shellcheck source=/dev/null
    source "$definition_path"
}
