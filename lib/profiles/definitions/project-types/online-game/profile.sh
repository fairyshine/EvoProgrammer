#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for client/server boundaries, latency tolerance, synchronization, and operational safety.\n- Be explicit about networking assumptions, state authority, and failure handling.\n- Prefer observability, testability, and incremental rollout of multiplayer features.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 96 "$prompt" "online game" "multiplayer" "networked game" "dedicated server" "client sync" "server authoritative" "联网游戏" && return 0
    return 1
}
