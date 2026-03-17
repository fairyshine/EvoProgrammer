#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for clear slide narrative, audience readability, and presentation-ready output.\n- Structure source content so charts, visuals, notes, and exported deliverables stay maintainable.\n- Prefer repeatable generation workflows over one-off manual edits when automation is involved.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 99 "$target_dir" "*.pptx" "*.key" && return 0
    evop_profile_match_path_named 99 "$target_dir" "slides" && return 0
    evop_profile_match_prompt 99 "$prompt" "ppt" "slides" "slide deck" "presentation" "deck" "幻灯片" "演示文稿" && return 0
    return 1
}
