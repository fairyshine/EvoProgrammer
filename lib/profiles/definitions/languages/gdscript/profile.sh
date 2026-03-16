#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Follow Godot scene and script conventions so nodes, scenes, and autoloads stay understandable.\n- Keep GDScript typed where practical, with clear signals, exported properties, and editor-friendly organization.\n- Prefer simple scene boundaries and reusable gameplay scripts over one giant root script.\n- Make local run, input, and asset assumptions explicit for fast playtesting.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_directory_has_file_named "$target_dir" "project.godot"; then
        EVOP_PROFILE_DETECT_SCORE=100
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.gd"; then
        EVOP_PROFILE_DETECT_SCORE=90
        return 0
    fi

    if evop_text_contains_any "$prompt" "gdscript"; then
        EVOP_PROFILE_DETECT_SCORE=40
        return 0
    fi

    return 1
}
