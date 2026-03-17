#!/usr/bin/env bash

EVOP_AGENT_COMMAND_NAME="codex"
EVOP_AGENT_DISPLAY_NAME="Codex"

evop_agent_build_command() {
    local target_dir="$1"
    local prompt="$2"
    shift 2

    EVOP_AGENT_COMMAND=(codex exec --dangerously-bypass-approvals-and-sandbox --cd "$target_dir" --add-dir "$target_dir")

    if (($# > 0)); then
        EVOP_AGENT_COMMAND+=("$@")
    fi

    EVOP_AGENT_COMMAND+=("$prompt")
}
