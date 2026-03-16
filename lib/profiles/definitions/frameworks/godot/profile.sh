#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Keep scenes, nodes, autoloads, resources, and gameplay scripts organized around clear responsibilities.\n- Respect Godot editor workflows, signal patterns, and project settings instead of fighting the engine.\n- Separate reusable gameplay logic from scene-specific glue so iteration stays fast.\n- Make export templates, input mappings, and asset pipeline assumptions explicit when they matter.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "project.godot" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.gd" && return 0
    evop_profile_match_prompt 40 "$prompt" "godot" && return 0
    return 1
}
