#!/usr/bin/env zsh

EVOP_AGENT_COMMAND_NAME="claude"
EVOP_AGENT_DISPLAY_NAME="Claude Code"

evop_agent_build_command() {
    local target_dir="$1"
    local prompt="$2"
    shift 2

    EVOP_AGENT_COMMAND=(claude --print --dangerously-skip-permissions)

    if (($# > 0)); then
        EVOP_AGENT_COMMAND+=("$@")
    fi

    EVOP_AGENT_COMMAND+=("$prompt")
}
