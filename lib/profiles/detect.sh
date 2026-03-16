#!/usr/bin/env bash

PROFILE_DETECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROFILE_DETECT_DIR/detect-helpers.sh"

evop_detect_language_profile() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_detect_profile_via_hooks "languages" "$target_dir" "$prompt"
}

evop_detect_framework_profile() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_detect_profile_via_hooks "frameworks" "$target_dir" "$prompt"
}

evop_detect_project_type() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_detect_profile_via_hooks "project-types" "$target_dir" "$prompt"
}
