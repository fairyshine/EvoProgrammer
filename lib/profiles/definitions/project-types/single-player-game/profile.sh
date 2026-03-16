#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for offline play, clear progression, save/load behavior, and moment-to-moment responsiveness.\n- Keep game loops, assets, controls, and content pipelines understandable for a solo codebase.\n- Prefer simple deployment and playtesting workflows over backend complexity.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 95 "$prompt" "single-player game" "offline game" "solo game" "单机游戏" && return 0
    evop_profile_match_prompt 70 "$prompt" "game" "玩法" "关卡" "combat loop" "boss fight" && return 0
    return 1
}
